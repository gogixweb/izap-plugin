/**
 * Minimal iZap MCP client (TypeScript).
 *
 * Connects to the iZap MCP server over Streamable HTTP with a Bearer JWT, lists
 * the available tools, and calls `list_connected_assistants`.
 *
 *   npm install
 *   export IZAP_JWT="<your access token>"
 *   # optional: export IZAP_MCP_URL="https://api-staging.izap.ai/mcp"
 *   npm start
 *
 * Get a JWT from POST {origin}/api/v1/auth/jwt/login (form-encoded
 * username/password) or via OAuth — see references/authentication.md.
 */
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";

const url = process.env.IZAP_MCP_URL ?? "https://api.izap.ai/mcp";

async function main(): Promise<void> {
  const token = process.env.IZAP_JWT;
  if (!token) throw new Error("Set IZAP_JWT to a valid iZap access token.");

  const transport = new StreamableHTTPClientTransport(new URL(url), {
    requestInit: { headers: { Authorization: `Bearer ${token}` } },
  });

  const client = new Client({ name: "izap-client", version: "1.0.0" });
  await client.connect(transport);

  const { tools } = await client.listTools();
  console.log(`Connected. ${tools.length} tools available:`);
  for (const tool of tools) console.log(`  - ${tool.name}`);

  console.log("\nCalling list_connected_assistants...");
  const result = await client.callTool({ name: "list_connected_assistants", arguments: {} });
  console.log(result.isError ? `Tool error: ${JSON.stringify(result.content)}` : result.structuredContent ?? result.content);

  await client.close();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
