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
    local expected_title="$2"
    local expected_body="$3"

    local title
    local body
    title="$(printf '%s\n' "$output" | sed -n '1p')"
    body="$(printf '%s\n' "$output" | sed -n '2p')"

    [ "$title" = "$expected_title" ] || {
        printf 'Unexpected title: %s\n' "$title" >&2
        exit 1
    }

    [ "$body" = "$expected_body" ] || {
        printf 'Unexpected body: %s\n' "$body" >&2
        exit 1
    }
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cp "$FIXTURE_ROOT/transcript.jsonl" "$tmpdir/transcript.jsonl"
jq --arg transcript_path "$tmpdir/transcript.jsonl" '. + {transcript_path: $transcript_path}' \
    "$FIXTURE_ROOT/stop-input.json" > "$tmpdir/stop-input.json"

session_start_output="$("$PLUGIN_SCRIPT_ROOT/on-session-start.sh" < "$FIXTURE_ROOT/session-start.json")"
assert_payload "$session_start_output" "Warp Codex" "Codex session started (gpt-5.4)"

prompt_submit_output="$("$PLUGIN_SCRIPT_ROOT/on-user-prompt-submit.sh" < "$FIXTURE_ROOT/user-prompt-submit.json")"
assert_payload "$prompt_submit_output" "Warp Codex" "Prompt submitted: Implement Warp notifications for Codex"

post_tool_use_output="$("$PLUGIN_SCRIPT_ROOT/on-post-tool-use.sh" < "$FIXTURE_ROOT/post-tool-use.json")"
assert_payload "$post_tool_use_output" "Warp Codex" "Bash completed: git status --short"

stop_output="$("$PLUGIN_SCRIPT_ROOT/on-stop.sh" < "$tmpdir/stop-input.json")"
assert_payload "$stop_output" "Warp Codex" "Task complete: Implemented Warp notifications and installer."

printf 'Smoke tests passed.\n'
