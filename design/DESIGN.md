# SyncPilot DESIGN.md — 视觉与交互契约（单一真源）

原型（`design/prototype/`）与实现（`linux/` GTK 宿主）都遵循本文件；改视觉先改这里，再同步实现。

**Tokens 来源说明**：宿主目前无自定义 CSS 体系（GTK 默认 Adwaita），故 tokens 为推导值，依据三条，逐项注明——
1. **accent 蓝**取自 `assets/app-icon.png`（用户在托盘/启动器里看到的产品色，桌面品牌唯一载体），按 WCAG 对比度在亮/暗底上各校一档；
2. **中性色**按 Linux 桌面基线（GTK Adwaita 冷中性灰）推导——chrome 必须与内嵌的官方 Resilio Web UI（中性灰系）同框不冲突，家族官网的暖纸色/terracotta 属 site-kit 网页体系，不搬进桌面 chrome；
3. **圆角三档 8/12/16、动效 150ms** 承继家族 site-kit（`site/family.css`）的框架值，保证家族一致性。

## Brief（2026-11-11）

- **目标**：给 shell 定边界而不是重设计。窗口内主角是官方 Resilio Web UI 与它呈现的同步状态；SyncPilot 自有 chrome（标题栏相位、底部状态栏、引导页、设置、更新卡）做到极简、安静、可信，达到可直接用于官网宣传的质量。
- **原型范围**（6 屏 × 亮/暗）：① 主视图 · 同步文件夹列表（英雄屏）② 文件夹详情 · 对端/传输 ③ 空态概览 · 许可横幅 ④ 引导页 · 首次安装下载态 ⑤ 设置 ⑥ 更新就绪卡。
- **Exit 条件**：6 屏关键状态齐（空态/下载进行态/同步进行态/断连态/错误态/更新就绪态）+ chrome 与内容的归属边界定稿 + HIG 清单全过 + 用户评审通过；实物截图验收后才能作对外宣传素材。
- **不在范围**：官方 Web UI 内部重设计（那是 Resilio 的界面，版本跟随 rslsync）；Windows/macOS 宿主（产品只支持 Linux）；付费/激活 UI（免费保活，见 PRICING.md）；RPC 面与数据路径变更。

## 设计原则（HIG 内核）

- **第三方状态是内容主角**：文件夹、对端、传输、速度都是 Resilio 的语义，chrome 只负责把它们衬出来；装饰不与状态争注意力。
- **chrome 极简**：SyncPilot 自有表面只有标题栏（相位芯片）与底部状态栏（相位 + 全局速度），其余一律让位；新增 chrome 元素默认拒绝，除非守护进程层面确有必要。
- **反馈及时**：守护进程相位（运行中/启动中/已停止/已崩溃/失败）在标题栏与状态栏双可见，下载/更新/索引有进行态，永不静默。
- **防错一致**：不发明 Resilio 没有的语义（3.x 已移除暂停，界面不得出现暂停）；破坏性操作（删除文件夹、重启守护进程）需确认；许可门禁如实呈现，不伪装成功能故障。
- **层级克制**：bg < surface < 浮层三层足够；accent 只给交互与进行态，同步结果态用语义色。

## Tokens（推导语义，依据见开头；亮暗成对）

推导依据（why，三条）：① accent 蓝取自 `assets/app-icon.png`（用户在托盘/启动器里看到的产品色），按 WCAG 对比度在亮/暗底各校一档；② 中性色按 Linux 桌面基线（GTK Adwaita 冷中性灰）推导——chrome 必须与内嵌的官方 Resilio Web UI 同框不冲突，家族官网的暖纸色/terracotta 属 site-kit 网页体系，不搬进桌面 chrome；③ 圆角三档 8/12/16、动效 150ms 承继家族 site-kit（`site/family.css`）。值载体 = 原型 `design/prototype/shared.css`（宿主实现落地时从这里取值），本表只记语义。

| Token | 语义 |
|---|---|
| `--bg --surface --raised --line` | 画布窗口底 / 卡片浮层对话框 / 悬浮选中底 / 分隔 |
| `--ink --mute` | 主/次级文字 |
| `--accent --accent-soft` | icon 蓝：选中/链接/进行态/主按钮 + 弱底（徽标/进度槽） |
| `--ok --ok-soft` | 已同步/运行中/对端在线 + 弱底 |
| `--err --err-soft` | 失败/崩溃/校验不匹配 + 弱底 |
| `--warn --warn-soft` | 正在扫描/需注意（许可等）+ 弱底 |

- **字体**：`system-ui, -apple-system, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Noto Sans CJK SC", sans-serif`；正文 14px/1.55，行标题 600，次级 13px，辅助 12px；速度/大小等数字用 `tabular-nums`。
- **圆角**：窗口 16px · 卡片 12px · 控件 8px（承继 family site-kit 8/12/16 三档）。**间距节奏**：4/8/12/16/24。**动效**：150ms ease，不过度。
- **语言**：界面文案跟随产品 i18n 单源（`shared/i18n/{zh,en}.json`，zh 默认）；官方 Web UI 区域文案归 rslsync 自己的本地化，SyncPilot 不代写。
- **品牌标记**：蓝色圆角方块 + 双循环箭头（`assets/app-icon.png` 的矢量简化），只出现在标题栏/引导卡/关于节，不重复刷存在感。

## 组件词汇

`TitlebarChrome`（窗口标题 + 守护进程相位芯片：运行中/启动中/已停止/已崩溃/失败）· `StatusBar`（相位 + 全局 ↓/↑ 速度，数据源既有 `get-speeds` RPC + rslsync 版本号）· `LicenseBanner`（overview 顶部横幅：许可未激活/试用中，来自 `license_state`）· `RailNav`（官方界面侧栏：同步文件夹/已连接设备/偏好设置——内容区，归 Resilio）· `FolderRow`（文件夹名/路径/状态徽标/同步进度条/对端数/大小）· `FolderTabs`（对端/传输/历史/偏好）· `PeerRow`（设备名/连接态/速率/最近同步）· `TransferRow`（文件/方向/进度/速率/对端）· `BootCard`（引导页居中卡：启动中/移交/未安装下载/错误重试）· `SettingsSection`（守护进程/设备/桌面/语言/更新/关于六节）· `UpdateCard`（发现新版本 → 下载中 → 已就绪(Ed25519 已校验+手动应用说明) → 失败）· `Toast` · `TrayMenu`（打开/设置/退出）。

## 不变式

1. **归属边界**：官方 Web UI 区域的状态、文案、交互归 Resilio，SyncPilot 不重绘不改词不翻译；自有 chrome 只允许出现在标题栏、底部状态栏、引导卡、设置窗、更新卡、托盘六处。
2. **不发明语义**：状态词汇与官方 UI 及 `docs/api-verified.md` 对齐（无暂停、无假在线）；数据没有的字段界面不出现。
3. **accent 纪律**：icon 蓝只给交互与进行态（选中/链接/进度/主按钮）；同步结果用 ok/err，扫描/许可用 warn；禁止大面积 accent 色块。
4. **chrome 安静**：chrome 文字默认 `mute` 层级，任何时刻窗口内 ≤3 层表面（bg/surface/浮层），层级靠底色与 1px line 表达，不用阴影堆叠。
5. **亮暗成对 + 相位双可见**：不存在只有暗态的界面；守护进程相位同时出现在标题栏芯片与状态栏，后台静默状态（崩溃重启退避、更新检查）必须有可见入口。


## 平台映射与差异声明（预钉 · 宿主实现时升级为落点表）

统一层（三平台必须一致，`design/prototype/` 原型已锁定）：信息架构、核心流程、快捷键语义、
语义色与层级词汇。因地制宜层（按平台惯例落地，不预画像素）：

| 维度 | macOS | Windows | Linux |
|---|---|---|---|
| 修饰键 | ⌘ | Ctrl | Ctrl |
| 命令入口 | 原生菜单栏 | 菜单栏/命令行内 | 菜单栏 |
| 字体 | 系统栈 + PingFang SC | 系统栈 + Microsoft YaHei | 系统栈 + Noto Sans CJK |
| 原生控件 | SwiftUI 控件 | WinUI 3 控件 | GTK4 控件 |

差异声明纪律：宿主特例必须先写进本节才能实现；未声明的宿主差异按违约处理
（案例：taskly 漂移台账 D8）。
