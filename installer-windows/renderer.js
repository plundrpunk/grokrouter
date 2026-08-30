const elements = {
  codex: document.querySelector("#codexEnabled"),
  openRouter: document.querySelector("#openRouterEnabled"),
  defaultProvider: document.querySelector("#defaultProvider"),
  codexModel: document.querySelector("#codexModel"),
  openRouterModel: document.querySelector("#openRouterModel"),
  openRouterKey: document.querySelector("#openRouterKey"),
  install: document.querySelector("#install"),
  status: document.querySelector("#status"),
  spinner: document.querySelector("#spinner"),
  activity: document.querySelector("#activity"),
};

const buttons = [...document.querySelectorAll("button")];
let busy = false;

function syncProviders() {
  const previous = elements.defaultProvider.value;
  elements.defaultProvider.replaceChildren();
  if (elements.codex.checked) elements.defaultProvider.add(new Option("Codex SDK", "codex"));
  if (elements.openRouter.checked) elements.defaultProvider.add(new Option("OpenRouter", "openrouter"));
  if ([...elements.defaultProvider.options].some((option) => option.value === previous)) {
    elements.defaultProvider.value = previous;
  }
  elements.codexModel.disabled = !elements.codex.checked || busy;
  elements.openRouterModel.disabled = !elements.openRouter.checked || busy;
  elements.openRouterKey.disabled = !elements.openRouter.checked || busy;
  elements.install.disabled = busy || (!elements.codex.checked && !elements.openRouter.checked);
}

function setBusy(value, status) {
  busy = value;
  elements.status.textContent = status;
  elements.spinner.classList.toggle("hidden", !value);
  elements.codex.disabled = value;
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

async function run(action, payload = {}) {
  if (busy) return;
  setBusy(true, action === "install" ? "Checking Grok Bot…" : "Connecting to the Bot computer…");
  try {
    const result = await window.grokRouter.run(action, payload);
    if (!result?.ok) return;
  } catch (error) {
    setBusy(false, `Stopped: ${error.message}`);
    appendLog(`✗ ${error.message}`);
  }
}

elements.codex.addEventListener("change", syncProviders);
elements.openRouter.addEventListener("change", syncProviders);
elements.install.addEventListener("click", () => {
  const key = elements.openRouterKey.value.trim();
  if (elements.openRouter.checked && key && !validOpenRouterKey(key)) {
    window.alert("That OpenRouter key does not look valid. Paste the complete key beginning with sk-or-v1-. Nothing has been saved or installed.");
    return;
  }
  const providers = [elements.codex.checked && "codex", elements.openRouter.checked && "openrouter"].filter(Boolean);
  const payload = {
    defaultProvider: elements.defaultProvider.value,
    providers,
    codexModel: elements.codexModel.value,
    openRouterModel: elements.openRouterModel.value,
    openRouterKey: key,
  };
  elements.openRouterKey.value = "";
  run("install", payload);
});

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
