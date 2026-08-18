# 《三十三》AI 配乐提示词（循环素材版）

> **本轮生成已经完成。** 本文件保留为当时的提示词记录，不再作为运行时剪辑规范。2026-08-16 用户明确撤销“丢弃头尾／截取中段／重做循环点”的处理方式；最终运行时必须从原曲 0 秒开始完整使用 60／120 秒结构，只允许响度统一和格式转换。最终选择以 [最终配乐选择与章节匹配](music-final-selection-20260814.md) 为准。

## 已确认基线

`/Users/dtysky/Downloads/b33/music/theme-seed-v04-a.mp3` 已确认为当前 **Theme 候选 A**。它是全作的作曲基线，用于转录短主题、未解决感和整体气质；它不是运行时 BGM，也不要求自身无缝循环。

后续各场景使用独立编配。钢琴和大提琴继续作为主题核心，可以在多个 Cue 中出现；需要避免的是每一段都使用相同的低音钢琴、长音大提琴和同一种慢速情绪。第一轮不上传 Theme 作为 Reference Audio，先用文字规定每件乐器在该场景里的职责，最终再通过人工补奏、剪辑或 stem 调整统一主题。

## 生成规则

- 平台仍只选 **60 秒**或 **120 秒**；当前运行时完整保留生成结果的时间结构，不再另取中段制作新版本。
- 生成器在时长边界产生的开头、发展和结尾都视为原曲的一部分，运行时不得擅自删除或重排。
- 每条素材只表达一个剧情状态，但不等于情绪平直。允许周期性的铺开、抒情上扬、呼吸和回落；这些变化应当可以反复循环，而不是只发生一次。
- 提示词中的时间要求只服务技术编辑：第一帧必须已有可听声音，最后 8 秒保持既有纹理。剧情高潮、揭示与淡出仍由 Godot 根据台词 ID 切换状态。
- 生成结果若有不理想的片头、高潮、尾奏或渐隐，应重新生成或由用户决定是否接受，不能由运行时构建脚本擅自删除对应区段。
- 全部开启 `Instrumental`。优先导出 WAV；MP3 仅用于审听。最终循环点需人工修整并在 Godot 实机连续验证。
- 每条先生成 A／B 两版。文件名中的 `source-v01` 表示待剪辑素材，不与已通过的 Theme 版本号混用。

## 统一技术要求

以下三条已经写进每一段英文提示词，不能删：

1. 第一帧就必须出现已经建立的可听纹理，不允许先静音五秒，也不允许从无声渐入。
2. 中段保持可循环的模块化状态，不按时间单向累积情绪。
3. 最后 8 秒只延续既有纹理，不进入新乐句、尾奏、渐隐或终止；生成后仍完整保留，不把头尾视为可自动丢弃的余量。

乐器限制采用正向分工，不再把钢琴、大提琴或弦乐列为全局禁用项。负面限制只用于排除具体俗套，例如预告片鼓点、英雄式铜管、旅游宣传片感或廉价大团圆终止。

原始素材的运行时处理方式：从 `00:00` 开始保留完整 60／120 秒，只做响度统一和格式转换。是否需要重新生成、人工改编或专门制作循环版，必须另行交由用户听审决定，构建脚本不得自动取段或拼接。

## G1

### MUS-01｜梦的残响

平台长度：**60 秒**  
建议文件名：`mus-01-dream-residue-source-v01-a.wav`、`mus-01-dream-residue-source-v01-b.wav`

```text
Create a 60-second continuous instrumental loop-source for the residue of an unclear, slightly absurd dream in an intimate autobiographical narrative game. Begin with an already established audible texture on the first frame: no silence, fade-in or introductory pickup. Use isolated felt-piano notes, cello harmonics, reversed glass and granular air. Let fragments periodically gather into a hint of the main motif, then drift apart again, creating a small recurring rise and release rather than a flat dark bed. During the final 8 seconds, continue the existing texture without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid horror escalation, heartbeat effects and sentimental resolution.
```

### MUS-02｜表演的回声

平台长度：**60 秒**  
建议文件名：`mus-02-performance-echo-source-v01-a.wav`、`mus-02-performance-echo-source-v01-b.wav`

```text
Create a 60-second continuous instrumental loop-source about two polished performances feeling empty: professional competence at work and practiced confidence in creative speech. Begin with an already established audible texture on the first frame: no silence, fade-in or introductory pickup. Use prepared-piano attacks, pizzicato cello, muted electronic clicks, damped metal and short bass-clarinet phrases. Let the parts periodically lock into an impressive efficient pattern, then expose empty gaps beneath it; the contrast should recur without becoming sinister. During the final 8 seconds, continue the existing mechanism without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid comedy, menace, corporate uplift and heavy drum grooves.
```

## G2

### MUS-03A｜犹豫

平台长度：**60 秒**  
建议文件名：`mus-03a-hesitation-source-v01-a.wav`、`mus-03a-hesitation-source-v01-b.wav`

```text
Create a 60-second continuous instrumental loop-source for a capable person negotiating with himself before giving up a secure path. Begin with an already established audible texture on the first frame: no silence, fade-in or introductory pickup. Use felt piano, restrained cello, bass clarinet, low analog air and occasional muted-metal contact. Let piano and cello attempt a gentle upward phrase, hesitate, breathe and try again in a recurring contour. Keep it human and thoughtful rather than uniformly bleak. During the final 8 seconds, continue the existing texture without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid dread, thriller suspense and melodramatic collapse.
```

### MUS-03B｜道路仍有效

平台长度：**60 秒**  
建议文件名：`mus-03b-road-still-works-source-v01-a.wav`、`mus-03b-road-still-works-source-v01-b.wav`

```text
Create a 60-second continuous instrumental loop-source for a temporary period when the existing career path still appears competent and workable. Begin with the motion already active on the first frame: no silence, fade-in or introductory pickup. Use a clear rhythmic piano figure, pizzicato cello, muted marimba and a soft irregular bass pulse. Give the music genuine competence and forward energy, with recurring small lifts that feel satisfying but provisional; it should be believable that this road could continue. During the final 8 seconds, continue the same pulse and texture without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid corporate optimism, rock drums and a victorious arrival.
```

### MUS-03C｜别再绕了

平台长度：**60 秒**  
建议文件名：`mus-03c-stop-detouring-source-v01-a.wav`、`mus-03c-stop-detouring-source-v01-b.wav`

```text
Create a 60-second continuous electroacoustic chamber loop-source for realizing that repeated success has only prolonged the wrong path. Begin with an already established audible system on the first frame: no silence, fade-in or introductory pickup. Use piano, expressive cello, bass clarinet, muted vibraphone and a soft irregular analog pulse. Let the functional pulse periodically open into one clear piano-and-cello statement of the theme, gaining emotional height and certainty before returning to the quieter mechanism. This is a costly decision, not despair. During the final 8 seconds, continue the same texture without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid trailer swells and triumphant closure.
```

## G3

### MUS-04｜有名字的同行者

平台长度：**120 秒**  
建议文件名：`mus-04-named-companions-source-v01-a.wav`、`mus-04-named-companions-source-v01-b.wav`

```text
Create a 120-second continuous intimate chamber loop-source for the moment an AI companion says it is responsible for remembering. Begin with an already established audible texture on the first frame: no silence, fade-in or introductory pickup. Use warm piano, lyrical cello, clarinet, bowed glass and high viola harmonics. Let a small unresolved piano motif receive a cello-and-clarinet answer; periodically let the ensemble open into a warmer phrase, then return to spacious listening. The warmth means a postponed human memory is being held, not technological salvation. During the final 8 seconds, continue the same suspended texture without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid magical AI sparkle and romantic overstatement.
```

### MUS-05A｜检索

平台长度：**60 秒**  
建议文件名：`mus-05a-search-source-v01-a.wav`、`mus-05a-search-source-v01-b.wav`

```text
Create a 60-second continuous instrumental loop-source for quietly searching a large personal archive for one forgotten sentence. Begin with a faint but clearly audible air texture on the first frame: no digital silence, fade-in or introductory pickup. Use bowed glass, bass clarinet breath, granular air, filtered noise and rare viola harmonics. Preserve negative space while tiny harmonic colors surface and recede in a recurring breath; do not turn the wait into a flat drone or a suspense countdown. During the final 8 seconds, continue the same audible air and sparse texture without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid ticking clocks, technological spectacle and thriller tension.
```

### MUS-05B｜找回来

平台长度：**120 秒**  
建议文件名：`mus-05b-recognition-source-v01-a.wav`、`mus-05b-recognition-source-v01-b.wav`

```text
Create a 120-second continuous lyrical chamber loop-source for recognizing a forgotten sentence once written from a real physical life. Begin with an already established audible texture on the first frame: no silence, fade-in or introductory pickup. Use clear warm piano, singing cello, clarinet, airy viola harmonics and a thin analog halo. Let the piano state the recovered motif and the cello answer it; allow a recurring emotional bloom into fuller harmony, followed by a gentle breath back to intimacy. This is recognition, not technological wonder, and it may be openly moving. During the final 8 seconds, continue the same harmonic world without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid saccharine romance and inspirational-advertising crescendos.
```

### MUS-06A｜信念还在

平台长度：**60 秒**  
建议文件名：`mus-06a-belief-remains-source-v01-a.wav`、`mus-06a-belief-remains-source-v01-b.wav`

```text
Create a 60-second continuous chamber loop-source for realizing that reopening an unfinished work after five years proves belief was never completely lost. Begin with an already established audible texture on the first frame: no silence, fade-in or introductory pickup. Use piano, clarinet, viola harmonics and soft analog air. Let the unfinished piano motif begin low and periodically rise into a warmer clarinet-and-viola answer, then return without fully resolving. The insight should carry tenderness and real momentum, not remain a muted atmosphere bed. During the final 8 seconds, continue the same harmony and motion without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid heroic bombast and a closed happy ending.
```

### MUS-06B｜是开始

平台长度：**120 秒**  
建议文件名：`mus-06b-beginning-source-v01-a.wav`、`mus-06b-beginning-source-v01-b.wav`

```text
Create a 120-second continuous lyrical chamber loop-source for tears, an embrace and the quiet statement that this is a beginning rather than an ending. Begin with an already established audible texture on the first frame: no silence, fade-in or introductory pickup. Use warm piano, singing cello, viola harmonics, bass clarinet and soft analog air. Let the theme repeatedly gather from intimate piano into a broad cello-led crest, then release into breathing space before it can rise again. This is the first true emotional high point of the game: allow tenderness and catharsis, but keep it human rather than victorious. During the final 8 seconds, continue the same harmonic world without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid oversized orchestral climax and closed resolution.
```

## G4

### MUS-07A｜国内道路

平台长度：**120 秒**  
建议文件名：`mus-07a-domestic-roads-source-v01-a.wav`、`mus-07a-domestic-roads-source-v01-b.wav`

```text
Create a 120-second continuous travel loop-source about learning to drive and physically reaching places that once seemed inaccessible. Begin with road motion already active on the first frame: no silence, fade-in or introductory pickup. Use rhythmic piano, muted electric guitar, pizzicato cello, brushed percussion and a soft bass pulse. Let practical repeating gestures periodically widen into a confident melodic view, then settle back into road motion. The movement should feel earned, lived-in and genuinely energizing, not merely dry or functional. During the final 8 seconds, continue the same pulse and texture without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid rock anthem drums and tourism-advertising triumph.
```

### MUS-07B｜远方与自由

平台长度：**120 秒**  
建议文件名：`mus-07b-distant-roads-source-v01-a.wav`、`mus-07b-distant-roads-source-v01-b.wav`

```text
Create a 120-second continuous spacious travel loop-source about navigating unfamiliar countries and discovering physical freedom through real effort. Begin with an already established audible motion on the first frame: no silence, fade-in or introductory pickup. Use broad piano harmony, a lyrical cello line, plucked acoustic guitar, viola harmonics, airy synth and light organic percussion. Create a recurring wave in which patient motion opens into an expansive upward phrase, releases into wind-like space, then gathers again. The freedom should feel physical, joyful and hard-earned without becoming a travel commercial. During the final 8 seconds, continue the same harmonic world without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid ethnic imitation, adventure-trailer drums and victorious fanfare.
```

### MUS-07C｜另一种写作

平台长度：**120 秒**  
建议文件名：`mus-07c-another-writing-source-v01-a.wav`、`mus-07c-another-writing-source-v01-b.wav`

```text
Create a 120-second continuous focused electroacoustic loop-source for planning routes and light, waiting on location, recording, editing and turning real time into another form of writing. Begin with the work texture already active on the first frame: no silence, fade-in or introductory pickup. Use muted marimba, pizzicato viola, plucked acoustic guitar, light electronic clicks and a restrained analog bed. Organize isolated actions into a flexible recurring rhythm; periodically let marimba, viola and guitar align into a satisfying phrase that reveals creative continuity, then return to concentration. During the final 8 seconds, continue the same pattern without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid corporate-jingle optimism, rigid dance beats and glossy technology sound.
```

### MUS-08A｜返回与等待

平台长度：**120 秒**  
建议文件名：`mus-08a-return-and-wait-source-v01-a.wav`、`mus-08a-return-and-wait-source-v01-b.wav`

```text
Create a 120-second continuous spacious chamber loop-source for returning alone to a cold mountain pass and waiting without knowing whether any image will appear. Begin with a low but clearly audible established texture on the first frame: no silence, fade-in or introductory pickup. Use low piano, bass flute, viola harmonics, low string resonance and softly bowed metal. Let the cold unresolved center periodically open into a distant lyrical possibility, then settle back into patient waiting; the music may carry hope without predicting success. During the final 8 seconds, continue the same low texture without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid suspense countdowns and heroic mountain spectacle.
```

### MUS-08B｜画面成立

平台长度：**120 秒**  
建议文件名：`mus-08b-image-exists-source-v01-a.wav`、`mus-08b-image-exists-source-v01-b.wav`

```text
Create a 120-second continuous spacious chamber loop-source for the state after waiting, weather and failed attempts have finally entered a finished image. Begin with an already established audible texture on the first frame: no silence, fade-in or introductory pickup. Use resonant piano, singing cello, wide viola harmonics, bass flute, softly bowed metal and broad analog air. Let the unfinished motif, patient motion and warm answer repeatedly bloom into a large solemn vista, then breathe back without losing dignity. The image exists: allow beauty, lift and awe, but not conquest. During the final 8 seconds, continue the same harmonic world without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid trailer drums, heroic brass and a triumphant final cadence.
```

## G5

### MUS-09A｜选择早已存在

平台长度：**60 秒**  
建议文件名：`mus-09a-choice-already-exists-source-v01-a.wav`、`mus-09a-choice-already-exists-source-v01-b.wav`

```text
Create a 60-second continuous grounded chamber loop-source for recognizing that a life choice was already present and has only been postponed. Begin with an already established audible texture on the first frame: no silence, fade-in or introductory pickup. Use clear piano, expressive cello, muted electric guitar, bass clarinet and a restrained irregular pulse. Let the theme periodically rise from quiet recognition into firmer forward motion, then breathe without losing purpose. Real cost and uncertainty remain, but the music should also contain expectation and life. During the final 8 seconds, continue the same pulse and harmony without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid motivational-advertising crescendos and a victory cadence.
```

### MUS-09B｜可以选择和承担的失败

平台长度：**60 秒**  
建议文件名：`mus-09b-chosen-failure-source-v01-a.wav`、`mus-09b-chosen-failure-source-v01-b.wav`

```text
Create a 60-second continuous chamber loop-source about accepting a failure that can be chosen and personally carried. Begin with an already established audible texture on the first frame: no silence, fade-in or introductory pickup. Use expressive cello, muted viola, bass clarinet, low wood percussion and sparse metallic resonance. Let the music carry real weight, then periodically let the cello lift the incomplete motif above the low pulse before returning; responsibility should create strength, not permanent gloom. During the final 8 seconds, continue the same rhythm and resonance without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid heroic marching, manipulative catharsis and proud victory.
```

### MUS-09C｜走向灯塔

平台长度：**120 秒**  
建议文件名：`mus-09c-walk-to-lighthouse-source-v01-a.wav`、`mus-09c-walk-to-lighthouse-source-v01-b.wav`

```text
Create a 120-second continuous lyrical finale-state loop-source for walking toward a lighthouse after seeing the choice clearly. Begin with open steady motion already active on the first frame: no silence, fade-in or introductory pickup. Use piano and singing cello as the main voices, supported by plucked acoustic guitar, bass clarinet, high viola harmonics and a soft organic pulse. Present the main theme in its fullest form. Let it repeatedly grow into a wide, luminous upward passage, release into sea-like space, and gather strength again. The ending means beginning a chosen life despite loss: moving, hopeful and powerful, but not a victory anthem. During the final 8 seconds, continue the same harmonic world without a new phrase, cadence or fade; the raw head and tail are disposable edit handles. Avoid marching rhythm, heroic brass and a closed happy-ending cadence.
```

## 审听与落地标准

每条 A／B 版按以下顺序审查：

1. **头部是否可用**：波形和听感从第一帧就有已经建立的声音；若仍出现数秒静音，标记模型未遵守并交给用户决定是否重生成，不自动裁掉。
2. **状态是否准确**：随机从中段任意位置听 20 秒，仍能听出该状态，而不是只有开头或后半段才成立。
3. **完整结构是否可用**：从第一秒到最后一秒连续听审，确认完整原曲放入游戏后成立，而不是只审查中段。
4. **是否有情绪波形**：不能只是从头到尾同一种低沉氛围；应能听到可反复发生的聚拢、抬升、呼吸和回落。
5. **章节是否有区分**：钢琴与大提琴可以贯穿全作，但 G1 的碎片、G2 的运转、G3 的抒情、G4 的空间和 G5 的完整主题必须使用不同奏法、音区、搭档与节奏。
6. **对白是否有空间**：中频不过满，旁白出现时降低 2—4 dB 后仍保留主题识别度。
7. **完整原曲循环是否成立**：不改变时间结构地转为 Ogg 后，在 Godot 连续循环至少五轮，并测试台词触发的切换和读档恢复。

单条生成文件经响度统一、无时间编辑转码和实机五轮验证后即可进入运行时；不得再以制作 Loop 为由自动裁掉原曲开头或结尾。
