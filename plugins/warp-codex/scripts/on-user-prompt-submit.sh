#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/should-notify.sh"
source "$SCRIPT_DIR/common.sh"

debug_hook_invocation "user_prompt_submit"
should_use_plain || exit 0
notification_event_enabled "user_prompt_submit" || {
    debug_log "hook=user_prompt_submit skipped_by_policy"
    exit 0
}

INPUT="$(cat)"
QUERY="$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)"
QUERY="$(truncate_text "$QUERY" 200)"
SUMMARY="Prompt submitted"
if [ -n "$QUERY" ]; then
    SUMMARY="$(truncate_text "Prompt submitted: $QUERY" 200)"
fi

debug_log "hook=user_prompt_submit summary=$SUMMARY"
"$SCRIPT_DIR/warp-notify.sh" "Warp Codex" "$SUMMARY"
