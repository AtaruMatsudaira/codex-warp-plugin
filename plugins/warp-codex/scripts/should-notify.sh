#!/bin/bash

set -euo pipefail

resolve_warp_tty() {
    if [ -n "${WARP_NOTIFY_TTY:-}" ] && [ -w "${WARP_NOTIFY_TTY}" ]; then
        printf '%s' "${WARP_NOTIFY_TTY}"
        return 0
    fi

    if [ -w /dev/tty ]; then
        printf '%s' "/dev/tty"
        return 0
    fi

    local pid tty_name tty_path parent
    pid="$$"

    while [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null; do
        tty_name="$(ps -o tty= -p "$pid" 2>/dev/null | tr -d '[:space:]')"
        if [ -n "$tty_name" ] && [ "$tty_name" != "??" ] && [ "$tty_name" != "?" ]; then
            tty_path="/dev/$tty_name"
            if [ -w "$tty_path" ]; then
                printf '%s' "$tty_path"
                return 0
            fi
        fi

        parent="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d '[:space:]')"
        if [ -z "$parent" ] || [ "$parent" = "$pid" ]; then
            break
        fi
        pid="$parent"
    done

    return 1
}

should_use_structured() {
    [ "${TERM_PROGRAM:-}" = "WarpTerminal" ] || return 1
    [ -n "${WARP_CLI_AGENT_PROTOCOL_VERSION:-}" ] || return 1
    resolve_warp_tty >/dev/null 2>&1 || [ "${WARP_NOTIFY_SINK:-}" = "stdout" ] || return 1
    return 0
}

should_use_plain() {
    [ "${TERM_PROGRAM:-}" = "WarpTerminal" ] || return 1
    resolve_warp_tty >/dev/null 2>&1 || [ "${WARP_NOTIFY_SINK:-}" = "stdout" ] || return 1
    return 0
}
