# Design

本目录只处理作品表达：发生过什么、作品要表达什么，以及每个游戏单元具体呈现什么。

## 文件

- [chronicle.md](chronicle.md)：事实与时间线。
- [inbox.md](inbox.md)：未经整理的记录、灵感和批注。
- [outline.md](outline.md)：整体命题与结构。
- [game-scenes.md](game-scenes.md)：当前生产台本，也是美术与代码共同使用的场景依据。
- [dialogue-line-break-review-20260813.md](dialogue-line-break-review-20260813.md)：全部游戏台词的审核断句；`◆` 表示分页，`↵` 表示同页换行，并直接生成运行时演出数据。
- [voiceover-recording-script-20260815.md](voiceover-recording-script-20260815.md)：从当前运行时台词提取的 158 条本人旁白录制清单；排除人物对白、少女 H 与已使用旧作原声的三十一岁段。
- [music-cue-plan-20260813.md](music-cue-plan-20260813.md)：生成阶段的主题、配器、环境声边界与制作依据；旧短段入退点已归档。
- [music-final-selection-20260814.md](music-final-selection-20260814.md)：当前可运行版本启用的 8 个长循环 BGM、1 个检索事件、保留候选与章节匹配；G0—G3 已进入待生成的重制阶段。
- [music-generated-audit-20260814.md](music-generated-audit-20260814.md)：`MUS-01` 至 `MUS-09C` 的响度、动态、重复内容与运行时处理审查。
- [music-runtime-integration-20260814.md](music-runtime-integration-20260814.md)：16 个已处理资产、10 个启用状态、全台词覆盖、Godot 状态机和验证记录。
- [music-selection-review-20260815.md](music-selection-review-20260815.md)：当前 10 个启用状态与 6 个备用候选的可编辑选择审核表。
- [music-ai-prompts-20260813.md](music-ai-prompts-20260813.md)：本轮 Loop 原始素材的提示词与生成记录。
- [music-remake-g0-g3-20260816.md](music-remake-g0-g3-20260816.md)：G0—G3 五首制重制结构、已作废方向、三首固定审美参照，以及当前 G0 钢琴主导的 v04 日常校准提示词与防截尾制作要求；校准通过前不展开其余曲目，也不替换运行时。
- [sound-effects-design-20260817.md](sound-effects-design-20260817.md)：全 28 个叙事单元的环境声、同步 Foley、结构性声音转场、复用资产库、制作优先级与运行时接入建议。
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
