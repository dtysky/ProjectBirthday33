# Art

本目录管理美术方向和生产台账，不存放 Godot 运行时资产。

## 文件

- [style-guide.md](style-guide.md)：已经确认的画风、动态边界与视觉递进。
- [asset-list.md](asset-list.md)：人设、地点母版、镜头包和来源素材的编号与状态。
- [reference-request.md](reference-request.md)：需要用户提供的人物、场景与旅行参考清单。
- [reference-source-catalog.md](reference-source-catalog.md)：已经收到的实景、人物与物件参考及其使用边界。
- [generation-manifest-20260731.md](generation-manifest-20260731.md)：2026-07-31 参考批次的生成结果、输入角色与提示词摘要。
- [g0-cg-manifest-20260731.md](g0-cg-manifest-20260731.md)：G0 现实段六张 CG 草稿的镜头约束、生成输入与审核边界。
- [g1-cg-manifest-20260803.md](g1-cg-manifest-20260803.md)：G1 园区、工位、创作表演与黑场关键 CG 的最终候选、输入约束与逐句用途。
- [character-h-reference-catalog.md](character-h-reference-catalog.md)：我的服装套系、姿态与原文件索引。
- [char-h-look-04-sheet-v1.png](characters/char-h/outfits/char-h-look-04-sheet-v1.png)：`H-LOOK-04`，同时作为 `CHAR-H` 人物身份基准。
- [char-h-look-09-sheet-v1.png](characters/char-h/outfits/char-h-look-09-sheet-v1.png)：`H-LOOK-09` 浅灰蓝睡衣待审核人设。
- [char-cats-sheet-v1.png](characters/cats/char-cats-sheet-v1.png)：两只猫当前保留的人设版本，后续仍需调整。
- [team-five-placeholder-sheet-v5.png](characters/team/team-five-placeholder-sheet-v5.png)：我与四名下属的差异化待审核人设，已锁定具体身高、偏瘦体型与 3 号短裤穿搭。
- [vehicle-dawn-sheet-v1.png](vehicles/vehicle-dawn-sheet-v1.png)：车辆“破晓”的待审核母版。
- [g0-home-garage-dawn-placeholder-v2.png](locations/g0/g0-home-garage-dawn-placeholder-v2.png)：家中地库与“破晓”的像素风地点参考。
- [g0-car-interior-clean-placeholder-v2.png](locations/g0/g0-car-interior-clean-placeholder-v2.png)：车内自拍机位的像素风空底图。
- [G0 运行时 CG](../game/assets/shots/shot-01/)：醒来、洗漱、告别猫猫、上车、驾驶与公司地库停驻。
- [G1 运行时 CG](../game/assets/shots/)：园区五人、工位五人及倒影、山地 VLOG 两姿态、黑场闭眼／睁眼。
- [loc-01-campus-master-v2.png](locations/loc-01/loc-01-campus-master-v2.png)：公司园区的像素风地点母版。
- [loc-01-workstation-master-v2.png](locations/loc-01/loc-01-workstation-master-v2.png)：个人工位的像素风地点母版。
- [company-garage-master-v2.png](locations/work/company-garage-master-v2.png)：公司地库的像素风地点母版。
- [char-ousia-sheet-v2.png](characters/char-ousia/char-ousia-sheet-v2.png)：`CHAR-OUSIA` 正式人物与核心服装设定。
- [agents/](characters/agents/)：Poros、Ariadne、Pothos、Pharos、Kairos、Nostos 的正式 `v2` 人设。

## 工作流

1. 从 `design/game-scenes.md` 确认生产单元，再从 `asset-list.md` 确认对应的 `SHOT-xx`。
2. 由人工提供全局人设、服装设定和该镜头的构图草图。
3. AI 先生成包含背景、人物、光线和前后景关系的一体母帧。
4. 人工审核人物一致性、机位、景别、光线和对白安全区。
5. 母帧通过后，按动态需求补出干净背景、人物、前景、差分和遮罩。
6. 最终文件导出到 `game/assets/shots/shot-xx/`，Codex 更新资产清单并接入场景；`art/` 不再另存一份最终 CG。

背景和人物不分开盲做。简单镜头只交付母帧；需要视差、表情差分或局部动画时才拆层。

来源素材默认只进入 `references-local/`。只有聊天、检索等必须保留原貌的叙事证据，才会经过裁切和遮罩后导出到 `game/assets/evidence/`；旅行和道路素材不直接进入运行时目录。

## 本地目录

以下目录按需创建，不进入 Git：

- `references-local/`：实拍照片、视频、录屏和旧作等来源素材。
- `workfiles/`：PSD、工程文件和中间稿。
- `generated/`：所有 AI 生成 CG 的原始输出、修改稿和候选版本；统一按 `SHOT-xx/` 归档，并由 Git 忽略。

以后生成 CG 时直接写入 `art/generated/SHOT-xx/`。审核前不复制到其他受 Git 管理的目录；审核通过后，只向 `game/assets/shots/shot-xx/` 导出一份游戏实际加载的最终资产，不保留第二份 PNG 审核稿。

需要进入 Git 的只有规范、台账和 `game/assets/` 中唯一一份最终交付。来源素材不进入 Git；画中证据和最终动态 CG 在确定后再决定 Git LFS 或发布存储方案。
