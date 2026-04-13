#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/should-notify.sh"
source "$SCRIPT_DIR/common.sh"

TITLE="${1:-Notification}"
BODY="${2:-}"

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
            exit 0
        fi
        debug_log "notify tty_write_failed tty_target=$TTY_TARGET"
    fi
else
    debug_log "notify no_tty_target title=$TITLE"
fi
