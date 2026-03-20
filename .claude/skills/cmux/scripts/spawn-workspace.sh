#!/bin/bash
# 派生命名 cmux 工作区并启动 Claude Code（不抢焦点）
# 用法: spawn-workspace.sh <名称> [--prompt "提示内容"]
set -euo pipefail

NAME="${1:?用法: spawn-workspace.sh <名称> [--prompt \"提示内容\"]}"
shift

PROMPT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt) PROMPT="$2"; shift 2 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

CURRENT=$(cmux current-workspace --id-format uuids | awk '{print $1}')

if [[ -n "$PROMPT" ]]; then
  TMPFILE=$(mktemp /tmp/spawn-prompt.XXXXXX)
  trap 'rm -f "$TMPFILE"' EXIT
  printf '%s' "$PROMPT" > "$TMPFILE"
  NEW=$(cmux new-workspace --command "claude \"\$(cat '$TMPFILE')\"" --id-format uuids | awk '{print $1}')
else
  NEW=$(cmux new-workspace --command "claude" --id-format uuids | awk '{print $1}')
fi

cmux rename-workspace --workspace "$NEW" "$NAME"
cmux select-workspace --workspace "$CURRENT"
echo "工作区 '$NAME' 已就绪 (ID: $NEW)"
