const elements = {
  codex: document.querySelector("#codexEnabled"),
  openAI: document.querySelector("#openAIEnabled"),
  openRouter: document.querySelector("#openRouterEnabled"),
  defaultProvider: document.querySelector("#defaultProvider"),
  codexModel: document.querySelector("#codexModel"),
  openAIModel: document.querySelector("#openAIModel"),
  openAIKey: document.querySelector("#openAIKey"),
  openRouterModel: document.querySelector("#openRouterModel"),
  openRouterKey: document.querySelector("#openRouterKey"),
  install: document.querySelector("#install"),
  status: document.querySelector("#status"),
  spinner: document.querySelector("#spinner"),
  activity: document.querySelector("#activity"),
  recovery: document.querySelector("#recovery"),
  retryInstall: document.querySelector("#retryInstall"),
  copyDiagnostics: document.querySelector("#copyDiagnostics"),
  openSupport: document.querySelector("#openSupport"),
};

const buttons = [...document.querySelectorAll("button")];
let busy = false;

function syncProviders() {
  const previous = elements.defaultProvider.value;
  elements.defaultProvider.replaceChildren();
  if (elements.codex.checked) elements.defaultProvider.add(new Option("Codex SDK", "codex"));
  if (elements.openAI.checked) elements.defaultProvider.add(new Option("OpenAI", "openai"));
  if (elements.openRouter.checked) elements.defaultProvider.add(new Option("OpenRouter", "openrouter"));
  if ([...elements.defaultProvider.options].some((option) => option.value === previous)) {
    elements.defaultProvider.value = previous;
  }
  elements.codexModel.disabled = !elements.codex.checked || busy;
  elements.openAIModel.disabled = !elements.openAI.checked || busy;
  elements.openAIKey.disabled = !elements.openAI.checked || busy;
  elements.openRouterModel.disabled = !elements.openRouter.checked || busy;
  elements.openRouterKey.disabled = !elements.openRouter.checked || busy;
  elements.install.disabled = busy || (!elements.codex.checked && !elements.openAI.checked && !elements.openRouter.checked);
}

function setBusy(value, status) {
  busy = value;
  elements.status.textContent = status;
  elements.spinner.classList.toggle("hidden", !value);
  elements.codex.disabled = value;
  elements.openAI.disabled = value;
  elements.openRouter.disabled = value;
  elements.defaultProvider.disabled = value;
  buttons.forEach((button) => { button.disabled = value; });
  syncProviders();
}

function appendLog(message) {
  elements.activity.textContent += `${message}\n`;
  elements.activity.scrollTop = elements.activity.scrollHeight;
}

function validOpenRouterKey(value) {
  return value.startsWith("sk-or-v1-") && value.length >= 33 && !/\s/.test(value);
}

function validOpenAIKey(value) {
  return value.startsWith("sk-") && value.length >= 20 && !/\s/.test(value) && !value.startsWith("sk-or-v1-");
}

async function run(action, payload = {}) {
  if (busy) return;
  elements.recovery.classList.add("hidden");
  setBusy(true, action === "install" ? "Checking Grok Bot…" : "Connecting to the Bot computer…");
  try {
    const result = await window.grokRouter.run(action, payload);
    if (!result?.ok) {
      if (busy) setBusy(false, `Stopped: ${result?.error || "The installer request failed."}`);
      elements.retryInstall.classList.toggle("hidden", action !== "install");
      elements.recovery.classList.remove("hidden");
      return;
    }
  } catch (error) {
    setBusy(false, `Stopped: ${error.message}`);
    appendLog(`✗ ${error.message}`);
    elements.retryInstall.classList.toggle("hidden", action !== "install");
    elements.recovery.classList.remove("hidden");
  }
}

elements.codex.addEventListener("change", syncProviders);
elements.openAI.addEventListener("change", syncProviders);
elements.openRouter.addEventListener("change", syncProviders);
elements.install.addEventListener("click", () => {
  const openAIKey = elements.openAIKey.value.trim();
  if (elements.openAI.checked && openAIKey && !validOpenAIKey(openAIKey)) {
    window.alert("That OpenAI key does not look valid. Paste the complete project key beginning with sk-. Nothing has been saved or installed.");
    return;
  }
  const key = elements.openRouterKey.value.trim();
  if (elements.openRouter.checked && key && !validOpenRouterKey(key)) {
    window.alert("That OpenRouter key does not look valid. Paste the complete key beginning with sk-or-v1-. Nothing has been saved or installed.");
    return;
  }
  const providers = [elements.codex.checked && "codex", elements.openAI.checked && "openai", elements.openRouter.checked && "openrouter"].filter(Boolean);
  const payload = {
    defaultProvider: elements.defaultProvider.value,
    providers,
    codexModel: elements.codexModel.value,
    openAIModel: elements.openAIModel.value,
    openAIKey,
    openRouterModel: elements.openRouterModel.value,
    openRouterKey: key,
  };
  elements.openAIKey.value = "";
  elements.openRouterKey.value = "";
  run("install", payload);
});

elements.retryInstall.addEventListener("click", () => elements.install.click());
elements.copyDiagnostics.addEventListener("click", async () => {
  const copied = await window.grokRouter.copyDiagnostics();
  if (copied) elements.status.textContent = "Safe diagnostics copied. Paste them into a GitHub issue or support reply.";
});
elements.openSupport.addEventListener("click", () => window.grokRouter.openSupport());

document.querySelectorAll("[data-action]").forEach((button) => {
  button.addEventListener("click", () => {
    const action = button.dataset.action;
    if (action === "uninstall" && !window.confirm("Restore the verified stock Grok Bot host? The router runtime and backup will remain recoverable on the Bot computer.")) return;
    run(action);
  });
});

window.grokRouter.onEvent((event) => {
  if (event.type === "log") appendLog(event.message);
  if (event.type === "status") setBusy(event.busy, event.message);
});

syncProviders();
