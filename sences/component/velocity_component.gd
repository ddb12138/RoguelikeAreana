extends Node

@export var max_speed:int = 40
@export var acceleration: float = 5

var velocity = Vector2.ZERO

func accelerate_to_player():
	var owner_node2d = owner as Node2D
	if owner_node2d == null:
		return
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
		
	var direction = (player.global_position - owner_node2d.global_position).normalized()
	accelerate_in_direction(direction)

func accelerate_in_direction(direction: Vector2):
	var desired_velocity = direction * max_speed
	velocity = velocity.lerp(desired_velocity, 1 - exp(-acceleration * get_process_delta_time()))

func decelarate():
	accelerate_in_direction(Vector2.ZERO)

func move(character_body: CharacterBody2D, external_velocity: Vector2 = Vector2.ZERO):
	character_body.velocity = velocity + external_velocity
	character_body.move_and_slide()
	if external_velocity.is_zero_approx():
		velocity = character_body.velocity
	else:
		# Keep the temporary pull out of the persistent movement velocity.
		for i in character_body.get_slide_collision_count():
			var normal = character_body.get_slide_collision(i).get_normal()
			if velocity.dot(normal) < 0:
				velocity = velocity.slide(normal)
