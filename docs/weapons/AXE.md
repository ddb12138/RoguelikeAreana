# 斧头：绕身扩散攻击

核查日期：2026-09-20。

## 简要说明与入口

[axe.tres](../../resource/upgrades/axe.tres) 解锁 ID 为 `斧头`，最多选择 1 次，安装 [控制器](../../sences/ability/axe_ability_controller/axe_ability_controller.gd) / [场景](../../sences/ability/axe_ability_controller/axe_ability_controller.tscn)。基础伤害 10，每 2 秒生成一个斧头。

[攻击实体](../../sences/ability/axe_ability/axe_ability.gd) 在 3 秒内绕玩家两圈，半径从 0 增到 100；中心每次计算都取玩家当前位置，所以玩家移动时整条轨迹跟随。随机的是初始方向，不是每帧方向。

## 升级选项

| 资源与真实 ID | 出现条件 | 上限 | 公式／满级 |
| --- | --- | --- | --- |
| [axe_damage.tres](../../resource/upgrades/axe_damage.tres)：`斧头:伤害升级` | 解锁斧头后加入池 | 5 | `10 × (1 + 0.1n)`，满级 15 |

当前没有斧头攻速、数量、半径强化，也没有火焰变种。

## 核心 GDScript

实体轨迹源码节选：

```gdscript
func _ready():
	base_rotation = Vector2.RIGHT.rotated(randf_range(0, TAU))
	
	var tween = create_tween()
	tween.tween_method(tween_method, 0.0, 2.0, 3)
	tween.tween_callback(queue_free)
	
func tween_method(rotations: float):
	var percent = rotations / 2
	var current_radius = percent * MAX_RADIUS
	var current_direction = base_rotation.rotated(rotations * TAU)
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	global_position = player.global_position + (current_direction * current_radius)
```

Tween 在 3 秒内把 `rotations` 从 0 推到 2；`TAU` 是一圈弧度，`rotations / 2` 则是生命周期进度。最后的回调释放节点。2 秒发射间隔小于 3 秒寿命，所以存在同时在场的斧头，这是当前参数的直接结果。

强化源码节选：

```gdscript
func on_ability_upgrade_added(upgrade:AbilityUpgrade, current_upgrades: Dictionary):
	if upgrade.id == "斧头:伤害升级":
		additional_damage_percent = 1 + (current_upgrades["斧头:伤害升级"]["quantity"] * .10)
```

## 场景配合与验证

[axe_ability.tscn](../../sences/ability/axe_ability/axe_ability.tscn) 的 AnimationPlayer 每 0.5 秒转动一次 Sprite2D，负责外观自转；上述 Tween 负责绕玩家公转，二者独立。Hitbox 一直启用，圆形碰撞区域随实体移动；伤害由进入 Hurtbox 触发，不是每帧自动扣血。

```sh
python3 tools/run_combat_lab.py --enemy 宝箱怪 --weapon 斧头
```

按 U 共升级 5 次后应没有其他卡牌，伤害倍率达到 1.5。实验场自动回归覆盖安装、上限与满级倍率；轨迹、同时在场数量和真实命中范围建议交互观察。

更新记录：2026-09-20 建立说明与定向测试入口，未增加新变种；见 [VARIANTS.md](VARIANTS.md)。
