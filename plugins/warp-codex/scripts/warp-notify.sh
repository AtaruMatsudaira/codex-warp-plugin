#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/should-notify.sh"
source "$SCRIPT_DIR/common.sh"

TITLE="${1:-Notification}"
BODY="${2:-}"

plain_notify_summary() {
    printf '%s' "$BODY" | jq -r '.summary // .response // .event // "Codex notification"' 2>/dev/null || printf '%s' "Codex notification"
}

plain_notify_event() {
    printf '%s' "$BODY" | jq -r '.event // "update"' 2>/dev/null || printf '%s' "update"
}

should_mirror_plain_notification() {
    local event_name
    event_name="$(plain_notify_event)"
    [ "$event_name" != "tool_complete" ]
}

if [ "${WARP_NOTIFY_SINK:-}" = "stdout" ]; then
    debug_log "notify sink=stdout title=$TITLE"
    printf '%s\n%s\n' "$TITLE" "$BODY"
    exit 0
fi

TTY_TARGET=""
if TTY_TARGET="$(resolve_warp_tty 2>/dev/null)"; then
    if should_use_structured || should_use_plain; then
        debug_log "notify tty_target=$TTY_TARGET title=$TITLE"
        if printf '\033]777;notify;%s;%s\007' "$TITLE" "$BODY" > "$TTY_TARGET" 2>/dev/null; then
            if should_mirror_plain_notification; then
                mirror_summary="$(truncate_text "$(plain_notify_summary)" 200)"
                mirror_event="$(plain_notify_event)"
                debug_log "notify mirror_plain tty_target=$TTY_TARGET event=$mirror_event summary=$mirror_summary"
                printf '\033]777;notify;%s;%s\007' "Warp Codex" "$mirror_summary" > "$TTY_TARGET" 2>/dev/null || true
            fi
            exit 0
        fi
        debug_log "notify tty_write_failed tty_target=$TTY_TARGET"
    fi
else
    debug_log "notify no_tty_target title=$TITLE"
fi

if command -v osascript >/dev/null 2>&1; then
    SUMMARY="$(printf '%s' "$BODY" | jq -r '.summary // .event // "Codex notification"' 2>/dev/null || printf '%s' "Codex notification")"
    EVENT_NAME="$(printf '%s' "$BODY" | jq -r '.event // "update"' 2>/dev/null || printf '%s' "update")"
    debug_log "notify fallback=osascript event=$EVENT_NAME summary=$SUMMARY"
    osascript \
        -e 'on run argv' \
        -e 'display notification (item 1 of argv) with title "Warp Codex" subtitle (item 2 of argv)' \
        -e 'end run' \
        "$SUMMARY" "$EVENT_NAME" >/dev/null 2>&1 || true
fi
