#!/usr/bin/env python3
"""Minimal iZap MCP client (Python).

Connects to the iZap MCP server over Streamable HTTP with a Bearer JWT, lists the
available tools, and calls `list_connected_assistants`.

    pip install mcp
    export IZAP_JWT="<your access token>"        # see how to get one below
    # optional: export IZAP_MCP_URL="https://api-staging.izap.ai/mcp"
    python izap_mcp_client.py

Get a JWT from the REST login endpoint (or use OAuth — see the plugin's
references/authentication.md):

    curl -X POST "https://api.izap.ai/api/v1/auth/jwt/login" \
         -H "Content-Type: application/x-www-form-urlencoded" \
         -d "username=$IZAP_EMAIL&password=$IZAP_PASSWORD"
"""

from __future__ import annotations

import asyncio
import os

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

URL = os.environ.get("IZAP_MCP_URL", "https://api.izap.ai/mcp")


async def main() -> None:
    token = os.environ.get("IZAP_JWT")
    if not token:
        raise SystemExit("Set IZAP_JWT to a valid iZap access token.")

    headers = {"Authorization": f"Bearer {token}"}
    async with streamablehttp_client(URL, headers=headers) as (read, write, _get_session_id):
        async with ClientSession(read, write) as session:
            await session.initialize()

            tools = await session.list_tools()
            print(f"Connected. {len(tools.tools)} tools available:")
            for tool in tools.tools:
                print(f"  - {tool.name}")

            print("\nCalling list_connected_assistants...")
            result = await session.call_tool("list_connected_assistants", {})
            if result.isError:
                print("Tool error:", result.content)
            else:
                print(result.structuredContent or result.content)


if __name__ == "__main__":
    asyncio.run(main())
