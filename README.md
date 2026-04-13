# Warp Codex

Codex CLI 向けの Warp ネイティブ通知プラグインです。  
`warpdotdev/claude-code-warp` の構造を参考にしつつ、Codex の公式 hooks に合わせて macOS + Warp Terminal で動くようにしています。

## できること

- `SessionStart` で Codex セッション開始を Warp に通知
- `UserPromptSubmit` でプロンプト送信を通知
- `PostToolUse` の `Bash` 完了を通知
- `Stop` でターン完了を通知

通知は Warp の OSC 777 を使って送ります。Warp が構造化 CLI agent payload を受け取れる場合は `warp://cli-agent` 宛ての JSON を送信します。

## 制限

現行の Codex 公開 hooks に合わせているため、Claude 版にある次のイベントは v1 では未対応です。

- `PermissionRequest`
- `Notification idle_prompt`

## インストール

前提:

- macOS
- Warp Terminal
- Codex CLI
- `jq`
- `rsync`

セットアップ:

```bash
bash scripts/install-local.sh
```

このスクリプトは次を行います。

- `plugins/warp-codex` を `~/.codex/plugins/warp-codex` に同期
- 同じ内容を `~/plugins/warp-codex` にも同期
- `~/.agents/plugins/marketplace.json` に `warp-codex` を登録
- `~/.codex/config.toml` の `[features].codex_hooks = true` を有効化
- `~/.codex/hooks.json` に必要な hook をマージ

反映後は Codex を再起動してください。

## 開発用確認

通知スクリプトの簡易検証:

```bash
bash scripts/smoke-test.sh
```

このテストは実際の Warp 通知送信を行わず、hook スクリプトが生成する payload を fixture 入力で検証します。

