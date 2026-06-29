# iZap Analytics MCP server

The MCP server (`iZap Analytics`) is served over **Streamable HTTP** at `/mcp`.
It is the transport required by AI clients such as Claude and the OpenAI Apps
SDK marketplace.

## Endpoints

| Environment | MCP URL |
|---|---|
| Production | `https://api.izap.ai/mcp` |
| Staging | `https://api-staging.izap.ai/mcp` |

## Connecting

This plugin ships the production server pre-wired in `.mcp.json`:

```json
{
  "mcpServers": {
    "izap": { "type": "http", "url": "https://api.izap.ai/mcp" }
  }
}
```

Auth is OAuth 2.0 — the server returns `401` with a `WWW-Authenticate` header
pointing at `/.well-known/oauth-protected-resource/mcp`, and the client runs the
authorization-code + PKCE flow automatically (see `authentication.md`). To target
staging instead, change the `url` to the staging origin.

All tools accept an optional `business_id` (UUID). When omitted, the user's
first business is used.

## Tool catalog

| Tool | Purpose | Key args |
|---|---|---|
| `list_connected_assistants` | List AI assistants (chatbots) on the account | `business_id?` |
| `get_today_message_stats` | Chat / message / unique-people counts for a date | `date`, `timezone="UTC"`, `business_id?` |
| `get_today_assistant_ratio` | AI-vs-human message ratio for a date | `date`, `timezone`, `business_id?` |
| `get_conversation_duration` | Avg/min/max conversation duration for a date | `date`, `timezone`, `business_id?` |
| `search_today_messages` | Keyword (ILIKE) search over a date's messages | `query`, `date`, `timezone`, `limit=20`, `business_id?` |
| `get_assistant_instructions` | Read an assistant's system prompt + instructions | `chatbot_id`, `business_id?` |
| `create_ai_assistant` | Create a new assistant/chatbot | `name`, `objective=""`, `ai_model_name="gpt-4.1-nano"`, `business_id?` |
| `update_ai_assistant_instructions` | Update an assistant's prompt/instructions | `chatbot_id`, one+ of `system_prompt` / `base_instructions` / `custom_instructions`, `business_id?` |

## Notes & limits

- **Dates** are ISO-8601 strings (e.g. `"2026-04-15"`); **timezone** is an IANA
  name (e.g. `"America/Sao_Paulo"`).
- `search_today_messages` is rate-limited to **60 calls per user per day** and
  matches substrings via SQL `ILIKE`.
- `update_ai_assistant_instructions` requires at least one of `system_prompt`,
  `base_instructions`, or `custom_instructions`; omitted fields are unchanged.
- Server errors surface as MCP tool errors (`isError: true`) with the message
  `Error <status>: <detail>`.
