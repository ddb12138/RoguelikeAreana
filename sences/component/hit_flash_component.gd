extends Node2D


@export var health_component: Node
@export var sprite: Sprite2D
@export var hit_flash_material: ShaderMaterial
@export var flash_interval: float = .3

var hit_flash_tween: Tween

func _ready() -> void:
	health_component.health_changed.connect(on_health_changed)
	sprite.material = hit_flash_material

func on_health_changed():
	if hit_flash_tween != null && hit_flash_tween.is_valid():
		hit_flash_tween.kill()
	
	(sprite.material as ShaderMaterial).set_shader_parameter("lerp_percent", 1.0)	
	hit_flash_tween = create_tween()
	hit_flash_tween.tween_property(sprite.material, "shader_parameter/lerp_percent", 0.0, flash_interval)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)