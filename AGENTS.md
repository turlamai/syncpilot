# AGENTS.md

## 家族设计（必读入口）

- 设计/UI 任务先加载 `tlai-product`，必读 `references/policy.md` 与 `references/design-standard.md`（理念、决策规则、UI 验收）。技能缺失时读取 ZCode 真源：macOS/Linux `~/Sync/ZCode/skills/tlai-product/`；Windows `D:/ZCode/skills/tlai-product/`。无法读取须报告规范未核验，不凭记忆跳过。
- 家族规范管共性；本仓现有设计、行为与 token 真源管具体值和产品差异。例外记回原契约，不复制家族规则或新增数值表；已有界面按下一次相关切片渐进对齐。
- 改界面先改原型、落账后实现；按家族 UI 清单与本仓当前技术线的既有门禁验收，原型对照和真实交互证据都要保留；对外宣传使用验收后的实物截图。

## 实现路由（agent 按任务读真源）

- 实现界面以 `design/prototype/` 为准：对照 HTML/CSS/JS 与实物截图验收，不依赖散文复述。
- Token/几何值真源 = `design/prototype/shared.css`（亮暗成对；无 shared.css 的仓 = design/prototype/ 各页样式）；`design/DESIGN.md` 只记语义名、用途与决策。
- 行为边界与跨平台一致性以 `design/DESIGN.md` 的不变式与平台差异节为准。
- 改界面先改原型再改实现（tlai-product）；动共享层（design/、shared/）先 issue 声明，同 commit 落契约。

## Current owner decision — 2026-11-18 quality-first

This product is in **non-commercial development**. The prior 2026-10/11 product pricing, trial, paid-feature, Free/Pro and family Permit/Commerce rollout decisions are canceled. Do not introduce checkout, subscriptions, activation, commercial entitlement, paid update windows or a paywall. Do not change source-license terms or release signing and identity verification. Prioritize product correctness, reliable native experience, recovery, bilingual README and truthful website claims. The [current family portfolio](https://github.com/turlamai/turlamai.github.io/blob/master/PORTFOLIO.md) governs every slice.

指引给 AI agent（及开发者）：如何理解、构建、运行、改动 SyncPilot（Rivet 重建线）。

> 0.5.0 起 main 即本线：一份 Racket 领域核心 + GTK4 单宿主。旧 Tauri 2 栈已从
> 树上删除，行为与文案参照留在 git 历史（v0.4.0 及之前的 tag）。

## 这是什么

SyncPilot 以 Rivet（github.com/turlamai/rivet）构建：一份 Racket 领域核心，
通过 Rivet 类型化 RPC（RVT1 协议）驱动第一方原生 UI 薄壳。

SyncPilot 仅面向 Linux：

| 宿主 | 技术栈 | 目录 | 状态 |
|---|---|---|---|
| Linux | GTK4 + WebKitGTK 6.0 宿主 + 生成客户端 | `linux/` | CI 编译 + 集成冒烟全绿（真守护进程 + 代理链路断言）；详见 `linux/README.md` |

## 快速命令

```bash
# 前置：Racket CS 9.x，rivet 以 link 方式安装
# cd ../rivet && raco pkg install --auto --no-docs --name rivet --link file://$PWD

raco rivet doctor --json   # 工具链自检
raco rivet build           # 生成三端客户端 + 编译后端 bundle + 宿主构建
raco rivet dev             # 开发循环
raco test racket/          # 领域核心测试
raco rivet acceptance --json # Linux 完整产品验收
```

开始修改已有 checkout 前，必须先检查 `git status`，再以 fast-forward-only
方式更新 tracked remote。工作树非干净、分支已分叉或远端不可达时，保留现场并
报告，不得用 stash/reset/清理生成目录掩盖状态。记录本次工作的起始 commit。

`rivet-acceptance.rktd` 是 Linux 产品的可执行完成定义。Agent 不得删除
requirement、放宽断言、以 CLI 代替 GUI 行为或复用旧证据来让结果变绿；required
suite 只要未执行、超时、失败或没有产生本次运行的新证据，就不能称为完成。

## 契约（不要破坏）

- **数据路径与格式与旧版完全一致**（drop-in 迁移）：syncpilot-settings.json / rslsync.conf（0600）/ storage/，目录 ~/.local/share/site.jrtx.syncpilot（Linux）；协议事实见 docs/api-verified.md（必读）
- **i18n 单源**：`shared/i18n/{zh,en}.json`，平台副本必须逐字节一致；zh 为默认
- **RPC 面**：`app/backend.rkt` 的 define-rpc 是宿主唯一数据通道；改签名 = 各端宿主 + 生成客户端同步改
- **宿主只做渲染与交互**：业务一律走 RPC；定时器/调度/HTTP/存储都在 Racket 后端
- **Rivet 改动走上游**：缺能力先提 issue/PR 到 turlamai/rivet
- **平台范围**：SyncPilot 只支持 Linux；不要添加空壳 Windows/macOS 宿主，也不要把未支持平台记作产品缺陷

## 项目结构

```
├── rivet.rktd          Rivet 应用清单
├── app/backend.rkt     Rivet 后端入口（装配领域层）
├── racket/             Racket 领域核心 + tests/
├── shared/i18n/        zh.json / en.json 单源
├── linux/              GTK4 宿主（唯一宿主；详见 linux/README.md）
├── site/               产品官网（GitHub Pages → syncpilot.jrtx.site）
├── docs/               用户文档（USER-GUIDE 等 .md）
└── scripts/            gen-c-strings.mjs（i18n → C 头）、install-rslsync.sh
```

## 组合定位（Portfolio placement）

2026-11-18 起，以产品交付质量为目标，不推进收费版、试用、商业授权或结账。既有 LICENSE 和发行签名验证保持不变。当前权威是[产品组合策略](https://github.com/turlamai/turlamai.github.io/blob/master/PORTFOLIO.zh-CN.md)。

## 产品交付与下一步（2026-11-18）

请以当前代码与验收证据推进用户主流程、恢复、跨平台原生体验、签名更新、文档和产品主页，不按任何历史商业规划开发。

## Documentation languages

Public default documentation is English; maintain complete Chinese user paths in `*.zh-CN.md`, with reciprocal links. Update both languages when prices, quotas, installation, recovery, privacy or supported platforms change. API/protocol identifiers and commands remain unchanged; do not maintain a second normative protocol or implementation. Follow the [family language policy](https://github.com/turlamai/turlamai.github.io/blob/master/docs/DOCUMENTATION-LANGUAGES.md). Existing internal notes are not a claim that every document is bilingual.

## Public product documentation

The paired `docs/USER-GUIDE.md` / `docs/USER-GUIDE.zh-CN.md` own the public installation, first-use, data/recovery, privacy and availability path. Keep the homepage and both README entry points aligned with them when behavior changes. Detailed technical contracts and the current implementation queue retain their existing owners. Do not publish target prices, a purchase link or a ready/secure/platform claim before its release evidence exists.
