extends CharacterBody2D
@onready var velocity_component = $VelocityComponent
@onready var visuals = $Visuals
@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent

var angry_state = preload("res://sences/game_object/wizard_enemy/angry_state.tres")

var is_moving = false
var is_angry: bool = false

func _ready() -> void:
	$HurtboxComponent.hit.connect(on_hit)
	$HealthComponent.died.connect(on_die)
	$HealthComponent.health_changed.connect(on_health_changed)
	

func _process(delta: float) -> void:
	if is_moving:
		velocity_component.accelerate_to_player()
	else:
		velocity_component.decelarate()	
	velocity_component.move(self)
	
	var move_sign = sign(velocity.x)
	if move_sign != 0:
		visuals.scale = Vector2(-move_sign, 1)

func set_is_moving(moving: bool):
	is_moving = moving

func on_hit():
	$HitRandomAudioPlayerComponent.play_random()

func on_health_changed() -> void:
	if not is_angry and health_component.current_health > 0 and health_component.get_health_percent() <= 0.5:
		is_angry = true
		$AnimationPlayer.play("disappear")
		sprite_2d.material = angry_state

func on_die():
	sprite_2d.modulate.a = 1
