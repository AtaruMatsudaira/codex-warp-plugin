#!/bin/bash

set -euo pipefail

debug_log() {
    local logfile="${WARP_CODEX_DEBUG_LOG:-$HOME/.codex/warp-codex.log}"
    mkdir -p "$(dirname "$logfile")"
    printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" >> "$logfile" 2>/dev/null || true
}

debug_hook_invocation() {
    local hook_name="${1:-unknown}"
    debug_log "hook=${hook_name} pid=$$ ppid=$PPID term_program=${TERM_PROGRAM:-} warp_proto=${WARP_CLI_AGENT_PROTOCOL_VERSION:-} pwd=$(pwd)"
}

truncate_text() {
    local value="${1:-}"
    local limit="${2:-200}"
    if [ -z "$value" ]; then
        printf '%s' ""
        return 0
    fi

    if [ "${#value}" -le "$limit" ]; then
        printf '%s' "$value"
        return 0
    fi

    local cutoff=$((limit - 3))
    if [ "$cutoff" -lt 0 ]; then
        cutoff=0
    fi

    printf '%s...' "${value:0:cutoff}"
}

plugin_version() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    jq -r '.version // "unknown"' "$script_dir/../.codex-plugin/plugin.json" 2>/dev/null || printf '%s' "unknown"
}

extract_last_transcript_user_prompt() {
    local transcript_path="${1:-}"
    if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
        return 0
    fi

    jq -rs '
        def msg_text:
            if type == "string" then .
            elif type == "array" then
                [ .[] | if type == "string" then . elif (.type? == "text") then .text else empty end ] | join(" ")
            elif type == "object" and .text? then .text
            else empty
            end;

        [
            .[]
            | if .message? then .message else . end
            | select((.role // .type // "") == "user")
            | (.content // empty | msg_text)
            | select(length > 0)
        ]
        | last // empty
    ' "$transcript_path" 2>/dev/null || true
}

extract_last_transcript_assistant_message() {
    local transcript_path="${1:-}"
    if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
        return 0
    fi

    jq -rs '
        def msg_text:
            if type == "string" then .
            elif type == "array" then
                [ .[] | if type == "string" then . elif (.type? == "text") then .text else empty end ] | join(" ")
            elif type == "object" and .text? then .text
            else empty
            end;

        [
            .[]
            | if .message? then .message else . end
            | select((.role // .type // "") == "assistant")
            | (.content // empty | msg_text)
            | select(length > 0)
        ]
        | last // empty
    ' "$transcript_path" 2>/dev/null || true
}
