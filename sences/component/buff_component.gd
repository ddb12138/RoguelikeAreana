extends Node
class_name BuffManager


@export var health_component: HealthComponent
@export var velocity_component: Node
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
		buff.calculate_time_pass(delta)	#统一调整buff时间
		if buff.try_active_buff():	#判断是否可触发buff效果
			buff.apply_buff()
		
		if !buff.check_buff_alive():	#判断buff是否存活
			remove_buff_list.append(ind)

	if remove_buff_list.size() == 0:
		return
		
	remove_buff_list.reverse() 	#反向遍历删除	
	for rem_ind in remove_buff_list:
		current_buff_list.remove_at(rem_ind)

#添加buff函数
func add_buff(buff_name: String):
	var buff = buff_list[buff_name]
	if buff == null:
		print_debug("存在的buff:", buff_name)
		return
	var buff_instance = buff.instantiate() as BuffBase
	buff_instance._parentNode = parentNode
	buff_instance._heath_component = health_component
	buff_instance._velocity_component = velocity_component
	add_child(buff_instance)
	current_buff_list.push_back(buff_instance)
