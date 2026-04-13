#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/should-notify.sh"
source "$SCRIPT_DIR/build-payload.sh"
source "$SCRIPT_DIR/common.sh"

should_use_plain || exit 0

INPUT="$(cat)"
SOURCE="$(printf '%s' "$INPUT" | jq -r '.source // "startup"' 2>/dev/null)"
MODEL="$(printf '%s' "$INPUT" | jq -r '.model // empty' 2>/dev/null)"
PERMISSION_MODE="$(printf '%s' "$INPUT" | jq -r '.permission_mode // empty' 2>/dev/null)"
SUMMARY="Codex session started"
if [ "$SOURCE" != "startup" ]; then
    SUMMARY="Codex session ${SOURCE}"
fi

BODY="$(build_payload "$INPUT" "session_start" \
    --arg summary "$SUMMARY" \
    --arg source "$SOURCE" \
    --arg model "$MODEL" \
    --arg permission_mode "$PERMISSION_MODE" \
    --arg plugin_version "$(plugin_version)")"

"$SCRIPT_DIR/warp-notify.sh" "warp://cli-agent" "$BODY"

