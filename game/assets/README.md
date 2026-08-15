# Runtime Assets

本目录只存放经过审核、会被 Godot 直接加载的最终资产。

镜头母帧、拆层和最终动态 CG 统一按 3840 × 2160 交付；Godot 内部界面仍使用 1920 × 1080 逻辑坐标。

G0 当前处于试玩阶段，六张已选 CG 草稿已导出为 3840 × 2160 WebP 并临时放入 `shots/shot-01/`；它们可以随审稿继续覆盖，不代表最终镜头编号已经锁定。

G1 当前的审核候选已导入 `shot-02`、`shot-03`、`shot-04` 与 `shot-19`：园区和工位严格使用既定五人团队；山地 VLOG 使用 `H-LOOK-05` 与三脚架摄影包；黑场近景包含闭眼、睁眼两个差分。运行时文件只保留当前最终候选，不存放被淘汰的生成历史。

## 目录

- `shots/`：按 `shot-xx/` 存放母帧、人物层、前景、差分和遮罩。
- `evidence/`：裁切后的聊天、检索等画中叙事原件。
- `video/`：定稿并转码为 `.ogv` 的动态 CG。
- `ui/`：标题页、文本框、快捷栏、历史和设置界面。
- `fx/`：像素遮罩、光影、天气和其他透明特效。
- `audio/`：音乐、环境声、音效和语音。
- `fonts/`：游戏内字体及其授权说明。

原始照片、视频和录屏放在 `../../art/references-local/`，PSD 等工程文件放在 `../../art/workfiles/`，AI 候选稿放在 `../../art/generated/`。

`audio/music/` 只存放 Godot 直接加载的成品 Ogg、导入元数据与构建报告。AI 平台原始 MP3 和 24-bit WAV 母版不重复放入运行时目录；它们保存在 `/Users/dtysky/Downloads/b33/music/` 及其 `runtime-masters/` 子目录，可由 `game/tools/build_music.mjs` 重建。

`audio/voice/` 存放会由台词时间轴直接播放的配音或原片声音。当前 `g4-01-thirty-one.ogg` 来自三十一岁旧作的正式视频：前 56.5 秒保留提问与原始配乐，之后只保留分离后的人声外配乐直到自然收束，总长 110.7 秒。九个字幕入点和跨场交接点记录在 `game/content/voice_sequences.json`；后续配音沿用同一数据结构，不把时间码写死在章节脚本中。
