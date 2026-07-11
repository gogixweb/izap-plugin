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

Every tool accepts an optional `business_id` (UUID). When omitted, the user's
first business is used.

## Tool catalog

The server exposes **19 tools**, grouped below by area.

### Analytics (read-only)

| Tool | Purpose | Key args |
|---|---|---|
| `list_connected_assistants` | List AI assistants (chatbots) on the account | `business_id?` |
| `get_today_message_stats` | Chat / message / unique-people counts for a date | `date`, `timezone="UTC"`, `business_id?` |
| `get_today_assistant_ratio` | AI-vs-human message ratio for a date | `date`, `timezone="UTC"`, `business_id?` |
| `get_conversation_duration` | Avg/min/max conversation duration for a date | `date`, `timezone="UTC"`, `business_id?` |
| `get_conversation_breakdown` | Split a day's conversations by who handled them (AI-only, human-assisted, unanswered, awaiting reply) | `date`, `timezone="UTC"`, `business_id?` |
| `search_today_messages` | Keyword (ILIKE) search over a date's messages | `query`, `date`, `timezone="UTC"`, `limit=20`, `business_id?` |

### Assistants

| Tool | Purpose | Key args |
|---|---|---|
| `get_assistant_instructions` | Read an assistant's system prompt + instructions | `chatbot_id`, `business_id?` |
| `create_ai_assistant` | Create a new assistant/chatbot | `name`, `objective=""`, `ai_model_name?`, `business_id?` |
| `update_ai_assistant_instructions` | Update an assistant's prompt/instructions | `chatbot_id`, one+ of `system_prompt` / `base_instructions` / `custom_instructions`, `business_id?` |

### Chats & contacts (read-only)

| Tool | Purpose | Key args |
|---|---|---|
| `list_contacts` | List people who have chatted with the business (names + phone numbers) | `limit=50`, `business_id?` |
| `list_chats` | List WhatsApp conversations, most-recently-active first (real customer chats only) | `limit=30`, `business_id?` |
| `get_chat_messages` | Read the most recent messages of one conversation, newest first | `chat_id`, `limit=50`, `business_id?` |

### WhatsApp messaging

| Tool | Purpose | Key args |
|---|---|---|
| `list_whatsapp_templates` | List the business's Meta-approved WhatsApp templates | `limit=50`, `business_id?` |
| `send_whatsapp_message` | Send an outbound WhatsApp text (only inside the 24h session window) | `to` (E.164), `body`, `preview_url=false`, `business_id?` |
| `send_whatsapp_template_message` | Send an approved template — the only way to open/re-open a conversation outside 24h | `to` (E.164), `template_name`, `language_code="pt_BR"`, `body_variables=[]` **or** `named_variables={}`, `business_id?` |

### Transmissions (bulk sends)

| Tool | Purpose | Key args |
|---|---|---|
| `create_transmission_preview` | Validate a CSV recipient list against a template and create a **DRAFT** (nothing sent) | `name`, `template_name`, `recipients` (≤5000 rows), `phone_column="phone"`, `variable_columns?`, `scheduled_at?`, `timezone="America/Sao_Paulo"`, `business_id?` |
| `confirm_transmission` | Confirm a DRAFT to send/schedule it — dispatches real messages (idempotent) | `transmission_id`, `business_id?` |
| `list_transmissions` | List transmissions, newest first, optionally filtered by status | `limit=50`, `status?` (`draft`/`scheduled`/`sending`/`completed`/`failed`/`cancelled`), `business_id?` |
| `get_transmission_status` | Delivery progress of a single transmission | `transmission_id`, `business_id?` |

## Model naming

`create_ai_assistant` takes an **optional** `ai_model_name`; omit it to use
iZap's default. The MCP **never exposes the underlying LLM**: an assistant's
model is always reported back as a branded tier — `iZ Lite`, `iZ Pro`, `iZ Max`,
or `iZ Core`, optionally with a single-letter provider suffix (e.g. `iZ Pro · O`).
Do not rely on raw provider/model ids anywhere in the MCP surface.

## Notes & limits

- **Dates** are ISO-8601 strings (e.g. `"2026-04-15"`); **timezone** is an IANA
  name (e.g. `"America/Sao_Paulo"`). Phone numbers are **E.164** (e.g. `+5562...`).
- `search_today_messages` is rate-limited to **60 calls per user per day** and
  matches substrings via SQL `ILIKE`.
- `send_whatsapp_message` and `send_whatsapp_template_message` share a limit of
  **200 messages per user per day**.
- `update_ai_assistant_instructions` requires at least one of `system_prompt`,
  `base_instructions`, or `custom_instructions`; omitted fields are unchanged.
- Sending flow: `create_transmission_preview` (DRAFT) → `confirm_transmission`
  (dispatch). Outside WhatsApp's 24-hour window, only template messages open a
  conversation.
- Server errors surface as MCP tool errors (`isError: true`) with the message
  `Error <status>: <detail>`.
