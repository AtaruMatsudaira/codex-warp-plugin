#!/bin/bash

set -euo pipefail

should_use_structured() {
    [ "${TERM_PROGRAM:-}" = "WarpTerminal" ] || return 1
    [ -n "${WARP_CLI_AGENT_PROTOCOL_VERSION:-}" ] || return 1
    [ -w /dev/tty ] || [ "${WARP_NOTIFY_SINK:-}" = "stdout" ] || return 1
    return 0
}

should_use_plain() {
    [ "${TERM_PROGRAM:-}" = "WarpTerminal" ] || return 1
    [ -w /dev/tty ] || [ "${WARP_NOTIFY_SINK:-}" = "stdout" ] || return 1
    return 0
}

