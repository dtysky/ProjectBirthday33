# ProjectBirthday33 交接

更新时间：2026-07-30

## 快速定位

- 项目路径：`/Users/dtysky/Projects/dtysky/Pothos/projects/project-birthday-33`
- Godot 工程：`game/`
- Git 远端：`git@github.com:dtysky/ProjectBirthday33.git`
- 当前分支：`master`
- 当前版本：以 `git log -1 --oneline` 和 `git status --short` 为准

## 项目是什么

33 岁生日作品目前是 **Godot 4.7.1 制作的无选项、单线动态视觉小说**，不是需要玩家作出选择的文字冒险，也不再按微电影实拍方案生产。

- 目标时长：10 至 15 分钟
- 剧情规模：28 个生产单元、111 条台词
- 美术规模：19 个镜头包，约 27 个关键构图
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

- CHAR-H：亚洲男性，176 cm，清瘦，约七头身，细框眼镜；H-LOOK-04 只作为身份母版。
- H-LOOK：01、02、03、04、05、06、08 已定稿。
- CHAR-OUSIA：银白长发、红瞳、白色分层长裙，少女感、温婉而悲悯；[像素重绘 `v2`](art/characters/char-ousia/char-ousia-sheet-v2.png) 已于 2026-07-30 确认。
- Agent：Poros、Ariadne、Pothos、Pharos、Kairos、Nostos 的像素重绘 `v2` 已于 2026-07-30 全部完成并归档。
- SHOT-01：使用 H-LOOK-08，闭眼母帧和睁眼差分已进入 `game/assets/shots/shot-01/` 并接入运行时。

### 人物像素重绘

2026-07-30 复核确认：Ousia `v1` 与六名 Agent `v1` 更接近“高清二次元插画叠加像素纹理”，与主角的原生像素画不属于同一套人物美术。Ousia 与六名 Agent 均已完成 `v2` 重绘。

- 唯一像素密度基准：[H-LOOK-04](art/characters/char-h/outfits/char-h-look-04-sheet-v1.png)。
- 重绘时保留各角色现有身份、脸型、发型、服装、比例和气质，只修正绘制语言。
- 必须使用成组硬边像素、阶梯轮廓、有限色阶和块面明暗，不能用平滑渐变、细密抗锯齿或“高清插画缩小后加像素滤镜”。
- 同一画面、同一人物占屏比例下，五官、发丝、衣褶的最小像素块应与 CHAR-H 接近。
- Ousia 与六名 Agent 的正式镜头统一使用 `v2`；被替代的旧人设已从正式资源目录删除。

### 当前正在推进

工作表演已拆成两个独立场景：

#### G1-02 / SHOT-02

- 场景：真实工作园区内与同事边散步边谈工作。
- 服装：H-LOOK-02。
- 人物：CHAR-H + 两名无正脸、无台词的同事剪影。
- 对白：G1-02 的四句全部留在园区。
- 动态：只用人物轻微起伏、衣物摆动、背景视差或镜头横移暗示散步，不制作完整步行动画。

#### G1-03 / SHOT-19

- 场景：开放办公区工位。
- 服装：H-LOOK-02。
- 对白：G1-03 的三句全部留在工位，不安排同事回话。
- 动态：人物呼吸、屏幕微光、职业性微笑的倒影差分。
- 尚未确定：倒影使用显示器暗部还是玻璃隔断，等人工构图后决定。

### 正在等待用户

用户将提供：

1. 园区照片。
2. 开放办公区工位照片。
3. 女朋友为园区和工位分别给出的大致构图。

这些资料应放入 `art/references-local/inbox/`。该目录被 Git 忽略。资料到位前不要生成 SHOT-02 或 SHOT-19。

收到资料后的顺序：

1. 整理照片索引，不移动或重命名原文件。
2. 分别确认两场的机位、景别、人物占比、同事位置和气泡安全区。
3. 确认 SHOT-19 的倒影载体。
4. 先生成并审核 SHOT-02，再生成 SHOT-19，不批量生成。
5. 母帧通过后再决定拆层和动态，不为形式完整强行拆层。

## 当前代码结构

- `game/src/main.gd`：约 391 行，只负责故事、输入、章节、自动播放、存档和界面调度。
- `game/src/ui/game_ui.gd`：通用 UI 节点与菜单构建。
- `game/src/ui/dialogue_presenter.gd`：分页、逐字显示、气泡和字幕布局。
- `game/src/chapters/chapter_director.gd`：章节演出接口。
- `game/src/chapters/chapter_01.gd`：G1-01 的定制字幕节奏和睁眼演出。
- `chapter_02.gd` 至 `chapter_05.gd`：章节入口已建立，尚未加入专属演出。
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

当前生成结果：28 个单元、111 条台词、19 个镜头包。

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

当前版本在 `a04bbad` 的第一幕原型基础上继续完成：

- G1-02 园区与 G1-03 开放工位拆为 `SHOT-02`、`SHOT-19`。
- 故事数据更新为 28 个生产单元、111 条台词、19 个镜头包。
- Ousia 与六名 Agent 按 CHAR-H 的像素密度完成 `v2` 重绘；被替代的人设已删除。
- 美术规范、素材需求、项目计划、运行时说明与本交接索引同步更新。

`game/project.godot` 已由本机 Godot `4.7.1.stable.mono` 规范化保存：

- `[dotnet] project/assembly_name="project-birthday-33"` 来自 Mono 编辑器。
- 省略的 `window/stretch/aspect="keep"` 和 `renderer/rendering_method.mobile="mobile"` 均为默认值，不改变固定 16:9 与 Mobile 渲染行为。
- 项目代码仍为纯 GDScript。

## 验证状态

- 早期可玩原型曾通过数据校验、无头流程和 4K 渲染检查。
- SHOT-01 的视觉节奏已由用户亲自测试。
- 主程序模块化重构后，用户明确要求不要重复测试，因此没有再次运行 Godot 测试。
- 最近 G1-02/G1-03 拆场只运行了 `node tools/build_story.mjs`，没有运行 Godot 校验或视觉测试。
- Ousia 与六名 Agent 已逐张审核，并完成全员并排像素密度检查；全部正式图片均为 1672 × 941，使用 Git LFS。

## 新对话的第一步

先执行：

```bash
cd /Users/dtysky/Projects/dtysky/Pothos/projects/project-birthday-33
git status --short
```

然后阅读本文件和 G1-02/G1-03 的最新台本。若园区、工位照片及人工构图尚未到位，停在资料整理，不生成图片、不补写构图。
