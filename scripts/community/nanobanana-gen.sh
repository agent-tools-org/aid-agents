#!/usr/bin/env bash
# nanobanana-gen: Generate images via nanobanana MCP server (direct JSON-RPC, no Gemini CLI quota)
# Usage: nanobanana-gen "prompt text" [output_dir]

set -euo pipefail

PROMPT="${1:?Usage: nanobanana-gen \"prompt\" [output_dir]}"
OUTPUT_DIR="${2:-$(pwd)/nanobanana-output}"
MCP_SERVER="$HOME/.gemini/extensions/nanobanana/mcp-server/dist/index.js"

if [[ -z "${NANOBANANA_API_KEY:-}" ]]; then
  echo "ERROR: NANOBANANA_API_KEY not set. Get one from https://aistudio.google.com/apikey" >&2
  exit 1
fi

if [[ ! -f "$MCP_SERVER" ]]; then
  echo "ERROR: nanobanana MCP server not found at $MCP_SERVER" >&2
  echo "Install: gemini extensions install https://github.com/gemini-cli-extensions/nanobanana" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Escape prompt for JSON
JSON_PROMPT=$(printf '%s' "$PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')

# JSON-RPC messages
INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"aid-nanobanana","version":"1.0"}}}'
NOTIFY='{"jsonrpc":"2.0","id":2,"method":"notifications/initialized"}'
CALL="{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"generate_image\",\"arguments\":{\"prompt\":${JSON_PROMPT},\"output_directory\":\"${OUTPUT_DIR}\",\"count\":1}}}"

# Call MCP server and extract result
RESULT=$(printf '%s\n%s\n%s\n' "$INIT" "$NOTIFY" "$CALL" | node "$MCP_SERVER" 2>/dev/null)

OUTPUT=$(echo "$RESULT" | grep '"id":3' | python3 -c '
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        msg = json.loads(line)
        if msg.get("id") == 3:
            for content in msg.get("result", {}).get("content", []):
                if content.get("type") == "text":
                    print(content["text"])
            break
    except json.JSONDecodeError:
        pass
')

if [[ -n "$OUTPUT" ]]; then
  echo "$OUTPUT"
else
  echo "ERROR: No output from nanobanana MCP server" >&2
  exit 1
fi
