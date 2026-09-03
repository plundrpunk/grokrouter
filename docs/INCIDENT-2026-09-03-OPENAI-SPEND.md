# OpenAI spend incident — 2026-09-03

Status: contained at the credential boundary by the owner; corrective beta.48 is implemented locally and not yet installed in Grok Bot.

## Impact

- User-reported OpenAI charge: approximately USD 160 on 2026-09-03.
- Exact billed cost, project, token totals, and charge type remain unverified until reconciled against OpenAI's Usage and Costs records.
- The live GrokRouter configuration observed during diagnosis was enabled with direct OpenAI as its default provider. Direct OpenAI API traffic is billed separately from ChatGPT and Codex subscriptions.

## Local evidence

The router audit contained 1,558 events from 08:32:21Z through 14:05:59Z on 2026-09-03. Within that window:

- 711 routed turn starts: 663 OpenAI, 48 OpenRouter.
- OpenAI recorded 586 successful turns and 77 turn errors.
- One OpenAI session accounted for 477 turn starts from 07:08:32 through 10:05:44 America/New_York.
- That session's transcript grew from 2 to 1,569 messages. All 477 turns carried sub-agent markers; 462 used tool-link identity.
- The repeated fingerprints were 205 user-shaped and 272 tool-shaped turns, consistent with an autonomous tool/sub-agent continuation loop rather than 477 distinct human prompts.

`turn_start` is not a provider invoice. Empty-response retries and failures can make HTTP-attempt counts differ, and the beta.47 audit did not persist provider usage or cost. OpenAI's provider-side records are authoritative for financial reconciliation.

## Root cause

Beta.47 allowed a metered provider to be selected as the default without making the subscription/API billing boundary sufficiently explicit. It also had no paid-provider sub-agent cutoff, stable-identity requirement, transcript/request/output limit, or per-Bot/router request quota. A long-running autonomous tool/sub-agent session could therefore repeatedly resend an expanding transcript to the direct OpenAI API.

## Containment

- The owner revoked the provider keys on 2026-09-03. This prevents new requests authenticated by those keys.
- No live provider request was made during diagnosis.
- The live router itself has not been disabled or replaced during this corrective pass; that reversible live change requires explicit owner direction.

## Beta.48 corrective controls

- Explicit billing classes: Codex account authentication, direct metered APIs, and local compute.
- Two-step `confirm-paid` chat switch for OpenAI and OpenRouter.
- Existing beta.47 Bots on a metered route are quarantined until reconfirmed under the new safety generation.
- Separate installer confirmation before a metered provider can become the default.
- Paid sub-agents, delegation, and background continuations blocked by default.
- Stable Bot/conversation identity required for metered turns.
- Default limits: 80 transcript messages, 128 KiB request body, 2,048 output tokens, 5 requests per Bot/hour, 20 per Bot/day, 10 router-wide/hour, and 30 router-wide/day.
- Atomic persistent quota reservation before every HTTP attempt, including retries.
- `provider_request_start` audit receipts and normalized usage/request-size fields on successful turns.

## Provider support packet

For a billing review, include:

- Date and amount: 2026-09-03, approximately USD 160.
- The affected OpenAI project and revoked key identifier, never the secret value.
- The provider Usage/Costs export for the incident window.
- Local evidence: 663 OpenAI routed turn starts, including a 477-turn autonomous session from 07:08:32–10:05:44 America/New_York.
- Containment: key revoked and corrective router limits implemented.

Do not describe the charge as card fraud unless the OpenAI account or purchase itself was unauthorized. This evidence instead supports a request to review accidental software-generated API usage; a refund is not guaranteed.

## Remaining gates

- Reconcile exact dollars/tokens and charge type in OpenAI Usage/Costs.
- Decide whether to disable the live router immediately or leave it enabled with revoked keys until beta.48 installation.
- Build beta.48, install it through the exact-host gate, and obtain a zero-request `turn_blocked` receipt plus normal Codex routing evidence.
- Keep paid-provider keys absent until provider-side project budgets are configured and the owner deliberately re-enables a metered path.
