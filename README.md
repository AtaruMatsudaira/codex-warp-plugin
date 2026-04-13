# Warp Codex

Warp-native notifications for Codex CLI on macOS.

This project adapts the `warpdotdev/claude-code-warp` idea to Codex CLI using Codex's public hook system. It sends Warp OSC 777 notifications for key Codex session events and mirrors a plain notification for visibility in current Warp builds.

Japanese documentation is available at [README.ja.md](./README.ja.md).

## Features

- Session start notifications
- User prompt submit notifications
- Bash post-tool-use notifications
- Turn completion notifications
- macOS Notification Center fallback when Warp delivery is not available

## Current Scope

This implementation targets:

- macOS
- Warp Terminal
- Codex CLI

It intentionally does not implement Claude-specific events that are not exposed by Codex public hooks, such as:

- `PermissionRequest`
- `idle_prompt`

## Requirements

- macOS
- Warp Terminal
- Codex CLI
- `jq`
- `rsync`

## Install

```bash
bash scripts/install-local.sh
```

The installer will:

- sync `plugins/warp-codex` to `~/.codex/plugins/warp-codex`
- sync the same plugin to `~/plugins/warp-codex`
- register `warp-codex` in `~/.agents/plugins/marketplace.json`
- enable `[features].codex_hooks = true` in `~/.codex/config.toml`
- merge the required hooks into `~/.codex/hooks.json`

Restart Codex after installation.

## Verify

Run the local smoke test:

```bash
bash scripts/smoke-test.sh
```

This validates the hook scripts against fixture inputs without depending on a live Warp session.

## Debugging

Runtime hook debug logs are written to:

```text
~/.codex/warp-codex.log
```

## Notes

- Structured `warp://cli-agent` payloads are still sent.
- A plain OSC 777 notification is mirrored for user-visible delivery in current Warp behavior.
- If Warp pane delivery is unavailable, the scripts fall back to macOS Notification Center.

