#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURE_ROOT="$REPO_ROOT/tests/fixtures"
PLUGIN_SCRIPT_ROOT="$REPO_ROOT/plugins/warp-codex/scripts"

export TERM_PROGRAM="WarpTerminal"
export WARP_CLI_AGENT_PROTOCOL_VERSION="1"
export WARP_NOTIFY_SINK="stdout"

assert_payload() {
    local output="$1"
    local expected_event="$2"
    local jq_expr="$3"

    local title
    local body
    title="$(printf '%s\n' "$output" | sed -n '1p')"
    body="$(printf '%s\n' "$output" | sed -n '2p')"

    [ "$title" = "warp://cli-agent" ] || {
        printf 'Unexpected title: %s\n' "$title" >&2
        exit 1
    }

    printf '%s\n' "$body" | jq -e --arg expected_event "$expected_event" '
        .agent == "codex" and .event == $expected_event
    ' >/dev/null

    printf '%s\n' "$body" | jq -e "$jq_expr" >/dev/null
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cp "$FIXTURE_ROOT/transcript.jsonl" "$tmpdir/transcript.jsonl"
jq --arg transcript_path "$tmpdir/transcript.jsonl" '. + {transcript_path: $transcript_path}' \
    "$FIXTURE_ROOT/stop-input.json" > "$tmpdir/stop-input.json"

session_start_output="$("$PLUGIN_SCRIPT_ROOT/on-session-start.sh" < "$FIXTURE_ROOT/session-start.json")"
assert_payload "$session_start_output" "session_start" '.source == "startup" and .plugin_version == "0.1.0"'

prompt_submit_output="$("$PLUGIN_SCRIPT_ROOT/on-user-prompt-submit.sh" < "$FIXTURE_ROOT/user-prompt-submit.json")"
assert_payload "$prompt_submit_output" "prompt_submit" '.query == "Implement Warp notifications for Codex"' 

post_tool_use_output="$("$PLUGIN_SCRIPT_ROOT/on-post-tool-use.sh" < "$FIXTURE_ROOT/post-tool-use.json")"
assert_payload "$post_tool_use_output" "tool_complete" '.tool_name == "Bash" and (.command | contains("git status"))'

stop_output="$("$PLUGIN_SCRIPT_ROOT/on-stop.sh" < "$tmpdir/stop-input.json")"
assert_payload "$stop_output" "stop" '.query == "Implement Warp notifications for Codex" and (.response | contains("Implemented Warp notifications"))'

printf 'Smoke tests passed.\n'

