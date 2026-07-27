# Game

本目录用于 Godot 工程和运行时资产。当前只完成工程规划，尚未初始化 `project.godot`。

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
│   ├── ui/
│   └── effects/
├── content/
│   ├── story.json
│   └── asset_manifest.json
├── assets/
│   ├── backgrounds/
│   ├── characters/
│   ├── cg/
│   ├── overlays/
│   ├── ui/
│   ├── movies/
│   ├── audio/
│   └── fonts/
├── tests/
└── tools/
```

## 实现顺序

1. 初始化 Godot 工程和基础窗口。
2. 实现 `StoryController`、文本框和占位资产。
3. 导入 28 个生产单元和 111 个文本框。
4. 完成 G1 垂直切片。
5. 接入历史、自动播放、保存、读取和设置。
6. 批量替换正式美术与真实素材。
7. 完成 Shader、视频、音频、测试和桌面构建。

美术工作文件不放入本目录；这里只接收经过审核、已按资产编号命名的最终导出。
