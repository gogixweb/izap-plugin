---
name: izap-platform
description: >
  Use when integrating an external application with the iZap platform — calling
  its HTTP API, handling webhooks, authenticating via OAuth 2.0 / JWT, or
  connecting to the iZap MCP server. Covers orders, chats, businesses,
  scheduling, webhook delivery, and the MCP tool surface. Do not use for tasks
  inside the iZap monorepo itself.
---

# iZap platform integration skill

iZap is a WhatsApp-first business automation platform. External applications
integrate two ways:

1. **HTTP REST API** rooted at `/api/v1`, with OAuth 2.0 / JWT auth.
2. **MCP server** (`iZap`) at `/mcp` over Streamable HTTP
   with OAuth: analytics, assistant management, chat/contact reads, WhatsApp
   messaging, and bulk transmissions.

Base origins:

| Environment | Origin |
|---|---|
| Production | `https://api.izap.ai` |
| Staging | `https://api-staging.izap.ai` |

## When to use this skill

Invoke this skill when the user is:

- Writing code that calls iZap's HTTP endpoints from a third-party app
- Building a webhook receiver for iZap events
- Configuring an OAuth client against iZap
- Connecting an MCP client (Claude, ChatGPT, etc.) to the iZap server
- **Embedding the iZap MCP as a tool source in your own app or agent** (Python /
  TypeScript MCP SDK, Claude Agent SDK, OpenAI Agents, LangChain) — see
  `references/mcp-integration.md`
- Asking conceptual questions about resources iZap exposes (orders, chats,
  businesses, scheduling, assistants/chatbots)

Do **not** use this skill for work inside the iZap monorepo.

## Resources at a glance

| Resource | Path | Purpose |
|---|---|---|
| Auth (OAuth/JWT) | `/api/v1/auth/*`, `/oauth/*`, `/.well-known/*` | JWT + OAuth 2.0 |
| Businesses | `/api/v1/businesses/*` | Tenant config, library, menus |
| Orders | `/api/v1/orders/*` | Order lifecycle |
| Chats | `/api/v1/chats/*` | Conversation read/write |
| Scheduling | `/api/v1/scheduling/*` | Appointment slots |
| Webhooks | `/api/v1/webhooks/*` | Inbound provider callbacks; outbound delivery |
| Feedback | `/api/v1/feedback/*` | End-user feedback capture |
| SSE | `/api/v1/sse/*` | Server-Sent Events streams |
| MCP | `/mcp` | Tools: analytics, assistants, chats, WhatsApp send + transmissions (see `references/mcp.md`) |
| Health | `/health` | Liveness probe |

## How to use this skill

1. Identify which surface the task touches — REST or MCP — and read the
   matching file under `references/` before writing code.
2. Confirm the auth model first. Both the REST API and the MCP server use the
   same OAuth 2.0 authorization server at `/oauth` (authorization-code + PKCE,
   refresh tokens, dynamic client registration). See `references/authentication.md`.
3. For webhooks, treat HMAC signature verification as mandatory — never trust
   payload contents until the signature checks out.
4. For long-running event consumption, prefer SSE (`/api/v1/sse/*`) over polling.
5. For analytics and assistant management from an AI client, prefer the MCP
   server over hand-rolled REST calls — it shares the same business logic and
   auth, and tool errors map cleanly to MCP `isError`.

## References

- `references/authentication.md` — OAuth 2.0 flow, discovery, JWT bearer usage.
- `references/mcp.md` — connecting to the MCP server and the full tool catalog.
- `references/mcp-integration.md` — embedding the MCP in your own code: client
  SDK snippets (Python / TypeScript / Claude Agent SDK / OpenAI / LangChain),
  bearer-token auth, and the runnable clients in `examples/`.
- `references/api-endpoints.md` — REST route groups and conventions.

## Versioning

The REST API is mounted under `/api/v1`; breaking changes move to `/api/v2`.
Endpoint behavior is authoritative-by-code — when in doubt, check Swagger UI at
`/docs` or ReDoc at `/redoc` on the target environment.
