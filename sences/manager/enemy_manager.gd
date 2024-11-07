extends Node

#敌人生成半径
const SPAWN_RADIUS = 200

@export var basic_enemy_scene: PackedScene
@export var wizard_enemy_scene: PackedScene
@export var bat_enemy_scene: PackedScene
@export var arena_time_manager: Node

@onready var timer = $Timer

var base_spwan_time = 0
var enemy_table = WeightedTable.new()
var number_to_swpan = 1

var wizard_generate = false
var bat_generate = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemy_table.add_item(basic_enemy_scene, 30)
	base_spwan_time = timer.wait_time
	timer.timeout.connect(on_timer_timeout)
	arena_time_manager.arena_difficulty_increased.connect(on_arena_difficulty_increased)

# 基本思路: 利用射线，看与周围的环境有没有碰撞，有则旋转90度
func get_spawn_position():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:	
		return Vector2.ZERO
		
	var spawn_postion = Vector2.ZERO
	var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	for i in 4:
		spawn_postion = player.global_position + (random_direction * SPAWN_RADIUS)	
		var additional_check_offset = random_direction * 20
	
		var query_paramaters = PhysicsRayQueryParameters2D.create(player.global_position, spawn_postion + additional_check_offset, 1<<0)
		var result = get_tree().root.world_2d.direct_space_state.intersect_ray(query_paramaters)
		if result.is_empty():
			break
		else:
			random_direction = random_direction.rotated(deg_to_rad(90))
	
	return spawn_postion	
	
func on_timer_timeout():
	timer.start()
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:	
		return
	
	for i in number_to_swpan:
		var enemy_scene = enemy_table.pick_item()
		var enemy = enemy_scene.instantiate() as Node2D
		
		var entities_layer = get_tree().get_first_node_in_group("entites_layer")
		entities_layer.add_child(enemy)
		enemy.global_position = get_spawn_position()
	
func on_arena_difficulty_increased(arena_difficulty: int):
	var time_off = (.1/12) * arena_difficulty
	time_off = min(time_off, .7)
	timer.wait_time = base_spwan_time - time_off
	#print("当前敌人生成时间为" , (base_spwan_time - time_off))	
	if arena_difficulty == 3 && !wizard_generate:
		enemy_table.add_item(wizard_enemy_scene, 20)
		wizard_generate = true
		number_to_swpan += 1

	if arena_difficulty == 6 && !bat_generate:
		enemy_table.add_item(bat_enemy_scene, 10)
		bat_generate = true
		number_to_swpan += 1
	
