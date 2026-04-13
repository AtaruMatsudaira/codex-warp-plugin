#!/bin/bash

set -euo pipefail

PLUGIN_NAME="warp-codex"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_SOURCE="$REPO_ROOT/plugins/$PLUGIN_NAME"
RUNTIME_PLUGIN_ROOT="$HOME/.codex/plugins/$PLUGIN_NAME"
HOME_PLUGIN_ROOT="$HOME/plugins/$PLUGIN_NAME"
HOOKS_TARGET="$HOME/.codex/hooks.json"
CONFIG_TARGET="$HOME/.codex/config.toml"
MARKETPLACE_TARGET="$HOME/.agents/plugins/marketplace.json"

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "$1" >&2
        exit 1
    }
}

sync_plugin_tree() {
    local source_root="$1"
    local target_root="$2"

    mkdir -p "$target_root"
    rsync -a --delete "$source_root/" "$target_root/"
    chmod +x "$target_root"/scripts/*.sh
}

render_hooks_file() {
    local output_path="$1"
    jq --arg plugin_root "$RUNTIME_PLUGIN_ROOT" '
        walk(
            if type == "string"
            then gsub("__PLUGIN_ROOT__"; $plugin_root)
            else .
            end
        )
    ' "$PLUGIN_SOURCE/hooks.json" > "$output_path"
}

ensure_hooks_config() {
    local rendered_hooks="$1"
    local temp_file
    temp_file="$(mktemp)"

    if [ -f "$HOOKS_TARGET" ]; then
        jq --arg plugin_marker "/$PLUGIN_NAME/" -s '
            def strip_plugin_entries:
                .hooks = (
                    (.hooks // {})
                    | with_entries(
                        .value |= map(
                            select(
                                (
                                    (.hooks // [])
                                    | map(.command // "")
                                    | any(contains($plugin_marker))
                                ) | not
                            )
                        )
                    )
                );

            def merge_hooks($base; $addon):
                reduce (($addon.hooks // {}) | to_entries[]) as $entry (
                    ($base | .hooks = (.hooks // {}) | strip_plugin_entries);
                    .hooks[$entry.key] = ((.hooks[$entry.key] // []) + $entry.value)
                );

            merge_hooks((.[0] // {"hooks": {}}); (.[1] // {"hooks": {}}))
        ' "$HOOKS_TARGET" "$rendered_hooks" > "$temp_file"
    else
        cp "$rendered_hooks" "$temp_file"
    fi

    mkdir -p "$(dirname "$HOOKS_TARGET")"
    mv "$temp_file" "$HOOKS_TARGET"
}

ensure_codex_hooks_feature() {
    local temp_file
    temp_file="$(mktemp)"

    if [ ! -f "$CONFIG_TARGET" ]; then
        mkdir -p "$(dirname "$CONFIG_TARGET")"
        cat > "$temp_file" <<'EOF'
[features]
codex_hooks = true
EOF
        mv "$temp_file" "$CONFIG_TARGET"
        return 0
    fi

    awk '
        BEGIN {
            in_features = 0
            found_features = 0
            found_key = 0
        }

        /^\[.*\][[:space:]]*$/ {
            if (in_features && !found_key) {
                print "codex_hooks = true"
                found_key = 1
            }

            in_features = ($0 == "[features]")
            if (in_features) {
                found_features = 1
            }

            print
            next
        }

        {
            if (in_features && $0 ~ /^[[:space:]]*codex_hooks[[:space:]]*=/) {
                if (!found_key) {
                    print "codex_hooks = true"
                    found_key = 1
                }
                next
            }

            print
        }

        END {
            if (!found_features) {
                if (NR > 0) {
                    print ""
                }
                print "[features]"
                print "codex_hooks = true"
            } else if (in_features && !found_key) {
                print "codex_hooks = true"
            }
        }
    ' "$CONFIG_TARGET" > "$temp_file"

    mv "$temp_file" "$CONFIG_TARGET"
}

ensure_home_marketplace() {
    local temp_file
    temp_file="$(mktemp)"

    if [ -f "$MARKETPLACE_TARGET" ]; then
        jq --arg plugin_name "$PLUGIN_NAME" '
            .name = (.name // "local-user")
            | .interface = (.interface // {"displayName": "Local User Plugins"})
            | .plugins = (.plugins // [])
            | .plugins = (
                [ .plugins[] | select(.name != $plugin_name) ] + [
                    {
                        "name": $plugin_name,
                        "source": {
                            "source": "local",
                            "path": ("./plugins/" + $plugin_name)
                        },
                        "policy": {
                            "installation": "AVAILABLE",
                            "authentication": "ON_INSTALL"
                        },
                        "category": "Productivity"
                    }
                ]
            )
        ' "$MARKETPLACE_TARGET" > "$temp_file"
    else
        mkdir -p "$(dirname "$MARKETPLACE_TARGET")"
        jq -n --arg plugin_name "$PLUGIN_NAME" '
            {
                "name": "local-user",
                "interface": {
                    "displayName": "Local User Plugins"
                },
                "plugins": [
                    {
                        "name": $plugin_name,
                        "source": {
                            "source": "local",
                            "path": ("./plugins/" + $plugin_name)
                        },
                        "policy": {
                            "installation": "AVAILABLE",
                            "authentication": "ON_INSTALL"
                        },
                        "category": "Productivity"
                    }
                ]
            }
        ' > "$temp_file"
    fi

    mv "$temp_file" "$MARKETPLACE_TARGET"
}

main() {
    if [ "$(uname -s)" != "Darwin" ]; then
        printf 'This installer currently supports macOS only.\n' >&2
        exit 1
    fi

    require_command codex
    require_command jq
    require_command rsync
    require_command awk
    require_command mktemp

    if [ ! -d "$PLUGIN_SOURCE" ]; then
        printf 'Plugin source not found: %s\n' "$PLUGIN_SOURCE" >&2
        exit 1
    fi

    sync_plugin_tree "$PLUGIN_SOURCE" "$RUNTIME_PLUGIN_ROOT"
    sync_plugin_tree "$PLUGIN_SOURCE" "$HOME_PLUGIN_ROOT"

    local rendered_hooks
    rendered_hooks="$(mktemp)"
    render_hooks_file "$rendered_hooks"
    ensure_hooks_config "$rendered_hooks"
    rm -f "$rendered_hooks"

    ensure_codex_hooks_feature
    ensure_home_marketplace

    printf 'Installed %s\n' "$PLUGIN_NAME"
    printf 'Runtime plugin: %s\n' "$RUNTIME_PLUGIN_ROOT"
    printf 'Marketplace plugin: %s\n' "$HOME_PLUGIN_ROOT"
    printf 'Codex config updated: %s\n' "$CONFIG_TARGET"
    printf 'Hooks updated: %s\n' "$HOOKS_TARGET"
    printf 'Restart Codex to load the updated hooks.\n'
}

main "$@"

