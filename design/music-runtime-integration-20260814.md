# 《三十三》配乐运行时接入记录（2026-08-15 修订）

## 当前结论

运行时不再按镜头或短台词段频繁切歌，而采用少数几个可循环的长音乐状态。除最终无人灯塔停驻外，`story.json` 的 294 条台词都有音乐覆盖：285 条拥有一个常驻 BGM 映射，G4-01 的 9 条由旧作原片声音覆盖。旧作最后一句结束后，原片声音与夜间返程画面同步渐隐；短暂停黑后，G4-02 白日驾驶画面与常驻 BGM 一起建立，两段音乐不再跨场。

- 已处理曲库：16 个 Ogg，其中 15 个可无缝循环、1 个固定 20 秒事件层。
- 实际启用：12 个状态，其中 11 个长循环 BGM、1 个固定 20 秒检索事件。
- 保留但不启用：`MUS-03A`、`MUS-03C`、`MUS-07A`、`MUS-08A`。文件不删除，供后续听审或替换使用。
- 未进入制作曲库：`MUS-06A`、重复的 `MUS-07C`、旧版 `MUS-03C` 与 Theme Seed。
- 唯一主动无配乐段：`G5-05-04` 结束后的无人灯塔空镜。它不是台词区间，而是章节演出的最终停驻。

## 最终运行时映射

| 章节状态 | Cue | 台词范围／事件 | 播放方式 |
| --- | --- | --- | --- |
| G0 梦中提问 | `MUS-01` | `G1-01-01` | 43.73 秒无缝 Loop |
| G0 醒来至公司地库 | `MUS-03B` | `G1-01-02`—`G1-01-24` | 与梦境音乐交叉切换，持续到第一章标题前 |
| G1 园区、加班与创作表演 | `MUS-02` | `G1-02-01`—`G1-04-06` | 保持此前选曲，三个单元连续播放 |
| G1 倒放与最终决定 | `MUS-03B` | `G1-05-01`—`G1-06-06` | 复用 G0 后段音乐；Cue 数据用多个区间表达，不复制音频状态 |
| G2 最后一次迂回 | `MUS-04` | `G2-01-01`—`G2-06-15` | 整章一个 Loop |
| G3 同行者与检索前 | `MUS-06B` | `G3-01-01`—`G3-03-04` | 连续 Loop |
| G3 二十秒检索 | `MUS-05A` | `G3-03-04` 推进后固定事件 | 20 秒一次性事件，接管当前底乐 |
| G3 找回来与开始 | `MUS-05B` | `G3-03-05`—`G3-06-07` | 后半章一个 Loop，不再另切 `MUS-06B` |
| G4 三十一岁旧作 | 原片提问及其原始配乐 | `G4-01-01`—`G4-01-09` | 前 56.5 秒自动驱动字幕与四幕画面，随后用约 1.6 秒音画同步渐隐；110.7 秒来源文件的后半尾奏不进入后文 |
| G4 道路与创作 | `MUS-07B` | `G4-02-01`—`G4-03-11` | 两个单元共用一个长状态 |
| G4 返回、等待与画面成立 | `MUS-08B` | `G4-04-01`—`G4-05-05`，含 `SHOT-61` 下山 | 下山无台词演出中继续播放 |
| G5 选择与憧憬 | `MUS-09A` | `G5-01-01`—`G5-02-05` | 连续 Loop |
| G5 现实代价 | `MUS-09B` | `G5-03-01`—`G5-04-02` | 连续 Loop |
| G5 走向灯塔 | `MUS-09C` | `G5-04-03`—`G5-05-04` | 最终空灯塔停驻开始时淡出 |

这套结构只在大的叙事状态变化时切换：G2 整章不换曲，G4 只换一次，G3 除固定检索事件外只分前后两段，G5 分为选择、代价与决定三段。`MUS-03B` 同时覆盖两个不连续区间；章节选择或读档从任意台词进入时，仍直接恢复该台词所属的循环状态。

## 音频制作

- 原始生成 MP3：`/Users/dtysky/Downloads/b33/music/`
- 48 kHz／24-bit WAV 母版：`/Users/dtysky/Downloads/b33/music/runtime-masters/`
- Godot Ogg：`game/assets/audio/music/`
- 制作清单与测量结果：`game/assets/audio/music/build-report.json`
- 可复现制作脚本：`game/tools/build_music.mjs`
- 连续循环校验：`game/tools/verify_music.mjs`

`MUS-01` 已从原先 28 秒一次性文件重制为 43.73 秒 Loop，源区段为 5.50—53.23 秒，首尾使用 4 秒等功率交叉；它不会在玩家尚未推进时自行结束。其余 14 个候选 Loop 同样从稳定区段制作首尾交叉。所有 Loop 文件约为 `-21.5 LUFS`，梦境和检索层约为 `-23 LUFS`；`Music` 总线再降低 3 dB，为未来语音与环境声留余量。

## 运行时行为

- `MusicDirector` 使用两个播放器完成恢复、淡入、交叉淡化与硬切。
- `G1-01-02` 从梦中提问交叉进入 `MUS-03B`；`G1-05-01` 再从 `MUS-02` 交叉切回同一首曲子。
- 正常换章时，旧 BGM 在上一章画面上用约 2.2 秒渐弱；约 5.2 秒的章节卡保持无新章音乐，卡片溶出并显露新场景后再延迟约 0.9 秒，随后淡入该章 BGM。场景内状态切换不使用这段长留白。
- G3 的检索音乐只在 20 秒证据演出真正开始时触发；进入 `G3-03-05` 后交叉进入 `MUS-05B`。
- G4-01 不启动 `MUS-07B`，由 `VoiceSequencePlayer` 播放旧作提问与原作配乐，并按九个时间码自动推进字幕与画面。56.5 秒处开始约 1.6 秒音画同步渐隐，深灰黑停留约 0.32 秒，再用约 1.25 秒显露 G4-02；`MUS-07B` 随三十三岁画面启动，玩家在显露完成后恢复操作。章节选择器直接进入 G4-02 时仍立即使用 `MUS-07B`。
- `MUS-08B` 贯穿 G4 的夜间下山，不在无台词镜头开始时退出。
- `MUS-09C` 只在最终无人灯塔停驻开始时淡出。
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

验证覆盖：16 个标准化音乐资产、15 个 Loop 连续解码五轮、285 条 BGM 台词与 9 条旧作原声台词无音乐空洞或双重播放、`MUS-03B` 多区间恢复、G2 长状态恢复、G3 检索交接、G4-01 自动字幕与年龄跳切音画渐隐、G4 下山不断乐，以及最终灯塔退场。最终仍需从章节选择器连续听审循环重复感、配乐音量和两个大段之间的情绪匹配。
