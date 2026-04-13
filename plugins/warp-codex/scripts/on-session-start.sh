#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/should-notify.sh"
source "$SCRIPT_DIR/common.sh"

debug_hook_invocation "session_start"
should_use_plain || exit 0
notification_event_enabled "session_start" || {
    debug_log "hook=session_start skipped_by_policy"
    exit 0
}

INPUT="$(cat)"
SOURCE="$(printf '%s' "$INPUT" | jq -r '.source // "startup"' 2>/dev/null)"
MODEL="$(printf '%s' "$INPUT" | jq -r '.model // empty' 2>/dev/null)"
SUMMARY="Codex session started"
if [ "$SOURCE" != "startup" ]; then
    SUMMARY="Codex session ${SOURCE}"
fi
BODY="$SUMMARY"
if [ -n "$MODEL" ]; then
    BODY="$BODY ($MODEL)"
fi
BODY="$(truncate_text "$BODY" 200)"

debug_log "hook=session_start summary=$SUMMARY source=$SOURCE"
"$SCRIPT_DIR/warp-notify.sh" "Warp Codex" "$BODY"
