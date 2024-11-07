extends Node

#攻击判定范围
@export var MAX_RANGE:int
var base_damage = 5
var additional_damage_percent = 1
#场景动画
@export var sword_ability: PackedScene
var base_wait_time

# 负责生成剑实体逻辑
func _ready() -> void:
	base_wait_time = $Timer.wait_time
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)

func on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	#获取周围半径内的敌人
	var enemies = get_tree().get_nodes_in_group("enemy");
	enemies = enemies.filter(func(enemy:Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) < pow(MAX_RANGE, 2)	
	)
	if enemies.size() == 0:
		return

	#排序获取到最近的敌人
	enemies.sort_custom(func(a:Node2D, b:Node2D):
		var a_distance = a.global_position.distance_squared_to(player.global_position)	
		var b_distance = b.global_position.distance_squared_to(player.global_position)	
		return a_distance < b_distance
	)

	#初始化武器生成地
	var sword_instance = sword_ability.instantiate() as SwordAbility
	var foreground_layer = get_tree().get_first_node_in_group("foreground_layer")
	foreground_layer.add_child(sword_instance)
	sword_instance.hitbox_component.damage = base_damage * additional_damage_percent
	
	sword_instance.global_position = enemies[0].global_position #生成重合导致分问题
	# RIGHT代表 X正方向的量 1,0, 其中TAU就是360,也就是随机转任意角度,然后乘以4单位向量放大
	sword_instance.global_position += Vector2.RIGHT.rotated(randf_range(0, TAU)) * 4 
	var enemy_direction = enemies[0].global_position - sword_instance.global_position 
	sword_instance.rotation = enemy_direction.angle()

func on_ability_upgrade_added(upgrade:AbilityUpgrade, current_upgrades: Dictionary):
	if upgrade.id == "剑:攻速升级":
		var percent_reduction = current_upgrades["剑:攻速升级"]["quantity"] * .1
		$Timer.wait_time = base_wait_time * (1 - percent_reduction)
		$Timer.start()
	elif upgrade.id == "剑:伤害升级":
		additional_damage_percent = 1 + (current_upgrades["剑:伤害升级"]["quantity"] * .15)
