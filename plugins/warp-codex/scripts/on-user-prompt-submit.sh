#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/should-notify.sh"
source "$SCRIPT_DIR/build-payload.sh"
source "$SCRIPT_DIR/common.sh"

should_use_plain || exit 0

INPUT="$(cat)"
QUERY="$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)"
QUERY="$(truncate_text "$QUERY" 200)"
SUMMARY="Prompt submitted"
if [ -n "$QUERY" ]; then
    SUMMARY="$(truncate_text "Prompt submitted: $QUERY" 200)"
fi

BODY="$(build_payload "$INPUT" "prompt_submit" \
    --arg summary "$SUMMARY" \
    --arg query "$QUERY")"

"$SCRIPT_DIR/warp-notify.sh" "warp://cli-agent" "$BODY"

