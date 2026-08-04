# ProjectBirthday33 交接

更新时间：2026-08-04

## 快速定位

- 项目路径：`/Users/dtysky/Projects/dtysky/Pothos/projects/project-birthday-33`
- Godot 工程：`game/`
- Git 远端：`git@github.com:dtysky/ProjectBirthday33.git`
- 当前分支：`master`
- 当前版本：以 `git log -1 --oneline` 和 `git status --short` 为准

## 项目是什么

33 岁生日作品目前是 **Godot 4.7.1 制作的无选项、单线动态视觉小说**，不是需要玩家作出选择的文字冒险，也不再按微电影实拍方案生产。

- 目标时长：10 至 15 分钟
- 剧情规模：28 个生产单元、258 条台词
- 美术规模：42 个镜头包；G0、G1、G2 与 G3 已有运行时 CG，其中 G3 共接入十四张 4K 母帧
- 画面：1920 × 1080 逻辑坐标，3840 × 2160 最终输出
- 风格：真实场景的透视与光线 + 亚洲二次元硬边像素人物 + 电影化动态 CG
- 核心情感：年度事件和离职决定只是材料，真正主题是停止延期，承认自己从小就想走另一条人生

## 必须遵守的边界

1. 不增加选项、数值、任务、地图或分支。
2. 不把台本重新写成年度总结；事业经历只承担抽象情感主题。
3. 不制作连续行走、复杂口型、多人连续动作或精确手部交互。
4. 画面按 `SHOT-xx` 镜头包生产，不能退回“通用背景 + 通用立绘”的拼贴方式。
5. 人物与背景先共同完成一体构图母帧，再按 Godot 实现需要拆层。
6. 生成任何含 CHAR-H 的镜头前，必须再次确认场景、人物状态、构图、发声关系和本镜头使用的 `H-LOOK`，不得代选服装。
7. 来源照片只作构图、天气和光线参考；聊天、检索等叙事证据只能嵌入 CG 内的屏幕、纸面或投影。
8. 用户明确说已经测试过时，不要重复运行视觉或节奏测试。

## 阅读索引

建议新对话按以下顺序阅读：

1. [README.md](README.md)：项目入口。
2. [design/outline.md](design/outline.md)：主题和完整叙事骨架。
3. [design/game-scenes.md](design/game-scenes.md)：28 个生产单元的正式台本、人物、对白和美术要求。
4. [art/style-guide.md](art/style-guide.md)：画风、动态和来源素材边界。
5. [art/asset-list.md](art/asset-list.md)：正式镜头包、人物、地点、来源素材和生产状态。
6. [art/reference-request.md](art/reference-request.md)：仍需用户提供的参考素材。
7. [project-plan.md](project-plan.md)：技术方案、排期与验收。
8. [game/README.md](game/README.md)：Godot 运行时结构与开发命令。

补充资料：

- [design/chronicle.md](design/chronicle.md)：事业轴与创作轴的年度事实。
- [design/inbox.md](design/inbox.md)：碎片化素材，不等于最终台本。
- [design/archive/film-continuity.md](design/archive/film-continuity.md)：旧微电影方案，仅作改编依据。
- [art/character-h-reference-catalog.md](art/character-h-reference-catalog.md)：CHAR-H 的 7 套正式服装和原照片索引。
- `art/characters/`：CHAR-H、Ousia 与六名 Agent 的正式人设。

## 当前美术进度

### 已锁定

- CHAR-H：亚洲男性，175 cm，清瘦，约七头身，细框眼镜；每个场景严格使用台本指定的 `H-LOOK`。
- H-LOOK：01、02、03、04、05、06、08 已定稿。
- CHAR-OUSIA：银白长发、红瞳、白色分层长裙，少女感、温婉而悲悯；[像素重绘 `v2`](art/characters/char-ousia/char-ousia-sheet-v2.png) 已于 2026-07-30 确认。
- Agent：Poros、Ariadne、Pothos、Pharos、Kairos、Nostos 的像素重绘 `v2` 已于 2026-07-30 全部完成并归档。
- SHOT-01：G0 已接入醒来、洗漱、告别猫猫、家中地库上车、驾驶和公司地库停驻六张 CG；梦境仍保留占位。

### 人物像素重绘

2026-07-30 复核确认：Ousia `v1` 与六名 Agent `v1` 更接近“高清二次元插画叠加像素纹理”，与主角的原生像素画不属于同一套人物美术。Ousia 与六名 Agent 均已完成 `v2` 重绘。

- 唯一像素密度基准：[H-LOOK-04](art/characters/char-h/outfits/char-h-look-04-sheet-v1.png)。
- 重绘时保留各角色现有身份、脸型、发型、服装、比例和气质，只修正绘制语言。
- 必须使用成组硬边像素、阶梯轮廓、有限色阶和块面明暗，不能用平滑渐变、细密抗锯齿或“高清插画缩小后加像素滤镜”。
- 同一画面、同一人物占屏比例下，五官、发丝、衣褶的最小像素块应与 CHAR-H 接近。
- Ousia 与六名 Agent 的正式镜头统一使用 `v2`；被替代的旧人设已从正式资源目录删除。

### 当前正在推进

G1 垂直切片已经完成。G2 当前进入全场景实机试制：

- 16 个独立 G2 场景均已接入一张 3840 × 2160 运行时母帧：`SHOT-05`、`06`、`07`、`08`、`20` 至 `31`。
- G2 不复用上一场 CG 充当新场景；同一工位、会议室或陶波地点也分别建立独立机位和构图。
- `chapter_02.gd` 按台词中的 `SHOT-xx` 标记逐行切换画面；口述字幕使用安全区，人物对白只显示内容并按当前角色使用无尖角的稳定空间锚点。
- 当前只验证母帧与剧本节奏。`plan/accepted`、`memory-pass`、饭后空桌和有限动画等差分，等用户实机审查后再按必要性制作。
- G2 试制清单见 [art/g2-cg-manifest-20260804.md](art/g2-cg-manifest-20260804.md)。

G3 已从三个占位包扩展为十四个独立镜头包并完成首轮接入：

- `SHOT-42` 是无 Agent 的独立开场：我独自在家整理旅行照片、摄影器材与 AI 对话；两句前置旁白结束后才进入 Poros。
- `SHOT-32` 至 `SHOT-37` 分别属于 Poros、Ariadne、Pothos、Pharos、Kairos、Nostos，每人包含工作中景与任务局部。
- `SHOT-38` 是纯白花海中的 Ousia 相遇；`SHOT-09`、`10`、`39`、`40`、`41`、`11` 分别承担花海聊天、深夜卧室仰视、旧文找回、女主原文退回、怀中哭泣和空白稿纸。
- G3 专项资产设计见 [art/g3-asset-plan-20260804.md](art/g3-asset-plan-20260804.md)。
- 用户已指定 G3 中的“我”统一使用 `H-LOOK-04`。
- `SHOT-09` 至 `11`、`SHOT-32` 至 `42` 中属于 G3 的十四张母帧均已导出为唯一的 4K 运行时 WebP；审核源稿仍只保存在 Git 忽略目录，记录见 [art/g3-cg-manifest-20260804.md](art/g3-cg-manifest-20260804.md)。
- 最终聊天与检索证据仍需 `SRC-01`、`SRC-03`；当前 `SRC-03` 使用可跳过的二十秒明确占位，`SRC-02` 仅在需要复刻真实卧室时可选提供。

### 当前仍待审查

- 逐场检查字幕是否遮挡人物、屏幕证据或关键手势。
- 判断 SHOT-08 与 SHOT-30 的 16:9 居中裁切是否需要重新构图。
- 判断哪些状态变化必须靠独立差分表达，哪些可继续由台词和屏幕母帧承担。
- 送别宴仍可用真实四人座次照片校准，但不阻塞当前试制。

## 当前代码结构

- `game/src/main.gd`：只负责故事、输入、章节、自动播放、存档和界面调度。
- `game/src/ui/game_ui.gd`：通用 UI 节点与菜单构建。
- `game/src/ui/dialogue_presenter.gd`：分页、逐字显示、气泡和字幕布局。
- `game/src/chapters/chapter_director.gd`：章节演出接口。
- `game/src/chapters/chapter_01.gd`：G1-01 的定制字幕节奏和睁眼演出。
- `game/src/chapters/chapter_02.gd`：G2 行级镜头切换、逐镜头角色对白锚点与旁白安全区。
- `game/src/chapters/chapter_03.gd`：G3 行级镜头切换、Agent／Ousia 空间气泡、卧室灯光呼吸、转场和二十秒检索占位。
- `chapter_04.gd` 至 `chapter_05.gd`：章节入口已建立，尚未加入完整专属演出。
- `game/src/story_controller.gd`：按 `story.json` 单线推进。
- `game/src/asset_registry.gd`：读取镜头母帧和差分。

章节专属节奏、镜头差分和转场写入对应的 `chapter_xx.gd`，不要再塞回 `main.gd`。

## 数据生成

正式来源：

- 台本：`design/game-scenes.md`
- 镜头映射：`art/asset-list.md`

生成文件：

- `game/content/story.json`
- `game/content/asset_manifest.json`

不要手改生成文件。修改台本或资产表后执行：

```bash
cd game
node tools/build_story.mjs
```

当前生成结果：28 个单元、258 条台词、42 个镜头包。

## Git 与大文件

- Git LFS 已在仓库初始化。
- `art/characters/` 的正式人物图片和 `game/assets/` 的运行时图片、音频、视频、字体使用 LFS。
- `.uid` 和 `.import` 必须提交；它们保存 Godot 的稳定资源标识和导入设置。
- `.godot/`、本地来源素材、AI 候选稿、工作源文件和构建产物必须忽略。

首次克隆：

```bash
git lfs install
git lfs pull
```

## 版本状态

当前工作树已经在 G1 垂直切片基础上完成：

- G0 六张日常 CG 与 G1 七张 CG 已接入。
- G2 拆为 16 个独立现实复现场景，并全部接入 4K 试制母帧。
- 故事数据为 28 个生产单元、258 条台词、42 个镜头包。
- Ousia、六名 Agent、CHAR-H、两只猫和五人团队均有固定身份边界；正式镜头不得用主角换皮代替组员。
- AI 候选与实景原图只保存在 Git 忽略目录；通过试制后只向 `game/assets/shots/` 导出唯一运行时版本。

`game/project.godot` 已由本机 Godot `4.7.1.stable.mono` 规范化保存：

- `[dotnet] project/assembly_name="project-birthday-33"` 来自 Mono 编辑器。
- 省略的 `window/stretch/aspect="keep"` 和 `renderer/rendering_method.mobile="mobile"` 均为默认值，不改变固定 16:9 与 Mobile 渲染行为。
- 项目代码仍为纯 GDScript。

## 验证状态

- 2026-08-04 已运行 `node tools/build_story.mjs`：28 个单元、258 条台词、42 个镜头包。
- 2026-08-04 已运行 Godot 编辑器无头导入，16 张 G2 与 14 张 G3 WebP 均生成稳定 `.import` 元数据。
- `validate_story.gd` 已通过：六张 G0、七张 G1、十六张 G2 试制母帧与十四张 G3 母帧均可加载，运行时纹理为 3840 × 2160。
- `smoke_test.gd` 已通过：G2／G3 行级镜头切换、G3 独立开场、逐镜避让的无姓名对白框、吊灯延后切入、二十秒检索占位、旁白布局、场景选择和结束流程正常。
- 自动化测试只验证资源、映射和界面状态；G2 与 G3 的最终字幕遮挡、节奏和审美仍需用户实机审查。

## 新对话的第一步

先执行：

```bash
cd /Users/dtysky/Projects/dtysky/Pothos/projects/project-birthday-33
git status --short
```

然后阅读本文件、[G2 试制清单](art/g2-cg-manifest-20260804.md)和 `design/game-scenes.md` 的 G2 段落。下一步优先从场景选择进入 G2-01 至 G2-06 实机审查，不先扩写差分或动画。
