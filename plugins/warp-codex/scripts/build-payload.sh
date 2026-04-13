#!/bin/bash

set -euo pipefail

PLUGIN_CURRENT_PROTOCOL_VERSION=1

negotiate_protocol_version() {
    local warp_version="${WARP_CLI_AGENT_PROTOCOL_VERSION:-1}"
    if [ "$warp_version" -lt "$PLUGIN_CURRENT_PROTOCOL_VERSION" ] 2>/dev/null; then
        printf '%s' "$warp_version"
    else
        printf '%s' "$PLUGIN_CURRENT_PROTOCOL_VERSION"
    fi
}

build_payload() {
    local input="$1"
    local event="$2"
    shift 2

    local protocol_version session_id turn_id cwd project client
    protocol_version="$(negotiate_protocol_version)"
    session_id="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"
    turn_id="$(printf '%s' "$input" | jq -r '.turn_id // empty' 2>/dev/null)"
    cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
    client="$(printf '%s' "$input" | jq -r '.client // empty' 2>/dev/null)"
    project=""
    if [ -n "$cwd" ]; then
        project="$(basename "$cwd")"
    fi

    jq -nc \
        --argjson v "$protocol_version" \
        --arg agent "codex" \
        --arg event "$event" \
        --arg session_id "$session_id" \
        --arg turn_id "$turn_id" \
        --arg cwd "$cwd" \
        --arg project "$project" \
        --arg client "$client" \
        "$@" \
        '
        {
          v: $v,
          agent: $agent,
          event: $event,
          session_id: $session_id,
          turn_id: $turn_id,
          cwd: $cwd,
          project: $project
        }
        + (if $client == "" then {} else {client: $client} end)
        + $ARGS.named
        '
}

