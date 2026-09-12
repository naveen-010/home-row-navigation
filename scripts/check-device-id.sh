#!/usr/bin/env bash
# Check the loop-prevention exclusion against an existing Kanata output device.
# Run while keyd is stopped and a Kanata probe is running; see docs/install.md.
set -euo pipefail
config=${1:-/etc/keyd/default.conf}
[[ -r $config ]] || { echo "Cannot read $config" >&2; exit 1; }
command -v keyd >/dev/null
command -v timeout >/dev/null
command -v stdbuf >/dev/null
# Keep only device announcements; never print or store typed key events.
set +e
ids=$(timeout 1s stdbuf -oL keyd monitor | awk '$1 == "device" && $2 == "added:" && $4 == "kanata" {print $3}')
monitor_status=${PIPESTATUS[0]}
set -e
if [[ $monitor_status != 0 && $monitor_status != 124 ]]; then
    echo 'Unable to enumerate devices. Run with sudo.' >&2
    exit 1
fi
[[ -n $ids ]] || { echo 'No kanata output device found. Start the isolated probe described in docs/install.md.' >&2; exit 1; }
while IFS= read -r device_id; do
    [[ $device_id =~ ^[[:xdigit:]]{4}:[[:xdigit:]]{4}:[[:xdigit:]]{8}$ ]] || exit 1
    if ! awk -v expected="-$device_id" '
        /^\[/ { in_ids = ($0 == "[ids]") }
        in_ids && $1 == expected { found = 1 }
        END { exit !found }
    ' "$config"; then
        echo "Missing exclusion: add -$device_id to [ids] in $config before starting keyd." >&2
        exit 1
    fi
    echo "PASS: $config excludes Kanata output $device_id"
done <<< "$ids"
