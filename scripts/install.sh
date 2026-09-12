#!/usr/bin/env bash
# Stage configs and the system service. Activation is deliberately a separate step.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
mode=--full
dry_run=false
for arg in "$@"; do
    case "$arg" in
        --full|--keyboard-only) mode=$arg ;;
        --dry-run) dry_run=true ;;
        --help|-h)
            echo "Usage: sudo bash $0 [--full|--keyboard-only] [--dry-run]"
            echo 'Backs up and installs files; does not start, stop, enable, or reload remappers.'
            exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done
bash "$repo/scripts/check.sh" "$mode"
sources=("$repo/keyd/default.conf")
targets=(/etc/keyd/default.conf)
if [[ $mode == --full ]]; then
    # Match the service PATH, which intentionally excludes user-specific Cargo paths.
    system_kanata=$(PATH=/usr/local/bin:/usr/bin:/bin command -v kanata) || {
        echo 'Install Kanata in /usr/bin or /usr/local/bin for the system service.' >&2
        exit 1
    }
    "$system_kanata" --check --cfg "$repo/kanata/kanata.kbd"
    sources+=("$repo/kanata/kanata.kbd" "$repo/kanata/home-row-navigation-mouse.service")
    targets+=(/etc/kanata/home-row-navigation.kbd /etc/systemd/system/home-row-navigation-mouse.service)
fi
for index in "${!targets[@]}"; do
    printf '%s -> %s\n' "${sources[index]}" "${targets[index]}"
done
if $dry_run; then
    echo 'Dry run: no files or services changed.'
    exit 0
fi
[[ $EUID -eq 0 ]] || { echo 'Run with sudo, or use --dry-run.' >&2; exit 1; }
# Other keyd configs may override the exclusion and re-grab Kanata's output.
shopt -s nullglob
for config in /etc/keyd/*.conf; do
    [[ $config == /etc/keyd/default.conf ]] || {
        echo "Additional keyd config $config found; merge mappings and exclusions manually." >&2
        exit 1
    }
done
install -d -m755 /var/backups
backup=$(mktemp -d /var/backups/home-row-navigation.XXXXXX)
echo "Backup directory: $backup (original paths retained inside)"
for target in "${targets[@]}"; do
    if [[ -e $target || -L $target ]]; then
        cp -a --parents -- "$target" "$backup/"
    fi
done
for index in "${!targets[@]}"; do
    install -Dm644 "${sources[index]}" "${targets[index]}"
done
systemctl daemon-reload
echo 'Files installed. No remappers started, stopped, enabled, or reloaded.'
echo "Follow $repo/docs/install.md to check routing and activate the setup."
