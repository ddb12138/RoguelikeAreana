extends CharacterBody2D

@export var wake_up_range:float = 200.0
@export var sleep_range:float = 300.0

@onready var suction_ability: Node = $SuctionAbility
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var velocity_component: Node = $VelocityComponent

var player:Node2D
var isPlayingAnimation:bool =  false
@export var isChasing:bool = false

func _ready() -> void:
	$HurtboxComponent.hit.connect(on_hit)
	player = get_tree().get_first_node_in_group("player") as Node2D


func _process(delta: float) -> void:
	var distance = player.global_position.distance_to(global_position)
	if distance <= wake_up_range && !isPlayingAnimation && !isChasing:
		play_wake_up()
	elif distance > sleep_range && !isPlayingAnimation && isChasing:
		play_sleep()
	if isChasing:
		suction_ability.apply_suction(self)
		velocity_component.accelerate_to_player()
		velocity_component.move(self)

func set_chasing_state(state:bool):
	isChasing = state

func set_play_state(state: bool):
	isPlayingAnimation = state

func on_hit():
	$HitRandomAudioPlayerComponent.play_random()



func play_idle():
	animation_player.play("idle")
	
func play_wake_up():
	animation_player.play("wakeup")
	
func play_chase():
	animation_player.play("chase")
	
func play_sleep():
	suction_ability.turn_off_suction()
	animation_player.play("RESET")
	animation_player.play("sleep")
