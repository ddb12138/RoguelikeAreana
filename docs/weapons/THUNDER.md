# 闪电：多目标连线与五种强化

核查日期：2026-09-20。

## 简要说明与入口

[thunder.tres](../../resource/upgrades/thunder.tres) 解锁 ID `闪电`，上限 1。安装 [控制器脚本](../../sences/ability/thunder_ability_controller/thunder_ability_controller.gd) / [场景](../../sences/ability/thunder_ability_controller/thunder_ability_controller.tscn)。实际初始值来自控制器，并覆盖实体的导出默认值：

- 5 秒一轮、1 条闪电；每条最多 3 个目标。
- 距离严格小于 100、每目标 5 伤害。
- Line2D 直接调用 Hurtbox，不使用物理 Hitbox。

## 升级选项

解锁后以下五项同时进入池，权重各 100。

| 资源／ID | 上限 | 每次效果 | 满级 |
| --- | --- | --- | --- |
| [thunder_distance.tres](../../resource/upgrades/thunder_distance.tres)：`闪电:距离` | 2 | 距离 +50 | 200 |
| [thunder_damage.tres](../../resource/upgrades/thunder_damage.tres)：`闪电:伤害` | 5 | 每目标伤害 +5 | 30 |
| [thunder_amount.tres](../../resource/upgrades/thunder_amount.tres)：`闪电:人数` | 5 | 每条目标上限 +1 | 8 |
| [thunder_ability_num.tres](../../resource/upgrades/thunder_ability_num.tres)：`闪电:数量` | 2 | 独立闪电实例 +1 | 3 条 |
| [thunder_rate.tres](../../resource/upgrades/thunder_rate.tres)：`闪电:频率` | 5 | 周期 `5 × (1 - 0.1n)` 秒 | 2.5 秒 |

“人数”与“数量”不同：3 条、每条 8 人不保证命中 24 个不同敌人，各条可以选择相同目标。没有已实现火焰闪电或其他独立变种。

## 核心 GDScript

[控制器](../../sences/ability/thunder_ability_controller/thunder_ability_controller.gd) 的升级节选：

```gdscript
func on_ability_upgrade_added(upgrade:AbilityUpgrade, current_upgrades: Dictionary):
	if upgrade.id == "闪电:距离":
		LightDistance += 50 
	elif upgrade.id == "闪电:伤害":
		LightDamage += 5
	elif upgrade.id == "闪电:人数":
		LightAmount += 1
	elif upgrade.id == "闪电:数量":
		LightAbilityNum += 1
		reset_ability_scene()
	elif upgrade.id == "闪电:频率":
		var percent_reduction = current_upgrades["闪电:频率"]["quantity"] * .1
		timer.wait_time = base_wait_time * (1 - percent_reduction)
		timer.start()
		return
	else:
		return
	reset_ability_data()
```

增加“数量”时创建额外的常驻 Line2D；`reset_ability_data()` 将人数、距离和伤害同步到所有已有实例。其他武器多在攻击后释放，闪电实例则保留，攻击结束清空路径以待下次复用。

## 当前选敌算法的真实行为

[thunder.gd](../../sences/ability/thunder_ability/thunder.gd) 的 `findNearestEnemy()` 虽名为“找最近”，当前实现**没有按距离排序**：先过滤范围，从 Group 返回结果前 N 个取目标，再 shuffle 顺序。不要把函数名当作算法证据。

关键节选：

```gdscript
var iterNum = min(LightAmount, enemies.size())
for i in iterNum:
	LightEnemies.append(enemies[i])
LightEnemies.shuffle()
```

每段调用 `toEnemy.hurtbox_component.on_hit(LightDamage)` 扣血，再 `await draw_lighting(from, to)` 绘制折线。中间点加入随机偏移，使线条呈现锯齿闪电效果。端点取自此次读取的位置，不是每帧追踪目标。

## 已知限制与定向验证

当前源码在多次 await 之间保存敌人引用，只检查 `== null`，尚未充分保护已经释放的对象；绘制用的 `create_timer(..., true)` 在暂停时仍可推进。这些是待修复风险，不是建议照抄的异步写法；本次文档与实验场任务没有修改闪电实现。

```sh
python3 tools/run_combat_lab.py --enemy 蝙蝠 --weapon 闪电 --max-enemies 8
```

在实验场配置 `max_enemies` 大于 1 后更适合观察连锁；按 U 观察五条分支。回归验证共 19 次强化及满级 3 条／8 人／30 伤害／200 距离／2.5 秒，未证明异步选敌在大群死亡场景下安全。2026-09-20 建立本文与定向入口；见 [VARIANTS.md](VARIANTS.md)。
