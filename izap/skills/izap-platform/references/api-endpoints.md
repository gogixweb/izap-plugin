# REST API endpoints

Version root: `/api/v1`. Interactive docs live at `/docs` (Swagger UI) and
`/redoc` on each environment — treat those as authoritative for request/response
shapes.

## Route groups

Mounted in `src/aizap/main.py`:

| Prefix | Notes |
|---|---|
| `/api/v1/auth` | First-party JWT auth (see also `/oauth/*` in `authentication.md`) |
| `/api/v1/businesses` | Tenant config, library, menus |
| `/api/v1/orders` | Order lifecycle |
| `/api/v1/chats` | Conversation read/write |
| `/api/v1/scheduling` | Appointment slots |
| `/api/v1/webhooks` | Inbound provider callbacks + outbound delivery |
| `/api/v1/feedback` | End-user feedback capture |
| `/api/v1/contact_form` | Contact form submissions |
| `/api/v1/sse` | Server-Sent Events streams |
| `/health` | Liveness probe |
| `/metrics` | Prometheus metrics |

For motorcycle/delivery deployments the public surface is narrower:
`/api/v1/webhooks`, `/api/v1/referrals`, `/health`.

## Conventions

- **Auth**: Bearer JWT on every request (`Authorization: Bearer <token>`).
- **Validation errors**: `422` for Pydantic validation failures; `400` for
  domain/data conflicts (e.g. invalid phone normalization, duplicate/constraint
  violations); `500` for unexpected server/database errors.
- **CORS**: driven by `FRONTEND_URLS` + `CORS_ORIGIN_REGEX` server-side.
- **Webhooks**: verify signatures before trusting payloads. Inbound provider
  callbacks (e.g. WhatsApp Cloud) carry a provider signature that the server validates;
  outbound webhook deliveries to your endpoint should be HMAC-verified on your side.

## Example: submit feedback

```
POST /api/v1/feedback
Authorization: Bearer <token>
Content-Type: application/json
```

Returns `201` with `{ "message": ..., "id": ... }` on success.
