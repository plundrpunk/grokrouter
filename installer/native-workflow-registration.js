(async () => {
  const definitions = __GROKROUTER_NATIVE_SKILLS__;
  const operation = __GROKROUTER_NATIVE_OPERATION__;
  const marker = "GROKROUTER_NATIVE_COMMAND:";
  const delay = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));
  const withTimeout = (promise, milliseconds, label) => Promise.race([
    promise,
    new Promise((_, reject) => setTimeout(() => reject(new Error(`${label} timed out`)), milliseconds)),
  ]);

  function findAppContext() {
    const root = document.querySelector("#root");
    const containerKey = Object.keys(root || {}).find((key) => key.startsWith("__reactContainer$"));
    const queue = [root?.[containerKey]];
    const seen = new Set();
    while (queue.length > 0) {
      const fiber = queue.shift();
      if (!fiber || seen.has(fiber)) continue;
      seen.add(fiber);
      for (let context = fiber.dependencies?.firstContext; context; context = context.next) {
        const value = context.memoizedValue;
        if (typeof value?.workflows?.install === "function"
          && typeof value?.workflows?.update === "function"
          && typeof value?.workflows?.remove === "function"
          && typeof value?.roster?.snapshots?.get === "function") {
          return value;
        }
      }
      queue.push(fiber.child, fiber.sibling);
    }
    return null;
  }

  async function waitForAppContext() {
    const deadline = Date.now() + 8_000;
    while (Date.now() < deadline) {
      const app = findAppContext();
      if (app) return app;
      await delay(100);
    }
    throw new Error("Grok Bot's workflow service is not ready");
  }

  function workflowValue(snapshot) {
    if (Array.isArray(snapshot)) return snapshot;
    if (Array.isArray(snapshot?.value)) return snapshot.value;
    if (Array.isArray(snapshot?.rows)) return snapshot.rows;
    if (Array.isArray(snapshot?.data)) return snapshot.data;
    if (Array.isArray(snapshot?.data?.rows)) return snapshot.data.rows;
    if (snapshot?.status === "empty") return [];
    return null;
  }

  async function waitForWorkflows(store) {
    const immediate = workflowValue(store.get());
    if (immediate) return immediate;
    return withTimeout(new Promise((resolve, reject) => {
      let unsubscribe = () => {};
      unsubscribe = store.subscribe(() => {
        const snapshot = store.get();
        const workflows = workflowValue(snapshot);
        if (workflows) {
          unsubscribe();
          resolve(workflows);
        } else if (["failed", "unavailable"].includes(snapshot?.status)) {
          unsubscribe();
          reject(new Error("workflow snapshot unavailable"));
        }
      });
    }), 6_000, "workflow snapshot");
  }

  const app = await waitForAppContext();
  const agents = (app.roster.snapshots.get()?.agents?.rows || [])
    .filter((agent) => typeof agent?.id === "string" && agent.id.length > 0);
  if (agents.length === 0) throw new Error("Grok Bot has no Bots or channels to register");

  const stats = {
    bots: agents.length,
    installed: 0,
    updated: 0,
    removed: 0,
    conflicts: 0,
    unavailable: 0,
    entries: definitions.length,
  };

  await Promise.all(agents.map(async (agent) => {
    let workflows;
    try {
      workflows = await waitForWorkflows(app.workflows.snapshotsFor(agent.id));
    } catch {
      stats.unavailable += 1;
      return;
    }
    const byName = new Map(workflows.map((workflow) => [String(workflow?.name || "").toLowerCase(), workflow]));
    for (const definition of definitions) {
      const existing = byName.get(definition.name.toLowerCase());
      const owned = existing && (String(existing.body || "").includes(marker)
        || (existing.source === "workflow" && /GrokRouter/i.test(String(existing.body || ""))));
      if (operation === "remove") {
        if (!owned) continue;
        await withTimeout(app.workflows.remove({ agentId: agent.id, workflowId: existing.id }), 5_000, `remove /${definition.name}`);
        stats.removed += 1;
        continue;
      }
      if (existing && !owned) {
        stats.conflicts += 1;
        continue;
      }
      if (existing) {
        await withTimeout(app.workflows.update({
          agentId: agent.id,
          workflowId: existing.id,
          spec: {
            name: definition.name,
            description: definition.description,
            body: definition.body,
            trigger: null,
            sourceRef: null,
          },
        }), 5_000, `update /${definition.name}`);
        stats.updated += 1;
      } else {
        await withTimeout(app.workflows.install(agent.id, {
          install: { kind: "content", content: definition.markdown, name: definition.name },
        }), 5_000, `install /${definition.name}`);
        stats.installed += 1;
      }
    }
  }));

  return JSON.stringify(stats);
})()
