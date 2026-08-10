# G4 运行时 CG 与占位清单（2026-08-06）

G4 当前共有 27 个镜头包，其中 26 个拥有并通过审核的 `3840 × 2160` WebP 运行时资源，只有 `SHOT-12` 继续使用语义占位。`SHOT-15` 已用深圳家中地库修正版替换错误的高原出发旧图。通过稿在 Git 忽略的 `art/generated/SHOT-xx/` 中只保留最终版本。

## 本轮已审核接入的 16 张母帧

`SHOT-43`、`SHOT-44`、`SHOT-45`、`SHOT-46`、`SHOT-47`、`SHOT-48`、`SHOT-49`、`SHOT-50`、`SHOT-51`、`SHOT-52`、`SHOT-53`、`SHOT-54`、`SHOT-56`、`SHOT-62`、`SHOT-63`、`SHOT-68`。

- 内容、构图和镜位沿用上一版，只重制整幅原生硬边像素画风。
- 所有出现主角的画面重新绑定正式 `CHAR-H`；旅行服装分别引用对应 `H-LOOK`，真实照片不再承担人物身份。
- 多人场景只校正主角，同伴保持各自独立脸型、发型、服装和动作，不得换皮。
- 已统一导出 `3840 × 2160` WebP 并替换旧运行时母帧；原始生成目录只保留通过稿 `master.png`。

## 既有运行时母帧映射

| 段落 | 镜头 | 运行时资产 | 演出用途 |
| --- | --- | --- | --- |
| G4-02 | SHOT-13 | [练车](../game/assets/shots/shot-13/master.webp) | 从三十一岁旧作匹配切入现实驾驶 |
| G4-02 | SHOT-62 | [破晓改装完成](../game/assets/shots/shot-62/master.webp) | 建立车辆身份 |
| G4-02 | SHOT-43 | [腾格里晚霞](../game/assets/shots/shot-43/master.webp) | 第一次独自长途抵达 |
| G4-02 | SHOT-63 | [腾格里日出](../game/assets/shots/shot-63/master.webp) | 车顶唱歌与行动欲被唤醒 |
| G4-02 | SHOT-44 | [怒江铁索桥](../game/assets/shots/shot-44/master.webp) | 两句共用；湿石场地、旧桥、怒江与停放的破晓按实景重制 |
| G4-02 | SHOT-45 | [丙察察](../game/assets/shots/shot-45/master.webp) | 复杂道路与事业阴霾被驱散 |
| G4-02 | SHOT-46 | [格聂大雪](../game/assets/shots/shot-46/master.webp) | 两句共用，不使用三年前素材 |
| G4-02 | SHOT-47 | [海外租车起点](../game/assets/shots/shot-47/master.webp) | 我和朋友共同处理陌生规则 |
| G4-02 | SHOT-48 | [开罗驾驶](../game/assets/shots/shot-48/master.webp) | 从车内建立拥挤和难度 |
| G4-02 | SHOT-66 | [埃及戈壁／红海](../game/assets/shots/shot-66/master.webp) | 主角、同行朋友与真实租赁车同框 |
| G4-02 | SHOT-68 | [金字塔三幻神](../game/assets/shots/shot-68/master.webp) | 原照锁动作、卡牌和克制微笑，身份取正式 CHAR-H |
| G4-02 | SHOT-49 | [瓦纳卡涉水银河](../game/assets/shots/shot-49/master.webp) | 人物与三脚架同时入水 |
| G4-02 | SHOT-50 | [三姐妹与大象岩](../game/assets/shots/shot-50/master.webp) | 等待海岸晚霞 |
| G4-02 | SHOT-51 | [湿地银河](../game/assets/shots/shot-51/master.webp) | 深夜独自拍摄 |
| G4-02 | SHOT-69 | [清晨风暴](../game/assets/shots/shot-69/master.webp) | 骤雨、起舞与自由共用一图 |
| G4-02 | SHOT-52 | [家中整理设备](../game/assets/shots/shot-52/master.webp) | 用真实装备承接工作的现实回报 |
| G4-03 | SHOT-14 | [出发前规划](../game/assets/shots/shot-14/master.webp) | 家中夜间规划路线、光线、银河与机位；已审核 |
| G4-03 | SHOT-53 | [同场拍摄过程](../game/assets/shots/shot-53/master.webp) | 找构图、架设、等待与落空；状态层按实机需要再补 |
| G4-03 | SHOT-54 | [家中组织素材](../game/assets/shots/shot-54/master.webp) | Sony 设备、声音、脚本和时间线 |
| G4-03 | SHOT-55 | [观看完成作品](../game/assets/shots/shot-55/master.webp) | 双手离开键鼠，只看显示器；已审核 |
| G4-04 | SHOT-56 | [风雪抵达](../game/assets/shots/shot-56/master.webp) | 抵达结果同时留下凌晨上山的代价 |
| G4-04 | SHOT-15 | [深圳地库共同出发](../game/assets/shots/shot-15/master.webp) | 四人围绕破晓和摄影装备装车；已审核 |
| G4-04 | SHOT-58 | [放晴后告别](../game/assets/shots/shot-58/master.webp) | 保留上一版红衣主角；灰衣稿废弃，已审核 |
| G4-04 | SHOT-60 | [独自折返](../game/assets/shots/shot-60/master.webp) | 破晓蓝白座舱、空副驾与返程道路；已审核 |
| G4-05 | SHOT-16 | [日落](../game/assets/shots/shot-16/sunset.webp)／[蓝调](../game/assets/shots/shot-16/blue.webp)／[星空](../game/assets/shots/shot-16/stars.webp)／[月照](../game/assets/shots/shot-16/moonrise.webp) | 同一机位四态；贡嘎方向无银河，月亮在右侧；已审核 |
| G4-05 | SHOT-61 | [夜间下山](../game/assets/shots/shot-61/master.webp) | 道路主导的破晓车内视角；已审核 |

## 2026-08-10 审核结论

| 镜头 | 生成边界 | 当前状态 |
| --- | --- | --- |
| SHOT-14 | `CHAR-H／H-LOOK-03` 在真实家中工作桌规划；屏幕只使用出发前 `旅程计划.png` 的像素重绘层 | 已审核接入 |
| SHOT-55 | 同一工作桌夜景，主角双手离开键鼠只看显示器；不使用电视、投影或放映厅 | 已审核接入 |
| SHOT-58 | 新都桥放晴后告别 | 保留运行时上一版红衣主角；灰衣候选废弃 |
| SHOT-60 | 破晓车内独自折返 | 已审核接入 |
| SHOT-16 | 同机位日落／蓝调／星空／月照四态 | 已审核接入；贡嘎方向无银河，月亮在右侧 |
| SHOT-61 | 破晓车内夜间下山道路 | 已审核接入 |
| SHOT-15 | 深圳家中地库四人装车出发 | 修正版已审核接入 |

## 当前语义占位

| 镜头 | 占位演出 | 后续替换边界 |
| --- | --- | --- |
| SHOT-12 | “旧作重演”占位；三十一岁的原声台词以无框字幕呈现 | 两张旧作重绘与原声音轨 |

`SHOT-15`、`SHOT-16`、`SHOT-58`、`SHOT-60`、`SHOT-61` 已替换并审核。车辆连续性以 `SHOT-62` 的黄色黑灰破晓外观和 `SHOT-13` 的蓝白座舱为硬参考。

## 当前演出规则

- G4-01 的“三十一岁的我”视为旧作原声音轨，不使用带尖角或姓名的对白框。
- 运行时母帧按镜头逐一使用独立字幕安全区；字幕不挡人物正脸、摄影设备、车辆身份与剪辑时间线。
- 同一镜头承载多句时不重复切画；只保留极慢推近和必要的天光／天气气氛变化。
- `SHOT-53` 第二句以冷色天气压暗表示等待落空，暂不提前生产额外差分。
- G4-05 在 `SHOT-16` 内依次进入日落、蓝调、星空、月照状态；最后一句结束后先进入无台词 `SHOT-61`，再转入 G5。
- 自动播放在字幕分页后会继续计时，不会停在 G4 的长句中间。

本轮通过稿只以 `art/generated/SHOT-xx/master.png` 保存在 Git 忽略目录中；旧稿与 V2 文件名已经清除，仓库中不提交第二份候选 PNG。
