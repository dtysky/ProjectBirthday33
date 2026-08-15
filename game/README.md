# Game

本目录是 Godot 工程和运行时资产目录。

## 当前实现

- 已初始化 Godot 4.7.1 工程，使用 1920 × 1080 逻辑坐标和 3840 × 2160 最终输出。
- 已从当前 `design/game-scenes.md` 生成 28 个生产单元；对白数量由构建脚本按当前台本生成并校验。
- 已实现标题页、角色空间锚定的纯内容对话框、无框独白／屏幕文字、逐字演出、单击推进、自动播放和结束页；G1 仍保留其已审核的固定台词卡。
- 已实现五段正文的跨章节标题演出：不切纯黑屏，而是分别借用公司地库、睁眼画面、送别宴、空白稿纸和雪夜下山路，在原场景的叙事留白中显示章名。上一章 BGM 先在原画面上用约 2.2 秒渐弱，随后进入约 5.2 秒的章节卡；卡片末段溶出并显露下一场景，再留约 0.9 秒才淡入新章 BGM。章节卡可单击跳过；读取存档与场景选择直达章中场景不会重复播放，从场景选择进入一章首个单元时仍显示，便于单独审查。
- 标题页与游戏内菜单均提供“场景选择”，可按 G1–G5 筛选并直接进入任一场景，便于逐段审查与调试。
- 全部 294 条台词使用已审核断句表决定视觉节拍：`◆` 生成下一页，`↵` 生成同一页内换行；原始台词与历史记录保持完整。自动按标点拆分只作为旧数据缺少审核结果时的兼容后备。
- 运行时内置 Noto Sans CJK SC（SIL OFL 1.1）覆盖完整中文台本，避免依赖系统字体回退而出现缺字框。
- 台词按人物对白、场景自白、跨场景旁白和屏幕文字分类；带“旁白”的说话人自动使用无框字幕。
- 已实现历史、保存、读取、文字速度、自动等待、音量和全屏设置。
- 已处理 16 个运行时音乐资产，实际启用 11 个长循环 BGM 状态与 1 个固定 20 秒检索事件；285 条台词拥有常驻 BGM 映射，G4-01 的 9 条台词改由旧作声音覆盖。台词 ID 驱动双播放器淡入、交叉淡化和多区间 Cue 恢复；G4-01 最后一句后音画同步渐隐，G4-02 随三十三岁画面重新建立 `MUS-07B`；G4 夜间下山不断乐，只有 G5 最终无人灯塔停驻淡出。
- 常驻界面仅保留折叠菜单入口，场景编号等制作信息默认隐藏，可用 `F3` 检查。
- 已接入 `SHOT-xx` 资产清单；正式母帧缺失时显示章节占位画面。
- `SHOT-01` 已按当前 24 句 G0 剧本接入醒来、洗漱、告别猫猫、上车、驾驶和公司地库停驻六张 CG；梦境继续显示明确占位。
- 章节演出由 `src/chapters/chapter_01.gd` 至 `chapter_05.gd` 分别管理；`main.gd` 只负责通用播放流程、界面与服务调度。
- G2 已接入 16 张独立 4K 试制母帧，覆盖 G2-01 至 G2-06 的全部场景复现；多人对白不显示姓名，并按每张 CG 中各角色的位置使用独立稳定锚点；差分、有限动画、音频与画中证据仍待实机审查后补充。
- G3 已接入 14 张独立 4K 母帧；新增无 Agent 的独立开场 `SHOT-42`。`chapter_03.gd` 负责六名 Agent 与 Ousia 的逐行镜头切换、逐镜禁放区、纯内容空间气泡、在“望着吊灯”时才切入的吸顶灯曝光呼吸，以及可跳过的 `SRC-03` 二十秒旧作索引检索场；真实录屏到位后可只替换中央证据区。
- G4 的 27 个镜头包均已有 4K 运行时画面；`SHOT-12` 以礼堂、山地、海岸、夜间返程四态完成三十一岁提问。G4-01 先以纸纤维／墨迹显影和无框“《三十一》 / 2024”进入旧作，再由原片声音自动驱动前 56.5 秒的九句字幕与四幕画面；末幕最后一句后音画同步渐隐至深灰黑，短暂停顿，再显露白日驾驶、无框“2026 / 三十三岁”和 `MUS-07B`。110.7 秒来源文件仍保留，但后半尾奏不再播放到 G4-02。
- G5 的九个镜头包、十三个运行时状态均已接入 4K 演出：包括 `SHOT-17` 三态、`SHOT-70` 与 `SHOT-74` 双态，以及 `SHOT-18`、`SHOT-71`、`SHOT-72`、`SHOT-73`、`SHOT-75`、使用 `H-LOOK-01` 的 `SHOT-76` 单态；G5 不再有语义占位。`chapter_05.gd` 负责逐态切换、逐镜字幕安全区、匹配转场、灯塔人物态向空镜慢溶、中央收束文字与最终无文字空镜停留。

## 技术边界

- Godot 4.7.1 stable。
- GDScript。
- 2D `Control` 节点。
- 单线 `StoryController`，无选项、数值、任务和地图。
- 台本来源：`../design/game-scenes.md`。
- 台词分页与换行来源：`../design/dialogue-line-break-review-20260813.md`。
- 美术来源：`../art/asset-list.md`。

## 规划结构

```text
game/
├── project.godot
├── src/
│   ├── main.tscn
│   ├── story_controller.gd
│   ├── asset_registry.gd
│   ├── save_service.gd
│   ├── music_director.gd
│   ├── voice_sequence_player.gd
│   ├── chapters/
│   │   ├── chapter_director.gd
│   │   ├── chapter_01.gd
│   │   ├── chapter_02.gd
│   │   ├── chapter_03.gd
│   │   ├── chapter_04.gd
│   │   └── chapter_05.gd
│   ├── ui/
│   │   ├── game_ui.gd
│   │   └── dialogue_presenter.gd
│   └── effects/
├── content/
│   ├── story.json
│   ├── asset_manifest.json
│   ├── music_cues.json
│   └── voice_sequences.json
├── assets/
│   ├── shots/
│   │   ├── shot-01/
│   │   └── ...
│   ├── evidence/
│   ├── video/
│   ├── ui/
│   ├── fx/
│   ├── audio/
│   └── fonts/
├── tests/
└── tools/
```

## 开发命令

从 `game/` 目录执行：

```bash
node tools/build_story.mjs
node tools/build_music.mjs
node tools/verify_music.mjs
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script res://tests/validate_story.gd
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script res://tests/music_director_test.gd
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script res://tests/voice_sequence_test.gd
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script res://tests/chapter_transition_audio_test.gd
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script res://tests/smoke_test.gd
```

`build_music.mjs` 默认读取 `/Users/dtysky/Downloads/b33/music/`，把 48 kHz／24-bit WAV 母版写入其 `runtime-masters/`，并把经过响度统一的 Ogg 写入 `assets/audio/music/`。换机时可用 `--source-dir`、`--master-dir` 和 `--output-dir` 指定位置。原始 MP3 不直接进入 Godot。

台本、审核断句或资产映射修改后必须重新运行 `build_story.mjs`，并提交更新后的 `content/story.json` 和 `content/asset_manifest.json`。构建会校验审核表覆盖全部台词，并确认分页内容能够逐字还原正式台本。

## 实现顺序

1. 初始化 Godot 工程和基础窗口。
2. 实现 `StoryController`、对白演出层和占位资产。
3. 导入 28 个生产单元，并随当前台本自动更新台词数量。
4. 完成 G1 垂直切片。
5. 接入历史、自动播放、保存、读取和设置。
6. 批量替换正式镜头包、画中证据与动态 CG。
7. 完成 Shader、视频、音频、测试和桌面构建。

前三项和 G1 垂直切片已经完成，G2 与 G3 当前均可按场景选择连续实机审查。

运行时以镜头包为资产单位，不维护一套可任意组合的全局背景库和人物立绘库。每个生产单元引用一个 `SHOT-xx`，再指定需要显示的母帧、差分、前景或遮罩层。

章节专属的节奏、镜头差分、字幕位置和转场写入对应的 `chapter_xx.gd`。跨章节复用的对白分页、输入、菜单、存档和资产加载留在 `main.gd` 或独立服务中。

`assets/evidence/` 只存放裁切后的聊天和检索等叙事原件，必须显示在镜头包定义的屏幕、纸面或投影区域内。旅行实拍与道路照片只作为美术参考，不进入运行时目录。

美术工作文件不放入本目录；这里只接收经过审核、已按镜头包编号命名的最终导出。镜头包内的拆层必须与母帧同尺寸、像素对齐。
