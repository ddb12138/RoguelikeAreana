extends CharacterBody2D

@onready var damage_interval_timer = $DamageIntervalTimer
@onready var health_component = $HealthComponent
@onready var health_bar = $HealthBar
@onready var animation_player = $AnimationPlayer
@onready var abilities = $Abilities
@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent
@onready var buff_component: BuffManager = $BuffComponent

var number_colliding_bodies = 0 #正在碰撞玩家个数

var base_speed = 0

func _ready() -> void:
	base_speed = velocity_component.max_speed
	
	$CollisonArea2D.body_entered.connect(on_body_entered)
	$CollisonArea2D.body_exited.connect(on_body_exited)
	damage_interval_timer.timeout.connect(on_damage_interval_timer_timeout)
	health_component.health_changed.connect(on_health_changed)
	health_component.health_heal.connect(on_health_heal)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	init_meta_buff()
	update_health_display()

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var movement_vector = get_movement_vector()
	var direction = movement_vector.normalized()
	velocity_component.accelerate_in_direction(direction)
	velocity_component.move(self)

	if movement_vector.x != 0 || movement_vector.y != 0:
		animation_player.play("walk")
	else:
		animation_player.play("RESET")	

	var move_sign = sign(velocity.x)
	if move_sign != 0:
		visuals.scale = Vector2(-move_sign, 1)

# 移动函数
func get_movement_vector():
	var x_movement = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y_movement = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return Vector2(x_movement, y_movement)

# 检查玩家受伤害
func check_deal_damage():
	if number_colliding_bodies == 0 || !damage_interval_timer.is_stopped():
			return
	health_component.damage(1)
	damage_interval_timer.start()
	print(health_component.current_health)
	
func update_health_display():
	health_bar.value = health_component.get_health_percent()

func init_meta_buff():
	var meta_buff_map = MetaProgression.get_meta_buff_upgrade_info()
	for buff_name in meta_buff_map:
		buff_component.add_buff(buff_name)
	
func on_damage_interval_timer_timeout():
	check_deal_damage()

func on_body_entered(ohter_body: Node2D):
	number_colliding_bodies += 1
	check_deal_damage()
	
func on_body_exited(ohter_body: Node2D):
	number_colliding_bodies -= 1

func on_health_heal():
	GameEvents.emit_player_heal()
	update_health_display()
	$HealRandomStreamPlayer.play_random()
	
func on_health_changed():
	GameEvents.emit_player_damaged()
	update_health_display()
	$HitRandomStreamPlayer.play_random()
	
func on_ability_upgrade_added(ability_upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	if ability_upgrade is Ability:
		var ability = ability_upgrade as Ability
		abilities.add_child(ability.ability_controller_scene.instantiate())	
	elif ability_upgrade.id == "玩家移速":
		velocity_component.max_speed = base_speed + (base_speed * current_upgrades["玩家移速"]["quantity"] * .1)
