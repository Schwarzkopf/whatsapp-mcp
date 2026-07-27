#!/bin/bash
set -e

mkdir -p /app/whatsapp-bridge/store

(cd /app/whatsapp-bridge && ./whatsapp-bridge) &
BRIDGE_PID=$!

trap 'kill -TERM "$BRIDGE_PID" 2>/dev/null' TERM INT

cd /app/whatsapp-mcp-server
uv run python main.py &
MCP_PID=$!

wait -n "$BRIDGE_PID" "$MCP_PID"
EXIT_CODE=$?
kill -TERM "$BRIDGE_PID" "$MCP_PID" 2>/dev/null
exit "$EXIT_CODE"
