# G2 CG 试制接入清单

本批将已经确认可试制的 16 张独立母帧统一导出为 3840 × 2160 WebP，并接入
G2 的逐行 `SHOT-xx` 切换。生成候选和实景原图继续保存在 ignored 目录；运行时只
保留下列正式导出，不重复提交 PNG 原始候选。

| 单元 | 镜头 | 正式资源 | 当前状态 |
| --- | --- | --- | --- |
| G2-01 | SHOT-05 | [旧工位前的决定](../game/assets/shots/shot-05/master.webp) | 母帧试制；状态差分待审查 |
| G2-02 | SHOT-06 | [从一人到五人](../game/assets/shots/shot-06/master.webp) | 母帧试制 |
| G2-02 | SHOT-22 | [凌晨排查内存](../game/assets/shots/shot-22/master.webp) | `memory-high` 母帧试制 |
| G2-03 | SHOT-07 | [食堂生日](../game/assets/shots/shot-07/master.webp) | 母帧试制 |
| G2-03 | SHOT-23 | [科兴再次延期](../game/assets/shots/shot-23/master.webp) | 母帧试制 |
| G2-03 | SHOT-24 | [上线却与我无关](../game/assets/shots/shot-24/master.webp) | 母帧试制 |
| G2-04 | SHOT-08 | [讨论去留](../game/assets/shots/shot-08/master.webp) | 母帧试制；居中裁成 16:9 |
| G2-04 | SHOT-25 | [绩效证据](../game/assets/shots/shot-25/master.webp) | 母帧试制 |
| G2-04 | SHOT-26 | [不可能的数据预测](../game/assets/shots/shot-26/master.webp) | 母帧试制 |
| G2-04 | SHOT-27 | [组员丁离开](../game/assets/shots/shot-27/master.webp) | 母帧试制 |
| G2-05 | SHOT-20 | [陶波远程答辩](../game/assets/shots/shot-20/master.webp) | 母帧试制 |
| G2-05 | SHOT-28 | [任务重新落回](../game/assets/shots/shot-28/master.webp) | 母帧试制 |
| G2-05 | SHOT-31 | [指出问题并重新竞聘](../game/assets/shots/shot-31/master.webp) | 母帧试制 |
| G2-05 | SHOT-29 | [与 HR 两人谈话](../game/assets/shots/shot-29/master.webp) | 母帧试制 |
| G2-05 | SHOT-30 | [职责再次调整](../game/assets/shots/shot-30/master.webp) | 母帧试制；居中裁成 16:9 |
| G2-06 | SHOT-21 | [组员丙送别宴](../game/assets/shots/shot-21/master.webp) | 母帧试制；饭后差分待审查 |

## 图像提示基线

本批母帧均使用内置图像生成工作流制作候选，统一提示基线为：成熟电影感硬边像素
CG、清晰方形像素簇、写实成年人比例、固定 CHAR-H 与团队身份、16:9 游戏画面、
为字幕保留安全区；禁止课本插画、儿童绘本、换皮人物、夸张英雄姿态、平滑数码绘画、
品牌标识和水印。每张再分别加入旧工位、团队、食堂、园区、陶波湖岸、会议室与餐厅
等实景约束，以及对应台词所需的屏幕状态和人物动作。

本轮接入没有重新生成图像，只将已经选定的唯一候选按 4K WebP 正式导出。SHOT-08
和 SHOT-30 的候选不是 16:9，因此只做居中裁切，不横向拉伸人物；其余镜头不改变
构图。
