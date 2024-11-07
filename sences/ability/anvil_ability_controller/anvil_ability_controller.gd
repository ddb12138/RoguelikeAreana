extends Node

const BASE_RANGE = 100
const BASE_DAMAGE = 15
var additional_damage_percent = 1
var anvil_count = 0

@export var anvil_ability_scene: PackedScene

func _ready() -> void:
	$Timer.timeout.connect(on_timer_out)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)

func on_timer_out():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	var additional_rotation_degress = 360.0 / (anvil_count + 1)
	var anvil_distance = randf_range(0, BASE_RANGE)
	for i in anvil_count + 1 :
		var adjusted_direction = direction.rotated(deg_to_rad(i * additional_rotation_degress))
		var spwan_position = player.global_position +  (adjusted_direction * anvil_distance)
		
		var query_paramaters = PhysicsRayQueryParameters2D.create(player.global_position, spwan_position, 1<<0)
		var result = get_tree().root.world_2d.direct_space_state.intersect_ray(query_paramaters)	
		if !result.is_empty():
			spwan_position = result["position"]
		
		var anvil_ability = anvil_ability_scene.instantiate()
		get_tree().get_first_node_in_group("foreground_layer").add_child(anvil_ability)
		anvil_ability.global_position = spwan_position
		anvil_ability.hitbox_component.damage = BASE_DAMAGE * additional_damage_percent

func on_ability_upgrade_added(upgrade:AbilityUpgrade, current_upgrades: Dictionary):
	if upgrade.id == "铁毡:伤害升级":
		additional_damage_percent = 1 + (current_upgrades["铁毡:伤害升级"]["quantity"] * .10)
	if upgrade.id == "铁毡:数量升级":
		anvil_count = current_upgrades["铁毡:数量升级"]["quantity"]
