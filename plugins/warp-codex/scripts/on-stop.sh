#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/should-notify.sh"
source "$SCRIPT_DIR/build-payload.sh"
source "$SCRIPT_DIR/common.sh"

should_use_plain || exit 0

INPUT="$(cat)"

STOP_HOOK_ACTIVE="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)"
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

TRANSCRIPT_PATH="$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)"
QUERY="$(extract_last_transcript_user_prompt "$TRANSCRIPT_PATH")"
RESPONSE="$(extract_last_transcript_assistant_message "$TRANSCRIPT_PATH")"
LAST_ASSISTANT_MESSAGE="$(printf '%s' "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)"

if [ -z "$RESPONSE" ]; then
    RESPONSE="$LAST_ASSISTANT_MESSAGE"
fi

QUERY="$(truncate_text "$QUERY" 200)"
RESPONSE="$(truncate_text "$RESPONSE" 200)"

SUMMARY="Task complete"
if [ -n "$RESPONSE" ]; then
    SUMMARY="$(truncate_text "Task complete: $RESPONSE" 200)"
fi

BODY="$(build_payload "$INPUT" "stop" \
    --arg summary "$SUMMARY" \
    --arg query "$QUERY" \
    --arg response "$RESPONSE" \
    --arg transcript_path "$TRANSCRIPT_PATH")"

"$SCRIPT_DIR/warp-notify.sh" "warp://cli-agent" "$BODY"
