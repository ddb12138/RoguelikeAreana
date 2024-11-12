extends Node

@export var suction_range: float = 200.0
@export var suction_strength: float = 50.0

var player:Node2D
var turnSwitch: bool = true

func _ready():
	player = get_tree().get_first_node_in_group("player") as Node2D

func turn_off_suction():
	turnSwitch = false

func turn_on_sction():
	turnSwitch = true	

func apply_suction(user_body: CharacterBody2D):
	if !turnSwitch:
		return
		
	var distance = player.global_position.distance_to(user_body.global_position)
	if distance <= suction_range:
		var direction = (user_body.global_position - player.global_position ).normalized()
		var desired_velocity = direction * suction_strength
		player.velocity = desired_velocity
		player.move_and_slide()
		
