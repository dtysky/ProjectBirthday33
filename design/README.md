# Design

本目录只处理作品表达：发生过什么、作品要表达什么，以及每个游戏单元具体呈现什么。

## 文件

- [chronicle.md](chronicle.md)：事实与时间线。
- [inbox.md](inbox.md)：未经整理的记录、灵感和批注。
- [outline.md](outline.md)：整体命题与结构。
- [game-scenes.md](game-scenes.md)：当前生产台本，也是美术与代码共同使用的场景依据。
- [archive/film-continuity.md](archive/film-continuity.md)：微电影阶段分镜，只作为改编参考。

## 流转

```text
chronicle / inbox
        -> outline
        -> game-scenes
        -> art/asset-list
        -> game/content/story.json
```

已经进入 `game-scenes.md` 的对白，修改时必须同步检查美术资产和 Godot 场景编号。
