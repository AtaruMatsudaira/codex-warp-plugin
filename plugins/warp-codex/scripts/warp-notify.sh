#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/should-notify.sh"

TITLE="${1:-Notification}"
BODY="${2:-}"

if [ "${WARP_NOTIFY_SINK:-}" = "stdout" ]; then
    printf '%s\n%s\n' "$TITLE" "$BODY"
    exit 0
fi

if should_use_structured; then
    printf '\033]777;notify;%s;%s\007' "$TITLE" "$BODY" > /dev/tty 2>/dev/null || true
    exit 0
fi

if should_use_plain; then
    printf '\033]777;notify;%s;%s\007' "$TITLE" "$BODY" > /dev/tty 2>/dev/null || true
fi

