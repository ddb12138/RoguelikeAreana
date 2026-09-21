# 剑：最近目标攻击与火焰附魔

核查日期：2026-09-20。

## 简要说明与入口

玩家默认自带剑。每次计时器触发，在严格小于 150 像素距离的敌人中找最近者，在其位置附近随机偏移 4 像素生成剑；不是从玩家手中发射的投射物。基础伤害 5，周期 1 秒（Timer 未覆盖 Godot 默认值）。当前默认附带火焰。

- [控制器脚本](../../sences/ability/sword_ability_controller/sword_ability_controller.gd) / [场景](../../sences/ability/sword_ability_controller/sword_ability_controller.tscn)：范围、伤害、计时与升级。
- [实体脚本](../../sences/ability/sword_ability/sword_ability.gd) / [场景](../../sences/ability/sword_ability/sword_ability.tscn)：挥砍与火焰表现。

## 升级选项

| 资源与真实 ID | 上限 | n 次选择后 | 满级 |
| --- | --- | --- | --- |
| [sword_damage.tres](../../resource/upgrades/sword_damage.tres)：`剑:伤害升级` | 5 | `5 × (1 + 0.15n)` | 8.75 直接伤害 |
| [sword_rate.tres](../../resource/upgrades/sword_rate.tres)：`剑:攻速升级` | 5 | `1 × (1 - 0.1n)` 秒 | 0.5 秒一次 |

两项开局就在升级池中。攻速升级缩短攻击生成间隔，不改变 0.75 秒挥剑动画长度；高等级时多个剑实例可以共存。伤害飘字当前仅显示一位小数，显示值可能是舍入结果，不能据此反推内部精确伤害。

## 核心 GDScript

控制器升级逻辑节选：

```gdscript
func on_ability_upgrade_added(upgrade:AbilityUpgrade, current_upgrades: Dictionary):
	if upgrade.id == "剑:攻速升级":
		var percent_reduction = current_upgrades["剑:攻速升级"]["quantity"] * .1
		$Timer.wait_time = base_wait_time * (1 - percent_reduction)
		$Timer.start()
	elif upgrade.id == "剑:伤害升级":
		additional_damage_percent = 1 + (current_upgrades["剑:伤害升级"]["quantity"] * .15)
```

`base_wait_time` 在 ready 时保存，因此每级相对初始间隔计算，不是每级继续乘 0.9。选敌排序用距离平方避免开方；完整代码见控制器 `on_timer_timeout()`。

实体在 ready 时接收火焰配置：

```gdscript
func _ready() -> void:
	if burn_config != null and burn_config.is_valid():
		hitbox_component.burn_config = burn_config

# 由 swing 方法轨道调用，与碰撞有效窗口对齐。
func start_fire() -> void:
	if hitbox_component.burn_config == null:
		return
	$Sprite2D/FireSlash.show()
	$Sprite2D/FireSlash.play()
	$Sprite2D/Embers.emitting = true
```

`start_fire()` 由场景的方法轨道调用，不能因为脚本中没有直接调用它就删除。

## 动画、变种与调参

`swing` 的碰撞启用窗口为 0.1–0.4 秒；0.1 秒开始火焰、0.4 秒停止火星发射、0.75 秒 `queue_free()`。火星寿命 0.25 秒，留出消散时间。

- 普通剑：控制器 `burn_config = null`。
- 火焰剑：引用 [sword_fire.tres](../../resource/buffs/sword_fire.tres)，默认 6 秒、每 2 秒 3 点，橙红色飘字；重复命中只刷新持续时间，不推迟下一跳。
- 剑伤害升级不增强灼烧，攻速升级也不改变灼烧间隔。火焰不是升级卡，不依赖局外存档解锁。

详细代码、素材许可和 34 项原回归见 [火焰附魔实现](../FIRE_BUFF.md)。未来冰剑、叠层、暴击均未实现，不将目录中的图片当作玩法。

## 定向验证

```sh
python3 tools/run_combat_lab.py --enemy 蝙蝠 --weapon 剑
python3 tools/run_combat_lab.py --enemy 蝙蝠 --weapon 剑 --no-fire
```

按 U 升级后观察直接伤害和生成频率；走出范围应停止产生新剑。当前专项回归检查满级倍率 1.75、周期 0.5 秒及单武器安装；完整画面和手感需交互观察。更新记录见 [VARIANTS.md](VARIANTS.md)。
