# izap-integrate

Scaffold an external integration against the iZap REST API for what the user
describes.

Use `izap/skills/izap-platform/references/` as your source of truth (auth,
endpoints, MCP). Then:

1. Clarify the target environment (production `https://api.izap.ai` vs staging
   `https://api-staging.izap.ai`) and which resource(s) the integration touches.
2. Establish auth first — OAuth 2.0 authorization-code + PKCE for third-party
   clients, Bearer JWT on every request. See `references/authentication.md`.
3. Write the integration in the user's stack. For:
   - **Webhooks** — HMAC signature verification before trusting any payload,
     plus idempotent handling.
   - **Event consumption** — prefer SSE (`/api/v1/sse/*`) over polling.
   - **Analytics / assistant management** — recommend the `izap` MCP server over
     hand-rolled REST where it fits.
4. Handle the documented error model: `422` validation, `400` domain/data
   conflicts, `500` server errors.

Confirm assumptions with the user before writing large amounts of code.
