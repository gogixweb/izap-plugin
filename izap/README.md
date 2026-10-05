# iZap Claude Code plugin

A Claude Code plugin for **external developers integrating with the iZap
platform** — its HTTP API and the iZap MCP server.

## What's inside

| Component | Name | Purpose |
|---|---|---|
| MCP server | `izap` | iZap MCP at `https://api.izap.ai/mcp` (OAuth 2.0), pre-wired |
| Skill | `izap-platform` | Integration guidance: REST API, OAuth/JWT, webhooks, MCP tool catalog, MCP-in-your-code |
| Command | `/izap-connect` | Connect to and verify the MCP server end-to-end |
| Command | `/izap-integrate` | Scaffold an external integration against the REST API |
| Command | `/izap-mcp-client` | Scaffold code that connects your app/agent to the iZap MCP server |
| Examples | `examples/` | Runnable Python + TypeScript MCP clients (bearer-token auth) |

## Install

This plugin lives in a marketplace at `.claude-plugin/marketplace.json` (repo
root). Add the marketplace, then install the plugin:

```
/plugin marketplace add gogixweb/izap-plugin
/plugin install izap@izap
```

`/plugin marketplace update` refreshes to the latest version. To develop against a
local checkout instead, point Claude Code at this directory as a local plugin. On
first MCP use, approve the OAuth sign-in prompt.

## Environments

| Environment | API origin | MCP URL |
|---|---|---|
| Production | `https://api.izap.ai` | `https://api.izap.ai/mcp` |
| Staging | `https://api-staging.izap.ai` | `https://api-staging.izap.ai/mcp` |

To target staging, edit `url` in `.mcp.json`.

## Auth

Both the REST API and the MCP server use the same OAuth 2.0 authorization server
at `{origin}/oauth` (authorization-code + PKCE, refresh tokens, dynamic client
registration). MCP clients bootstrap the flow automatically via the `401` +
`WWW-Authenticate` discovery response. See
`skills/izap-platform/references/authentication.md`.

## Layout

```
izap-plugin/
├── .claude-plugin/plugin.json   # manifest
├── .mcp.json                    # iZap MCP server (http + OAuth)
├── commands/
│   ├── izap-connect.md
│   ├── izap-integrate.md
│   └── izap-mcp-client.md
├── examples/                    # runnable MCP clients (Python + TypeScript)
│   ├── README.md
│   ├── python/izap_mcp_client.py
│   └── typescript/izapMcpClient.ts
└── skills/izap-platform/
    ├── SKILL.md
    └── references/
        ├── authentication.md
        ├── mcp.md
        ├── mcp-integration.md
        └── api-endpoints.md
```
