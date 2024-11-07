extends Node2D

@onready var hitbox_component: HitboxComponent = $HitboxComponent
var player: Node2D

const RADIUS = 10 #距离玩家多少个像素

var base_rotation = 45
var current_direction = Vector2.ZERO
var player_offset_y = 8
	

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D


func _process(delta: float) -> void:
	current_direction = Vector2.RIGHT.rotated(deg_to_rad(base_rotation))
	print(current_direction)
	global_position = player.global_position + (Vector2.UP * player_offset_y)  + (current_direction * RADIUS)
	rotation_degrees = base_rotation + 90
