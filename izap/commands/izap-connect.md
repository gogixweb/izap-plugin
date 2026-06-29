---
description: Connect to and verify the iZap Analytics MCP server
---

The iZap plugin pre-wires the iZap Analytics MCP server (`izap`) at
`https://api.izap.ai/mcp` via the bundled `.mcp.json`.

Help the user get connected and confirm it works:

1. Confirm the `izap` MCP server is configured and connected. If its tools are
   not yet available, tell the user to approve the OAuth prompt — the server
   uses OAuth 2.0 (authorization-code + PKCE) and will open a browser sign-in on
   first connect. To target staging instead of production, the `url` in
   `.mcp.json` should point at `https://api-staging.izap.ai/mcp`.
2. Once connected, run a harmless read-only tool to verify auth end-to-end —
   prefer `list_connected_assistants` (no required args). Report the returned
   assistants and total.
3. If a tool returns an error like `Error 401: ...` or "Invalid or expired JWT
   token", the OAuth session needs re-authorization — guide the user to
   reconnect the server.

Read the `izap-platform` skill (`references/mcp.md`) for the full tool catalog
before suggesting follow-up queries.

$ARGUMENTS
