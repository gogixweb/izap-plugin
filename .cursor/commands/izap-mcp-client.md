# izap-mcp-client

Scaffold code that connects the user's app/agent to the iZap MCP
server as a tool source.

Use `izap/skills/izap-platform/references/mcp-integration.md` (client SDKs +
auth) and `references/mcp.md` (the tool catalog) as your source of truth before
writing anything. Then:

1. Confirm the **stack** (Python / TypeScript MCP SDK, or an agent framework
   like the Claude Agent SDK / OpenAI Agents / LangChain) and the **environment**
   (production `https://api.izap.ai/mcp` vs staging).
2. Establish **auth** first. For server-to-server code, get a Bearer JWT from
   `POST {origin}/api/v1/auth/jwt/login` (or the OAuth grants in
   `references/authentication.md`) and pass `Authorization: Bearer <jwt>` on the
   transport. Read the token from an env var (`IZAP_JWT`) — never hardcode.
   Refresh on `401`.
3. Mirror the working examples in `izap/examples/` (Python
   `streamablehttp_client` + `ClientSession`; TypeScript `Client` +
   `StreamableHTTPClientTransport` with `requestInit.headers`). Wire the
   specific tool(s) the goal needs from the catalog.
4. Map tool errors correctly: an MCP `isError` with `Error 401` / "Invalid or
   expired JWT" means refresh the token, not a bad call shape.
5. Offer to run it end-to-end against the chosen environment once the token is
   set, starting with a read-only tool (`list_connected_assistants`).

Keep secrets in env vars and confirm the stack before generating large amounts
of code.
