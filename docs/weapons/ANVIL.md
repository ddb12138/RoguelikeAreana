# 铁毡：随机落点与环形数量扩展

核查日期：2026-09-20。项目当前显示名与 ID 均使用“铁毡”，保留该拼写。

## 简要说明与入口

[anvil.tres](../../resource/upgrades/anvil.tres) 的解锁 ID `铁毡`，上限 1。安装 [控制器](../../sences/ability/anvil_ability_controller/anvil_ability_controller.gd) / [场景](../../sences/ability/anvil_ability_controller/anvil_ability_controller.tscn)，每 2 秒生成一轮，基础伤害 15、基础数量 1。

生成时选一个 0–100 的随机半径及初始方向，按数量等分圆周得到落点。射线碰到地形时将落点裁到碰撞位置；不会追踪移动中的敌人。

## 升级选项

| 资源与真实 ID | 上限 | n 次选择后的效果 | 满级 |
| --- | --- | --- | --- |
| [anvil_damage.tres](../../resource/upgrades/anvil_damage.tres)：`铁毡:伤害升级` | 5 | `15 × (1 + 0.1n)` | 22.5 伤害 |
| [anvil_amount.tres](../../resource/upgrades/anvil_amount.tres)：`铁毡:数量升级` | 5 | 每轮 `1 + n` 个 | 每轮 6 个 |

两项都在解锁后加入池。`anvil_count` 保存额外数量，基础 0 并不等于不生成。当前没有范围、攻速、火焰变种。

## 核心 GDScript

[控制器](../../sences/ability/anvil_ability_controller/anvil_ability_controller.gd) 的落点计算节选（循环后段射线与实例创建见源码）：

```gdscript
var direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
var additional_rotation_degress = 360.0 / (anvil_count + 1)
var anvil_distance = randf_range(0, BASE_RANGE)
for i in anvil_count + 1:
	var adjusted_direction = direction.rotated(deg_to_rad(i * additional_rotation_degress))
	var spwan_position = player.global_position + (adjusted_direction * anvil_distance)
```

同一轮共用一个半径，只改变方向，所以数量升级产生环形分布；不是每个铁毡都独立选半径。

强化源码节选：

```gdscript
func on_ability_upgrade_added(upgrade:AbilityUpgrade, current_upgrades: Dictionary):
	if upgrade.id == "铁毡:伤害升级":
		additional_damage_percent = 1 + (current_upgrades["铁毡:伤害升级"]["quantity"] * .10)
	if upgrade.id == "铁毡:数量升级":
		anvil_count = current_upgrades["铁毡:数量升级"]["quantity"]
```

## 为什么实体脚本很短

[anvil_ability.gd](../../sences/ability/anvil_ability/anvil_ability.gd) 只暴露 Hitbox；主要动作在 [场景动画](../../sences/ability/anvil_ability/anvil_ability.tscn)：

- 视觉从 Y=-64 落下，0.15 秒到地面并发出粒子。
- 碰撞只在 0.15–0.25 秒启用，圆形半径 32。
- 0.7 秒的方法轨道调用 `queue_free()`。

落点是实体根节点位置，动画移动的是 `Visuals`，这使落地判定固定在地面，不在空中提前造成伤害。

## 定向验证与更新

```sh
python3 tools/run_combat_lab.py --enemy 普通敌人 --weapon 铁毡
```

按 U 升级数量，观察每轮 1→6 个；按伤害强化观察 15→22.5。实验场回归验证两条分支各 5 次、额外数量 5 和倍率 1.5；真实落点和地形遮挡需交互观察。2026-09-20 新增本文，玩法未改；见 [VARIANTS.md](VARIANTS.md)。
