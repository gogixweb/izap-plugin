# izap-connect

Connect to and verify the iZap Analytics MCP server.

The `izap` MCP server (`https://api.izap.ai/mcp`) is wired via `.cursor/mcp.json`.

1. Confirm the `izap` MCP server is enabled and connected in Cursor's MCP
   settings. If its tools are not yet available, approve the OAuth prompt — the
   server uses OAuth 2.0 (authorization-code + PKCE) and opens a browser sign-in
   on first connect. To target staging, point the `url` in `.cursor/mcp.json` at
   `https://api-staging.izap.ai/mcp`.
2. Once connected, run a harmless read-only tool to verify auth end-to-end —
   prefer `list_connected_assistants` (no required args). Report the returned
   assistants and total.
3. If a tool returns `Error 401` or "Invalid or expired JWT token", the OAuth
   session needs re-authorization — guide the user to reconnect the server.

Read `izap/skills/izap-platform/references/mcp.md` for the full tool catalog
before suggesting follow-up queries.
