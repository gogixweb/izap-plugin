# Embedding the iZap MCP in your code

This is for **developers who want the iZap Analytics MCP server as a tool source
inside their own application or agent** — not just an interactive AI client. The
server speaks **Streamable HTTP** at `{origin}/mcp` and authenticates every
request with a **Bearer JWT** (audience `fastapi-users:auth`).

| Environment | MCP URL |
|---|---|
| Production | `https://api.izap.ai/mcp` |
| Staging | `https://api-staging.izap.ai/mcp` |

## Two ways to authenticate

- **OAuth 2.0 (interactive / agent clients).** Spec-compliant MCP clients follow
  the `401` + `WWW-Authenticate` discovery and run authorization-code + PKCE for
  you — this is what the bundled `.mcp.json` uses. See `authentication.md`.
- **Bearer JWT (server-to-server code).** For backend services and scripts,
  obtain a JWT once and send it as `Authorization: Bearer <token>` on the MCP
  transport. Simplest path to a token — the REST login endpoint:

  ```bash
  curl -X POST "$IZAP_ORIGIN/api/v1/auth/jwt/login" \
       -H "Content-Type: application/x-www-form-urlencoded" \
       -d "username=$IZAP_EMAIL&password=$IZAP_PASSWORD"
  # -> {"access_token":"<JWT>","token_type":"bearer"}
  ```

  (Or use the OAuth `client_credentials`/`refresh_token` grants from
  `authentication.md`.) The rest of this doc assumes you have `IZAP_JWT`.

> Tokens expire. For long-lived services, refresh on `401` (re-login or use the
> OAuth refresh grant) rather than pinning one token.

## Python — official MCP SDK

`pip install mcp` — the streamable-HTTP client takes a `headers` dict directly.

```python
import asyncio
import os
from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

URL = os.environ.get("IZAP_MCP_URL", "https://api.izap.ai/mcp")
HEADERS = {"Authorization": f"Bearer {os.environ['IZAP_JWT']}"}


async def main() -> None:
    async with streamablehttp_client(URL, headers=HEADERS) as (read, write, _get_session_id):
        async with ClientSession(read, write) as session:
            await session.initialize()

            tools = await session.list_tools()
            print("tools:", [t.name for t in tools.tools])

            result = await session.call_tool("list_connected_assistants", {})
            print(result.structuredContent or result.content)


asyncio.run(main())
```

## TypeScript — official MCP SDK

`npm i @modelcontextprotocol/sdk` — pass headers via the transport's
`requestInit`. `client.connect()` performs the initialize handshake.

```ts
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";

const url = process.env.IZAP_MCP_URL ?? "https://api.izap.ai/mcp";

const transport = new StreamableHTTPClientTransport(new URL(url), {
  requestInit: { headers: { Authorization: `Bearer ${process.env.IZAP_JWT}` } },
});

const client = new Client({ name: "izap-client", version: "1.0.0" });
await client.connect(transport);

const { tools } = await client.listTools();
console.log("tools:", tools.map((t) => t.name));

const result = await client.callTool({ name: "list_connected_assistants", arguments: {} });
console.log(result.structuredContent ?? result.content);

await client.close();
```

## Claude Agent SDK

Register the server as a remote `http` MCP server with a bearer header; the
agent can then call its tools (namespaced `mcp__izap__<tool>`). Works in code or
via a `.mcp.json` next to your agent.

```jsonc
// .mcp.json — headers use ${ENV} interpolation
{
  "mcpServers": {
    "izap": {
      "type": "http",
      "url": "https://api.izap.ai/mcp",
      "headers": { "Authorization": "Bearer ${IZAP_JWT}" }
    }
  }
}
```

```python
# Python — claude-agent-sdk
from claude_agent_sdk import ClaudeAgentOptions, query

options = ClaudeAgentOptions(
    mcp_servers={
        "izap": {
            "type": "http",
            "url": "https://api.izap.ai/mcp",
            "headers": {"Authorization": f"Bearer {os.environ['IZAP_JWT']}"},
        }
    },
    allowed_tools=["mcp__izap__list_connected_assistants", "mcp__izap__get_today_message_stats"],
)
async for message in query(prompt="How many messages did we handle today?", options=options):
    ...
```

## Other agent frameworks (remote HTTP MCP + bearer header)

- **OpenAI Agents SDK** (`pip install openai-agents`):
  ```python
  from agents.mcp import MCPServerStreamableHttp
  server = MCPServerStreamableHttp(params={
      "url": "https://api.izap.ai/mcp",
      "headers": {"Authorization": f"Bearer {token}"},
  })
  # pass `mcp_servers=[server]` to your Agent(...)
  ```
- **LangChain** (`pip install langchain-mcp-adapters`):
  ```python
  from langchain_mcp_adapters.client import MultiServerMCPClient
  client = MultiServerMCPClient({"izap": {
      "transport": "streamable_http",
      "url": "https://api.izap.ai/mcp",
      "headers": {"Authorization": f"Bearer {token}"},
  }})
  tools = await client.get_tools()   # LangChain tools, ready for any agent
  ```

## Gotchas

- **Header name & format**: exactly `Authorization: Bearer <jwt>` (one space).
- **TS SDK version**: custom `requestInit.headers` reliably reach the server on
  `@modelcontextprotocol/sdk` ≥ 1.18 — pin a recent version.
- **Tool errors** come back as MCP tool errors (`isError: true`) with message
  `Error <status>: <detail>` — a `401`/"Invalid or expired JWT" means refresh the
  token, not that the call shape was wrong.
- **`business_id`** is optional on every tool; omit it to use the user's first
  business. See `mcp.md` for the full tool catalog and argument shapes.
```
