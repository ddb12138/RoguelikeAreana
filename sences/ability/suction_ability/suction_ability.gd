extends Node

@export var suction_range: float = 200.0
@export var suction_strength: float = 50.0

var source: Node2D
var turnSwitch: bool = false

func _ready() -> void:
	source = get_parent() as Node2D

func turn_off_suction() -> void:
	turnSwitch = false
	remove_from_group("suction_sources")

func turn_on_suction() -> void:
	turnSwitch = true
	add_to_group("suction_sources")

# Legacy experiment entry: register the source; the player owns movement.
func apply_suction(user_body: CharacterBody2D) -> void:
	source = user_body
	turn_on_suction()

func get_suction_velocity(target: Node2D) -> Vector2:
	if !turnSwitch || !is_instance_valid(source) || source.is_queued_for_deletion():
		return Vector2.ZERO
	if !is_instance_valid(target) || target.is_queued_for_deletion():
		return Vector2.ZERO
	var offset = source.global_position - target.global_position
	if offset.length_squared() > suction_range * suction_range:
		return Vector2.ZERO
	return offset.normalized() * suction_strength
