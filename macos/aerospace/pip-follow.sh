#!/bin/bash
set -euo pipefail
# Serialize workspace-change callbacks without dropping events. lockf ships with macOS;
# flock is a fallback for systems where it is installed.
lockfile="/tmp/pip-follow.lock"
if [[ "${PIP_FOLLOW_LOCKED:-0}" != "1" ]]; then
  if [[ -x /usr/bin/lockf ]]; then
    PIP_FOLLOW_LOCKED=1 exec /usr/bin/lockf "$lockfile" "$0"
  elif command -v flock >/dev/null 2>&1; then
    PIP_FOLLOW_LOCKED=1 exec flock -x "$lockfile" "$0"
  fi
fi

# Read the focused workspace after taking the lock; queued callbacks may be stale.
current_workspace="$(aerospace list-workspaces --focused --format '%{workspace}')"
# Monitor hosting the workspace we just switched to. This callback also fires when
# focus merely moves to another display, so the monitor check below keeps the PiP
# on whichever display it was dragged to instead of chasing the focus.
target_monitor="$(aerospace list-workspaces --all --format '%{workspace}%{tab}%{monitor-id}' |
  awk -F'\t' -v ws="$current_workspace" '$1 == ws { print $2; exit }')"
[[ -n "$target_monitor" ]] || exit 0
shopt -s nocasematch
while IFS=$'\t' read -r window_id window_title window_workspace window_monitor; do
  # Skip windows already on the target workspace — avoids a no-op IPC call
  [[ "$window_workspace" == "$current_workspace" ]] && continue
  # Only follow workspace switches happening on the PiP's own display
  [[ "$window_monitor" == "$target_monitor" ]] || continue
  # Exact match prevents browser tabs containing this phrase from following.
  if [[ "$window_title" =~ ^picture[-[:space:]]+in[-[:space:]]+picture$ ]]; then
    aerospace move-node-to-workspace --window-id "$window_id" "$current_workspace" 2>/dev/null || true
  fi
done < <(aerospace list-windows --all --format '%{window-id}%{tab}%{window-title}%{tab}%{workspace}%{tab}%{monitor-id}')
