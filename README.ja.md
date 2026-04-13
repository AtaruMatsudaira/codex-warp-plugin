# Warp Codex

Codex CLI 向けの Warp ネイティブ通知プラグインです。

このプロジェクトは `warpdotdev/claude-code-warp` の考え方を Codex CLI に移植し、Codex の公開 hook 機構を使って主要イベントを Warp に通知します。通知は Warp の公式ドキュメントにある OSC 777 の title/body 形式に合わせています。

## できること

- セッション開始通知
- プロンプト送信通知
- Bash 実行後の通知
- ターン完了通知

## 対象範囲

対象は以下です。

- macOS
- Warp Terminal
- Codex CLI

Codex の公開 hooks にないため、Claude 版の以下は未対応です。

- `PermissionRequest`
- `idle_prompt`

## 前提

- macOS
- Warp Terminal
- Codex CLI
- `jq`
- `rsync`

## インストール

```bash
bash scripts/install-local.sh
```

このスクリプトは次を行います。

- `plugins/warp-codex` を `~/.codex/plugins/warp-codex` に同期
- 同じ内容を `~/plugins/warp-codex` にも同期
- `~/.agents/plugins/marketplace.json` に `warp-codex` を登録
- `~/.codex/config.toml` の `[features].codex_hooks = true` を有効化
- `~/.codex/hooks.json` に必要な hook をマージ

インストール後は Codex を再起動してください。

## 動作確認

```bash
bash scripts/smoke-test.sh
```

fixture 入力で hook スクリプトの payload 生成を確認できます。

## デバッグ

hook のデバッグログは以下に出ます。

```text
~/.codex/warp-codex.log
```

## 補足

- 通知は Warp の公式な OSC 777 `notify;<title>;<body>` 形式を使います
- 通知は trigger 時に別アプリへフォーカスしているときだけ表示されます
- Warp 側の通知設定と macOS 側の通知許可の両方が必要です
