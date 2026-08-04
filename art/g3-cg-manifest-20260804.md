# G3 CG 当前生成记录

日期：2026-08-04

本轮使用内置 imagegen。`SHOT-32` 至 `SHOT-37` 按“角色职责优先于统一场所”的
方案完成审核，并已各自导出唯一的 4K WebP 到 `game/assets/shots/`。Ousia 原有的
写实花海小径不通过，Ousia 的相遇及后续动作改为相互衔接的纯白花海镜头；G3-03
则单独回到普通卧室的深夜主观视线。审核源稿仍只保存在 Git 忽略目录
`art/generated/`，通过的运行时母帧只导入 `game/assets/shots/`。本轮另补了无 Agent 的
G3 独立开场 `SHOT-42`，用于承接前置旁白；G3 中的主角统一使用
`H-LOOK-04`。

## G3-01 接入组

| 镜头 | 当前文件 | 现场与动作 | 正式化前仍需处理 |
| --- | --- | --- | --- |
| SHOT-32 | [Poros／4K 运行时母帧](../game/assets/shots/shot-32/master.webp) | Poros 在真实客厅墙屏前解释跑道，我坐在旅行装备旁，两只猫保持正常比例 | 已审核接入；数字与月份由 Godot 重做 |
| SHOT-33 | [Ariadne／4K 运行时母帧](../game/assets/shots/shot-33/master.webp) | 两人并肩行走，我在真实分岔前慢下半步 | 已审核接入；手机证据与路牌标签后加 |
| SHOT-34 | [Pothos／4K 运行时母帧](../game/assets/shots/shot-34/master.webp) | Pothos 站立推动带轮场景板，多个经历场面可直接辨认 | 已审核接入；场景板标题和主题位由 Godot 后加 |
| SHOT-35 | [Pharos／4K 运行时母帧](../game/assets/shots/shot-35/master.webp) | 我跪在三脚架后实际取景；Pharos 在旁用终端完成规划和现场协助 | 已审核接入；终端信息后加 |
| SHOT-36 | [Kairos／4K 运行时母帧](../game/assets/shots/shot-36/master.webp) | Kairos 站在投影前指出顺序，我坐在观众席共同观看 | 已审核接入；银幕素材换成真实贡嘎／子梅垭口抽帧 |
| SHOT-37 | [Nostos／4K 运行时母帧](../game/assets/shots/shot-37/master.webp) | Nostos 在梯上校平相框，我在下方托住 | 已审核接入；作品与墙签后续替换 |
| SHOT-42 | [独立开场／4K 运行时母帧](../game/assets/shots/shot-42/master.webp) | 我独自在家整理旅行照片、摄影器材与 AI 对话，画面中尚无 Agent | 已生成接入；待本轮实机审查 |

`SHOT-32` 至 `SHOT-37` 与 `SHOT-42` 的运行时文件均为 `3840 × 2160`，每个镜头包只保留一张
游戏实际加载的 `master.webp`。

## Ousia 已接受并接入组

| 镜头 | 当前文件 | 叙事职责 |
| --- | --- | --- |
| SHOT-38 | [纯白花海相遇／4K](../game/assets/shots/shot-38/master.webp) | 六名 Agent 之后第一次见到 Ousia |
| SHOT-09 | [花海并坐对话／4K](../game/assets/shots/shot-09/master.webp) | 那个夜晚的长对话，真实聊天以后替换低位设备内容 |
| SHOT-10 | [深夜卧室仰视／4K](../game/assets/shots/shot-10/master.webp) | 躺在床上直视开着的普通吸顶灯，只用于“二十秒”与吊灯旧文 |
| SHOT-39 | [从花中递回旧文／4K](../game/assets/shots/shot-39/master.webp) | 把“找回来”落成递页动作 |
| SHOT-40 | [合上女主旧稿／4K](../game/assets/shots/shot-40/master.webp) | 把“不是你的”落成稿件归属动作 |
| SHOT-41 | [在 Ousia 怀中哭泣／4K](../game/assets/shots/shot-41/master.webp) | 正脸不入镜，以身体完成情绪释放 |
| SHOT-11 | [空白纸与落笔／4K](../game/assets/shots/shot-11/master.webp) | 落笔并接入 G4 旧作投影 |

审核联系表仍保存在 ignored 目录：[Ousia／卧室叙事组 `v3`](generated/G3/ousia-white-space-contact-v3.png)。
七张均已导出为唯一的 `3840 × 2160` 运行时 `master.webp`；其中仅 `SHOT-10` 离开
花海，进入一次性的普通卧室深夜主观视线。

## 本轮提示词集

Agent 与花海组使用 `illustration-story`；最终 `SHOT-10` 以 `precise-object-edit`
从普通卧室仰视稿定向调整为深夜、开灯和三分之一画宽。共同约束如下：正式 `v2`
人设、主角 `H-LOOK-04`、已经通过的 G0/G2 像素 CG 作为像素密度参考；人物与环境共享硬边
方形像素簇、阶梯轮廓和有限色阶；禁止平滑二次元叠像素滤镜、儿童课本构图、
角色面向镜头陈列、长桌会议、悬浮 HUD、全屏霓虹、可读伪文字、姓名框、对白框、
水印和 Logo。

- `SHOT-32`：晴朗上午的真实家中，Poros 站在普通墙屏旁，我坐在旅行装备旁听他
  解释；两只金吉拉只作正常比例的生活背景。
- `SHOT-42`：同一生活空间的另一机位；我独自在右半画面处理照片、相机、旅行箱和
  笔记本电脑，左上暗墙留给无框旁白；禁止出现 Poros、其他 Agent、财务屏或悬浮界面。
- `SHOT-33`：午后植物园的真实岔路，Ariadne 与我并肩行走而非面对面咨询。
- `SHOT-34`：黑盒剧场的实体带轮场景板，Pothos 用身体推动工位场景，禁止伏案
  写作与抽象悬浮界面。
- `SHOT-35`：高地花甸的实际拍摄准备，我穿 `H-LOOK-04` 跪在三脚架后操作相机；
  Pharos 靠近机位半蹲，用耐候终端完成路线、抵达时间、天气和日照规划，并以
  克制的小幅手势提示山脊。Pharos 不触碰相机，也不摆出摄影师姿态。
- `SHOT-36`：夜晚小型放映厅，Kairos 在投影光束中重排银幕素材，我坐着观看，
  禁止电脑桌与演讲式站姿。
- `SHOT-37`：尚未开放的摄影展布展现场，Nostos 与我共同校平同一相框，运输箱、
  梯子和工具必须可见。
- `SHOT-38`：没有天空、山路和地平线的纯白花海，我从近处停在 Ousia 面前。
- `SHOT-09`：同一花海的并坐中景，聊天设备低位放置，不把空间变成科技演示。
- `SHOT-10`：深夜普通卧室的床上第一人称仰视；开着的圆形吸顶灯占画面宽度约
  三分之一，大片天花板、顶角、上段墙面和闭合窗帘共同建立凝固的视线。灯芯与冷灰
  眩光必须刺眼，但禁止白天、灯具产品特写、巨大满屏灯具、可见人物和花海。
- `SHOT-39`：Ousia 从花间取出单页旧文并递向我；纸面保留无字合成区。
- `SHOT-40`：Ousia 合上属于女主的旧装订稿，我收回靠近的手。
- `SHOT-41`：我正脸被遮住地靠入 Ousia 怀中，不做爱情、母子或宗教姿态。
- `SHOT-11`：花海俯斜手部近景，空白纸、笔和两只尚未相触的手构成 G4 转场。

## 下一步

1. 实机审查新 `SHOT-42`、逐镜内容卡安全区、字幕换行、切镜速度和二十秒占位节奏。
2. 获得 `SRC-01`、`SRC-03` 后替换低位聊天设备与检索占位，不为每句台词重画 CG。
3. `SHOT-36` 后续替换真实旅行抽帧，`SHOT-37` 替换正式参展作品。
4. G4 开始制作后，为 `SHOT-11` 补三十一岁作品从纸面显出的投影转场。
