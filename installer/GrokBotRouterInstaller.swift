import AppKit
import CryptoKit
import Foundation
import Vision

private let supportedGrokVersion = "0.30.0"
private let grokBundleIdentifier = "com.anysphere.sand"
private let grokAppPath = "/Applications/Grok Bot.app"
private let cdpPort = 19222

enum InstallerError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let value): return value
        }
    }
}

final class CDPClient {
    private let task: URLSessionWebSocketTask
    private var nextID = 1

    init(url: URL) {
        task = URLSession(configuration: .default).webSocketTask(with: url)
        task.resume()
    }

    deinit {
        task.cancel(with: .goingAway, reason: nil)
    }

    private func nextRequestID() -> Int {
        let requestID = nextID
        nextID += 1
        return requestID
    }

    private func send(_ envelope: [String: Any]) async throws {
        let data = try JSONSerialization.data(withJSONObject: envelope)
        guard let string = String(data: data, encoding: .utf8) else {
            throw InstallerError.message("Could not encode a DevTools request.")
        }
        try await task.send(.string(string))
    }

    private func receiveObject() async throws -> [String: Any] {
        while true {
            let message = try await task.receive()
            let responseData: Data
            switch message {
            case .string(let text): responseData = Data(text.utf8)
            case .data(let data): responseData = data
            @unknown default: continue
            }
            if let value = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                return value
            }
        }
    }

    private func result(from value: [String: Any]) throws -> [String: Any] {
        if let error = value["error"] {
            throw InstallerError.message("DevTools error: \(error)")
        }
        return value["result"] as? [String: Any] ?? [:]
    }

    func call(_ method: String, params: [String: Any] = [:], sessionID: String? = nil) async throws -> [String: Any] {
        if let sessionID {
            return try await callNested(method, params: params, sessionID: sessionID)
        }
        let requestID = nextRequestID()
        try await send(["id": requestID, "method": method, "params": params])
        while true {
            let value = try await receiveObject()
            guard (value["id"] as? Int) == requestID else { continue }
            return try result(from: value)
        }
    }

    // Electron 40 accepts flattened sessions for Runtime reads but can route Input
    // commands to the main renderer. Nested target messages keep noVNC keyboard
    // input inside the Bot computer on the same diagnostic WebSocket.
    private func callNested(_ method: String, params: [String: Any], sessionID: String) async throws -> [String: Any] {
        let nestedID = nextRequestID()
        let outerID = nextRequestID()
        let nestedData = try JSONSerialization.data(withJSONObject: [
            "id": nestedID,
            "method": method,
            "params": params
        ])
        guard let nestedMessage = String(data: nestedData, encoding: .utf8) else {
            throw InstallerError.message("Could not encode a nested DevTools request.")
        }
        try await send([
            "id": outerID,
            "method": "Target.sendMessageToTarget",
            "params": ["sessionId": sessionID, "message": nestedMessage]
        ])
        while true {
            let value = try await receiveObject()
            if (value["id"] as? Int) == outerID {
                _ = try result(from: value)
                continue
            }
            guard value["method"] as? String == "Target.receivedMessageFromTarget",
                  let eventParams = value["params"] as? [String: Any],
                  eventParams["sessionId"] as? String == sessionID,
                  let message = eventParams["message"] as? String,
                  let messageData = message.data(using: .utf8),
                  let nested = try JSONSerialization.jsonObject(with: messageData) as? [String: Any],
                  (nested["id"] as? Int) == nestedID else { continue }
            return try result(from: nested)
        }
    }
}

struct TargetInfo {
    let id: String
    let type: String
    let title: String
    let url: String
}

struct AttachedTarget {
    let targetID: String
    let sessionID: String
}

final class InstallerCardView: NSView {
    init(content: NSView, padding: NSEdgeInsets = NSEdgeInsets(top: 18, left: 20, bottom: 18, right: 20)) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.backgroundColor = NSColor(calibratedRed: 0.105, green: 0.112, blue: 0.118, alpha: 1).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor(calibratedWhite: 1, alpha: 0.075).cgColor
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding.right),
            content.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding.bottom)
        ])
    }

    required init?(coder: NSCoder) { nil }
}

final class RouterInstallerController: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private let codexCheckbox = NSButton(checkboxWithTitle: "Codex SDK", target: nil, action: nil)
    private let openRouterCheckbox = NSButton(checkboxWithTitle: "OpenRouter", target: nil, action: nil)
    private let defaultProviderPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let codexModelPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let openRouterModelPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let openRouterKeyField = NSSecureTextField()
    private let installButton = NSButton(title: "Install Router", target: nil, action: nil)
    private let authButton = NSButton(title: "Start Codex Sign-in", target: nil, action: nil)
    private let doctorButton = NSButton(title: "Run Doctor", target: nil, action: nil)
    private let repairButton = NSButton(title: "Repair Router", target: nil, action: nil)
    private let uninstallButton = NSButton(title: "Restore Stock Grok Bot", target: nil, action: nil)
    private let progress = NSProgressIndicator()
    private let statusLabel = NSTextField(labelWithString: "Ready. Grok Bot will restart during installation.")
    private let logView = NSTextView()
    private var busy = false
    private var diagnosticsLaunchedByInstaller = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildWindow()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 790),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "GrokRouter"
        window.backgroundColor = NSColor(calibratedRed: 0.055, green: 0.059, blue: 0.063, alpha: 1)
        window.appearance = NSAppearance(named: .darkAqua)

        let iconView = NSImageView()
        iconView.image = Bundle.main.url(forResource: "AppIcon", withExtension: "icns").flatMap(NSImage.init(contentsOf:))
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 88).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 88).isActive = true

        let eyebrow = NSTextField(labelWithString: "PRIVATE BETA  •  GROK BOT 0.30.0")
        eyebrow.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        eyebrow.textColor = NSColor(calibratedRed: 1.0, green: 0.48, blue: 0.12, alpha: 1)
        let title = NSTextField(labelWithString: "Bring your own brain.")
        title.font = .systemFont(ofSize: 30, weight: .bold)
        title.textColor = .labelColor
        let subtitle = NSTextField(wrappingLabelWithString: "Keep Grok Bot’s interface, computer, files and tools. Route each Bot through Codex or OpenRouter, then switch models from the normal chat composer.")
        subtitle.textColor = .secondaryLabelColor
        subtitle.font = .systemFont(ofSize: 14, weight: .regular)
        subtitle.maximumNumberOfLines = 3
        let heroCopy = NSStackView(views: [eyebrow, title, subtitle])
        heroCopy.orientation = .vertical
        heroCopy.alignment = .leading
        heroCopy.spacing = 6
        let hero = NSStackView(views: [iconView, heroCopy])
        hero.orientation = .horizontal
        hero.alignment = .centerY
        hero.spacing = 20

        codexCheckbox.state = .on
        openRouterCheckbox.state = .on
        codexCheckbox.target = self
        openRouterCheckbox.target = self
        codexCheckbox.action = #selector(providerSelectionChanged)
        openRouterCheckbox.action = #selector(providerSelectionChanged)

        defaultProviderPopup.addItems(withTitles: ["Codex SDK", "OpenRouter"])
        codexModelPopup.addItems(withTitles: ["gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna"])
        openRouterModelPopup.addItems(withTitles: [
            "anthropic/claude-sonnet-4.6",
            "openai/gpt-5.6-sol",
            "openai/gpt-5.6-terra",
            "openai/gpt-5.6-luna",
            "google/gemini-3.1-pro-preview",
            "google/gemini-3.1-flash-lite"
        ])
        openRouterKeyField.placeholderString = "OpenRouter API key (stored only in Grok Bot Secrets)"

        codexCheckbox.font = .systemFont(ofSize: 14, weight: .medium)
        openRouterCheckbox.font = .systemFont(ofSize: 14, weight: .medium)
        let providerRow = NSStackView(views: [codexCheckbox, openRouterCheckbox])
        providerRow.orientation = .horizontal
        providerRow.spacing = 28
        let defaultRow = formRow("Default provider", defaultProviderPopup)
        let codexRow = formRow("Codex model", codexModelPopup)
        let openRouterRow = formRow("OpenRouter model", openRouterModelPopup)
        let keyRow = formRow("OpenRouter key", openRouterKeyField)

        let modelSectionHeader = sectionHeader(
            number: "01",
            title: "Choose the models",
            detail: "New Bots start on the default. Each Bot can switch later."
        )
        let modelStack = NSStackView(views: [modelSectionHeader, providerRow, defaultRow, codexRow, openRouterRow, keyRow])
        modelStack.orientation = .vertical
        modelStack.alignment = .leading
        modelStack.spacing = 12
        let modelCard = InstallerCardView(content: modelStack)

        installButton.isBordered = false
        installButton.wantsLayer = true
        installButton.layer?.cornerRadius = 10
        installButton.layer?.backgroundColor = NSColor(calibratedRed: 0.94, green: 0.34, blue: 0.08, alpha: 1).cgColor
        installButton.attributedTitle = NSAttributedString(
            string: "Install Router",
            attributes: [.font: NSFont.systemFont(ofSize: 15, weight: .semibold), .foregroundColor: NSColor.white]
        )
        installButton.heightAnchor.constraint(equalToConstant: 42).isActive = true
        installButton.widthAnchor.constraint(equalToConstant: 176).isActive = true
        installButton.keyEquivalent = "\r"
        installButton.target = self
        installButton.action = #selector(startInstall)
        authButton.target = self
        authButton.action = #selector(startCodexAuth)
        doctorButton.target = self
        doctorButton.action = #selector(startDoctor)
        repairButton.target = self
        repairButton.action = #selector(startRepair)
        uninstallButton.target = self
        uninstallButton.action = #selector(startUninstall)
        authButton.title = "Codex sign-in"
        doctorButton.title = "Check health"
        repairButton.title = "Repair"
        uninstallButton.title = "Restore stock"
        [authButton, doctorButton, repairButton, uninstallButton].forEach(styleUtilityButton)
        let utilities = NSStackView(views: [authButton, doctorButton, repairButton, uninstallButton])
        utilities.orientation = .horizontal
        utilities.spacing = 8
        utilities.distribution = .fillEqually

        progress.style = .spinning
        progress.controlSize = .small
        progress.isDisplayedWhenStopped = false
        progress.isHidden = true
        progress.contentFilters = []
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        let statusRow = NSStackView(views: [progress, statusLabel])
        statusRow.orientation = .horizontal
        statusRow.spacing = 10
        let statusCard = InstallerCardView(
            content: statusRow,
            padding: NSEdgeInsets(top: 11, left: 14, bottom: 11, right: 14)
        )

        let installSectionHeader = sectionHeader(
            number: "02",
            title: "Install once",
            detail: "The router then applies automatically to every new Bot."
        )
        let note = NSTextField(wrappingLabelWithString: "Keep Grok Bot visible. If asked, select any Bot and open its Computer. The installer verifies the exact app version, saves a stock backup, and reconnects Grok Bot when it finishes.")
        note.textColor = .secondaryLabelColor
        note.font = .systemFont(ofSize: 12, weight: .regular)
        note.maximumNumberOfLines = 3
        let installRow = NSStackView(views: [note, installButton])
        installRow.orientation = .horizontal
        installRow.alignment = .centerY
        installRow.spacing = 20
        let utilityLabel = NSTextField(labelWithString: "TOOLS")
        utilityLabel.font = .monospacedSystemFont(ofSize: 10, weight: .semibold)
        utilityLabel.textColor = .tertiaryLabelColor
        let installStack = NSStackView(views: [installSectionHeader, installRow, utilityLabel, utilities])
        installStack.orientation = .vertical
        installStack.alignment = .leading
        installStack.spacing = 12
        let installCard = InstallerCardView(content: installStack)

        logView.isEditable = false
        logView.isSelectable = true
        logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logView.textColor = NSColor(calibratedWhite: 0.76, alpha: 1)
        logView.backgroundColor = NSColor(calibratedRed: 0.035, green: 0.038, blue: 0.041, alpha: 1)
        logView.textContainerInset = NSSize(width: 12, height: 10)
        logView.string = "The installer will verify Grok Bot 0.30.0, create a stock backup, install the pinned runtime, and test the result.\n"
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.wantsLayer = true
        scroll.layer?.cornerRadius = 10
        scroll.layer?.borderWidth = 1
        scroll.layer?.borderColor = NSColor(calibratedWhite: 1, alpha: 0.06).cgColor
        scroll.documentView = logView
        scroll.heightAnchor.constraint(equalToConstant: 118).isActive = true
        let activityLabel = NSTextField(labelWithString: "ACTIVITY")
        activityLabel.font = .monospacedSystemFont(ofSize: 10, weight: .semibold)
        activityLabel.textColor = .tertiaryLabelColor

        let stack = NSStackView(views: [hero, modelCard, installCard, statusCard, activityLabel, scroll])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.contentView?.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 30),
            stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -30),
            stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 26),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: window.contentView!.bottomAnchor, constant: -26),
            hero.widthAnchor.constraint(equalTo: stack.widthAnchor),
            modelCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
            installCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
            statusCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scroll.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        providerSelectionChanged()
    }

    private func sectionHeader(number: String, title: String, detail: String) -> NSStackView {
        let numberLabel = NSTextField(labelWithString: number)
        numberLabel.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
        numberLabel.textColor = NSColor(calibratedRed: 1.0, green: 0.48, blue: 0.12, alpha: 1)
        numberLabel.widthAnchor.constraint(equalToConstant: 28).isActive = true
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        let detailLabel = NSTextField(labelWithString: detail)
        detailLabel.font = .systemFont(ofSize: 12, weight: .regular)
        detailLabel.textColor = .secondaryLabelColor
        let copy = NSStackView(views: [titleLabel, detailLabel])
        copy.orientation = .vertical
        copy.alignment = .leading
        copy.spacing = 2
        let row = NSStackView(views: [numberLabel, copy])
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = 8
        return row
    }

    private func styleUtilityButton(_ button: NSButton) {
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 8
        button.layer?.backgroundColor = NSColor(calibratedWhite: 1, alpha: 0.065).cgColor
        button.layer?.borderWidth = 1
        button.layer?.borderColor = NSColor(calibratedWhite: 1, alpha: 0.07).cgColor
        button.font = .systemFont(ofSize: 12, weight: .medium)
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
    }

    private func formRow(_ label: String, _ control: NSView) -> NSStackView {
        let text = NSTextField(labelWithString: label)
        text.font = .systemFont(ofSize: 13, weight: .medium)
        text.widthAnchor.constraint(equalToConstant: 126).isActive = true
        control.translatesAutoresizingMaskIntoConstraints = false
        let row = NSStackView(views: [text, control])
        row.orientation = .horizontal
        row.spacing = 12
        control.widthAnchor.constraint(greaterThanOrEqualToConstant: 500).isActive = true
        return row
    }

    @objc private func providerSelectionChanged() {
        let codex = codexCheckbox.state == .on
        let openRouter = openRouterCheckbox.state == .on
        let previousSelection = defaultProviderPopup.titleOfSelectedItem
        codexModelPopup.isEnabled = codex
        openRouterModelPopup.isEnabled = openRouter
        openRouterKeyField.isEnabled = openRouter
        defaultProviderPopup.removeAllItems()
        if codex { defaultProviderPopup.addItem(withTitle: "Codex SDK") }
        if openRouter { defaultProviderPopup.addItem(withTitle: "OpenRouter") }
        if let previousSelection, defaultProviderPopup.itemTitles.contains(previousSelection) {
            defaultProviderPopup.selectItem(withTitle: previousSelection)
        }
        installButton.isEnabled = (codex || openRouter) && !busy
    }

    private func setBusy(_ value: Bool, status: String) {
        busy = value
        statusLabel.stringValue = status
        progress.isHidden = !value
        if value { progress.startAnimation(nil) } else { progress.stopAnimation(nil) }
        codexCheckbox.isEnabled = !value
        openRouterCheckbox.isEnabled = !value
        installButton.isEnabled = !value
        installButton.alphaValue = value ? 0.55 : 1
        authButton.isEnabled = !value
        doctorButton.isEnabled = !value
        repairButton.isEnabled = !value
        uninstallButton.isEnabled = !value
        if !value { providerSelectionChanged() }
    }

    private func appendLog(_ text: String) {
        DispatchQueue.main.async {
            self.logView.string += text.hasSuffix("\n") ? text : "\(text)\n"
            self.logView.scrollToEndOfDocument(nil)
        }
    }

    private func runOperation(_ initialStatus: String, operation: @escaping () async throws -> String) {
        guard !busy else { return }
        setBusy(true, status: initialStatus)
        Task {
            do {
                let message = try await operation()
                await self.relaunchGrokNormallyIfNeeded()
                await MainActor.run {
                    self.setBusy(false, status: message)
                    self.appendLog("✓ \(message)")
                }
            } catch {
                await self.relaunchGrokNormallyIfNeeded()
                await MainActor.run {
                    let detail = error.localizedDescription
                    self.setBusy(false, status: "Stopped: \(detail)")
                    self.appendLog("✗ \(detail)")
                }
            }
        }
    }

    @objc private func startInstall() {
        let codex = codexCheckbox.state == .on
        let openRouter = openRouterCheckbox.state == .on
        guard codex || openRouter else { return }
        let defaultProvider = defaultProviderPopup.titleOfSelectedItem == "OpenRouter" ? "openrouter" : "codex"
        let providers = [codex ? "codex" : nil, openRouter ? "openrouter" : nil].compactMap { $0 }.joined(separator: ",")
        let codexModel = codexModelPopup.titleOfSelectedItem ?? "gpt-5.6-sol"
        let openRouterModel = openRouterModelPopup.titleOfSelectedItem ?? "anthropic/claude-sonnet-4.6"
        let key = openRouterKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if openRouter && !key.isEmpty && !isValidOpenRouterKey(key) {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "That OpenRouter key does not look valid"
            alert.informativeText = "Paste the complete key beginning with sk-or-v1-. Nothing has been saved or installed."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        openRouterKeyField.stringValue = ""
        runOperation("Checking Grok Bot…") {
            try await self.install(
                defaultProvider: defaultProvider,
                providers: providers,
                codexModel: codexModel,
                openRouterModel: openRouterModel,
                openRouterKey: key
            )
        }
    }

    @objc private func startCodexAuth() {
        runOperation("Opening Codex sign-in inside the Bot computer…") {
            try await self.sendRemoteCommand(
                "/home/box/.local/bin/grokbot-router auth codex",
                relaunch: false,
                confirmationSentinel: "Welcome to Codex"
            )
            return "Codex sign-in is visible in the Bot terminal. Complete the displayed device flow."
        }
    }

    @objc private func startDoctor() {
        runOperation("Opening Router Doctor…") {
            try await self.sendRemoteCommand(
                "/home/box/.local/bin/grokbot-router doctor",
                relaunch: false,
                confirmationSentinel: "GROKBOT_ROUTER_DOCTOR_DONE"
            )
            return "Router Doctor is running in the Bot terminal."
        }
    }

    @objc private func startRepair() {
        runOperation("Repairing the version-gated host adapter…") {
            try await self.sendRemoteCommand(
                "/home/box/.local/bin/grokbot-router repair",
                relaunch: false,
                confirmationSentinel: "GROKBOT_ROUTER_REPAIR_OK"
            )
            return "Router repaired. Automatic repair is enabled. Send /provider in Grok Bot."
        }
    }

    @objc private func startUninstall() {
        let alert = NSAlert()
        alert.messageText = "Restore stock Grok Bot?"
        alert.informativeText = "This restores the verified stock host. The router runtime and backup stay on the Bot computer so the change remains recoverable."
        alert.addButton(withTitle: "Restore Stock")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        runOperation("Restoring the stock Grok Bot host…") {
            try await self.sendRemoteCommand(
                "/home/box/.local/bin/grokbot-router uninstall",
                relaunch: false,
                confirmationSentinel: "GROKBOT_ROUTER_UNINSTALL_OK"
            )
            return "Restore command sent. Grok Bot will reconnect to its stock host."
        }
    }

    private func validateGrokApp() throws {
        let plistPath = "\(grokAppPath)/Contents/Info.plist"
        guard let info = NSDictionary(contentsOfFile: plistPath) as? [String: Any] else {
            throw InstallerError.message("Install the official Grok Bot app in /Applications first.")
        }
        let version = info["CFBundleShortVersionString"] as? String ?? "unknown"
        guard version == supportedGrokVersion else {
            throw InstallerError.message("Grok Bot \(version) is not supported. This beta is pinned to \(supportedGrokVersion) and will not patch an unknown build.")
        }
    }

    private func relaunchGrokWithDiagnostics() async throws {
        appendLog("Verified Grok Bot \(supportedGrokVersion). Restarting with a local diagnostic port…")
        await stopRunningGrok()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-na", grokAppPath, "--args", "--remote-debugging-address=127.0.0.1", "--remote-debugging-port=\(cdpPort)"]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw InstallerError.message("Grok Bot could not be relaunched.")
        }
        diagnosticsLaunchedByInstaller = true
        for _ in 0..<120 {
            if (try? await browserWebSocketURL()) != nil { return }
            try await Task.sleep(nanoseconds: 250_000_000)
        }
        throw InstallerError.message("Grok Bot's local diagnostic connection did not become ready.")
    }

    private func stopRunningGrok() async {
        let running = {
            NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier == grokBundleIdentifier }
        }
        for app in running() { _ = app.terminate() }
        for _ in 0..<40 {
            if running().isEmpty { return }
            try? await Task.sleep(nanoseconds: 125_000_000)
        }
        for app in running() { _ = app.forceTerminate() }
        for _ in 0..<40 {
            if running().isEmpty { return }
            try? await Task.sleep(nanoseconds: 125_000_000)
        }
    }

    private func relaunchGrokNormallyIfNeeded() async {
        let diagnosticEndpointOpen = (try? await browserWebSocketURL()) != nil
        guard diagnosticsLaunchedByInstaller || diagnosticEndpointOpen else { return }
        appendLog("Closing the temporary diagnostic port and reopening Grok Bot normally…")
        await stopRunningGrok()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-na", grokAppPath]
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                appendLog("Grok Bot did not reopen automatically. Open it normally from Applications.")
            }
        } catch {
            appendLog("Grok Bot did not reopen automatically. Open it normally from Applications.")
        }
        diagnosticsLaunchedByInstaller = false
    }

    private func browserWebSocketURL() async throws -> URL {
        let url = URL(string: "http://127.0.0.1:\(cdpPort)/json/version")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let value = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let string = value["webSocketDebuggerUrl"] as? String,
              let result = URL(string: string) else {
            throw InstallerError.message("Grok Bot's diagnostic endpoint is unavailable.")
        }
        return result
    }

    private func targets(_ client: CDPClient) async throws -> [TargetInfo] {
        let result = try await client.call("Target.getTargets")
        let raw = result["targetInfos"] as? [[String: Any]] ?? []
        return raw.compactMap { item in
            guard let id = item["targetId"] as? String else { return nil }
            return TargetInfo(
                id: id,
                type: item["type"] as? String ?? "",
                title: item["title"] as? String ?? "",
                url: item["url"] as? String ?? ""
            )
        }
    }

    private func attach(_ client: CDPClient, targetID: String) async throws -> String {
        let result = try await client.call("Target.attachToTarget", params: ["targetId": targetID, "flatten": false])
        guard let sessionID = result["sessionId"] as? String else {
            throw InstallerError.message("Could not attach to Grok Bot's computer session.")
        }
        return sessionID
    }

    private func mainPageSession(_ client: CDPClient) async throws -> String {
        let page = try await targets(client).first { $0.type == "page" && $0.url.contains("/renderer/index.html") }
        guard let page else { throw InstallerError.message("Grok Bot's main window was not found.") }
        return try await attach(client, targetID: page.id)
    }

    private func jsonLiteral(_ value: String) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: [value])
        let array = String(data: data, encoding: .utf8)!
        return String(array.dropFirst().dropLast())
    }

    private func isValidOpenRouterKey(_ value: String) -> Bool {
        value.hasPrefix("sk-or-v1-") && value.count >= 33 && !value.contains(where: { $0.isWhitespace })
    }

    private func evaluate(_ client: CDPClient, sessionID: String, expression: String) async throws -> [String: Any] {
        try await client.call("Runtime.evaluate", params: [
            "expression": expression,
            "awaitPromise": true,
            "returnByValue": true
        ], sessionID: sessionID)
    }

    private func saveOpenRouterKey(_ key: String, client: CDPClient, pageSession: String) async throws {
        guard !key.isEmpty else { return }
        appendLog("Saving OPENROUTER_API_KEY through Grok Bot's protected Secrets store…")
        let literal = try jsonLiteral(key)
        _ = try await evaluate(
            client,
            sessionID: pageSession,
            expression: "window.desktop.secrets.upsert({OPENROUTER_API_KEY:\(literal)}).then(()=>({saved:true}))"
        )
    }

    private func tryOpenComputer(_ client: CDPClient, pageSession: String) async throws {
        let script = """
        (() => {
          const buttons = [...document.querySelectorAll('button')];
          const button = buttons.find((item) => /open computer/i.test(item.textContent || item.getAttribute('aria-label') || ''));
          if (!button) return false;
          button.click();
          return true;
        })()
        """
        _ = try? await evaluate(client, sessionID: pageSession, expression: script)
    }

    private func waitForVNC(_ client: CDPClient, pageSession: String) async throws -> AttachedTarget {
        appendLog("Waiting for a Bot computer. If Grok Bot does not open it automatically, select any Bot and click Open computer…")
        for index in 0..<360 {
            if let vnc = try await targets(client).first(where: { $0.type == "webview" && $0.url.contains("/vnc.html") }) {
                return AttachedTarget(targetID: vnc.id, sessionID: try await attach(client, targetID: vnc.id))
            }
            // Reuse an already open computer. Clicking first can replace the
            // valid webview between installer phases and manufacture a retry.
            if index % 20 == 0 { try? await tryOpenComputer(client, pageSession: pageSession) }
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        throw InstallerError.message("No Bot computer appeared. Open one in Grok Bot and try again.")
    }

    private func keyEvent(
        _ client: CDPClient,
        sessionID: String,
        type: String,
        key: String,
        code: String,
        virtualKey: Int,
        modifiers: Int = 0
    ) async throws {
        let keysym: Int
        switch virtualKey {
        case 13: keysym = 0xff0d
        case 17: keysym = 0xffe3
        case 18: keysym = 0xffe9
        default:
            guard key.count == 1, let scalar = key.unicodeScalars.first else {
                throw InstallerError.message("The Bot computer received an unsupported key event.")
            }
            keysym = Int(scalar.value)
        }
        let down = type == "keyDown"
        let codeLiteral = try jsonLiteral(code)
        let expression = """
        (async () => {
          const UI = (await import('./app/ui.js')).default;
          if (!UI?.rfb) return false;
          UI.rfb.sendKey(\(keysym), \(codeLiteral), \(down ? "true" : "false"));
          return true;
        })()
        """
        let response = try await evaluate(client, sessionID: sessionID, expression: expression)
        guard let remoteObject = response["result"] as? [String: Any],
              remoteObject["value"] as? Bool == true else {
            throw InstallerError.message("The Bot computer did not accept a noVNC key event.")
        }
    }

    private func clickRemoteCanvas(_ client: CDPClient, sessionID: String, x: Int, y: Int) async throws {
        // The pinned noVNC build exports its connected RFB instance from UI.
        // Use that exact input path because nested CDP events can return success
        // without being forwarded through Electron's guest webview.
        let expression = """
        (async () => {
          const UI = (await import('./app/ui.js')).default;
          const canvas = document.querySelector('#noVNC_container canvas') || document.querySelector('canvas');
          if (!UI?.rfb || !canvas) return false;
          const rect = canvas.getBoundingClientRect();
          const localX = \(x) - rect.left;
          const localY = \(y) - rect.top;
          UI.rfb._handleMouseButton(localX, localY, 1);
          UI.rfb._handleMouseButton(localX, localY, 0);
          return true;
        })()
        """
        let response = try await evaluate(client, sessionID: sessionID, expression: expression)
        guard let remoteObject = response["result"] as? [String: Any],
              remoteObject["value"] as? Bool == true else {
            throw InstallerError.message("The Bot computer did not accept a noVNC pointer event.")
        }
    }

    private func clickRemoteDesktop(
        _ client: CDPClient,
        sessionID: String,
        remoteX: Int,
        remoteY: Int
    ) async throws {
        let expression = """
        (() => {
          const canvas = document.getElementById('noVNC_canvas') || document.querySelector('canvas');
          const surface = canvas || document.getElementById('noVNC_container') || document.documentElement;
          const rect = surface.getBoundingClientRect();
          const framebufferWidth = Number(canvas?.width) || 1280;
          const framebufferHeight = Number(canvas?.height) || 800;
          return JSON.stringify({
            x: rect.left + (\(remoteX) / framebufferWidth) * rect.width,
            y: rect.top + (\(remoteY) / framebufferHeight) * rect.height
          });
        })()
        """
        let response = try await evaluate(client, sessionID: sessionID, expression: expression)
        guard let remoteObject = response["result"] as? [String: Any],
              let encoded = remoteObject["value"] as? String,
              let data = encoded.data(using: .utf8),
              let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let x = (value["x"] as? NSNumber)?.doubleValue,
              let y = (value["y"] as? NSNumber)?.doubleValue,
              x.isFinite,
              y.isFinite else {
            throw InstallerError.message("The Bot computer canvas could not be mapped for keyboard input.")
        }
        try await clickRemoteCanvas(
            client,
            sessionID: sessionID,
            x: Int(x.rounded()),
            y: Int(y.rounded())
        )
    }

    private func openTerminal(_ client: CDPClient, vncSession: String) async throws {
        // A target session alone does not move Electron's UI focus into the guest
        // webview. Clicking the canvas first prevents Input.insertText from falling
        // through to Grok Bot's currently focused chat composer.
        try await clickRemoteDesktop(client, sessionID: vncSession, remoteX: 400, remoteY: 400)
        _ = try? await evaluate(client, sessionID: vncSession, expression: "document.getElementById('noVNC_keyboardinput')?.focus(); true")
        try await keyEvent(client, sessionID: vncSession, type: "keyDown", key: "Control", code: "ControlLeft", virtualKey: 17, modifiers: 2)
        try await keyEvent(client, sessionID: vncSession, type: "keyDown", key: "Alt", code: "AltLeft", virtualKey: 18, modifiers: 3)
        try await keyEvent(client, sessionID: vncSession, type: "keyDown", key: "t", code: "KeyT", virtualKey: 84, modifiers: 3)
        try await keyEvent(client, sessionID: vncSession, type: "keyUp", key: "t", code: "KeyT", virtualKey: 84, modifiers: 3)
        try await keyEvent(client, sessionID: vncSession, type: "keyUp", key: "Alt", code: "AltLeft", virtualKey: 18, modifiers: 2)
        try await keyEvent(client, sessionID: vncSession, type: "keyUp", key: "Control", code: "ControlLeft", virtualKey: 17)
        try await Task.sleep(nanoseconds: 1_200_000_000)
        try await clickRemoteDesktop(client, sessionID: vncSession, remoteX: 400, remoteY: 250)
        _ = try? await evaluate(client, sessionID: vncSession, expression: "document.getElementById('noVNC_keyboardinput')?.focus(); true")
    }

    private func waitForTerminalPrompt(_ client: CDPClient, vncSession: String, attempts: Int = 8) async -> Bool {
        for _ in 0..<attempts {
            if let text = try? await screenshotText(client, sessionID: vncSession) {
                let normalized = text.uppercased().filter { $0.isLetter || $0.isNumber }
                if normalized.contains("TERMINAL")
                    && (normalized.contains("WORKSPACE") || normalized.contains("BOXCURSOR")) {
                    return true
                }
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        return false
    }

    private func focusTerminal(_ client: CDPClient, vncSession: String) async throws {
        try await clickRemoteDesktop(client, sessionID: vncSession, remoteX: 400, remoteY: 250)
        _ = try? await evaluate(
            client,
            sessionID: vncSession,
            expression: "document.getElementById('noVNC_keyboardinput')?.focus(); true"
        )
    }

    private func ensureTerminal(_ client: CDPClient, vncSession: String) async throws {
        if await waitForTerminalPrompt(client, vncSession: vncSession, attempts: 2) {
            try await focusTerminal(client, vncSession: vncSession)
            return
        }
        try await openTerminal(client, vncSession: vncSession)
        // Do not click the dock while a slow shortcut launch is still in flight;
        // that would toggle the just-opened terminal back to the desktop.
        if await waitForTerminalPrompt(client, vncSession: vncSession, attempts: 24) {
            try await focusTerminal(client, vncSession: vncSession)
            return
        }
        appendLog("The terminal shortcut missed. Opening Terminal from the Bot desktop dock…")
        // Grok Bot 0.30.0's guest framebuffer is 1280×800 and is normally shown
        // at 80% (1024×640) in fullscreen. The terminal launcher is the stable
        // right-most app icon in its three-icon dock at intrinsic point 700×768.
        try await clickRemoteDesktop(client, sessionID: vncSession, remoteX: 700, remoteY: 768)
        try await Task.sleep(nanoseconds: 1_200_000_000)
        try await focusTerminal(client, vncSession: vncSession)
        // A stopped guest can take several seconds to cold-start Xfce Terminal.
        // Keep checking the actual screenshot instead of assuming the click failed.
        guard await waitForTerminalPrompt(client, vncSession: vncSession, attempts: 24) else {
            throw InstallerError.message("The Bot terminal did not open from its shortcut or dock. Open the Bot computer and retry.")
        }
    }

    private func resetRemotePrompt(_ client: CDPClient, vncSession: String) async throws {
        // A prior interrupted transfer can leave half of a base64 append command
        // on the shell's editable line. Cancel it before every fresh attempt;
        // the payload sequence itself then truncates its staging file safely.
        try await keyEvent(client, sessionID: vncSession, type: "keyDown", key: "Control", code: "ControlLeft", virtualKey: 17)
        try await keyEvent(client, sessionID: vncSession, type: "keyDown", key: "c", code: "KeyC", virtualKey: 67)
        try await keyEvent(client, sessionID: vncSession, type: "keyUp", key: "c", code: "KeyC", virtualKey: 67)
        try await keyEvent(client, sessionID: vncSession, type: "keyUp", key: "Control", code: "ControlLeft", virtualKey: 17)
        try await Task.sleep(nanoseconds: 200_000_000)
    }

    private func typeRemoteCommand(_ command: String, client: CDPClient, vncSession: String) async throws {
        let chunkSize = 4_000
        var index = command.startIndex
        while index < command.endIndex {
            let end = command.index(index, offsetBy: chunkSize, limitedBy: command.endIndex) ?? command.endIndex
            let chunk = String(command[index..<end])
            let literal = try jsonLiteral(chunk)
            let expression = """
            (async () => {
              const UI = (await import('./app/ui.js')).default;
              if (!UI?.rfb) return false;
              let emitted = 0;
              for (const character of \(literal)) {
                UI.rfb.sendKey(character.codePointAt(0));
                emitted += 1;
                // noVNC can acknowledge a large JavaScript burst before its
                // guest keyboard socket has drained. Pace small batches so a
                // long base64 line arrives completely instead of truncating.
                if (emitted % 8 === 0) {
                  await new Promise(resolve => setTimeout(resolve, 4));
                }
              }
              await new Promise(resolve => setTimeout(resolve, 20));
              return true;
            })()
            """
            let response = try await evaluate(client, sessionID: vncSession, expression: expression)
            guard let remoteObject = response["result"] as? [String: Any],
                  remoteObject["value"] as? Bool == true else {
                throw InstallerError.message("The Bot computer did not accept noVNC text input.")
            }
            index = end
        }
        try await keyEvent(client, sessionID: vncSession, type: "keyDown", key: "Enter", code: "Enter", virtualKey: 13)
        try await keyEvent(client, sessionID: vncSession, type: "keyUp", key: "Enter", code: "Enter", virtualKey: 13)
    }

    private func typeRemoteCommandsResilient(
        _ commands: [String],
        client: CDPClient,
        pageSession: String
    ) async throws -> AttachedTarget {
        guard !commands.isEmpty else {
            throw InstallerError.message("The installer generated no remote commands.")
        }
        var lastError: Error?
        for attempt in 1...3 {
            do {
                let vnc = try await waitForVNC(client, pageSession: pageSession)
                try await ensureTerminal(client, vncSession: vnc.sessionID)
                try await resetRemotePrompt(client, vncSession: vnc.sessionID)
                for command in commands {
                    try await typeRemoteCommand(command, client: client, vncSession: vnc.sessionID)
                    try await Task.sleep(nanoseconds: 150_000_000)
                }
                // Every command reached the verified terminal session. The
                // encoded GROKBOT_ROUTER_INSTALL_OK output checked below is the
                // only completion authority; an extra OCR acknowledgement here
                // can disappear during a legitimate noVNC target swap.
                return vnc
            } catch {
                lastError = error
                if attempt < 3 {
                    appendLog("The Bot computer changed during transfer. Retrying safely (\(attempt + 1)/3)…")
                }
            }
        }
        throw lastError ?? InstallerError.message("The Bot terminal did not acknowledge the install command.")
    }

    private func screenshotText(_ client: CDPClient, sessionID: String) async throws -> String {
        // A PNG from a newly provisioned high-resolution Bot desktop can exceed
        // URLSessionWebSocketTask's nested-message limit. A bounded JPEG remains
        // sharp enough for the Terminal/workspace OCR gate and prevents the
        // misleading "Message too long" transport failure.
        let result = try await client.call("Page.captureScreenshot", params: [
            "format": "jpeg",
            "quality": 55,
            "fromSurface": true,
            "optimizeForSpeed": true
        ], sessionID: sessionID)
        guard let encoded = result["data"] as? String,
              let data = Data(base64Encoded: encoded),
              let image = NSImage(data: data),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return "" }
        let request = VNRecognizeTextRequest()
        // The Bot computer is often a small preview rather than fullscreen.
        // Accurate OCR reliably sees the Terminal title and workspace prompt;
        // fast OCR can miss both and make the dock fallback toggle it away.
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }

    private func waitForSentinel(_ sentinel: String, client: CDPClient, vnc: AttachedTarget, timeoutSeconds: Int) async throws {
        let expected = sentinel.uppercased().filter { $0.isLetter || $0.isNumber }
        var activeTargetID = vnc.targetID
        var activeSession = vnc.sessionID
        var reportedReconnect = false
        for _ in 0..<(timeoutSeconds / 3) {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            if let current = try? await targets(client).first(where: { $0.type == "webview" && $0.url.contains("/vnc.html") }),
               current.id != activeTargetID,
               let replacement = try? await attach(client, targetID: current.id) {
                activeTargetID = current.id
                activeSession = replacement
                if !reportedReconnect {
                    appendLog("The Bot computer reconnected. Continuing completion verification…")
                    reportedReconnect = true
                }
            }
            let text: String
            do {
                text = try await screenshotText(client, sessionID: activeSession)
            } catch {
                if let vnc = try? await targets(client).first(where: { $0.type == "webview" && $0.url.contains("/vnc.html") }),
                   let replacement = try? await attach(client, targetID: vnc.id) {
                    activeTargetID = vnc.id
                    activeSession = replacement
                    if !reportedReconnect {
                        appendLog("The Bot computer reconnected. Continuing completion verification…")
                        reportedReconnect = true
                    }
                }
                continue
            }
            let normalized = text.uppercased().filter { $0.isLetter || $0.isNumber }
            if normalized.contains(expected) { return }
            if normalized.contains("ERROR") && !normalized.contains("NOERROR") {
                appendLog("The terminal displayed an error. Waiting briefly in case the installer recovered…")
            }
        }
        throw InstallerError.message("The Bot terminal did not report completion. Run grokbot-router doctor there for the exact diagnostic.")
    }

    private func archiveURL() throws -> URL {
        guard let url = Bundle.main.url(forResource: "grokbot-router-payload", withExtension: "tgz") else {
            throw InstallerError.message("Installer payload is missing.")
        }
        return url
    }

    private func install(
        defaultProvider: String,
        providers: String,
        codexModel: String,
        openRouterModel: String,
        openRouterKey: String
    ) async throws -> String {
        try validateGrokApp()
        try await relaunchGrokWithDiagnostics()
        let client = CDPClient(url: try await browserWebSocketURL())
        let pageSession = try await mainPageSession(client)
        if providers.contains("openrouter") {
            if openRouterKey.isEmpty {
                appendLog("No OpenRouter key entered. Keeping any existing OPENROUTER_API_KEY in Grok Bot Secrets.")
            } else {
                try await saveOpenRouterKey(openRouterKey, client: client, pageSession: pageSession)
            }
        }
        appendLog("Verifying that keyboard input is isolated to the Bot terminal…")
        let transportPayload = Data("\nGROKBOT_ROUTER_TRANSPORT_OK\n".utf8).base64EncodedString()
        // Opening the Computer can replace Grok's webview between discovery
        // and the first noVNC action. Run the harmless transport probe through
        // the same fresh-target retry path as the payload transfer.
        let transportVNC = try await typeRemoteCommandsResilient(
            ["printf %s \(transportPayload) | base64 -d"],
            client: client,
            pageSession: pageSession
        )
        appendLog("Connected to the Bot computer without Accessibility permissions.")
        try await waitForSentinel("GROKBOT_ROUTER_TRANSPORT_OK", client: client, vnc: transportVNC, timeoutSeconds: 30)
        appendLog("Terminal transport verified.")

        let archive = try Data(contentsOf: archiveURL())
        let encoded = archive.base64EncodedString()
        let digest = SHA256.hash(data: archive).map { String(format: "%02x", $0) }.joined()
        let installPayload = Data("\nGROKBOT_ROUTER_INSTALL_OK\n\nGROKBOT_ROUTER_INSTALL_OK\n".utf8).base64EncodedString()
        // Short, quote-free commands always return to a usable shell prompt if
        // the VNC target changes mid-transfer. A retry starts from an empty file.
        var encodedChunks: [String] = []
        var encodedIndex = encoded.startIndex
        while encodedIndex < encoded.endIndex {
            let encodedEnd = encoded.index(encodedIndex, offsetBy: 1_000, limitedBy: encoded.endIndex) ?? encoded.endIndex
            encodedChunks.append(String(encoded[encodedIndex..<encodedEnd]))
            encodedIndex = encodedEnd
        }
        var commands = [
            "mkdir -p /tmp/grokbot-router-installer",
            ": > /tmp/grokbot-router-installer/payload.b64"
        ]
        commands.append(contentsOf: encodedChunks.map {
            "printf %s \($0) >> /tmp/grokbot-router-installer/payload.b64"
        })
        commands.append(contentsOf: [
            "base64 -d /tmp/grokbot-router-installer/payload.b64 > /tmp/grokbot-router-installer/payload.tgz",
            "echo \(digest) /tmp/grokbot-router-installer/payload.tgz | sha256sum -c -",
            "rm -rf /tmp/grokbot-router-installer/payload",
            "mkdir -p /tmp/grokbot-router-installer/payload",
            "tar -xzf /tmp/grokbot-router-installer/payload.tgz -C /tmp/grokbot-router-installer/payload --strip-components=1",
            "bash /tmp/grokbot-router-installer/payload/remote/install.sh --provider \(defaultProvider) --providers \(providers) --codex-model \(codexModel) --openrouter-model \(openRouterModel) && clear && printf %s \(installPayload) | base64 -d"
        ])
        appendLog("Transferring a SHA-256-verified payload into the Bot computer…")
        let installVNC = try await typeRemoteCommandsResilient(commands, client: client, pageSession: pageSession)
        appendLog("Installing pinned dependencies and applying the reversible host adapter…")
        try await waitForSentinel("GROKBOT_ROUTER_INSTALL_OK", client: client, vnc: installVNC, timeoutSeconds: 360)
        appendLog("The Bot computer reported a successful install.")
        _ = try? await evaluate(client, sessionID: pageSession, expression: "window.desktop.forceGatewayReconnect().then(()=>true)")
        if defaultProvider == "openrouter" {
            return "Installed with OpenRouter selected. Send /router doctor in Grok Bot."
        }
        if providers.contains("codex") {
            return "Installed. Click Start Codex Sign-in, then send /router doctor in Grok Bot."
        }
        return "Installed. Send /router doctor in Grok Bot to verify the selected model."
    }

    private func sendRemoteCommand(
        _ command: String,
        relaunch: Bool,
        confirmationSentinel: String? = nil
    ) async throws {
        try validateGrokApp()
        let existingEndpoint = try? await browserWebSocketURL()
        if relaunch || existingEndpoint == nil {
            try await relaunchGrokWithDiagnostics()
        }
        let client = CDPClient(url: try await browserWebSocketURL())
        let pageSession = try await mainPageSession(client)
        let vnc = try await typeRemoteCommandsResilient([command], client: client, pageSession: pageSession)
        if let confirmationSentinel {
            try await waitForSentinel(confirmationSentinel, client: client, vnc: vnc, timeoutSeconds: 45)
        }
    }
}

let application = NSApplication.shared
let controller = RouterInstallerController()
application.delegate = controller
application.setActivationPolicy(.regular)
application.run()
