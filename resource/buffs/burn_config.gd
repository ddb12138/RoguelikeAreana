extends Resource
class_name BurnConfig

@export_range(0.1, 60.0, 0.1, "or_greater") var duration: float = 6.0
@export_range(0.05, 30.0, 0.05, "or_greater") var tick_interval: float = 2.0
@export_range(0.1, 100.0, 0.1, "or_greater") var tick_damage: float = 3.0
@export var damage_color: Color = Color(1.0, 0.38, 0.08)

func is_valid() -> bool:
	return is_finite(duration) and duration > 0.0 \
		and is_finite(tick_interval) and tick_interval >= 0.05 \
		and is_finite(tick_damage) and tick_damage > 0.0
