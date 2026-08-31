const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("grokRouter", {
  run(action, payload = {}) {
    return ipcRenderer.invoke("grokrouter:run", { action, payload });
  },
  onEvent(callback) {
    const listener = (_event, value) => callback(value);
    ipcRenderer.on("grokrouter:event", listener);
    return () => ipcRenderer.removeListener("grokrouter:event", listener);
  },
});
