extends Node2D
class_name SwordAbility

var burn_config: BurnConfig
@onready var hitbox_component: HitboxComponent = $HitboxComponent

func _ready() -> void:
	if burn_config != null and burn_config.is_valid():
		hitbox_component.burn_config = burn_config

# 由 swing 方法轨道调用，与碰撞有效窗口对齐。
func start_fire() -> void:
	if hitbox_component.burn_config == null:
		return
	$Sprite2D/FireSlash.show()
	$Sprite2D/FireSlash.play()
	$Sprite2D/Embers.emitting = true

func stop_fire() -> void:
	$Sprite2D/Embers.emitting = false

func _on_fire_slash_finished() -> void:
	$Sprite2D/FireSlash.hide()
