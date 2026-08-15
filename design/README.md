# Design

本目录只处理作品表达：发生过什么、作品要表达什么，以及每个游戏单元具体呈现什么。

## 文件

- [chronicle.md](chronicle.md)：事实与时间线。
- [inbox.md](inbox.md)：未经整理的记录、灵感和批注。
- [outline.md](outline.md)：整体命题与结构。
- [game-scenes.md](game-scenes.md)：当前生产台本，也是美术与代码共同使用的场景依据。
- [dialogue-line-break-review-20260813.md](dialogue-line-break-review-20260813.md)：全部游戏台词的审核断句；`◆` 表示分页，`↵` 表示同页换行，并直接生成运行时演出数据。
- [voiceover-recording-script-20260815.md](voiceover-recording-script-20260815.md)：从当前运行时台词提取的 148 条本人旁白录制清单；排除人物对白、少女 H 与已使用旧作原声的三十一岁段。
- [music-cue-plan-20260813.md](music-cue-plan-20260813.md)：生成阶段的主题、配器、环境声边界与制作依据；旧短段入退点已归档。
- [music-final-selection-20260814.md](music-final-selection-20260814.md)：当前启用的 11 个长音乐状态、保留候选与章节匹配。
- [music-generated-audit-20260814.md](music-generated-audit-20260814.md)：`MUS-01` 至 `MUS-09C` 的响度、动态、重复内容与运行时处理审查。
- [music-runtime-integration-20260814.md](music-runtime-integration-20260814.md)：16 个已处理资产、11 个启用状态、全台词覆盖、Godot 状态机和验证记录。
- [music-selection-review-20260815.md](music-selection-review-20260815.md)：当前 11 个启用状态与 5 个备用候选的可编辑选择审核表。
- [music-ai-prompts-20260813.md](music-ai-prompts-20260813.md)：本轮 Loop 原始素材的提示词与生成记录。
- [archive/film-continuity.md](archive/film-continuity.md)：微电影阶段分镜，只作为改编参考。

## 流转

```text
chronicle / inbox
        -> outline
        -> game-scenes
        -> dialogue-line-break-review
        -> art/asset-list
        -> game/content/story.json
```

已经进入 `game-scenes.md` 的对白，修改时必须同步更新断句审核表，并检查美术资产和 Godot 场景编号。
