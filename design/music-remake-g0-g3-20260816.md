# 《三十三》G0—G3 配乐重制方案（2026-08-16）

## 当前状态

本方案已经确认曲目结构。G1 表演段已于 2026-08-17 通过人工听审并替换运行时音频；G0、G2、G3 仍在新素材完成生成、人工听审与实机验收后再替换。

本轮最终只保留五个音乐资产：G0、G1、G2、G3 各一首常驻 BGM，G3 检索使用一首十秒事件曲。G3 检索结束后回到同一首 G3 主曲，不增加“辨认”“信念”“开始”等额外曲目。

## 为什么五首足够

G0 至 G3 的主要结构变化发生在章与章之间，而不是每几个镜头之间。每章一首可以建立清楚的章节身份，也适合玩家自行控制阅读速度。检索是唯一具有固定时长和明确动作边界的事件，因此单独拥有一首十秒 Cue。

曲目数量不是上一轮失配的根源。第一版重制提示词随后又证明，“常规独立叙事游戏／视觉小说 BGM”同样不是正确答案：它虽然避开了实验声音，却生成了过于温暖、规整、轻巧和功能化的库存音乐，与作品的成年私人叙事、冷静自审和硬边像素影像不一致。

## 最终运行时结构

| 新 Cue | 剧情范围 | 功能 | 运行方式 |
| --- | --- | --- | --- |
| `MUS-R01` | `G1-01-D01`—`G1-01-D18` 与 `G1-01-02`—`G1-01-24`（序章 G0） | 梦境提问与三十三岁生日清晨的日常惯性 | 当前运行时保留梦境／现实两种音色：`MUS-03C` 在末句后退出，黑场与晨景缓冲后再进入 `MUS-03B` |
| `MUS-R02` | `G1-02-01`—`G1-04-06` | 工作表演与创作表演 | 一首长 Loop；进入 G1-05 回放时渐隐，之后保持无配乐 |
| `MUS-R03` | `G2-01-01`—`G2-06-15` | 团队建立、努力、反复延期、组织失序与最终失望 | 一首长 Loop；章内不换曲 |
| `MUS-R04` | `G3-01-01`—`G3-03-04`；`G3-03-05`—`G3-06-07` | 有名字的同行者、身体经验被辨认、信念仍在与开始行动 | 同一首长 Loop；检索前后均使用 |
| `MUS-R05` | G3 固定十秒检索演出 | 从二十万字中寻找一句旧作原文 | 十秒一次性 Cue；结束后回到 `MUS-R04` |

G3 的实现应把 `MUS-R04` 视为同一音乐资产。检索可以暂时接管 Music 总线，也可以在主曲降低后叠加；最终选择以实机听感为准。无论采用哪种实现，检索结束后都不得出现第六首“情绪解释曲”。

## 第一版重制提示词已作废

2026-08-16 的第一次试生成使用了“conventional indie narrative game or visual novel BGM”作为风格锚点，并强调温暖钢琴、电钢琴、马林巴、木吉他、轻鼓组和规整乐句。实听确认这个方向与游戏整体气质不符，**不得继续使用该版五条提示词生成或接入**。

问题不在于音乐“不够正常”，而在于它把交互形式误当成了音乐类型。《三十三》是视觉小说，但并不需要典型视觉小说音乐；它的声音身份应来自成年私人纪录、都市生活的低温、数字媒介与真实身体之间的张力，以及硬边像素影像，而不是“温暖、轻巧、陪伴阅读”的类型默认值。

## 第二版赛博朋克方向已作废

第二版用“现代像素叙事”“人／系统双层”和模拟合成器脉冲解释作品，实听直接滑向赛博朋克。这个错误来自再次把视觉媒介与剧情概念翻译成固定音色：像素画面不要求 chiptune，AI 与“系统”也不要求合成器、电子鼓或数字颗粒。

后续不得再从像素、AI、虚拟机、系统等词推导配器。音乐只需要承载人物正在经历的时间、情感和思想。

## 已确认的审美参照

用户明确指定以下三首：

- 《素晴らしき日々》`夜の向日葵`
- 《素晴らしき日々》`夏の大三角`
- 《サクラノ詩》`風の筆射す春日花抄`

只提取三首共有的高层作曲语言，不复刻具体旋律、和弦排列或标志性乐句：

- 音乐以能被记住、能够歌唱的完整旋律为中心，不以纹理、音效或节拍概念为中心。
- 钢琴与指弹原声吉他负责流动和留白，小规模弦乐只在乐句需要时托起旋律。
- 明亮的春夏空气、清澈日常与隐约哀感同时存在；沉重命题不靠阴暗音色表达。
- 和声可以保持大调表面，但使用 `add9`、`maj7`、挂留音、经过减和弦与少量同主音小调借用制造距离感。
- 情绪随旋律自然铺开和回返，不靠鼓点推进、电子脉冲、电影式渐强或突然高潮。
- 编配透明、声部数量有限，但不是平直的氛围床；BGM 可以拥有清楚而克制的抒情存在感。

`theme-seed-v04-a.mp3` 暂停作为 Reference Audio。先确认新审美语言，再决定是否只保留其中可兼容的主题轮廓；不得让旧 Seed 把新样片重新拉回此前的音色与结构。

## G0 v03 试听结论

- 钢琴主导版比原声吉他主导版更接近作品，G0 后续固定以钢琴为主。
- v03 仍然过于抒情：长旋律、扩展和声与弦乐抬升让音乐主动索取情绪，不适合洗漱、看猫、下地库和通勤这些首先应当成立为日常的画面。
- G0 需要的不是“悲伤主题”，而是日常表面几乎正常，只有很淡的疲惫与忧伤从短句和和声缝隙中出现。
- v03 原始生成文件在时长边界硬截断。原因是提示词要求“无终止、无淡出”，却没有为平台截断预留尾部编辑区。后续 source 必须在最后十二秒前结束旋律，只重复已建立的伴奏型；正式试听前还要制作交叉循环，不能把 raw source 的硬截尾直接当成成品。

## G0 日常校准样片 v04

只保留钢琴主导方向。平台开启 `Instrumental`，长度选择 120 秒，不上传 Reference Audio；同一提示词生成 A／B 两个候选，只用于比较模型随机结果。

建议文件名：

- `mus-r01-g0-everyday-calibration-v04-a.wav`
- `mus-r01-g0-everyday-calibration-v04-b.wav`

Prompt（约 100 个英文词）：

```text
Instrumental everyday BGM for an autobiographical Japanese narrative game. A quiet, ordinary late-summer morning: waking, washing, looking at aging cats, entering the garage, commuting. Soft upright piano leads at 80 BPM in steady 4/4, using a plain broken-chord pattern and a brief three-to-five-note motif with plenty of space. Mostly simple major-key harmony, with only an occasional passing minor shadow. Emotionally neutral and gently tired, never lyrical or sentimental. Keep dynamics soft and even, with no buildup. Finish the melody before the final twelve seconds, then repeat an existing two-bar accompaniment pattern without cadence or fade for seamless loop editing.
```

Exclude Styles：

```text
ballad, emotional piano solo, sentimental, melancholic, cinematic, string ensemble, dramatic crescendo, ambient, lo-fi beat, jazz, cute comedy, electronic, synthesizer, chiptune, cyberpunk, vocals
```

## G1 独立重制｜60 秒 Music v2（已完成）

2026-08-17 最终选用 `A_Clear_View_2026-08-17T054928.mp3`，完整转码为运行时 `MUS-02`。进入 `G1-05` 回放时用 2.8 秒渐隐，`G1-05` 与 `G1-06` 不再切回 G0 的音乐。下方机械化提示词及验收规则仅保留为被否决方案的记录。

G1 不再等待 G0 校准结果，也不使用任何 Reference Audio。当前运行时 `MUS-02` 的前半段已经证明干燥、精确的小编制机械运动适合“装明白”；失配发生在约 44 秒后的增厚和约 48 秒出现的弓弦乐抬升。新一版只重做这一首，并把“全程不扩编”作为首要约束。

ElevenLabs 设置：

- Model：`Music v2`
- Finetune：`无微调`
- Duration：`60 seconds`
- Variants：`1`
- Instrumental：开启
- Audio Reference：不上传

当前网页端初始生成页没有独立的 Include Styles／Exclude Styles 输入框；这两组约束必须合并进唯一的 Prompt。界面截图中时长仍为 `2:00`，生成前必须手动改为 `1:00`。

单框 Prompt：

```text
Create a 60-second instrumental background track for a contemporary narrative game at 96 BPM in steady 4/4. A dry prepared piano plays a precise repeating two-bar figure. Support it only with muted marimba, short staccato bass-clarinet notes, very soft electronic clicks, and occasional damped-metal accents. Keep the tone controlled, efficient, clear, and understated, with stable low-to-medium energy. From 0–20 seconds establish the pattern; from 20–40 seconds make small rhythmic and voicing variations; from 40–60 seconds return to the opening texture. Keep exactly this small ensemble for the entire track. Do not introduce violin, viola, cello, any bowed or pizzicato strings, a string section, orchestral layers, ambient pads, a featured solo, crescendo, emotional swell, jazz, cyberpunk synths, or vocals. Finish by repeating the original two-bar pattern at the same energy.
```

验收时首先检查 40—60 秒：不得出现新乐器、弓弦乐、音区抬高、持续长线主旋律或整体能量增长。只要后段再次自动“解释情绪”，整首淘汰；不以修改情绪形容词继续追加生成。

## v04 听审与循环处理

1. 先试听前九十秒，确认它首先是早晨日常 BGM，淡淡忧伤不应被听成“这段正在煽情”。
2. 只要出现长旋律、弦乐抬升、明显高潮或钢琴独奏会式表达，直接淘汰。
3. 对通过的 source，从中段选择不少于七十秒的稳定区间，并用尾部预留的两小节伴奏制作交叉循环。
4. 循环成品连续播放五轮后，再覆盖 G0 二十四句完整听审；raw source 的最后一秒不作为运行时验收对象。

G0 v04 通过后再继续写 G2、G3 与十秒检索事件。G1 按上面的 60 秒 Music v2 方案独立重制，不继承 G0 的钢琴日常语言。

## 后续接入

新素材通过听审后再执行以下修改：

- 从通过听审的 source 中人工确定循环点，制作 48 kHz／24-bit WAV 母版与 Ogg；G1 source 固定为 60 秒，其余曲目沿各自已确认长度执行。
- 将五个 Cue 加入构建报告；旧的 G0—G3 音频退出运行时但继续保留为历史候选。
- 把 `game/content/music_cues.json` 改为上表的五状态映射。
- 为 G3 检索验证“主曲 → 十秒事件 → 同一主曲”的恢复行为。
- 更新自动化覆盖测试，并完成一次有记录的人工整章听审。
