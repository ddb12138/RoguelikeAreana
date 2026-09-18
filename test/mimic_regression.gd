extends Node

var failures: int = 0
var player: CharacterBody2D
var mimic: CharacterBody2D

func check(condition: bool, label: String) -> void:
	if !condition:
		failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)

func wait_seconds(seconds: float) -> void:
	var elapsed = 0.0
	while elapsed < seconds:
		await get_tree().process_frame
		elapsed += get_process_delta_time()

func place_player(offset: Vector2) -> void:
	player.global_position = mimic.global_position + offset
	player.velocity = Vector2.ZERO
	player.velocity_component.velocity = Vector2.ZERO

func _ready() -> void:
	# Exercise actual scene bindings; disable unrelated combat in this fixture.
	player = load("res://sences/game_object/player/player.tscn").instantiate()
	add_child(player)
	player.get_node("Abilities").process_mode = Node.PROCESS_MODE_DISABLED
	player.get_node("BuffComponent").process_mode = Node.PROCESS_MODE_DISABLED
	player.get_node("CollisonArea2D").collision_mask = 0
	mimic = load("res://sences/game_object/mimic_chest_enemy/mimic_chest_enemy.tscn").instantiate()
	add_child(mimic)
	place_player(Vector2(200, 0))
	await wait_seconds(0.1)
	check(mimic.state == mimic.State.IDLE, "outside wake range remains idle")
	check(!mimic.suction_ability.turnSwitch, "idle has no suction")

	# Reproduce the old skipped method key at 0.595 / 0.600 seconds.
	mimic.set_process(false)
	var animation = mimic.animation_player
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	place_player(Vector2(80, 0))
	mimic.enter_state(mimic.State.WAKING)
	animation.advance(0.595)
	await get_tree().process_frame
	check(mimic.state == mimic.State.WAKING, "wakeup cannot switch before completion")
	animation.advance(0.02)
	await get_tree().process_frame
	check(mimic.state == mimic.State.CHASING, "crossing animation end starts chase")
	check(mimic.suction_ability.turnSwitch, "chase starts suction")
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	mimic.set_process(true)
	var start = mimic.global_position
	await wait_seconds(0.2)
	check(mimic.global_position.x > start.x + 1, "activated chest actually moves toward player")

	for cycle in 3:
		place_player(Vector2(200, 0))
		await wait_seconds(0.1)
		check(mimic.state == mimic.State.SLEEPING, "leaving range starts sleep %d" % cycle)
		check(!mimic.suction_ability.turnSwitch && mimic.velocity.is_zero_approx(), "sleep immediately stops movement and pull %d" % cycle)
		start = mimic.global_position
		await wait_seconds(0.7)
		check(mimic.state == mimic.State.IDLE && mimic.global_position.is_equal_approx(start), "sleep completes without drifting %d" % cycle)
		place_player(Vector2(80, 0))
		await wait_seconds(0.8)
		check(mimic.state == mimic.State.CHASING && mimic.suction_ability.turnSwitch, "natural wake restores chase and pull %d" % cycle)

	# Hysteresis: 100..150 retains the existing idle/chase state.
	place_player(Vector2(125, 0))
	await wait_seconds(0.1)
	check(mimic.state == mimic.State.CHASING, "chasing persists between thresholds")
	mimic.enter_state(mimic.State.IDLE)
	place_player(Vector2(125, 0))
	await wait_seconds(0.1)
	check(mimic.state == mimic.State.IDLE, "idle persists between thresholds")
	place_player(Vector2(80, 0))
	await wait_seconds(0.1)
	place_player(Vector2(200, 0))
	await wait_seconds(0.8)
	check(mimic.state == mimic.State.IDLE, "leaving during wake cancels activation")

	# Keep the chest fixed to measure the real player's integration of suction.
	mimic.set_process(false)
	mimic.enter_state(mimic.State.CHASING)
	place_player(Vector2(80, 0))
	var player_start = player.global_position
	await wait_seconds(0.2)
	check(player.global_position.x < player_start.x - 1, "stationary player is pulled toward chest")
	check(player.velocity_component.velocity.is_zero_approx(), "pull does not accumulate into input velocity")
	Input.action_press("move_right")
	player_start = player.global_position
	await wait_seconds(0.3)
	check(player.global_position.x > player_start.x + 10, "player can move against pull")
	Input.action_release("move_right")
	place_player(Vector2(200, 0))
	player_start = player.global_position
	await wait_seconds(0.2)
	check(player.global_position.is_equal_approx(player_start), "no pull outside suction radius")
	place_player(Vector2(80, 0))
	mimic.enter_state(mimic.State.IDLE)
	player_start = player.global_position
	await wait_seconds(0.2)
	check(player.global_position.is_equal_approx(player_start), "sleep leaves no residual pull")

	# Two opposite sources cancel instead of overwriting each other.
	var second = load("res://sences/game_object/mimic_chest_enemy/mimic_chest_enemy.tscn").instantiate()
	add_child(second)
	second.set_process(false)
	second.global_position = player.global_position + Vector2(80, 0)
	second.enter_state(second.State.CHASING)
	mimic.enter_state(mimic.State.CHASING)
	player_start = player.global_position
	await wait_seconds(0.2)
	check(player.global_position.is_equal_approx(player_start), "opposite chest pulls combine symmetrically")
	second.queue_free()
	await get_tree().process_frame

	# Collision still resolves while an external velocity is present.
	var wall = StaticBody2D.new()
	wall.collision_layer = 1
	var shape = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(10, 200)
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = mimic.global_position + Vector2(40, 0)
	add_child(wall)
	place_player(Vector2(55, 0))
	await wait_seconds(0.8)
	check(player.global_position.x > wall.global_position.x + 5, "suction cannot pull player through terrain")
	wall.queue_free()
	await get_tree().process_frame

	place_player(Vector2(80, 0))
	player_start = player.global_position
	get_tree().paused = true
	await get_tree().create_timer(0.1, true).timeout
	check(player.global_position.is_equal_approx(player_start), "pause freezes pull")
	get_tree().paused = false

	mimic.queue_free()
	await get_tree().process_frame
	player_start = player.global_position
	await wait_seconds(0.2)
	check(player.global_position.is_equal_approx(player_start), "freed source leaves no pull")
	check(get_tree().get_nodes_in_group("suction_sources").is_empty(), "freed sources leave group")

	mimic = load("res://sences/game_object/mimic_chest_enemy/mimic_chest_enemy.tscn").instantiate()
	add_child(mimic)
	mimic.enter_state(mimic.State.CHASING)
	player.queue_free()
	await wait_seconds(0.1)
	check(mimic.state == mimic.State.IDLE && !mimic.suction_ability.turnSwitch, "missing player safely stops chase")
	mimic.queue_free()
	await get_tree().process_frame
	print("MIMIC_REGRESSION failures=", failures)
	get_tree().quit(1 if failures else 0)
