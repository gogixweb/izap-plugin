# iZap MCP client examples

Minimal, runnable clients that connect your **own code** to the iZap
MCP server (Streamable HTTP + Bearer JWT), list its tools, and call
`list_connected_assistants`. Full guidance: `../skills/izap-platform/references/mcp-integration.md`.

## Get a token

The MCP server authenticates every request with a Bearer JWT. Grab one from the
REST login endpoint (or use OAuth — see `references/authentication.md`):

```bash
export IZAP_ORIGIN="https://api.izap.ai"      # or https://api-staging.izap.ai
curl -X POST "$IZAP_ORIGIN/api/v1/auth/jwt/login" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=$IZAP_EMAIL&password=$IZAP_PASSWORD"
# -> {"access_token":"<JWT>","token_type":"bearer"}
export IZAP_JWT="<JWT>"
```

## Python

```bash
cd python
pip install -r requirements.txt
python izap_mcp_client.py
```

## TypeScript

```bash
cd typescript
npm install
npm start
```

Both honor `IZAP_MCP_URL` (defaults to production) so you can point them at
staging: `export IZAP_MCP_URL="https://api-staging.izap.ai/mcp"`.
