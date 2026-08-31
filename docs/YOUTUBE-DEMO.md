# YouTube installation and proof runbook

## The clean promise

“Install one small Mac app, sign into Codex or add OpenRouter, and keep using the Grok Bot interface and computer—with a reversible stock backup.”

Do not frame this as an official integration. Say that it is a version-pinned, unofficial reconstruction for Grok Bot 0.30.0 and that future updates can temporarily break compatibility.

## Before recording

- Use the exact public source commit viewers will install. Build it through the documented source-installer path.
- Start with a throwaway demo Bot and non-sensitive files.
- Hide device codes, account identifiers, API keys, terminal history, and unrelated conversations.
- Run install and restore once off-camera on the same release artifact.
- Complete every live row in `TEST-MATRIX.md` before stating tool/sub-agent parity as fact.
- Install the exact artifact you will show, create the demo Bot only after that install, and leave the Shell permission/resume plus returned-child proof unedited. A passing older Bot is not evidence for the recording build.

## Beta.40 candidate decision

Beta.40 is not yet film-ready. Its source suite and Mac/Windows package builds pass, but the exact candidate still needs the fresh-Bot menu, group-state, install → restore → reinstall, and capability gates below. Do not substitute beta.38's live evidence for beta.40.

## Last live-verified recording decision: beta.38

Beta.38 is ready for a scoped proof of the install and model-routing experience: exact installer, genuinely new Bot, normal greeting, `/router doctor`, `/models`, paste Luna, `/provider`, a normal model-identity reply, one exact-once text reply, second-Bot isolation, stock restore, and reinstall. Viewers build the app locally from the public source, so film the same README installation command they will use.

Do not currently film or narrate OpenRouter Shell, Screenshot, or sub-agent parity as working in this candidate. The latest explicit Shell turn received zero actionable host schemas; the adapter failed safely instead of executing model-authored pseudo-tool markup. Add those scenes only after the same release artifact passes every capability row unedited.

## Diagram scene

Use the [4K diagram](diagrams/grokbot-router-end-to-end-4k.png) as a full-screen filming surface immediately after showing the stock app. The editable source is [grokbot-router-end-to-end.svg](diagrams/grokbot-router-end-to-end.svg).

Suggested 45–60 second explanation:

> Grok Bot stays the same, but the AI brain can change. I still type inside the normal Grok Bot chat. A small router checks which model this Bot is set to use, sends the turn to Codex or a model through OpenRouter, and puts the answer back into the same conversation. If the AI needs a computer, file or browser action, it can only request a tool Grok actually offered, and Grok's normal permissions still apply. The installer checks the exact Grok version, saves a verified original, and Restore Stock puts the original inference path back.

Do not animate the optional tool loop as a guaranteed beta.38 result. Present it as the architecture and immediately retain the on-screen qualifier, “Only tools Grok offers for that turn.”

## Eight-part demo

1. **Receipt:** show stock Grok Bot 0.30.0 and a normal Bot with its computer.
2. **Simple diagram:** show the 16:9 end-to-end diagram and deliver the explanation above.
3. **Installer:** paste the README install command, let GrokRouter open, select Codex, and click Install. Explain the exact hash gate and automatic stock backup while dependencies install.
4. **Authentication:** click Start Codex Sign-in, blur the code/account, and complete the device flow.
5. **Fresh-Bot identity:** after installation, create a brand-new Bot on camera and leave its automatic greeting visible. It must greet normally without invoking a tool. Then send `/router doctor`, `/models`, paste one listed model ID by itself, and send `/provider`. Explain that the UI is Grok Bot but inference is now the named routed model.
6. **Native Codex proof:** ask: `Create /workspace/codex-router-proof.txt with today's date, read it back, and tell me the exact contents.` Show the file in the Bot computer.
7. **Outer Grok tool proof:** ask Codex to use the Bot's computer for one visible, reversible task. Then request one small sub-agent task and show its returned result. Keep the unedited wait and result in the recording.
8. **Recovery:** click Restore Stock Grok Bot, show the verified restore result, reconnect, and demonstrate a normal stock response.

For OpenRouter, the beta.38 scoped recording may repeat steps 3–4 with a fresh demo Bot: enter the key into the secure installer field, switch with `/provider openrouter`, and verify the named model plus one normal text response. Repeat the computer and sub-agent portions only after the live capability gate passes on the exact release artifact.

The commands are deterministic composer controls with native slash-discovery descriptors. After the exact candidate passes the menu gate, show `/models` or `/doctor` being selected from Grok's `/` suggestions, then keep the returned deterministic receipt visible. Do not infer command correctness from the menu alone, and confirm the text proof produces one response with no extra follow-up bubbles.

Before recording, run every step in [the fresh-Bot release gate](FRESH-BOT-ACCEPTANCE.md) against the exact candidate installer.

## The install steps that actually worked

1. Identify Grok Bot's real inference seam in its Linux host—not the macOS chat renderer.
2. Preserve Grok's session, tool schemas, computer, and delivery loop; replace only the prompt executor.
3. Run the official Codex SDK in an isolated Node runtime inside the Bot computer.
4. Translate provider tool requests back into Grok tool calls and feed results into the provider's next turn.
5. Store provider/thread state per Bot instead of globally.
6. Transfer a tiny checksummed bootstrap through Grok's own noVNC surface over a loopback Electron diagnostic connection.
7. Install pinned dependencies in the Bot computer, verify the known stock host, create backups, syntax-check, and atomically activate.
8. Restart the Grok host and test text, files, computer tools, orchestration, provider switching, and restore.

The original investigation took hours because these boundaries had to be discovered. Viewers do not repeat that work; the installer encodes it.

## Honest functionality language

- “The bridge preserves the computer and tools Grok offers to that Bot.”
- “Codex or the selected OpenRouter model decides when to call those tools, so behavior can differ by model.”
- “A Grok update is expected to fail closed until a tested compatibility release exists.”
- “Claude is connected through OpenRouter in this beta; this is not the direct Anthropic SDK.”
