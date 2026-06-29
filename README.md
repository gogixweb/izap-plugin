# iZap plugin

Integrate external applications with the **iZap platform** — its HTTP API
(orders, chats, businesses, scheduling, webhooks), OAuth 2.0 auth, and the
**iZap Analytics MCP server** — from your AI coding tool of choice.

The portable core is the `izap` MCP server at `https://api.izap.ai/mcp`
(Streamable HTTP + OAuth 2.0). This repo ships ready-to-use config and guidance
for **Claude Code**, **Cursor**, and **Codex**, all backed by one shared set of
reference docs under [`izap/skills/izap-platform/references/`](izap/skills/izap-platform/references/).

## What's inside

| Component | Name | Purpose |
|---|---|---|
| MCP server | `izap` | iZap Analytics MCP at `https://api.izap.ai/mcp` (OAuth 2.0) |
| Guidance | `izap-platform` | REST API, OAuth/JWT, webhooks, MCP tool catalog, MCP-in-your-code |
| Commands | `izap-connect`, `izap-integrate`, `izap-mcp-client` | Connect/verify, scaffold a REST integration, scaffold an MCP client |
| Examples | `izap/examples/` | Runnable Python + TypeScript MCP clients (bearer-token auth) |

## Install

### Claude Code

This repo is a Claude Code plugin marketplace
([`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)). Add it,
then install the plugin:

```
/plugin marketplace add gogixweb/izap-plugin
/plugin install izap@izap
```

`/plugin marketplace update` refreshes to the latest version. On first MCP use,
approve the OAuth sign-in prompt. The plugin bundles the MCP server, the
`izap-platform` skill, and the three commands.

### Cursor

Copy [`.cursor/`](.cursor/) into your project (or merge its contents):

- [`.cursor/mcp.json`](.cursor/mcp.json) — the `izap` MCP server.
- [`.cursor/rules/izap-platform.mdc`](.cursor/rules/izap-platform.mdc) — integration guidance.
- [`.cursor/commands/`](.cursor/commands/) — `/izap-connect`, `/izap-integrate`, `/izap-mcp-client`.

Enable the `izap` server in Cursor's MCP settings and approve the OAuth prompt.

### Codex

Merge [`codex/config.toml`](codex/config.toml) into `~/.codex/config.toml`:

```toml
[mcp_servers.izap]
url = "https://api.izap.ai/mcp"
```

Codex supports streamable HTTP MCP servers natively. Drop
[`AGENTS.md`](AGENTS.md) into your project root for the integration guidance, and
copy any of the `.cursor/commands/*.md` into `~/.codex/prompts/` to use them as
custom prompts.

## Environments

| Environment | API origin | MCP URL |
|---|---|---|
| Production | `https://api.izap.ai` | `https://api.izap.ai/mcp` |
| Staging | `https://api-staging.izap.ai` | `https://api-staging.izap.ai/mcp` |

To target staging, point the `url` at the staging MCP URL in
`izap/.mcp.json` (Claude Code), `.cursor/mcp.json` (Cursor), or `codex/config.toml`
(Codex).

## Auth

Both the REST API and the MCP server use the same OAuth 2.0 authorization server
at `{origin}/oauth` (authorization-code + PKCE, refresh tokens, dynamic client
registration). MCP clients bootstrap the flow automatically via the `401` +
`WWW-Authenticate` discovery response. See
[`izap/skills/izap-platform/references/authentication.md`](izap/skills/izap-platform/references/authentication.md).

## Layout

```
izap-plugin/
├── .claude-plugin/marketplace.json   # Claude Code marketplace catalog → ./izap
├── izap/                             # the Claude Code plugin
│   ├── .claude-plugin/plugin.json
│   ├── .mcp.json                     # iZap Analytics MCP (http + OAuth)
│   ├── commands/                     # izap-connect, izap-integrate, izap-mcp-client
│   ├── examples/                     # runnable Python + TypeScript MCP clients
│   └── skills/izap-platform/         # SKILL.md + references/ (shared source of truth)
├── .cursor/                          # Cursor: mcp.json, rules/, commands/
├── AGENTS.md                         # Codex / generic agent guidance
└── codex/config.toml                 # Codex MCP server snippet
```
