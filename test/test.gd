extends Node

@onready var timer: Timer = $Timer

var a = preload("res://sences/buff/heal_buff/HealBuff.tscn")

func _ready() -> void:
	timer.timeout.connect(add_buff)
	
func add_buff():
	var ts = a.instantiate()
	ts.apply_buff()
	#print("定时器启动加buff了")
	#var player = get_tree().get_first_node_in_group("player")
	#player.buff_component.add_buff_by_name_signal.emit("治疗")
