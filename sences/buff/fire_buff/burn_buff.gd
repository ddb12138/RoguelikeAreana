extends BuffBase
class_name BurnBuff

const VISUAL_SCENE = preload("res://sences/buff/fire_buff/burn_visual.tscn")
const TIME_EPSILON: float = 0.000001

var hurtbox: Node
var visual_offset: Vector2
var visual_scale: float = 0.22
var remaining_time: float = 0.0
var time_until_tick: float = 0.0
var tick_interval: float = 2.0
var tick_damage: float = 3.0
var damage_color: Color
var visual: Node2D
var initialized: bool = false

func _ready() -> void:
	visual = VISUAL_SCENE.instantiate() as Node2D
	_parentNode.add_child(visual)
	visual.position = visual_offset
	visual.scale = Vector2.ONE * visual_scale

func refresh(config: BurnConfig) -> void:
	# 仅复制数值；Resource 不保存敌人的运行状态。
	remaining_time = config.duration
	tick_interval = config.tick_interval
	tick_damage = config.tick_damage
	damage_color = config.damage_color
	if not initialized:
		time_until_tick = tick_interval
		initialized = true

func advance(delta: float) -> void:
	if not is_instance_valid(hurtbox) or _heath_component.current_health <= 0:
		remaining_time = 0.0
		return
	# 仅结算有效持续期；低帧率跨过多个间隔时逐跳补齐。
	var active_delta: float = minf(delta, remaining_time)
	remaining_time = maxf(remaining_time - active_delta, 0.0)
	time_until_tick -= active_delta
	while time_until_tick <= TIME_EPSILON:
		hurtbox.apply_periodic_damage(tick_damage, damage_color)
		_trigger_times += 1
		time_until_tick += tick_interval
		if _heath_component.current_health <= 0:
			remaining_time = 0.0
			break

func check_buff_alive() -> bool:
	return remaining_time > TIME_EPSILON and _heath_component.current_health > 0

func destory_buff() -> void:
	if is_instance_valid(visual):
		visual.queue_free()
	super.destory_buff()

func _exit_tree() -> void:
	if is_instance_valid(visual) and not visual.is_queued_for_deletion():
		visual.queue_free()
