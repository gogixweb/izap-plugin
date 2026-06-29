# Authentication

Both the REST API and the MCP server are protected by the same OAuth 2.0
authorization server, mounted at `{origin}/oauth`.

## Discovery

Clients discover the authorization server via RFC 8414 / RFC 9728 metadata:

| Document | Path |
|---|---|
| Authorization server metadata | `/.well-known/oauth-authorization-server` |
| OpenID configuration (OAuth subset) | `/.well-known/openid-configuration` |
| Protected resource metadata (MCP) | `/.well-known/oauth-protected-resource/mcp` |

The MCP endpoint returns `401` with a `WWW-Authenticate` header carrying
`resource_metadata`, so spec-compliant MCP clients bootstrap the OAuth flow
automatically. You normally do not hand-build this flow.

## Authorization server capabilities

From the metadata document (issuer = `{origin}/oauth`):

- **endpoints**: `/oauth/authorize`, `/oauth/token`, `/oauth/register`
- **response_types_supported**: `code`
- **grant_types_supported**: `authorization_code`, `refresh_token`
- **token_endpoint_auth_methods_supported**: `none`, `client_secret_post`, `client_secret_basic`
- **code_challenge_methods_supported**: `S256` (PKCE required for public clients)
- **client_id_metadata_document_supported**: `true`

## Flows

### Authorization code + PKCE (recommended)

1. `GET /oauth/authorize?response_type=code&client_id=...&redirect_uri=...&code_challenge=...&code_challenge_method=S256&state=...`
2. User authenticates and approves; iZap redirects to `redirect_uri?code=...&state=...`.
3. `POST /oauth/token` with `grant_type=authorization_code`, `code`, `redirect_uri`,
   `code_verifier`, and client auth → returns `access_token` (JWT) + `refresh_token`.

### Dynamic client registration

Public clients may self-register via `POST /oauth/register` (RFC 7591). Useful
for MCP clients that register on first connect.

### Refresh

`POST /oauth/token` with `grant_type=refresh_token` and `refresh_token`.

## Using the access token

The access token is a JWT. Send it as a Bearer header on every API and MCP
request:

```
Authorization: Bearer <access_token>
```

The JWT audience is `fastapi-users:auth`. The MCP server decodes the token,
loads the active user, and rejects inactive users or expired/invalid tokens
with an MCP tool error.
