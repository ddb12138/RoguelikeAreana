# 武器与升级如何实现

核查日期：2026-09-20。本文解释当前实现；代码块均为源码节选，片段间省略的代码请点链接查看。

## 四层职责

| 层 | 负责什么 | 例子 |
| --- | --- | --- |
| 配置 Resource | 升级的 ID、文字、次数上限；解锁项还指向控制器场景 | `resource/upgrades/axe.tres` |
| 控制器 Node | 保存当前数值，Timer 到时选择目标或生成实体，接收升级信号 | `AxeAbilityController` |
| 攻击实体 Node2D | 位置、旋转、动画与碰撞窗口，结束后释放 | `AxeAbility` |
| 通用组件 | Hitbox 携带伤害；Hurtbox 扣血、飘字；Health 管死亡 | 斧头、剑、铁毡、巨剑共用 |

闪电用 Line2D 直接调用敌人 Hurtbox，属于同一受伤链的另一种入口。火焰附魔则在 Hitbox 额外携带 BurnConfig，通过敌人 BuffManager 保存周期状态。

## 从升级卡到新武器

[AbilityUpgrade](../../resource/upgrades/ability_upgrade.gd) 是基础配置；[Ability](../../resource/upgrades/ability.gd) 表示“解锁新控制器”：

```gdscript
extends AbilityUpgrade
class_name Ability

@export var ability_controller_scene: PackedScene
```

[Player](../../sences/game_object/player/player.gd) 接收 `GameEvents.ability_upgrade_added`，安装控制器：

```gdscript
func on_ability_upgrade_added(ability_upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	if ability_upgrade is Ability:
		var ability = ability_upgrade as Ability
		abilities.add_child(ability.ability_controller_scene.instantiate())	
	elif ability_upgrade.id == "玩家移速":
		velocity_component.max_speed = base_speed + (base_speed * current_upgrades["玩家移速"]["quantity"] * .1)
```

`is Ability` 是资源类型判断；普通伤害强化也是 AbilityUpgrade，但不属于 Ability，因此不会重复安装控制器。剑是例外：玩家场景默认已挂剑控制器，没有“剑解锁”资源。

## 升级数量与生效

[UpgradeManager](../../sences/manager/upgrade_manager.gd) 保存：

```gdscript
current_upgrades[upgrade.id] = {
	"resource": upgrade,
	"quantity": 1
}
```

再次选择增加 `quantity`；达到 `max_quantity > 0` 上限时从池中移除。当前 `apply_upgrade()` 依赖正常选卡入口，不是能随意重复调用的幂等接口；手工调用满级资源仍可能越界。

解锁斧头后才把伤害项加入池中：

```gdscript
func update_upgrade_pool(chosen_upgrade: AbilityUpgrade):
	if chosen_upgrade.id == upgrade_axe.id:
		upgrade_pool.add_item(upgrade_axe_damage, 10)
		return
	if chosen_upgrade.id == upgrade_anvil.id:
		upgrade_pool.add_item(upgrade_anvil_damage, 10)
		upgrade_pool.add_item(upgrade_anvil_amount, 10)
		return
	if chosen_upgrade.id == upgrade_thunder.id:
		upgrade_pool.add_item(upgrade_ability_num, 100)
		upgrade_pool.add_item(upgrade_thunder_amount, 100)
		upgrade_pool.add_item(upgrade_thunder_damage, 100)
		upgrade_pool.add_item(upgrade_thunder_distance, 100)
		upgrade_pool.add_item(upgrade_thunder_rate, 100)
```

因此**新增 `.tres` 不会自动出现在卡池里**。先更新记录和后续池，再发升级信号，控制器即可读取本次选择后的数量。

斧头按总等级重新计算伤害倍率，不是在旧伤害上不断乘 1.1：

```gdscript
func on_ability_upgrade_added(upgrade:AbilityUpgrade, current_upgrades: Dictionary):
	if upgrade.id == "斧头:伤害升级":
		additional_damage_percent = 1 + (current_upgrades["斧头:伤害升级"]["quantity"] * .10)
```

基础 10，五次强化为 `10 × (1 + 5 × 0.1) = 15`。剑和铁毡类似；闪电伤害则是每次事件直接加 5，两种写法对重复发送信号的敏感程度不同。

## 抽卡与屏蔽选项

初始池：斧头／铁毡／巨剑各权重 20，剑攻速／剑伤害各 10，玩家移速 5，闪电 30。解锁后的强化权重：斧头和铁毡各 10，闪电各 100。权重控制相对概率，不是百分比。

```gdscript
func pick_upgrades():
	# 在抽取时过滤，解锁后动态加入的强化也不会混入其他武器。
	var candidates = WeightedTable.new()
	for entry in upgrade_pool.items:
		var upgrade = entry["item"] as AbilityUpgrade
		if test_weapon_id.is_empty() or upgrade.id == test_weapon_id or upgrade.id.begins_with(test_weapon_id + ":"):
			candidates.add_item(upgrade, entry["weight"])
	var chosen_upgrades: Array[AbilityUpgrade] = []
	for i in mini(2, candidates.items.size()):
		chosen_upgrades.append(candidates.pick_item(chosen_upgrades))
	return chosen_upgrades
```

本次增加的 `test_weapon_id` 默认空字符串，正式模式保留全部候选；实验场传入“闪电”等稳定 ID，只允许解锁 ID 和同前缀强化。过滤发生在每次抽取前，因此动态加入的强化也受约束。最多抽两个不同资源；无候选时不创建升级界面，避免永久空窗或无卡暂停。

## 从攻击到掉血

[SwordAbilityController](../../sences/ability/sword_ability_controller/sword_ability_controller.gd) 初始化实例时的关键顺序：

```gdscript
var sword_instance = sword_ability.instantiate() as SwordAbility
sword_instance.burn_config = burn_config
var foreground_layer = get_tree().get_first_node_in_group("foreground_layer")
foreground_layer.add_child(sword_instance)
sword_instance.hitbox_component.damage = base_damage * additional_damage_percent
```

`add_child()` 进入场景树后会执行 `_ready()`，所以 `_ready()` 要读的火焰配置必须提前设置；`@onready` 的 Hitbox 引用则在进入树后才可读取。不能把两种赋值顺序机械交换。

[Hurtbox](../../sences/component/hurtbox_component.gd) 的命中入口：

```gdscript
func on_area_entered(other_area: Area2D):
	if not other_area is HitboxComponent:
		return
	var hitbox_component = other_area as HitboxComponent
	on_hit(hitbox_component.damage)
	if buff_component != null:
		buff_component.add_burn(hitbox_component.burn_config, self)
```

先结算直接伤害，再尝试添加灼烧；BuffManager 会拒绝已致死目标。物理武器借助 Area2D 的进入事件触发，并不等价于“持续重叠就每帧扣血”。

## 新增武器或强化的最小步骤

1. 从最相近武器复制控制器与实体，修改场景绑定，明确寿命、碰撞窗口和暂停行为。
2. 解锁用 Ability 资源并绑定 `ability_controller_scene`；强化用 AbilityUpgrade，定义稳定 ID 和上限。
3. 在 UpgradeManager 注册解锁及强化分支，在控制器实现对应升级事件。
4. 同时核对 `.tscn` 的 Timer、NodePath、碰撞层和方法轨道；不要仅靠 `.gd` 推断默认值。
5. 如需在实验场选择，补充 `combat_lab.gd` 的武器枚举与路径映射；升级过滤依赖 `武器ID:强化名`，非此前缀的设计需要同步调整过滤规则。
6. 在独立存档副本中验证初始、每级、上限、死亡／暂停和场景退出；更新对应文档与 [变种记录](VARIANTS.md)。

把现有剑加火焰是组合附魔；新增“巨剑”是独立控制器，两者并非同一种扩展方式。
