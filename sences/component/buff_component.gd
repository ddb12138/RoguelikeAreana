extends Node
class_name BuffManager


@export var health_component: HealthComponent
@export var velocity_component: Node
@export var burn_visual_offset: Vector2 = Vector2(0, -8)
@export var burn_visual_scale: float = 0.22

const BURN_SCENE = preload("res://sences/buff/fire_buff/burn_buff.tscn")
var active_burn: BurnBuff
@onready var parentNode:Node

var buff_list = {
	"buff_heal": preload("res://sences/buff/heal_buff/HealBuff.tscn"),
}

var current_buff_list:Array = [] #当前buff队列

func _ready() -> void:
	parentNode = get_parent()

func _process(delta: float) -> void:
	update_buff_by_delta(delta)

#定时刷新buff队列
func update_buff_by_delta(delta: float) ->void:
	if current_buff_list.size() == 0:
		return
	
	var remove_buff_list:Array = [] #过期buff列表
	for ind in range(current_buff_list.size()):	#遍历buff
		var buff = current_buff_list[ind] as BuffBase
		buff.advance(delta)
		
		if !buff.check_buff_alive():	#判断buff是否存活
			remove_buff_list.append(ind)

	if remove_buff_list.size() == 0:
		return
		
	remove_buff_list.reverse() 	#反向遍历删除	
	for rem_ind in remove_buff_list:
		var expired_buff = current_buff_list[rem_ind] as BuffBase
		if expired_buff == active_burn:
			active_burn = null
		expired_buff.destory_buff()
		current_buff_list.remove_at(rem_ind)

#添加buff函数
func add_buff(buff_name: String):
	var buff = buff_list.get(buff_name)
	if buff == null:
		print_debug("存在的buff:", buff_name)
		return
	var buff_instance = buff.instantiate() as BuffBase
	buff_instance._parentNode = parentNode
	buff_instance._heath_component = health_component
	buff_instance._velocity_component = velocity_component
	add_child(buff_instance)
	current_buff_list.push_back(buff_instance)

# 同一敌人只保留一个灼烧实例，刷新持续时间不重置下一跳。
func add_burn(config: BurnConfig, hurtbox: Node) -> void:
	if config == null or not config.is_valid() or health_component == null:
		return
	if health_component.current_health <= 0:
		return
	if is_instance_valid(active_burn) and not active_burn.is_queued_for_deletion():
		active_burn.refresh(config)
		return
	active_burn = BURN_SCENE.instantiate() as BurnBuff
	active_burn._parentNode = parentNode
	active_burn._heath_component = health_component
	active_burn.hurtbox = hurtbox
	active_burn.visual_offset = burn_visual_offset
	active_burn.visual_scale = burn_visual_scale
	active_burn.refresh(config)
	add_child(active_burn)
	current_buff_list.append(active_burn)
