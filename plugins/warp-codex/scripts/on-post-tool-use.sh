#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/should-notify.sh"
source "$SCRIPT_DIR/build-payload.sh"
source "$SCRIPT_DIR/common.sh"

debug_hook_invocation "post_tool_use"
should_use_plain || exit 0

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // "Bash"' 2>/dev/null)"
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
OUTPUT_PREVIEW="$(printf '%s' "$INPUT" | jq -r '(.tool_response // {} | tostring)' 2>/dev/null)"
COMMAND="$(truncate_text "$COMMAND" 160)"
OUTPUT_PREVIEW="$(truncate_text "$OUTPUT_PREVIEW" 160)"
SUMMARY="$TOOL_NAME completed"
if [ -n "$COMMAND" ]; then
    SUMMARY="$(truncate_text "$TOOL_NAME completed: $COMMAND" 200)"
fi

BODY="$(build_payload "$INPUT" "tool_complete" \
    --arg summary "$SUMMARY" \
    --arg tool_name "$TOOL_NAME" \
    --arg command "$COMMAND" \
    --arg output_preview "$OUTPUT_PREVIEW")"

debug_log "hook=post_tool_use tool=$TOOL_NAME summary=$SUMMARY"
"$SCRIPT_DIR/warp-notify.sh" "warp://cli-agent" "$BODY"
