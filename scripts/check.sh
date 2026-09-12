#!/usr/bin/env bash
# Validate repository files without changing installed configs or services.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
mode=${1:---full}
case "$mode" in --full|--keyboard-only) ;; *) echo "Usage: $0 [--full|--keyboard-only]" >&2; exit 2 ;; esac
command -v keyd >/dev/null || { echo 'Install keyd first.' >&2; exit 1; }
keyd check "$repo/keyd/default.conf"
if [[ $mode == --full ]]; then
    command -v kanata >/dev/null || { echo 'Install Kanata first.' >&2; exit 1; }
    kanata --check --cfg "$repo/kanata/kanata.kbd"
fi
for script in "$repo"/scripts/*.sh; do bash -n "$script"; done
echo 'Configuration and shell syntax checks passed.'
