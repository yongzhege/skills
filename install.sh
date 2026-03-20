#!/bin/bash
# cmux-skill 安装器
# 将 cmux skill 安装到不同 AI 编码工具的指令目录
#
# 用法:
#   ./install.sh                    # 交互式选择目标
#   ./install.sh claude             # 安装到 Claude Code
#   ./install.sh opencode           # 安装到 OpenCode
#   ./install.sh cursor             # 安装到 Cursor
#   ./install.sh copilot            # 安装到 GitHub Copilot
#   ./install.sh windsurf           # 安装到 Windsurf
#   ./install.sh codex              # 安装到 Codex / AGENTS.md
#   ./install.sh all                # 安装到所有已检测到的工具
#   ./install.sh --path <dir>       # 安装到自定义项目目录
#   ./install.sh --global           # 安装到全局目录（~/.claude 等）
#   ./install.sh --list             # 列出支持的目标
#   ./install.sh --check            # 检测当前目录已安装的 skill

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_SKILL="$SCRIPT_DIR/.claude/skills/cmux/SKILL.md"
PROJECT_DIR="$(pwd)"
GLOBAL=false

# ── 颜色 ──────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { printf "${CYAN}[info]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[ok]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[warn]${NC}  %s\n" "$*"; }
err()   { printf "${RED}[err]${NC}   %s\n" "$*" >&2; }

# ── 提取 skill 正文（去掉 YAML frontmatter）──────────
extract_body() {
  awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2{print}' "$SOURCE_SKILL"
}

# ── 安装函数 ──────────────────────────────────────────

install_claude() {
  local base="$1"
  local dest="$base/.claude/skills/cmux"
  mkdir -p "$dest/scripts"
  cp "$SOURCE_SKILL" "$dest/SKILL.md"
  if [[ -f "$SCRIPT_DIR/.claude/skills/cmux/scripts/spawn-workspace.sh" ]]; then
    cp "$SCRIPT_DIR/.claude/skills/cmux/scripts/spawn-workspace.sh" "$dest/scripts/"
    chmod +x "$dest/scripts/spawn-workspace.sh"
  fi
  ok "Claude Code -> $dest/SKILL.md"
}

install_opencode() {
  local base="$1"
  local dest="$base/.opencode"
  mkdir -p "$dest"

  {
    echo "# cmux Skill"
    echo ""
    echo "当用户提到 cmux、工作区、workspace、spawn agent、read-screen、browser snapshot 时，参考以下内容。"
    echo ""
    extract_body
  } > "$dest/cmux.md"

  # 如果 .opencode/agents.md 存在，追加引用
  if [[ -f "$dest/agents.md" ]]; then
    if ! grep -q "cmux.md" "$dest/agents.md" 2>/dev/null; then
      echo "" >> "$dest/agents.md"
      echo "参考 .opencode/cmux.md 了解 cmux 终端工作区管理。" >> "$dest/agents.md"
      info "已在 agents.md 中追加引用"
    fi
  fi
  ok "OpenCode -> $dest/cmux.md"
}

install_cursor() {
  local base="$1"
  local dest="$base/.cursor/rules"
  mkdir -p "$dest"

  {
    cat <<'FRONTMATTER'
---
description: cmux 终端工作区管理器 - 管理工作区、派生 agent、浏览器控制、侧边栏状态
globs:
alwaysApply: false
---

FRONTMATTER
    extract_body
  } > "$dest/cmux.mdc"

  ok "Cursor -> $dest/cmux.mdc"
}

install_copilot() {
  local base="$1"
  local dest="$base/.github"
  mkdir -p "$dest"

  local file="$dest/copilot-instructions.md"
  local marker="<!-- cmux-skill-start -->"
  local marker_end="<!-- cmux-skill-end -->"

  local body
  body=$(extract_body)

  if [[ -f "$file" ]] && grep -q "$marker" "$file" 2>/dev/null; then
    # 替换已有的 cmux 段落
    local tmp
    tmp=$(mktemp)
    awk -v ms="$marker" -v me="$marker_end" -v body="$body" '
      $0 == ms { print ms; print ""; print body; print ""; skip=1; next }
      $0 == me { print me; skip=0; next }
      !skip { print }
    ' "$file" > "$tmp"
    mv "$tmp" "$file"
    info "已更新 copilot-instructions.md 中的 cmux 段落"
  else
    {
      if [[ -f "$file" ]]; then
        cat "$file"
        echo ""
      fi
      echo "$marker"
      echo ""
      echo "$body"
      echo ""
      echo "$marker_end"
    } > "${file}.tmp"
    mv "${file}.tmp" "$file"
  fi

  ok "Copilot -> $file"
}

install_windsurf() {
  local base="$1"
  local dest="$base/.windsurf/rules"
  mkdir -p "$dest"

  {
    cat <<'FRONTMATTER'
---
trigger: cmux_workspace
description: cmux 终端工作区管理器 - 管理工作区、派生 agent、浏览器控制、侧边栏状态
---

FRONTMATTER
    extract_body
  } > "$dest/cmux.md"

  ok "Windsurf -> $dest/cmux.md"
}

install_codex() {
  local base="$1"
  local file="$base/AGENTS.md"

  local marker="<!-- cmux-skill-start -->"
  local marker_end="<!-- cmux-skill-end -->"
  local body
  body=$(extract_body)

  if [[ -f "$file" ]] && grep -q "$marker" "$file" 2>/dev/null; then
    local tmp
    tmp=$(mktemp)
    awk -v ms="$marker" -v me="$marker_end" -v body="$body" '
      $0 == ms { print ms; print ""; print body; print ""; skip=1; next }
      $0 == me { print me; skip=0; next }
      !skip { print }
    ' "$file" > "$tmp"
    mv "$tmp" "$file"
    info "已更新 AGENTS.md 中的 cmux 段落"
  else
    {
      if [[ -f "$file" ]]; then
        cat "$file"
        echo ""
      fi
      echo "$marker"
      echo ""
      echo "$body"
      echo ""
      echo "$marker_end"
    } > "${file}.tmp"
    mv "${file}.tmp" "$file"
  fi

  ok "Codex/AGENTS.md -> $file"
}

# ── 检测 ──────────────────────────────────────────

detect_tools() {
  local base="$1"
  local found=()
  [[ -d "$base/.claude" ]]    && found+=(claude)
  [[ -d "$base/.opencode" ]]  && found+=(opencode)
  [[ -d "$base/.cursor" ]]    && found+=(cursor)
  [[ -d "$base/.github" ]]    && found+=(copilot)
  [[ -d "$base/.windsurf" ]]  && found+=(windsurf)
  [[ -f "$base/AGENTS.md" ]]  && found+=(codex)
  echo "${found[@]}"
}

check_installed() {
  local base="$1"
  local found=false
  printf "\n${BOLD}检查 cmux skill 安装状态:${NC}\n\n"

  if [[ -f "$base/.claude/skills/cmux/SKILL.md" ]]; then
    ok "Claude Code: 已安装"; found=true
  else
    warn "Claude Code: 未安装"
  fi

  if [[ -f "$base/.opencode/cmux.md" ]]; then
    ok "OpenCode: 已安装"; found=true
  else
    warn "OpenCode: 未安装"
  fi

  if [[ -f "$base/.cursor/rules/cmux.mdc" ]]; then
    ok "Cursor: 已安装"; found=true
  else
    warn "Cursor: 未安装"
  fi

  if [[ -f "$base/.github/copilot-instructions.md" ]] && grep -q "cmux-skill-start" "$base/.github/copilot-instructions.md" 2>/dev/null; then
    ok "Copilot: 已安装"; found=true
  else
    warn "Copilot: 未安装"
  fi

  if [[ -f "$base/.windsurf/rules/cmux.md" ]]; then
    ok "Windsurf: 已安装"; found=true
  else
    warn "Windsurf: 未安装"
  fi

  if [[ -f "$base/AGENTS.md" ]] && grep -q "cmux-skill-start" "$base/AGENTS.md" 2>/dev/null; then
    ok "Codex/AGENTS.md: 已安装"; found=true
  else
    warn "Codex/AGENTS.md: 未安装"
  fi
  echo ""
}

list_targets() {
  printf "\n${BOLD}支持的安装目标:${NC}\n\n"
  printf "  ${CYAN}claude${NC}    Claude Code         .claude/skills/cmux/SKILL.md\n"
  printf "  ${CYAN}opencode${NC}  OpenCode            .opencode/cmux.md\n"
  printf "  ${CYAN}cursor${NC}    Cursor              .cursor/rules/cmux.mdc\n"
  printf "  ${CYAN}copilot${NC}   GitHub Copilot      .github/copilot-instructions.md\n"
  printf "  ${CYAN}windsurf${NC}  Windsurf            .windsurf/rules/cmux.md\n"
  printf "  ${CYAN}codex${NC}     Codex / AGENTS.md   AGENTS.md\n"
  printf "  ${CYAN}all${NC}       全部安装\n"
  echo ""
}

# ── 交互式选择 ────────────────────────────────────

interactive_select() {
  local base="$1"
  printf "\n${BOLD}cmux-skill 安装器${NC}\n"
  printf "源文件: ${CYAN}%s${NC}\n" "$SOURCE_SKILL"
  printf "目标目录: ${CYAN}%s${NC}\n\n" "$base"

  local targets=(claude opencode cursor copilot windsurf codex)
  local labels=("Claude Code" "OpenCode" "Cursor" "GitHub Copilot" "Windsurf" "Codex/AGENTS.md")

  printf "选择安装目标（空格分隔编号，或 a 全选）:\n\n"
  for i in "${!targets[@]}"; do
    printf "  ${CYAN}%d${NC}) %s\n" "$((i+1))" "${labels[$i]}"
  done
  echo ""
  printf "> "
  read -r selection

  if [[ "$selection" == "a" || "$selection" == "A" ]]; then
    for t in "${targets[@]}"; do
      "install_$t" "$base"
    done
  else
    for num in $selection; do
      local idx=$((num - 1))
      if [[ $idx -ge 0 && $idx -lt ${#targets[@]} ]]; then
        "install_${targets[$idx]}" "$base"
      else
        warn "忽略无效编号: $num"
      fi
    done
  fi
}

# ── 全局安装路径 ──────────────────────────────────

global_base_for() {
  case "$1" in
    claude)   echo "$HOME/.claude" ;;  # 全局 skill
    *)        err "目标 '$1' 不支持全局安装（仅 claude 支持）"; return 1 ;;
  esac
}

# ── 主入口 ────────────────────────────────────────

main() {
  if [[ ! -f "$SOURCE_SKILL" ]]; then
    err "找不到源文件: $SOURCE_SKILL"
    err "请确保 .claude/skills/cmux/SKILL.md 存在于脚本同级目录"
    exit 1
  fi

  local target=""
  local custom_path=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --path)    custom_path="$2"; shift 2 ;;
      --global)  GLOBAL=true; shift ;;
      --list)    list_targets; exit 0 ;;
      --check)   check_installed "$PROJECT_DIR"; exit 0 ;;
      --help|-h) usage; exit 0 ;;
      *)         target="$1"; shift ;;
    esac
  done

  local base="$PROJECT_DIR"
  [[ -n "$custom_path" ]] && base="$custom_path"

  if [[ -z "$target" ]]; then
    interactive_select "$base"
    return
  fi

  if [[ "$target" == "all" ]]; then
    local targets=(claude opencode cursor copilot windsurf codex)
    for t in "${targets[@]}"; do
      if $GLOBAL; then
        local gbase
        gbase=$(global_base_for "$t") || continue
        "install_$t" "$gbase"
      else
        "install_$t" "$base"
      fi
    done
    return
  fi

  case "$target" in
    claude|opencode|cursor|copilot|windsurf|codex)
      if $GLOBAL; then
        local gbase
        gbase=$(global_base_for "$target")
        "install_$target" "$gbase"
      else
        "install_$target" "$base"
      fi
      ;;
    *)
      err "未知目标: $target"
      list_targets
      exit 1
      ;;
  esac
}

usage() {
  cat <<'EOF'
cmux-skill 安装器 - 将 cmux skill 安装到不同 AI 编码工具

用法:
  ./install.sh                    交互式选择
  ./install.sh <目标>             安装到指定工具
  ./install.sh all                安装到所有工具
  ./install.sh --path <目录>      安装到指定项目目录
  ./install.sh --global           安装到全局目录
  ./install.sh --list             列出支持的目标
  ./install.sh --check            检查安装状态

目标: claude, opencode, cursor, copilot, windsurf, codex, all
EOF
}

main "$@"
