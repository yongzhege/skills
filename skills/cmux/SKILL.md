---
name: cmux
description: cmux 终端工作区管理器 - 管理工作区、派生 agent、浏览器控制、侧边栏状态、远程 GUI 操控。当用户提到 "cmux"、"工作区"、"workspace"、"spawn agent"、"read-screen"、"browser snapshot"、"PVE 图形界面" 时触发。
---

# cmux 终端工作区管理器

从一个终端管理多个 cmux 工作区和 AI 编码 agent。

## 层级结构

```
Window → Workspace（侧边栏条目）→ Pane（分屏区域）→ Surface（面板内标签页）→ Panel（终端或浏览器）
```

`cmux tree` 可以直观展示完整层级。大部分命令操作的对象是 Workspace 和 Surface。

## 环境变量

cmux 终端内自动设置，所有命令的默认 `--workspace` / `--surface` 取自这些变量：

| 变量 | 说明 |
|---|---|
| `CMUX_WORKSPACE_ID` | 当前工作区 ID，所有命令的默认 `--workspace` |
| `CMUX_SURFACE_ID` | 当前 surface ID，所有命令的默认 `--surface` |
| `CMUX_TAB_ID` | 当前 tab ID，`tab-action` / `rename-tab` 的默认 `--tab` |
| `CMUX_SOCKET_PATH` | socket 路径，默认 `/tmp/cmux.sock` |

```bash
# 检测是否在 cmux 终端中
[ -n "${CMUX_WORKSPACE_ID:-}" ] && echo "inside cmux"
```

## ID 格式

支持 UUID、短引用（`workspace:1`、`surface:2`、`pane:3`、`window:1`）或索引。
输出默认用短引用，传 `--id-format uuids` 或 `--id-format both` 切换。

---

## 常用操作速查

```bash
# 查看工作区结构（最佳调试工具）
cmux tree
cmux tree --all              # 所有窗口

# 查看当前身份
cmux identify

# 列出工作区
cmux list-workspaces

# 创建命名工作区并运行 Claude（不抢焦点）
CURRENT=$(cmux current-workspace --id-format uuids | awk '{print $1}')
NEW=$(cmux new-workspace --command "claude '你的提示'" --id-format uuids | awk '{print $1}')
cmux rename-workspace --workspace "$NEW" "任务名"
cmux select-workspace --workspace "$CURRENT"

# 读取其他工作区的屏幕
cmux read-screen --workspace workspace:2
cmux read-screen --workspace workspace:2 --scrollback --lines 200

# 向其他工作区发送命令
cmux send --workspace workspace:2 "ls -la"
cmux send-key --workspace workspace:2 Enter

# 通知
cmux notify --title "完成" --body "任务已完成"
```

---

## 工作区管理

```bash
cmux list-workspaces [--json]
cmux new-workspace [--cwd <路径>] [--command <命令>]
cmux select-workspace --workspace <id|ref>
cmux close-workspace --workspace <id|ref>
cmux rename-workspace [--workspace <id|ref>] <标题>
cmux current-workspace [--json]
cmux reorder-workspace --workspace <id|ref> (--index <n> | --before <id|ref> | --after <id|ref>)
cmux workspace-action --action <名称> [--workspace <id|ref>] [--title <文本>]
```

## 窗口管理

```bash
cmux list-windows
cmux current-window
cmux new-window
cmux focus-window --window <id>
cmux close-window --window <id>
cmux move-workspace-to-window --workspace <id|ref> --window <id|ref>
cmux rename-window [--workspace <id|ref>] <标题>
cmux next-window | previous-window | last-window
```

## Pane 和 Surface 管理

```bash
# 列出
cmux list-panes [--workspace <id|ref>]
cmux list-pane-surfaces [--workspace <id|ref>] [--pane <id|ref>]
cmux list-panels [--workspace <id|ref>]

# 创建分屏 — 返回 "OK surface:N workspace:N"，解析 surface ref 用于后续操作
cmux new-split <left|right|up|down> [--workspace <id|ref>] [--surface <id|ref>]
cmux new-pane [--type <terminal|browser>] [--direction <left|right|up|down>] [--workspace <id|ref>]
cmux new-surface [--type <terminal|browser>] [--pane <id|ref>] [--workspace <id|ref>]

# 操作
cmux focus-pane --pane <id|ref> [--workspace <id|ref>]
cmux focus-panel --panel <id|ref> [--workspace <id|ref>]
cmux close-surface [--surface <id|ref>] [--workspace <id|ref>]
cmux move-surface --surface <id|ref> [--pane <id|ref>] [--workspace <id|ref>] [--index <n>]
cmux reorder-surface --surface <id|ref> (--index <n> | --before <id|ref> | --after <id|ref>)
cmux drag-surface-to-split --surface <id|ref> <left|right|up|down>
cmux rename-tab [--workspace <id|ref>] [--surface <id|ref>] <标题>

# 布局调整（tmux 兼容）
cmux resize-pane --pane <id|ref> (-L|-R|-U|-D) [--amount <n>]
cmux swap-pane --pane <id|ref> --target-pane <id|ref>
cmux join-pane --target-pane <id|ref> [--pane <id|ref>] [--surface <id|ref>]
cmux break-pane [--workspace <id|ref>] [--pane <id|ref>] [--surface <id|ref>] [--no-focus]
cmux last-pane [--workspace <id|ref>]
```

## 读取与发送

**注意：`read-screen` 和 `send`/`send-key` 仅适用于终端 surface，对浏览器 surface 会报错 `Surface is not a terminal`。**

```bash
# 读取屏幕内容
cmux read-screen [--workspace <id|ref>] [--surface <id|ref>] [--scrollback] [--lines <n>]
cmux capture-pane [--workspace <id|ref>] [--surface <id|ref>] [--scrollback] [--lines <n>]

# 发送文本和按键（不支持空字符串）
cmux send [--workspace <id|ref>] [--surface <id|ref>] <文本>
cmux send-key [--workspace <id|ref>] [--surface <id|ref>] <按键>
cmux send-panel --panel <id|ref> [--workspace <id|ref>] <文本>
cmux send-key-panel --panel <id|ref> [--workspace <id|ref>] <按键>

# 剪贴板/缓冲区
cmux set-buffer [--name <名称>] <文本>
cmux list-buffers
cmux paste-buffer [--name <名称>] [--workspace <id|ref>] [--surface <id|ref>]

# 搜索工作区（按标题匹配）
cmux find-window [--content] [--select] <查询>

# 重生/清理
cmux respawn-pane [--workspace <id|ref>] [--surface <id|ref>] [--command <命令>]
cmux clear-history [--workspace <id|ref>] [--surface <id|ref>]
```

## 侧边栏元数据

用于向用户展示任务状态：

```bash
# 状态标签
cmux set-status <键> <值> [--icon <名称>] [--color <#hex>] [--workspace <id|ref>]
cmux clear-status <键> [--workspace <id|ref>]
cmux list-status [--workspace <id|ref>]

# 进度条
cmux set-progress <0.0-1.0> [--label <文本>] [--workspace <id|ref>]
cmux clear-progress [--workspace <id|ref>]

# 日志
cmux log [--level <级别>] [--source <来源>] [--workspace <id|ref>] [--] <消息>
cmux list-log [--limit <n>] [--workspace <id|ref>]
cmux clear-log [--workspace <id|ref>]

# 侧边栏状态
cmux sidebar-state [--workspace <id|ref>]
```

## 通知

```bash
cmux notify --title <标题> [--subtitle <副标题>] [--body <正文>] [--workspace <id|ref>]
cmux list-notifications [--json]
cmux clear-notifications

# 在脚本/子进程中也可通过 OSC 777 转义序列直接发通知（无需调用 cmux CLI）
printf '\e]777;notify;Title;Body\a'
```

## 浏览器集成

### 指定浏览器 surface

`--surface` 可以放在子命令前或后，也可以用位置参数。**除 `open` 外，所有子命令都需要指定 surface。**

```bash
cmux browser --surface surface:8 snapshot     # flag 在前
cmux browser snapshot --surface surface:8     # flag 在后
cmux browser surface:8 snapshot               # 位置参数（推荐，最简洁）
```

### 返回值格式

```bash
# browser open 返回: OK surface=surface:N pane=pane:N placement=split|reuse
# screenshot --json 返回: {"url", "surface_ref", "workspace_ref", "path"}
```

### 导航和目标定位

```bash
# 打开浏览器 — 唯一不需要 --surface 的命令
cmux browser open [url]                # 返回 surface ref，后续操作需用它
cmux browser open-split [url]

# 识别当前 surface 信息
cmux browser identify
cmux browser surface:N identify

# 导航（navigate 和 goto 等价）
cmux browser surface:N navigate <url> [--snapshot-after]
cmux browser surface:N back|forward|reload [--snapshot-after]
cmux browser surface:N url

# Webview 焦点
cmux browser surface:N focus-webview
cmux browser surface:N is-webview-focused
```

### 等待

阻塞直到条件满足：

```bash
cmux browser surface:N wait --load-state complete --timeout-ms 15000
cmux browser surface:N wait --selector "#checkout" --timeout-ms 10000
cmux browser surface:N wait --text "Order confirmed"
cmux browser surface:N wait --url-contains "/dashboard"
cmux browser surface:N wait --function "window.__appReady === true"
```

### DOM 交互

所有变更操作支持 `--snapshot-after` 用于快速验证。

```bash
# 点击
cmux browser surface:N click "button[type='submit']" --snapshot-after
cmux browser surface:N dblclick ".item-row"

# 悬停/聚焦/勾选
cmux browser surface:N hover "#menu"
cmux browser surface:N focus "#email"
cmux browser surface:N check "#terms"
cmux browser surface:N uncheck "#newsletter"
cmux browser surface:N scroll-into-view "#pricing"

# 文本输入
cmux browser surface:N type "#search" "cmux"                        # 模拟逐字符输入
cmux browser surface:N fill "#email" --text "ops@example.com"       # 直接填充值
cmux browser surface:N fill "#email" --text ""                      # 清空输入框

# 按键
cmux browser surface:N press Enter
cmux browser surface:N keydown Shift
cmux browser surface:N keyup Shift

# 选择/滚动
cmux browser surface:N select "#region" "us-east"
cmux browser surface:N scroll --dy 800 --snapshot-after
cmux browser surface:N scroll --selector "#log-view" --dx 0 --dy 400
```

### 检查

```bash
# 快照（结构化 DOM 树）
cmux browser surface:N snapshot --interactive --compact              # 仅交互元素，紧凑格式
cmux browser surface:N snapshot --selector "main" --max-depth 5     # 限定范围和深度

# 截图
cmux browser surface:N screenshot --out /tmp/page.png
cmux browser surface:N screenshot --json                             # 返回 {url, path, surface_ref}

# 获取页面数据
cmux browser surface:N get title
cmux browser surface:N get url
cmux browser surface:N get text "h1"
cmux browser surface:N get html "main"
cmux browser surface:N get value "#email"
cmux browser surface:N get attr "a.primary" --attr href
cmux browser surface:N get count ".row"
cmux browser surface:N get box "#checkout"
cmux browser surface:N get styles "#total" --property color

# 状态检查
cmux browser surface:N is visible "#checkout"
cmux browser surface:N is enabled "button[type='submit']"
cmux browser surface:N is checked "#terms"

# 元素查找
cmux browser surface:N find role button --name "Continue"
cmux browser surface:N find text "Order confirmed"
cmux browser surface:N find label "Email"
cmux browser surface:N find placeholder "Search"
cmux browser surface:N find testid "save-btn"
cmux browser surface:N find first ".row"
cmux browser surface:N find last ".row"
cmux browser surface:N find nth 2 ".row"

# 高亮元素（调试用）
cmux browser surface:N highlight "#checkout"
```

### JavaScript 执行和注入

```bash
# eval — 字符串/数组/null/undefined 直接返回；对象需 JSON.stringify()；
# Promise 自动 resolve；await 语法不支持；异常返回 js_error
cmux browser surface:N eval "document.title"
cmux browser surface:N eval --script "window.location.href"

# 注入脚本/样式
cmux browser surface:N addinitscript "window.__cmuxReady = true;"   # 每次导航前执行
cmux browser surface:N addscript "document.querySelector('#name')?.focus()"
cmux browser surface:N addstyle "#debug-banner { display: none !important; }"
```

### iframe 操作

操作 iframe 内元素前必须先切入：

```bash
cmux browser surface:N frame "iframe[name='checkout']"    # 切入 iframe
cmux browser surface:N click "#pay-now"                     # 在 iframe 内操作
cmux browser surface:N frame main                           # 切回主 frame
```

### 状态和会话数据

```bash
# Cookies
cmux browser surface:N cookies get
cmux browser surface:N cookies get --name session_id
cmux browser surface:N cookies set session_id abc123 --domain example.com --path /
cmux browser surface:N cookies clear --name session_id
cmux browser surface:N cookies clear --all

# Storage
cmux browser surface:N storage local set theme dark
cmux browser surface:N storage local get theme
cmux browser surface:N storage local clear
cmux browser surface:N storage session set flow onboarding
cmux browser surface:N storage session get flow

# 完整浏览器状态持久化
cmux browser surface:N state save /tmp/session.json
cmux browser surface:N state load /tmp/session.json
```

### 标签页

```bash
cmux browser surface:N tab list
cmux browser surface:N tab new https://www.yongzhege.com/
cmux browser surface:N tab switch 1                 # 按索引切换
cmux browser surface:N tab switch surface:7          # 按 surface ref 切换
cmux browser surface:N tab close                     # 关闭当前标签
cmux browser surface:N tab close surface:7           # 关闭指定标签
```

### 控制台、错误、对话框、下载

```bash
# 控制台和错误日志
cmux browser surface:N console list
cmux browser surface:N console clear
cmux browser surface:N errors list
cmux browser surface:N errors clear

# 对话框（alert/confirm/prompt）
cmux browser surface:N dialog accept
cmux browser surface:N dialog accept "Confirmed by automation"
cmux browser surface:N dialog dismiss

# 下载
cmux browser surface:N click "a#download-report"
cmux browser surface:N download --path /tmp/report.csv --timeout-ms 30000
```

### 视觉定位策略

Agent 没有眼睛，需要通过 snapshot 获取页面结构再操作：

```bash
# 标准定位流程：snapshot → 找 ref → 操作
cmux browser surface:N snapshot -i --compact     # 只返回可交互元素，紧凑格式
# 输出示例: - button "登录" [ref=e42]
cmux browser surface:N click e42                  # 用 ref 直接点击

# 限定范围（减少 token 消耗）
cmux browser surface:N snapshot --selector "main" --max-depth 3

# 结合截图进行视觉分析（多模态 Agent 可用）
cmux browser surface:N screenshot --json    # 返回 {path: "/tmp/xxx.png"}
# 用 Read 工具读取图片 → 视觉分析页面布局 → 确定坐标或元素位置
```

注意：`ref=eN` 是临时 ID，页面变化后失效，操作前需重新 snapshot。

### 调试失败操作

当 click/fill/type 不生效时，按以下流程排查：

```bash
# 1. 元素是否存在/可见/启用
cmux browser surface:N is visible "<selector>"
cmux browser surface:N is enabled "<selector>"
cmux browser surface:N get box "<selector>"        # 获取坐标和尺寸

# 2. 截图 + 控制台查看实际状态
cmux browser surface:N screenshot --out /tmp/debug.png
cmux browser surface:N console list
cmux browser surface:N errors list

# 3. 用 eval 绕过 selector 直接操作 DOM
cmux browser surface:N eval "document.querySelector('<css>').click()"
```

### 复杂 UI 框架交互（ExtJS/React/Vue）

标准 selector 对 ExtJS（如 PVE）、React 等框架经常失效。用 `eval` 直接操作 DOM：

```bash
# ExtJS/PVE: 隐藏 input，需要直接设值并触发事件
cmux browser surface:N eval "
  var el = document.querySelector('input[name=username]');
  el.value = 'root';
  el.dispatchEvent(new Event('input', {bubbles:true}));
  'ok'
"

# React: 需要绕过 React 的 value setter
cmux browser surface:N eval "
  var el = document.querySelector('#my-input');
  var setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
  setter.call(el, 'new value');
  el.dispatchEvent(new Event('input', {bubbles:true}));
  'ok'
"

# 通用: 找不到元素时，用 eval 枚举页面上所有 input
cmux browser surface:N eval "
  var r = '';
  document.querySelectorAll('input').forEach(function(el,i){
    r += el.name + '|' + el.type + '|' + el.id + '\n';
  }); r
"
```

### 浏览器自动化的限制与注意

- **canvas**：click 能触发事件但坐标始终为 (0,0)，无法精确点击 canvas 内元素。noVNC 等复杂 canvas 应用用 PVE guest exec + xdotool 替代
- **iframe 内的 xterm.js**：PVE 控制台等 Web 终端无法通过 browser 命令交互，用 SSH + `cmux send` 替代
- **自签名 HTTPS**：首次访问可能被拦截，用户在 UI 中接受证书后后续正常
- **原生 dialog（alert/confirm/prompt）**：`dialog accept/dismiss` 需在弹窗出现前注册，实际操作中更推荐用 `eval` 提前 override：
  ```bash
  cmux browser surface:N eval "window.confirm = function(){return true}; 'ok'"
  cmux browser surface:N click "#trigger-button"   # 之后 confirm 会自动返回 true
  ```

## Markdown 查看器

```bash
cmux markdown open <路径>    # 在面板中打开 Markdown，支持实时刷新
```

## Claude Hook（内置）

```bash
cmux claude-hook <session-start|stop|notification> [--workspace <id|ref>] [--surface <id|ref>]
```

## 其他实用命令

```bash
cmux version
cmux ping
cmux capabilities [--json]   # 列出所有可用方法（145 个）
cmux themes list|set|clear
cmux shortcuts
cmux pipe-pane --command <shell-command> [--workspace <id|ref>] [--surface <id|ref>]
cmux wait-for [-S|--signal] <name> [--timeout <seconds>]
cmux set-hook [--list] [--unset <event>] | <event> <command>
cmux display-message [-p|--print] <text>
cmux tab-action --action <name> [--tab <id|ref>] [--surface <id|ref>] [--workspace <id|ref>] [--title <text>] [--url <url>]
cmux refresh-surfaces                    # 刷新所有 surface 状态
cmux trigger-flash [--workspace <id|ref>] [--surface <id|ref>]   # 触发 surface 闪烁提醒
cmux surface-health [--workspace <id|ref>]                       # 检查 surface 健康状态
```

---

## 常用模式

### 派生 agent 并监控

```bash
# 1. 派生
CURRENT=$(cmux current-workspace --id-format uuids | awk '{print $1}')
NEW=$(cmux new-workspace --command "claude '实现功能 X'" --id-format uuids | awk '{print $1}')
cmux rename-workspace --workspace "$NEW" "feature-x"
cmux select-workspace --workspace "$CURRENT"

# 2. 监控进度
cmux read-screen --workspace "$NEW"

# 3. 发送追加指令
cmux send --workspace "$NEW" "补充说明..."
cmux send-key --workspace "$NEW" Enter
```

### SSH 远程操作（比浏览器控制台更可靠）

当需要操作远程服务器终端时，优先用 SSH + `cmux send`，而非浏览器中的 Web 终端。

```bash
# 1. 新建终端分屏
cmux new-split right    # 返回 "OK surface:N workspace:N"

# 2. SSH 连接
cmux send --surface surface:N "ssh user@host"
cmux send-key --surface surface:N Enter
# 等待密码提示后输入密码
cmux send --surface surface:N "password"
cmux send-key --surface surface:N Enter

# 3. 执行命令并读取结果
cmux send --surface surface:N "ls -la"
cmux send-key --surface surface:N Enter
sleep 2
cmux read-screen --surface surface:N --scrollback --lines 30
```

### 浏览器自动化

```bash
# 1. 打开浏览器并记住 surface ref
cmux browser open "https://example.com"    # 返回 surface=surface:N

# 2. 等待加载完成
cmux browser surface:N wait --load-state complete --timeout-ms 15000

# 3. 快照查看页面结构（--interactive --compact 最实用）
cmux browser surface:N snapshot --interactive --compact

# 4. 交互（用 snapshot 中的 ref 或 CSS selector）
cmux browser surface:N click e5 --snapshot-after
cmux browser surface:N fill "#email" --text "user@example.com"
cmux browser surface:N press Enter --snapshot-after

# 5. 操作 iframe 内的元素
cmux browser surface:N frame "iframe[name='checkout']"
cmux browser surface:N click "#pay-now"
cmux browser surface:N frame main             # 切回

# 6. 用 eval 获取复杂数据（对象需 JSON.stringify）
cmux browser surface:N eval "document.title"            # OK
cmux browser surface:N eval "JSON.stringify({a:1})"     # OK — 对象必须序列化
cmux browser surface:N eval "{a:1}"                     # 报错！

# 7. 失败时捕获调试信息
cmux browser surface:N console list
cmux browser surface:N errors list
cmux browser surface:N screenshot --out /tmp/failure.png

# 8. 保存/恢复浏览器会话（含 cookies、storage 等）
cmux browser surface:N state save /tmp/session.json
# ...之后恢复...
cmux browser surface:N state load /tmp/session.json
cmux browser surface:N reload
```

### PVE Web 界面操作

通过浏览器控制 PVE 管理界面（ExtJS 应用）：

```bash
# 打开 PVE 并登录
cmux browser open "https://pve-host:8006"
cmux browser surface:N wait --load-state complete

# PVE 登录（ExtJS 输入框用 eval 填写更可靠）
cmux browser surface:N eval "
  document.querySelector('input[name=username]').value = 'root';
  document.querySelector('input[name=username]').dispatchEvent(new Event('input', {bubbles:true}));
  document.querySelector('input[name=password]').value = 'password';
  document.querySelector('input[name=password]').dispatchEvent(new Event('input', {bubbles:true}));
  'ok'
"
cmux browser surface:N snapshot -i    # 找到登录按钮 ref
cmux browser surface:N click eN       # 点击登录

# 选择 VM/CT 并操作
cmux browser surface:N snapshot --selector ".x-tree-panel"   # 查看节点树
cmux browser surface:N click eN                               # 选择 VM
cmux browser surface:N snapshot -i | grep "启动"              # 找启动按钮
cmux browser surface:N click eN                               # 启动 VM
```

### 设置任务状态

```bash
cmux set-status task "构建中" --icon hammer --color "#f59e0b"
cmux set-progress 0.5 --label "编译 50%"
# 完成后清理
cmux clear-status task
cmux clear-progress
```

---

## PVE 虚拟机图形界面控制

当需要操作 PVE 虚拟机的图形桌面（noVNC 无法通过浏览器自动化操控）时，使用以下方案。

### 前提条件

在 VM 内安装：
```bash
# 通过 PVE 宿主机安装（需要先能在 VM 终端中操作，可用 qm sendkey 输入）
qm sendkey <vmid> ctrl-alt-t                    # 打开终端
# 用 qm sendkey 逐字符输入，或通过 qm_type 辅助函数：
qm_type() {
  local vmid=$1; shift; local text="$*"
  for ((i=0; i<${#text}; i++)); do
    c="${text:$i:1}"
    case "$c" in
      [a-z]) qm sendkey $vmid $c;;
      [A-Z]) qm sendkey $vmid shift-${c,,};;
      [0-9]) qm sendkey $vmid $c;;
      ' ') qm sendkey $vmid spc;; '-') qm sendkey $vmid minus;;
      '.') qm sendkey $vmid dot;; '/') qm sendkey $vmid slash;;
    esac
  done
}

# 安装 guest agent 和 xdotool
qm_type <vmid> 'sudo apt install -y qemu-guest-agent xdotool'
qm sendkey <vmid> ret
# 输入 sudo 密码...
qm_type <vmid> 'sudo systemctl enable --now qemu-guest-agent'
qm sendkey <vmid> ret
```

### 核心操作

```bash
VMID=200
XENV='DISPLAY=:0 XAUTHORITY=/home/<user>/.Xauthority'

# ── 截图（screendump → ffmpeg → scp） ─────────────────
# 进入 qm monitor → screendump → 退出 → 转换 → 拉回本地
qm monitor $VMID       # 交互式进入
screendump /tmp/s.ppm  # 在 monitor 中执行
quit                   # 退出 monitor
ffmpeg -y -i /tmp/s.ppm /tmp/s.png 2>/dev/null
scp root@pve-host:/tmp/s.png /tmp/s.png

# ── 鼠标操作（通过 guest agent + xdotool）────────────
qm guest exec $VMID -- bash -c "$XENV xdotool mousemove 500 400 click 1"      # 单击
qm guest exec $VMID -- bash -c "$XENV xdotool mousemove 55 50 click --repeat 2 1"  # 双击
qm guest exec $VMID -- bash -c "$XENV xdotool mousemove 500 400 click 3"      # 右键
qm guest exec $VMID -- bash -c "$XENV xdotool getmouselocation"               # 查询位置
# 拖拽（分步执行）
qm guest exec $VMID -- bash -c "$XENV xdotool mousemove 100 200"
qm guest exec $VMID -- bash -c "$XENV xdotool mousedown 1"
qm guest exec $VMID -- bash -c "$XENV xdotool mousemove 300 400"
qm guest exec $VMID -- bash -c "$XENV xdotool mouseup 1"

# ── 键盘输入 ─────────────────────────────────────────
# 方式 1: xdotool type（英文，guest agent 内）
qm guest exec $VMID -- bash -c "$XENV xdotool type --clearmodifiers 'hello world'"
# 方式 2: xdotool key（快捷键）
qm guest exec $VMID -- bash -c "$XENV xdotool key ctrl+alt+t"     # 打开终端
qm guest exec $VMID -- bash -c "$XENV xdotool key alt+F4"         # 关闭窗口
qm guest exec $VMID -- bash -c "$XENV xdotool key ctrl+l"         # 浏览器地址栏
# 方式 3: qm sendkey（硬件级，不依赖 guest agent）
qm sendkey $VMID ctrl-alt-t
qm sendkey $VMID ret

# ── 窗口管理 ─────────────────────────────────────────
qm guest exec $VMID -- bash -c "$XENV xdotool getactivewindow getwindowname"
qm guest exec $VMID -- bash -c "$XENV xdotool getactivewindow getwindowgeometry"
qm guest exec $VMID -- bash -c "$XENV xdotool getactivewindow windowmove 50 50"
qm guest exec $VMID -- bash -c "$XENV xdotool getactivewindow windowsize 800 600"
qm guest exec $VMID -- bash -c "$XENV xdotool getactivewindow windowminimize"
qm guest exec $VMID -- bash -c "$XENV xdotool windowactivate <window-id>"
qm guest exec $VMID -- bash -c "$XENV xdotool getactivewindow windowclose"
qm guest exec $VMID -- bash -c "$XENV wmctrl -l"                  # 列出所有窗口

# ── 启动应用 ─────────────────────────────────────────
qm guest exec $VMID -- bash -c "su - <user> -c '$XENV chromium-browser --no-sandbox http://example.com &'"
qm guest exec $VMID -- bash -c "$XENV xdotool key ctrl+alt+t"     # 打开终端

# ── 执行命令（不需要图形界面）────────────────────────
qm guest exec $VMID -- echo 'hello'
qm guest exec $VMID -- apt install -y <package>
qm guest exec $VMID -- systemctl status <service>

# ── 屏幕信息 ─────────────────────────────────────────
qm guest exec $VMID -- bash -c "$XENV xdpyinfo | grep dimensions"
```

### 陷阱与注意事项

1. **XAUTHORITY 路径**：guest agent 以 root 运行，需要指定用户的 `.Xauthority`
2. **多 DISPLAY**：VM 可能有多个 display（如 `:0` QEMU + `:1` KasmVNC），确认桌面在哪个 DISPLAY
3. **不要 windowclose 桌面壁纸**：`Alt+F4` 和 `windowclose` 可能误杀桌面壁纸进程；先用 `wmctrl -l` 或 `xdotool search` 确认窗口再关
4. **桌面壁纸恢复**：如果桌面变黑，重启桌面进程（如 `killall peony-qt-desktop && su - <user> -c "DISPLAY=:0 nohup peony-qt-desktop -w -d &"`）
5. **中文输入**：`xdotool type` 不支持中文（会超时导致 guest agent 崩溃），需安装 `xclip`，用剪贴板 + `Ctrl+V` 粘贴
6. **屏保/锁屏**：操作前先禁用 `xset s off -dpms s noblank`；如果已锁屏，`xset dpms force on` + `qm sendkey` 唤醒
7. **guest agent 崩溃**：长时间运行的命令可能超时导致 agent 无响应，从宿主机重启 `qm guest exec <vmid> -- systemctl restart qemu-guest-agent`

### 完整工作流示例：在 VM 中打开浏览器访问网站

```bash
VMID=200; XENV='DISPLAY=:0 XAUTHORITY=/home/QiSi/.Xauthority'

# 1. 禁用屏保
qm guest exec $VMID -- bash -c "$XENV xset s off -dpms s noblank"

# 2. 启动 Chromium
qm guest exec $VMID -- bash -c "su - QiSi -c '$XENV chromium-browser --no-sandbox http://example.com &'"

# 3. 等待窗口出现
sleep 5

# 4. 截图查看
qm monitor $VMID  →  screendump /tmp/s.ppm  →  quit
ffmpeg -y -i /tmp/s.ppm /tmp/s.png 2>/dev/null

# 5. 导航到新网址
qm guest exec $VMID -- bash -c "$XENV xdotool key ctrl+l"    # 聚焦地址栏
qm guest exec $VMID -- bash -c "$XENV xdotool type --clearmodifiers 'https://target-site.com'"
qm guest exec $VMID -- bash -c "$XENV xdotool key Return"

# 6. 截图确认
sleep 3
# 重复步骤 4

# 7. 点击页面元素（根据截图估算坐标）
qm guest exec $VMID -- bash -c "$XENV xdotool mousemove 500 300 click 1"

# 8. 关闭浏览器
qm guest exec $VMID -- bash -c "$XENV xdotool key alt+F4"
```

---

## 脚本: spawn-workspace.sh

创建命名工作区并启动 Claude Code，不抢焦点。

```bash
#!/bin/bash
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
```

---

## 提示

- 用 `cmux tree` 快速了解当前工作区结构
- 用 `cmux identify` 确认自己在哪个工作区/surface
- 用 `--id-format uuids` 获取稳定的 UUID（脚本中推荐）
- `read-screen` 加 `--scrollback --lines 200` 可读取历史输出
- `browser open` 返回 `surface=surface:N`，后续所有浏览器操作需指定这个 ref
- `read-screen`/`send`/`send-key` 仅限终端 surface，浏览器 surface 会报错
- 远程服务器操作优先用 SSH（`cmux new-split` + `cmux send`），比浏览器 Web 终端可靠
- PVE 图形界面用 `qm guest exec` + `xdotool`，不要尝试通过 noVNC canvas 操作
- 截图延迟约 1.8 秒（screendump + ffmpeg + scp 全链路）
