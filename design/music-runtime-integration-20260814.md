# 《三十三》配乐运行时接入记录（2026-08-16 修订）

## 当前结论

运行时不再按镜头或短台词段频繁切歌，而采用少数几个可循环的长音乐状态。`story.json` 的 312 条台词中，295 条拥有常驻 BGM 映射，G4-01 的 9 条由旧作原片声音覆盖；G1-05 至 G1-06 的 8 条主动无配乐。G1 表演曲在回放开始时渐隐，旧作最后一句结束后则由原片声音与夜间返程画面同步渐隐。

- 已处理曲库：16 个完整原曲 Ogg，其中 15 个循环资产、1 个固定 10 秒事件层。
- 实际启用：9 个状态，其中 8 个长循环 BGM、1 个固定 10 秒检索事件。
- 保留但不启用：`MUS-01`、`MUS-03A`、`MUS-07A`、`MUS-08A`、`MUS-08B`、`MUS-09A`、`MUS-09B`。文件不删除，供后续听审或替换使用。
- 未进入制作曲库：`MUS-06A`、重复的 `MUS-07C`、`MUS-03C` 的 source 版与 Theme Seed。
- 主动无配乐段：`G1-05-01`—`G1-06-06` 的回放与收束，以及 `G5-05-04` 结束后的无人灯塔空镜。

## 最终运行时映射

| 章节状态 | Cue | 台词范围／事件 | 播放方式 |
| --- | --- | --- | --- |
| G0 梦中提问 | `MUS-03C` | `G1-01-D01`—`G1-01-D18` | 完整 60.029 秒原曲循环；末句后淡出 |
| G0 醒来至公司地库 | `MUS-03B` | `G1-01-02`—`G1-01-24` | 黑场停顿后先淡入晨景，再启动音乐与旁白，持续到第一章标题前 |
| G1 园区、加班与创作表演 | `MUS-02` | `G1-02-01`—`G1-04-06` | 使用 `A_Clear_View_2026-08-17T054928.mp3` 的完整转码；三个单元连续播放 |
| G1 回放与收束 | 无 | `G1-05-01`—`G1-06-06` | 进入回放时将 `MUS-02` 用 2.8 秒渐隐，之后保持无配乐 |
| G2 最后一次迂回 | `MUS-04` | `G2-01-01`—`G2-06-15` | 整章一个 Loop |
| G3 同行者与检索前 | `MUS-06B` | `G3-01-01`—`G3-03-04` | 连续 Loop |
| G3 十秒检索 | `MUS-05A` | `G3-03-04` 推进后固定事件 | 10 秒一次性事件，接管当前底乐 |
| G3 找回来与开始 | `MUS-05B` | `G3-03-05`—`G3-06-07` | 后半章一个 Loop，不再另切 `MUS-06B` |
| G4 三十一岁旧作 | 原片提问及其原始配乐 | `G4-01-01`—`G4-01-09` | 前 56.5 秒自动驱动字幕与四幕画面，随后用约 1.6 秒音画同步渐隐；110.7 秒来源文件的后半尾奏不进入后文 |
| G4 三十三岁道路至画面成立 | `MUS-07B` | `G4-02-01`—`G4-05-06`，含 `SHOT-61` 下山收束旁白 | G4 常规 BGM 全程一个 Loop，不在章内切换 |
| G5 主动失去与走向灯塔 | `MUS-09C` | `G5-01-01`—`G5-05-04` | G5 全章连续播放，最终空灯塔停驻开始时淡出 |

这套结构只在大的叙事状态变化时切换：G1 进入回放后退到环境声与旁白；G2 整章不换曲；G4 的常规 BGM 不再章内切换；G3 除固定检索事件外只分前后两段；G5 全章不换曲。章节选择或读档从任意台词进入时，直接恢复该台词所属的音乐或无配乐状态。

## 音频制作

- 原始生成 MP3：`/Users/dtysky/Downloads/b33/music/`
- 48 kHz／24-bit WAV 母版：`/Users/dtysky/Downloads/b33/music/runtime-masters/`
- Godot Ogg：`game/assets/audio/music/`
- 制作清单与测量结果：`game/assets/audio/music/build-report.json`
- 可复现制作脚本：`game/tools/build_music.mjs`
- 连续循环校验：`game/tools/verify_music.mjs`

全部运行时 Ogg 都从原始 MP3 的 0 秒开始并保留完整 60／120 秒时长；不再使用任何源区段起点、片头片尾裁切或首尾交叉拼接。构建只做响度统一和格式转换。常规音乐约为 `-21.5 LUFS`，梦境和检索层约为 `-23 LUFS`；`Music` 总线再降低 3 dB，为未来语音与环境声留余量。

## 运行时行为

- `MusicDirector` 使用两个播放器完成恢复、淡入、交叉淡化与硬切。
- `G1-01-D18` 将 `MUS-03C` 用 1.35 秒渐隐，黑场保留停顿；晨景用 1.16 秒淡入后启动 `MUS-03B`，再进入 `G1-01-02` 旁白。`G1-05-01` 不再切换新曲，而是将 `MUS-02` 用 2.8 秒渐隐。
- 正常换章时，旧 BGM 在上一章画面上用约 2.2 秒渐弱；约 5.2 秒的章节卡保持无新章音乐，卡片溶出并显露新场景的同一时刻淡入该章 BGM。场景内状态切换不使用这段长留白。
- G3 的检索音乐只在 10 秒证据演出真正开始时触发；进入 `G3-03-05` 后交叉进入 `MUS-05B`。
- G4-01 不启动 `MUS-07B`，由 `VoiceSequencePlayer` 播放旧作提问与原作配乐，并按九个时间码自动推进字幕与画面。56.5 秒处开始约 1.6 秒音画同步渐隐，深灰黑停留约 0.32 秒，再用约 1.25 秒显露 G4-02；`MUS-07B` 随三十三岁画面启动，玩家在显露完成后恢复操作。章节选择器直接进入 G4-02 时仍立即使用 `MUS-07B`。
- `MUS-07B` 从 G4-02 贯穿至夜间下山，不在 G4-04、G4-05 或无台词下降镜头处换曲。
- `MUS-09C` 从 G5-01 第一条台词覆盖至 G5-05 最后一条台词，章内不再切换；只在最终无人灯塔停驻开始时淡出。
- 返回标题页会硬停音乐；运行时建立 `Voice`、`Ambience`、`SFX`、`Music` 四条子总线。

## 验证

已通过：

```bash
cd game
node tools/verify_music.mjs
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script res://tests/validate_story.gd
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script res://tests/music_director_test.gd
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script res://tests/music_sequence_test.gd
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script res://tests/voice_sequence_test.gd
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script res://tests/smoke_test.gd
```

验证覆盖：16 个完整、无时间编辑的标准化音乐资产，15 个循环资产连续解码五轮，277 条 BGM 台词、9 条旧作原声台词与 8 条主动无配乐的 G1 台词均无双重播放；另验证 G1 回放渐隐、G2 长状态恢复、G3 检索交接、G4-01 自动字幕与年龄跳切音画渐隐、`MUS-07B` 贯穿 G4 常规段、`MUS-09C` 贯穿 G5，以及最终灯塔退场。
