extends Area2D
class_name HurtboxComponent

signal hit

@export var health_component: HealthComponent
@export var buff_component: BuffManager

var floating_text_scene = preload("res://sences/ui/floating_text.tscn")

func _ready() -> void:
	area_entered.connect(on_area_entered)

func showDamageText(damageFloat:float, text_color: Color = Color.WHITE):
	var floating_text = floating_text_scene.instantiate() as Node2D
	get_tree().get_first_node_in_group("foreground_layer").add_child(floating_text)
	
	floating_text.global_position = global_position + (Vector2.UP * 16)
	var format_string = "%0.1f"
	if round(damageFloat) == damageFloat:
		format_string = "%0.0f"
	floating_text.start(format_string % damageFloat, text_color)

func on_area_entered(other_area: Area2D):
	if not other_area is HitboxComponent:
		return
	var hitbox_component = other_area as HitboxComponent
	on_hit(hitbox_component.damage)
	if buff_component != null:
		buff_component.add_burn(hitbox_component.burn_config, self)

func on_hit(damage: float):
	if health_component == null or health_component.current_health <= 0:
		return
		
	health_component.damage(damage)
	showDamageText(damage)	
	hit.emit()

# 周期伤害保留生命变化/死亡链路，不重播物理命中的音效。
func apply_periodic_damage(damage: float, text_color: Color) -> void:
	if health_component == null or health_component.current_health <= 0:
		return
	health_component.damage(damage)
	showDamageText(damage, text_color)
