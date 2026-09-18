extends CharacterBody2D

enum State { IDLE, WAKING, CHASING, SLEEPING }

@export var wake_up_range: float = 200.0
@export var sleep_range: float = 300.0

@onready var suction_ability: Node = $SuctionAbility
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var velocity_component: Node = $VelocityComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent

var player: Node2D
var state: State = State.IDLE

func _ready() -> void:
	$HurtboxComponent.hit.connect(on_hit)
	animation_player.animation_finished.connect(on_animation_finished)
	player = get_tree().get_first_node_in_group("player") as Node2D
	enter_state(State.IDLE)

func _process(_delta: float) -> void:
	if !is_instance_valid(player) || player.is_queued_for_deletion():
		if state != State.IDLE:
			enter_state(State.IDLE)
		return

	var distance = player.global_position.distance_to(global_position)
	if state == State.IDLE && distance <= wake_up_range:
		enter_state(State.WAKING)
	elif (state == State.WAKING || state == State.CHASING) && distance > sleep_range:
		enter_state(State.SLEEPING)

	if state == State.CHASING:
		velocity_component.accelerate_to_player()
		velocity_component.move(self)

func enter_state(next_state: State) -> void:
	state = next_state
	if state == State.CHASING:
		suction_ability.turn_on_suction()
		animation_player.play("chase")
		return

	suction_ability.turn_off_suction()
	velocity = Vector2.ZERO
	velocity_component.velocity = Vector2.ZERO
	match state:
		State.IDLE:
			animation_player.play("idle")
		State.WAKING:
			animation_player.play("wakeup")
		State.SLEEPING:
			# Reset chase squash/rotation before closing the chest.
			animation_player.play("RESET")
			animation_player.advance(0)
			animation_player.play("sleep")

func on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"wakeup" && state == State.WAKING:
		if is_instance_valid(player) && !player.is_queued_for_deletion() \
				&& player.global_position.distance_to(global_position) <= sleep_range:
			enter_state(State.CHASING)
		else:
			enter_state(State.SLEEPING)
	elif animation_name == &"sleep" && state == State.SLEEPING:
		enter_state(State.IDLE)

func on_hit() -> void:
	$HitRandomAudioPlayerComponent.play_random()
