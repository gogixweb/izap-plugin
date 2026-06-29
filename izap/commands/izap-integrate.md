---
description: Scaffold an external integration against the iZap REST API
argument-hint: "[what you want to build, e.g. 'a webhook receiver for orders']"
---

The user wants to build an external integration against the iZap platform:
**$ARGUMENTS**

Use the `izap-platform` skill as your source of truth (read its `references/`
for auth, endpoints, and MCP). Then:

1. Clarify the target environment (production `https://api.izap.ai` vs staging
   `https://api-staging.izap.ai`) and which resource(s) the integration touches.
2. Establish the auth approach first — OAuth 2.0 authorization-code + PKCE for
   third-party clients, Bearer JWT on every request. Point to
   `references/authentication.md`.
3. Write the integration in the user's stack. For:
   - **Webhooks** — include HMAC signature verification before trusting any
     payload, and idempotent handling.
   - **Event consumption** — prefer SSE (`/api/v1/sse/*`) over polling.
   - **Analytics / assistant management** — recommend the `izap` MCP server
     instead of hand-rolled REST where it fits.
4. Handle the documented error model: `422` validation, `400` domain/data
   conflicts, `500` server errors.

Confirm assumptions with the user before writing large amounts of code.
