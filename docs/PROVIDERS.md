# Providers and extension contract

GrokRouter beta.47 has one provider registry and two adapter families. Adding a provider means adding an explicit registry entry, configuration schema, credential policy, model validation, tests, and documentation. It does not mean accepting an arbitrary URL or secret path from inherited configuration.

## Supported adapters

| Provider ID | Transport | Credential | Endpoint policy | Current status |
| --- | --- | --- | --- | --- |
| `codex` | Pinned Codex SDK | Codex device sign-in inside the Bot computer | SDK-managed | Automated contract; prior beta live evidence only |
| `openai` | OpenAI Chat Completions with native function calls | `OPENAI_API_KEY` in Grok Bot Secrets | Fixed to `https://api.openai.com/v1` | Automated contract; beta.47 live proof pending |
| `openrouter` | OpenAI-compatible Chat Completions with native function calls | `OPENROUTER_API_KEY` in Grok Bot Secrets | Fixed to `https://openrouter.ai/api/v1` | Automated contract; prior beta live evidence only |
| `llamacpp` | OpenAI-compatible Chat Completions with native function calls | None | Unauthenticated loopback HTTP(S) only | Development adapter; beta.47 live proof pending |

The desktop installers expose Codex, OpenAI, and OpenRouter. llama.cpp is intentionally not in the beginner UI: `llama-server` must run inside the Grok Bot computer because `127.0.0.1` is evaluated there, not on the Mac or Windows desktop. Enable it through `remote/install.sh` only after that local service exists.

## Security rules

- OpenAI and OpenRouter use fixed official base URLs. Legacy custom base-URL fields cause a runtime refusal instead of redirecting a credential or conversation.
- Provider secrets come only from the provider's named environment variable or `/home/box/sand-data/box-secrets.json`. A custom secret-store path is rejected.
- llama.cpp accepts only literal IPv4 or IPv6 loopback `http` or `https` endpoints with no URL username or password. Hostnames are rejected so local name resolution cannot redirect a request. It never receives an Authorization header.
- Reinstall starts from packaged defaults and preserves only allowlisted provider, model, reasoning, and loopback llama.cpp fields. Unknown inherited fields are discarded.
- The selected provider receives the conversation, attachments, and tool results needed for that routed turn. Grok remains the authority that offers and executes outer tools.

## Adding another OpenAI-compatible provider

A new compatibility provider needs a code review even if it implements `/v1/chat/completions`. At minimum:

1. Add an immutable provider definition with an exact endpoint and named credential, or a narrowly justified endpoint validator.
2. Define which headers and request fields are permitted. Do not reuse OpenRouter-only headers or reasoning fields automatically.
3. Add provider-specific key validation and redaction without logging the secret.
4. Add packaged config fields, installer controls if it is user-facing, CLI status/Doctor output, and model validation.
5. Test endpoint pinning, authorization behavior, tool-call conversion, error redaction, state isolation, and install-time config sanitization.
6. Complete the fresh-Bot live gate before claiming text, image, computer, or sub-agent capability.

## llama.cpp

The official llama.cpp server exposes an OpenAI-compatible API and defaults to `http://127.0.0.1:8080`. GrokRouter uses `/v1/chat/completions`; native tool calling also depends on a model/chat template that supports tools, commonly with llama.cpp's Jinja template support enabled. The current adapter proves request shape and the loopback boundary in tests, not model quality or live tool parity.

A future bridge from the Mac to the Bot computer must be designed separately. Do not weaken the loopback rule or expose an unauthenticated llama.cpp server on a LAN/public address merely to connect it.

## FreeToken

FreeToken's documented public integration is a native Swift SDK with device registration, model downloads, message threads, and callback-based tools. It is not documented as a generic OpenAI-compatible HTTP server, so beta.47 does not pretend it can use the compatibility adapter.

The safe future route is a dedicated, reviewed sidecar or native bridge that:

- owns FreeToken device registration and downloaded-model lifecycle;
- translates GrokRouter messages and exact offered tool schemas into the SDK contract;
- keeps provider state isolated per Bot;
- returns structured tool requests without executing them itself; and
- has explicit storage, network, and credential boundaries plus the same automated and live acceptance gates.

Until that bridge exists, `freetoken` is unsupported rather than silently routed through another provider.
