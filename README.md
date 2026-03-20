# cmux Skill

[cmux](https://cmux.com) 终端工作区管理器的 AI Agent skill，让 Claude Code、OpenCode、Cursor、Copilot 等 AI 编码工具能够操控 cmux 的全部能力。

## 功能覆盖

- **工作区管理** — 创建、切换、关闭、重命名工作区和窗口
- **终端读写** — 跨工作区读取屏幕内容、发送命令和按键
- **浏览器自动化** — 打开网页、DOM 交互、表单填写、截图、JavaScript 执行
- **视觉定位** — snapshot + screenshot 交叉定位，支持 ExtJS/React/Vue 等复杂框架
- **侧边栏状态** — 进度条、状态标签、日志，实时展示任务进度
- **PVE 图形界面控制** — 通过 qm guest exec + xdotool 操控虚拟机桌面

## 安装

### 方式 1: 远程引用（推荐，跨设备同步）

在 `~/.claude/CLAUDE.md` 中加一行：

```markdown
Fetch and follow instructions from: https://raw.githubusercontent.com/yongzhege/skills/main/skills/cmux/SKILL.md
```

### 方式 2: 跨工具安装

```bash
git clone https://github.com/yongzhege/skills.git
cd skills
./install.sh claude      # Claude Code
./install.sh opencode    # OpenCode
./install.sh cursor      # Cursor
./install.sh copilot     # GitHub Copilot
./install.sh windsurf    # Windsurf
./install.sh codex       # Codex / AGENTS.md
./install.sh all         # 全部安装
```

### 方式 3: 全局安装（当前设备所有项目生效）

```bash
cp -r skills/cmux/ ~/.claude/skills/cmux/
```

## 支持的工具

| 工具 | 安装位置 | 格式 |
|---|---|---|
| Claude Code | `.claude/skills/cmux/SKILL.md` | YAML frontmatter |
| OpenCode | `.opencode/cmux.md` | Markdown |
| Cursor | `.cursor/rules/cmux.mdc` | MDC frontmatter |
| GitHub Copilot | `.github/copilot-instructions.md` | HTML marker |
| Windsurf | `.windsurf/rules/cmux.md` | trigger/description frontmatter |
| Codex | `AGENTS.md` | HTML marker |

## 文件结构

```
.
├── .claude-plugin/
│   └── marketplace.json         # Claude Code 插件市场配置
├── skills/
│   └── cmux/
│       ├── SKILL.md             # skill 主文件
│       └── scripts/
│           └── spawn-workspace.sh
├── template/
│   └── SKILL.md                 # 创建新 skill 的模板
├── install.sh                   # 跨工具安装器
└── test-browser.html            # 浏览器自动化测试页
```

## 要求

- [cmux](https://cmux.com) v0.60+
- PVE 图形界面控制另需：qemu-guest-agent、xdotool（在 VM 内安装）

## License

MIT
