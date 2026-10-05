# iZap platform integration — agent guidance

Guidance for AI coding agents (Codex CLI, and any tool that reads `AGENTS.md`)
**integrating an external application with the iZap platform** — its HTTP API and
the iZap MCP server. This is the same guidance shipped as the
`izap-platform` Claude Code skill and the Cursor rule; the reference docs under
`izap/skills/izap-platform/references/` are the shared source of truth.

iZap is a WhatsApp-first business automation platform. External applications
integrate two ways:

1. **HTTP REST API** rooted at `/api/v1`, with OAuth 2.0 / JWT auth.
2. **MCP server** (`iZap`) at `/mcp`, over Streamable HTTP with OAuth.

| Environment | API origin | MCP URL |
|---|---|---|
| Production | `https://api.izap.ai` | `https://api.izap.ai/mcp` |
| Staging | `https://api-staging.izap.ai` | `https://api-staging.izap.ai/mcp` |

## Connect the MCP server (Codex)

Codex reads MCP servers from `~/.codex/config.toml`. Merge the block in
[`codex/config.toml`](codex/config.toml):

```toml
[mcp_servers.izap]
url = "https://api.izap.ai/mcp"
```

Codex supports streamable HTTP servers natively — no `npx mcp-remote` shim. On
first use, approve the OAuth sign-in (authorization-code + PKCE). Verify with a
read-only tool such as `list_connected_assistants`.

## Read before writing code

The authoritative references live under
`izap/skills/izap-platform/references/`:

- `authentication.md` — OAuth 2.0 flow, discovery, JWT bearer usage.
- `mcp.md` — connecting to the MCP server and the full tool catalog.
- `mcp-integration.md` — embedding the MCP in your own code (Python / TypeScript
  / Claude Agent SDK / OpenAI / LangChain) plus runnable `izap/examples/`.
- `api-endpoints.md` — REST route groups and conventions.

## Rules

- Confirm the auth model first. Both surfaces use the same OAuth 2.0 server at
  `{origin}/oauth`. For server-to-server code, get a Bearer JWT from
  `POST {origin}/api/v1/auth/jwt/login` and send `Authorization: Bearer <jwt>`.
- Read tokens from an env var (`IZAP_JWT`) — never hardcode. Refresh on `401`.
- Webhooks: HMAC signature verification is mandatory; handle idempotently.
- Prefer SSE (`/api/v1/sse/*`) over polling for event consumption.
- Prefer the `izap` MCP server over hand-rolled REST for analytics / assistant
  management.
- Error model: `422` validation, `400` domain/data conflicts, `500` server
  errors; MCP `isError` with `Error 401` / "Invalid or expired JWT" means
  refresh the token.
