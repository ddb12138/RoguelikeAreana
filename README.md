# Roguelike Arena 学习项目

这是一个使用 **Godot 4.3 / GDScript** 制作的俯视角 2D 生存动作游戏。项目入口是 `sences/ui/main_menu.tscn`，一局战斗的核心闭环是：移动与躲避 → 自动攻击 → 敌人死亡后按概率掉落经验 → 升级选卡 → 难度随时间提高 → 胜利或失败 → 局外成长。

> 仓库保留了早期学习时的拼写，如 `sences`、`asserts`、`entites_layer`、`expericen_manager`。它们可能已经成为路径、Group 或序列化字段；复习时先理解，不要顺手改名。

## 第一次回来时怎么读

全部文档按用途分类，见 [文档导航](docs/README.md)。

1. 先读[从课程重新理解游戏](docs/learning/LEARNING_GUIDE.md)，沿一局游戏恢复 Godot 概念、设计思路和运行时数据流。
2. 对照[81 节课程与代码地图](docs/learning/COURSE_MAP.md)，按原视频顺序定位当前场景、脚本、Resource 和编辑器设置。
3. 需要知道“在 Godot 哪儿点、选哪个节点、看哪个属性”时，打开[Godot 编辑器操作指南](docs/learning/GODOT_EDITOR_GUIDE.md)。
4. 要修改代码前，查看[项目知识地图](docs/architecture/ARCHITECTURE.md)和[开发与验证基线](docs/development/DEVELOPMENT.md)。宝箱怪的扩展设计另见[宝箱怪说明](docs/monsters/MIMIC_CHEST.md)，本次“进入追逐动画后不移动”的定位与修复过程见[宝箱怪追逐 Bug 修复单](docs/bugs/MIMIC_CHASE_FIX.md)。

## 快速打开与运行

使用 Godot 4.3 的项目管理器导入根目录中的 `project.godot`。等待第一次资源导入完成后：

- “运行项目”从主菜单开始；“运行当前场景”只运行编辑器当前打开的 `.tscn`，两者依赖可能不同。
- WASD 或方向键移动，P 打开暂停菜单；项目也包含虚拟摇杆。
- 项目逻辑视口为 640×360，桌面调试窗口覆盖为 1920×1080。
- 启动时 Autoload `MetaProgression` 会读取并写入 `user://game.save`，而且当前存在“每次启动自动增加永久升级”的已知缺陷。反复练习前务必按[隔离运行说明](docs/development/DEVELOPMENT.md#隔离运行)使用副本和独立用户目录。

## 四条最重要的代码链

### 玩家移动

```text
Input Map
→ player.gd 读取动作并得到方向
→ VelocityComponent 平滑得到目标速度
→ CharacterBody2D.move_and_slide()
```

玩家脚本负责输入与协调，移动公式放在可复用的 `VelocityComponent`。主场景中的玩家实例还会覆盖原场景属性，所以“改了脚本默认值却没生效”时要逐层检查 Inspector 覆盖。

### 自动攻击与伤害

```text
武器 Controller 的 Timer
→ 选择目标并实例化一次攻击
→ HitboxComponent 进入敌人 HurtboxComponent
→ HealthComponent.damage()
→ died 信号
→ 掉落、死亡特效等监听者先响应
→ 释放敌人 owner
```

剑并不是固定在玩家身边挥动：当前控制器会筛选玩家 150 范围内的敌人，按距离选择最近目标，在目标附近生成剑。动画、有效命中窗口和 `queue_free()` 位于攻击场景的 AnimationPlayer 轨道中，不能只读 `.gd`。

### 经验与局内升级

```text
敌人 died
→ VialDropComponent 生成经验瓶
→ 玩家拾取后发出 GameEvents.experience_vial_collected
→ ExperienceManager 累计经验并发出 level_up
→ UpgradeManager 抽取最多两张不同卡
→ UpgradeScreen 暂停战斗并显示卡牌
→ 选择后发出 ability_upgrade_added
→ Player 安装新控制器，或已有控制器更新数值
```

`.tres` Resource 描述“这项升级是什么”；真正效果由 Player、武器控制器或其他监听者实现。逻辑 ID 还会参与字典和存档，修改显示文字时优先改 `name`、`description`，不要随意改 `id`。

### 一局游戏与永久成长

`ArenaTimeManager` 管时间与胜利，`EnemyManager` 管生成和难度，`ExperienceManager` 管局内等级，`UpgradeManager` 管局内升级池；`MetaProgression` 是跨场景 Autoload，管理永久货币、升级和 `user://game.save`。局内状态与永久状态的生命周期不同，不应混在 Player 或某个 UI 中。

## 当前学习时要知道的边界

文档按当前工作区静态核对，不代表原视频每一步与现在完全相同。课程中的 Rat 对应当前 `basic_enemy`，旧 TileMap 在 Godot 4.3 项目中实际是 `TileMapLayer`，Anvil 的逻辑 ID 保留为“铁毡”。当前还存在永久升级、暂停退出、刷怪极端位置、闪电异步目标等已知问题；详见[开发基线](docs/development/DEVELOPMENT.md#已知问题与待验证项)。这些现状适合拿来学习排错，但不应当作推荐写法。
