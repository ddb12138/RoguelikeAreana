extends Node

@export var huge_sword_ability_scene: PackedScene

var base_damage = 25
var per_rotation_angle = 45
var now_rotation_angle = 0

func _ready() -> void:
	$Timer.timeout.connect(on_timer_timeout)

func on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D	
	if player == null:
		return
		
	var foreground = get_tree().get_first_node_in_group("foreground_layer")	 as Node2D
	if foreground == null:
		return
	
	var huge_sword_instance = huge_sword_ability_scene.instantiate() as Node2D
	foreground.add_child(huge_sword_instance)
	huge_sword_instance.base_rotation = now_rotation_angle
	huge_sword_instance.global_position = player.global_position
	huge_sword_instance.hitbox_component.damage = base_damage
	now_rotation_angle += per_rotation_angle
