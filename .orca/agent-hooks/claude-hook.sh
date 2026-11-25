#!/bin/sh
orca_hook_printed=
orca_hook_answer=
orca_hook_decides=
orca_hook_finish() {
  [ -z "$orca_hook_printed" ] || return 0
  if [ -n "$orca_hook_answer" ]; then printf '%s\n' "$orca_hook_answer"; else printf '{}\n'; fi
}
trap orca_hook_finish EXIT
: "${ORCA_PANE_KEY:=${ORCA_AGENT_PANE:-}}"
: "${ORCA_AGENT_LAUNCH_TOKEN:=${ORCA_AGENT_LAUNCH:-}}"
export ORCA_PANE_KEY ORCA_AGENT_LAUNCH_TOKEN
payload=$(if [ -x /bin/cat ]; then exec /bin/cat 2>/dev/null; fi; { command -p cat 2>/dev/null || cat; })
if [ -z "$payload" ]; then
  exit 0
fi
case "$payload" in
  *'"hook_event_name":"PreToolUse"'*|*'"hook_event_name": "PreToolUse"'*) orca_hook_decides=claude-pre-tool-use-v1; max_time=8 ;;
  *'"hook_event_name":"PermissionRequest"'*|*'"hook_event_name": "PermissionRequest"'*) if [ -n "${ORCA_HOOK_ASYNC:-}" ]; then printf '{}\n'; orca_hook_printed=1; else orca_hook_decides=claude-permission-request-v1; max_time=126; fi ;;
  *) printf '{}\n'; orca_hook_printed=1 ;;
esac
if [ -n "$GROK_HOOK_EVENT" ]; then
  exit 0
fi
if [ -n "$CURSOR_VERSION" ] && [ -n "$CURSOR_PROJECT_DIR" ]; then
  exit 0
fi
spool_hook_event() {
  case "$payload" in *'"PreToolUse"'*|*'"PostToolUse"'*|*'"PostToolUseFailure"'*|*'"hook_event_name":"PostToolBatch"'*|*'"hook_event_name": "PostToolBatch"'*) return 0 ;; esac
  [ -n "${ORCA_AGENT_HOOK_ENDPOINT:-}" ] || return 0
  [ -n "${ORCA_PANE_KEY:-}" ] || return 0
  [ -r "$ORCA_AGENT_HOOK_ENDPOINT" ] || return 0
  spool_base=${ORCA_AGENT_HOOK_ENDPOINT%/*}
  spool_dir="$spool_base/spool"
  mkdir -p "$spool_dir" 2>/dev/null || return 0
  chmod 700 "$spool_dir" 2>/dev/null || :
  spool_id=$(printf %s "${ORCA_PANE_KEY:-unknown}" | tail -c 36 | tr '/:' '__')
  spool_file="$spool_dir/pane-$spool_id.jsonl"
  if [ -f "$spool_file" ] && find "$spool_file" -mtime +7 -print -quit 2>/dev/null | grep -q .; then : > "$spool_file"; fi
  [ -f "$spool_file" ] || : > "$spool_file"
  spool_size=$(wc -c < "$spool_file" 2>/dev/null || printf 0)
  [ "$spool_size" -lt 5242880 ] || return 0
  spool_now=$(date +%s 2>/dev/null || printf 0)
  spool_now=$((spool_now * 1000))
  spool_json_escape() { printf %s "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/[[:cntrl:]]/ /g'; }
  { printf '\n{"paneKey":"%s","tabId":"%s","worktreeId":"%s","env":"%s","version":"%s","launchToken":"%s","source":"%s","receivedAt":%s,"agentProcess":"%s","tmuxPane":"%s","payload":%s}\n' "$(spool_json_escape "${ORCA_PANE_KEY:-}")" "$(spool_json_escape "${ORCA_TAB_ID:-}")" "$(spool_json_escape "${ORCA_WORKTREE_ID:-}")" "$(spool_json_escape "${ORCA_AGENT_HOOK_ENV:-}")" "$(spool_json_escape "${ORCA_AGENT_HOOK_VERSION:-}")" "$(spool_json_escape "${ORCA_AGENT_LAUNCH_TOKEN:-}")" "$(spool_json_escape "claude")" "$spool_now" "$(spool_json_escape "${orca_agent_process:-}")" "$(spool_json_escape "${orca_tmux_pane:-}")" "$payload"; } >> "$spool_file" 2>/dev/null || :
  chmod 600 "$spool_file" 2>/dev/null || :
}
if [ -n "$DEVIN_PROJECT_DIR" ]; then
  exit 0
fi
if [ -n "$CLAUDE_JOB_DIR" ]; then
  exit 0
fi
orca_agent_process= orca_agent_pid="${ORCA_HOOK_AGENT_PID:-}"
orca_agent_stat_fields() { orca_agent_ppid=${2-}; orca_agent_start=${20-}; }
[ -z "${ORCA_PANE_KEY:-}" ] || case "$orca_agent_pid" in ""|*[!0-9]*) ;; *)
  if [ -r "/proc/$orca_agent_pid/stat" ]; then
    orca_agent_stat= orca_agent_line= orca_agent_boot= orca_agent_start= orca_agent_ppid= orca_agent_cmdline=
    while IFS= read -r orca_agent_line || [ -n "$orca_agent_line" ]; do orca_agent_stat="$orca_agent_stat$orca_agent_line "; orca_agent_line=; done 2>/dev/null < "/proc/$orca_agent_pid/stat"
    orca_agent_stat_fields ${orca_agent_stat##*) }
    case "${orca_agent_stat%%) *}" in *" (sh"|*" (dash"|*" (bash"|*" (zsh")
      while IFS= read -r orca_agent_line || [ -n "$orca_agent_line" ]; do orca_agent_cmdline="$orca_agent_cmdline$orca_agent_line "; orca_agent_line=; done 2>/dev/null < "/proc/$orca_agent_pid/cmdline"
      case "$orca_agent_cmdline" in *ORCA_HOOK_AGENT_PID=*)
        case "$orca_agent_ppid" in ""|0|1|*[!0-9]*) ;; *)
          if [ -r "/proc/$orca_agent_ppid/stat" ]; then
            orca_agent_pid=$orca_agent_ppid orca_agent_stat= orca_agent_line= orca_agent_start=
            while IFS= read -r orca_agent_line || [ -n "$orca_agent_line" ]; do orca_agent_stat="$orca_agent_stat$orca_agent_line "; orca_agent_line=; done 2>/dev/null < "/proc/$orca_agent_pid/stat"
            orca_agent_stat_fields ${orca_agent_stat##*) }
          fi ;; esac ;; esac ;; esac
    IFS= read -r orca_agent_boot 2>/dev/null < /proc/sys/kernel/random/boot_id
    case "$orca_agent_start" in ""|*[!0-9]*) ;; *)
      [ -z "$orca_agent_boot" ] || orca_agent_process="{\"pid\":$orca_agent_pid,\"platform\":\"linux\",\"startTime\":\"$orca_agent_boot:$orca_agent_start\"}" ;; esac
  elif case "${OSTYPE-}" in darwin*) ;; *) [ "$(uname -s 2>/dev/null)" = Darwin ] ;; esac; then
    orca_agent_cmdline=$(exec /bin/ps -p "$orca_agent_pid" -o ppid=,args= 2>/dev/null)
    orca_agent_cmdline=${orca_agent_cmdline#"${orca_agent_cmdline%%[! ]*}"}
    orca_agent_ppid=${orca_agent_cmdline%% *}
    orca_agent_cmdline=${orca_agent_cmdline#* }
    orca_agent_cmdline=${orca_agent_cmdline#"${orca_agent_cmdline%%[! ]*}"}
    case "${orca_agent_cmdline%% *}" in sh|*/sh|dash|*/dash|bash|*/bash|zsh|*/zsh)
      case "$orca_agent_cmdline" in *ORCA_HOOK_AGENT_PID=*)
        case "$orca_agent_ppid" in ""|0|1|*[!0-9]*) ;; *) orca_agent_pid=$orca_agent_ppid ;; esac ;; esac ;; esac
    orca_agent_start=$(TZ=UTC0 LC_ALL=C exec /bin/ps -p "$orca_agent_pid" -o lstart= 2>/dev/null)
    orca_agent_start=${orca_agent_start#"${orca_agent_start%%[! ]*}"}
    orca_agent_start=${orca_agent_start%"${orca_agent_start##*[! ]}"}
    [ -z "$orca_agent_start" ] || orca_agent_process="{\"pid\":$orca_agent_pid,\"platform\":\"darwin\",\"startTime\":\"$orca_agent_start\"}"
  fi ;;
esac
orca_tmux_pane=
case "${TMUX_PANE:-}" in %[0-9]*) [ -z "${TMUX:-}" ] || orca_tmux_pane="$TMUX_PANE ${TMUX%,*,*}" ;; esac
[ "$orca_tmux_pane" != "${ORCA_INHERITED_TMUX:-}" ] || orca_tmux_pane=
if [ -n "$ORCA_AGENT_HOOK_ENDPOINT" ] && [ -r "$ORCA_AGENT_HOOK_ENDPOINT" ]; then
  unset ORCA_AGENT_HOOK_TRANSPORT
  . "$ORCA_AGENT_HOOK_ENDPOINT" 2>/dev/null || :
fi
if [ -z "$ORCA_AGENT_HOOK_PORT" ] || [ -z "$ORCA_AGENT_HOOK_TOKEN" ] || [ -z "$ORCA_PANE_KEY" ]; then
  spool_hook_event
  exit 0
fi
orca_hook_pack_metadata() {
  orca_hook_meta_key="${#ORCA_PANE_KEY}:$ORCA_PANE_KEY ${#ORCA_TAB_ID}:$ORCA_TAB_ID ${#ORCA_AGENT_LAUNCH_TOKEN}:$ORCA_AGENT_LAUNCH_TOKEN ${#ORCA_WORKTREE_ID}:$ORCA_WORKTREE_ID ${#ORCA_AGENT_HOOK_ENV}:$ORCA_AGENT_HOOK_ENV ${#ORCA_AGENT_HOOK_VERSION}:$ORCA_AGENT_HOOK_VERSION"
  orca_hook_meta_file=
  if [ -r "${ORCA_AGENT_HOOK_ENDPOINT:-}" ]; then
    orca_hook_meta_id=$ORCA_PANE_KEY
    while :; do case "$orca_hook_meta_id" in *[/:]*) orca_hook_meta_id="${orca_hook_meta_id%%[/:]*}_${orca_hook_meta_id#*[/:]}" ;; *) break ;; esac; done
    orca_hook_meta_file="${ORCA_AGENT_HOOK_ENDPOINT%/*}/hook-metadata/pane-$orca_hook_meta_id"
    orca_hook_meta_line=
    IFS= read -r orca_hook_meta_line 2>/dev/null < "$orca_hook_meta_file"
    orca_hook_metadata=${orca_hook_meta_line%% *}
    [ -z "$orca_hook_metadata" ] || [ "${orca_hook_meta_line#* }" != "$orca_hook_meta_key" ] || return 0
  fi
  orca_hook_metadata=$(printf '%s\037%s\037%s\037%s\037%s\037%s' "$ORCA_PANE_KEY" "$ORCA_TAB_ID" "$ORCA_AGENT_LAUNCH_TOKEN" "$ORCA_WORKTREE_ID" "$ORCA_AGENT_HOOK_ENV" "$ORCA_AGENT_HOOK_VERSION" | base64 | tr -d '\n') && [ -n "$orca_hook_metadata" ] || return 1
  [ -n "$orca_hook_meta_file" ] || return 0
  [ -d "${orca_hook_meta_file%/*}" ] || mkdir -m 700 "${orca_hook_meta_file%/*}" 2>/dev/null || return 0
  printf '%s %s\n' "$orca_hook_metadata" "$orca_hook_meta_key" 2>/dev/null > "$orca_hook_meta_file.$$" && mv -f "$orca_hook_meta_file.$$" "$orca_hook_meta_file" 2>/dev/null
  return 0
}
if [ -z "$orca_hook_decides" ]; then
if [ "${ORCA_AGENT_HOOK_TRANSPORT:-}" = "raw-json-v1" ] && command -v base64 >/dev/null 2>&1 && command -v tr >/dev/null 2>&1; then
  orca_hook_pack_metadata && \
  printf '%s' "$payload" | LC_ALL= LC_NUMERIC=C curl -sS -X POST "http://127.0.0.1:${ORCA_AGENT_HOOK_PORT}/hook/claude" \
    --connect-timeout "${connect_timeout:-0.5}" --max-time "${max_time:-1.5}" \
    --noproxy "127.0.0.1" \
    -H "Content-Type: application/json" \
    -H "X-Orca-Agent-Hook-Token: ${ORCA_AGENT_HOOK_TOKEN}" \
    -H "X-Orca-Agent-Hook-Meta-Encoding: base64" \
    -H "X-Orca-Agent-Hook-Meta: ${orca_hook_metadata}" \
    -H "X-Orca-Agent-Process: ${orca_agent_process:-}" \
    -H "X-Orca-Tmux-Pane: ${orca_tmux_pane:-}" \
    -H "X-Orca-Hook-Decision: ${orca_hook_decides:-}" \
    --data-binary @-
else
  printf '%s' "$payload" | LC_ALL= LC_NUMERIC=C curl -sS -X POST "http://127.0.0.1:${ORCA_AGENT_HOOK_PORT}/hook/claude" \
    --connect-timeout "${connect_timeout:-0.5}" --max-time "${max_time:-1.5}" \
    --noproxy "127.0.0.1" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "X-Orca-Agent-Hook-Token: ${ORCA_AGENT_HOOK_TOKEN}" \
    -H "X-Orca-Hook-Decision: ${orca_hook_decides:-}" \
    --data-urlencode "paneKey=${ORCA_PANE_KEY}" \
    --data-urlencode "tabId=${ORCA_TAB_ID}" \
    --data-urlencode "launchToken=${ORCA_AGENT_LAUNCH_TOKEN}" \
    --data-urlencode "worktreeId=${ORCA_WORKTREE_ID}" \
    --data-urlencode "env=${ORCA_AGENT_HOOK_ENV}" \
    --data-urlencode "version=${ORCA_AGENT_HOOK_VERSION}" \
    --data-urlencode "agentProcess=${orca_agent_process:-}" \
    --data-urlencode "tmuxPane=${orca_tmux_pane:-}" \
    --data-urlencode "payload@-"
fi >/dev/null 2>&1 || spool_hook_event
  exit 0
fi
orca_hook_reply=$(if [ "${ORCA_AGENT_HOOK_TRANSPORT:-}" = "raw-json-v1" ] && command -v base64 >/dev/null 2>&1 && command -v tr >/dev/null 2>&1; then
  orca_hook_pack_metadata && \
  printf '%s' "$payload" | LC_ALL= LC_NUMERIC=C curl -sS -X POST "http://127.0.0.1:${ORCA_AGENT_HOOK_PORT}/hook/claude" \
    --connect-timeout "${connect_timeout:-0.5}" --max-time "${max_time:-1.5}" \
    --noproxy "127.0.0.1" \
    -H "Content-Type: application/json" \
    -H "X-Orca-Agent-Hook-Token: ${ORCA_AGENT_HOOK_TOKEN}" \
    -H "X-Orca-Agent-Hook-Meta-Encoding: base64" \
    -H "X-Orca-Agent-Hook-Meta: ${orca_hook_metadata}" \
    -H "X-Orca-Agent-Process: ${orca_agent_process:-}" \
    -H "X-Orca-Tmux-Pane: ${orca_tmux_pane:-}" \
    -H "X-Orca-Hook-Decision: ${orca_hook_decides:-}" \
    --data-binary @-
else
  printf '%s' "$payload" | LC_ALL= LC_NUMERIC=C curl -sS -X POST "http://127.0.0.1:${ORCA_AGENT_HOOK_PORT}/hook/claude" \
    --connect-timeout "${connect_timeout:-0.5}" --max-time "${max_time:-1.5}" \
    --noproxy "127.0.0.1" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "X-Orca-Agent-Hook-Token: ${ORCA_AGENT_HOOK_TOKEN}" \
    -H "X-Orca-Hook-Decision: ${orca_hook_decides:-}" \
    --data-urlencode "paneKey=${ORCA_PANE_KEY}" \
    --data-urlencode "tabId=${ORCA_TAB_ID}" \
    --data-urlencode "launchToken=${ORCA_AGENT_LAUNCH_TOKEN}" \
    --data-urlencode "worktreeId=${ORCA_WORKTREE_ID}" \
    --data-urlencode "env=${ORCA_AGENT_HOOK_ENV}" \
    --data-urlencode "version=${ORCA_AGENT_HOOK_VERSION}" \
    --data-urlencode "agentProcess=${orca_agent_process:-}" \
    --data-urlencode "tmuxPane=${orca_tmux_pane:-}" \
    --data-urlencode "payload@-"
fi 2>/dev/null) || { orca_hook_reply=; spool_hook_event; }
case "$orca_hook_decides:$orca_hook_reply" in
  claude-pre-tool-use-v1:'{"hookSpecificOutput":{"hookEventName":"PreToolUse"'*'}}') orca_hook_answer=$orca_hook_reply ;;
  claude-permission-request-v1:'{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"'*'}}}') orca_hook_answer=$orca_hook_reply ;;
esac
exit 0
