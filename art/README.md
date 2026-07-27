# Art

本目录管理美术方向和生产台账，不存放 Godot 运行时资产。

## 文件

- [style-guide.md](style-guide.md)：已经确认的画风、动态边界与视觉递进。
- [asset-list.md](asset-list.md)：背景、人物、CG 和真实素材的编号与状态。

## 工作流

1. 从 `design/game-scenes.md` 确认单元和构图需求。
2. 由人工提供人物设定与关键构图草图。
3. AI 根据草图扩展背景、差分和关键 CG。
4. 人工审核人物一致性、构图和风格。
5. 最终文件按资产编号导出到 `game/assets/`。
6. Codex 更新 `game/content/asset_manifest.json` 并接入场景。

## 本地目录

以下目录按需创建，不进入 Git：

- `references-local/`：本地参考照片。
- `workfiles/`：PSD、工程文件和中间稿。
- `generated/`：未经筛选的 AI 生成结果。

需要进入 Git 的只有规范、台账和体积可控的最终交付。大型视频在选定片段后再决定 Git LFS 或发布存储方案。
