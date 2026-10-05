# iZap MCP server

The MCP server (`iZap`) is served over **Streamable HTTP** at `/mcp`.
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

The server exposes **24 tools**, grouped below by area.

### Analytics (read-only)

| Tool | Purpose | Key args |
|---|---|---|
| `list_connected_assistants` | List AI assistants (chatbots) on the account | `business_id?` |
| `get_message_stats` | Chat / message / unique-people counts for a date (legacy name `get_today_message_stats` is still accepted but no longer listed) | `date?`, `timezone="UTC"`, `business_id?` |
| `get_assistant_ratio` | AI-vs-human message ratio for a date (legacy name `get_today_assistant_ratio` is still accepted but no longer listed) | `date?`, `timezone="UTC"`, `business_id?` |
| `get_conversation_duration` | Avg/min/max conversation duration for a date | `date?`, `timezone="UTC"`, `business_id?` |
| `get_conversation_breakdown` | Split a day's conversations by who handled them (AI-only, human-assisted, unanswered, awaiting reply) | `date?`, `timezone="UTC"`, `business_id?` |
| `search_messages` | Keyword (ILIKE) search over a date or date range (legacy name `search_today_messages` is still accepted but no longer listed) | `query=""`, `date?`, `end_date?`, `timezone="UTC"`, `limit=20`, `business_id?` |

### Assistants

| Tool | Purpose | Key args |
|---|---|---|
| `get_assistant_instructions` | Read an assistant's system prompt + instructions | `chatbot_id`, `business_id?` |
| `create_ai_assistant` | Create a new assistant/chatbot | `name`, `objective=""`, `ai_model_name?`, `business_id?` |
| `update_ai_assistant_instructions` | Update an assistant's prompt/instructions | `chatbot_id`, one+ of `system_prompt` / `base_instructions` / `custom_instructions`, `business_id?` |
| `update_assistant_settings` | Update an assistant's settings (everything but its instructions) | `chatbot_id`, one+ of `name` / `is_active` / `objective` / `ai_model_name` / `timezone` / `locale` / `communication_style` / `detect_client_language` / `use_emojis` / `greetings` / `off_hours_message` / `ai_pause_minutes`, `business_id?` |

### Chats & contacts (read-only)

| Tool | Purpose | Key args |
|---|---|---|
| `list_contacts` | List people who have chatted with the business (names + phone numbers) | `limit=50`, `business_id?` |
| `list_chats` | List WhatsApp conversations, most-recently-active first (real customer chats only) | `limit=30`, `business_id?` |
| `get_chat_messages` | Read the most recent messages of one conversation, newest first (rehosted media comes back as a 1h signed URL) | `chat_id`, `limit=50`, `business_id?` |
| `download_media` | Download the file behind a media message — image/audio blocks, an embedded binary for documents; >8 MB returns the signed URL only | `message_id`, `business_id?` |

### WhatsApp messaging

| Tool | Purpose | Key args |
|---|---|---|
| `list_whatsapp_templates` | List the business's Meta-approved WhatsApp templates (reads Meta's catalog, so local drafts are absent) | `limit=50`, `business_id?` |
| `create_whatsapp_template` | Create a template and submit it to Meta for approval — the way to get a template that does not exist yet | `name` (lowercase_snake_case), `body_text`, `language="pt_BR"`, `category="utility"`, `header_text?`, `footer_text?`, `buttons=[]`, `example_variables?` (one sample per `{{n}}`; omitted samples are filled in), `submit_for_approval=true`, `business_id?` |
| `get_whatsapp_template_status` | Approval status of a created template, plus Meta's rejection reason — the only view of a submission Meta refused outright | `template_id`, `business_id?` |
| `send_whatsapp_message` | Send an outbound WhatsApp text (only inside the 24h session window) | `to` (E.164), `body`, `preview_url=false`, `business_id?` |
| `send_whatsapp_template_message` | Send an approved template — the only way to open/re-open a conversation outside 24h | `to` (E.164), `template_name`, `language_code="pt_BR"`, `body_variables=[]` **or** `named_variables={}`, `header_media_url?`, `header_media_filename?`, `business_id?` |
| `get_whatsapp_message_status` | Delivery status of a message a send tool returned | `message_id` (wamid), `business_id?` |
| `connect_whatsapp_number` | Mint a one-hour link the user opens to connect a WhatsApp number via Meta's Embedded Signup | `business_id?` |
| `get_whatsapp_connection_status` | Diagnose the connection — number, `waba_id`, `phone_number_id`, registration, webhook health, history sync, and the last Meta error in plain language. Never errors when nothing is connected | `business_id?` |

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
  name (e.g. `"America/Sao_Paulo"`). An omitted `date` on the analytics tools
  defaults to **today in `timezone`**. Phone numbers are **E.164** (e.g. `+5562...`).
- `search_messages` (and its legacy name `search_today_messages`) is rate-limited to **60 calls per user per day** and
  matches substrings via SQL `ILIKE`; an empty/omitted `query` returns all of
  the date's messages (newest first, capped by `limit`).
- `send_whatsapp_message` and `send_whatsapp_template_message` share a limit of
  **200 messages per user per day**.
- A template approved with a **media header** (document/image/video) needs
  `header_media_url`: a publicly reachable `https://` URL iZap fetches and uploads to
  WhatsApp before sending. `header_media_filename` sets the name a document shows the
  recipient. The file is free per send — only the header *format* is fixed by the approved
  template. Documents: PDF/txt/Word/Excel/PowerPoint ≤ 100 MB; images: JPEG/PNG ≤ 5 MB;
  videos: MP4/3GPP ≤ 16 MB. Passing it for a template without a media header, or omitting
  it for one with, fails before anything is sent. `create_whatsapp_template` cannot create
  a media-header template yet — make it in Meta's WhatsApp Manager.
- `update_ai_assistant_instructions` requires at least one of `system_prompt`,
  `base_instructions`, or `custom_instructions`; omitted fields are unchanged.
- `update_assistant_settings` requires at least one setting; omitted settings are
  unchanged. Clearing is explicit: send `""` for `objective` / `locale` /
  `off_hours_message`, or `ai_pause_minutes=0` to fall back to the system default.
  `is_active=false` takes an assistant off the air without deleting it or releasing
  its number.
- Sending flow: `create_transmission_preview` (DRAFT) → `confirm_transmission`
  (dispatch). Outside WhatsApp's 24-hour window, only template messages open a
  conversation.
- Server errors surface as MCP tool errors (`isError: true`) with the message
  `Error <status>: <detail>`.
