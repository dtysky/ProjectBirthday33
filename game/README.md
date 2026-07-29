# Game

本目录是 Godot 工程和运行时资产目录。

## 当前实现

- 已初始化 Godot 4.7.1 工程，使用 1920 × 1080 逻辑坐标和 3840 × 2160 最终输出。
- 已从 `design/game-scenes.md` 生成 28 个生产单元、111 条对白。
- 已实现标题页、场景内对白气泡、无框独白／屏幕文字、逐字演出、单击推进、自动播放和结束页。
- 长对白按标点拆成连续的视觉节拍，原始台词与历史记录保持完整。
- 111 条台词已区分为 53 条人物对白、34 条场景自白、20 条跨场景旁白和 4 条屏幕文字。
- 已实现历史、保存、读取、文字速度、自动等待、音量和全屏设置。
- 常驻界面仅保留折叠菜单入口，场景编号等制作信息默认隐藏，可用 `F3` 检查。
- 已接入 `SHOT-xx` 资产清单；正式母帧缺失时显示章节占位画面。
- 章节演出由 `src/chapters/chapter_01.gd` 至 `chapter_05.gd` 分别管理；`main.gd` 只负责通用播放流程、界面与服务调度。
- 尚未接入正式美术、音频、画中证据和镜头动态。

## 技术边界

- Godot 4.7.1 stable。
- GDScript。
- 2D `Control` 节点。
- 单线 `StoryController`，无选项、数值、任务和地图。
- 台本来源：`../design/game-scenes.md`。
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
│   ├── audio_service.gd
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
│   └── asset_manifest.json
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
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script res://tests/validate_story.gd
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script res://tests/smoke_test.gd
```

台本或资产映射修改后必须重新运行 `build_story.mjs`，并提交更新后的 `content/story.json` 和 `content/asset_manifest.json`。

## 实现顺序

1. 初始化 Godot 工程和基础窗口。
2. 实现 `StoryController`、对白演出层和占位资产。
3. 导入 28 个生产单元和 111 条台词。
4. 完成 G1 垂直切片。
5. 接入历史、自动播放、保存、读取和设置。
6. 批量替换正式镜头包、画中证据与动态 CG。
7. 完成 Shader、视频、音频、测试和桌面构建。

前三项已经完成，当前进入 G1 垂直切片。

运行时以镜头包为资产单位，不维护一套可任意组合的全局背景库和人物立绘库。每个生产单元引用一个 `SHOT-xx`，再指定需要显示的母帧、差分、前景或遮罩层。

章节专属的节奏、镜头差分、字幕位置和转场写入对应的 `chapter_xx.gd`。跨章节复用的对白分页、输入、菜单、存档和资产加载留在 `main.gd` 或独立服务中。

`assets/evidence/` 只存放裁切后的聊天和检索等叙事原件，必须显示在镜头包定义的屏幕、纸面或投影区域内。旅行实拍与道路照片只作为美术参考，不进入运行时目录。

美术工作文件不放入本目录；这里只接收经过审核、已按镜头包编号命名的最终导出。镜头包内的拆层必须与母帧同尺寸、像素对齐。
