extends Node

@export var thunder_ability_scene: PackedScene
@export var LightAmount = 3 #闪电攻击人数
@export var LightDistance = 100 #闪电有效距离
@export var LightDamage = 5 #闪电伤害
@export var LightAbilityNum = 1 #闪电数量
@onready var timer: Timer = $Timer

var LightAbilitySceneArray:Array = [] #当前正在执行闪电的实例
var base_wait_time

func _ready() -> void:
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	base_wait_time = timer.wait_time
	timer.timeout.connect(on_time_out)
	reset_ability_scene()

#初始化闪电数据
func reset_ability_scene():
	if (LightAbilitySceneArray.size() >= LightAbilityNum):
		return
	
	var wait_init_num = LightAbilityNum - LightAbilitySceneArray.size() 
	for i in wait_init_num:
		#初始化闪电数量
		var thunder_ability_instance = thunder_ability_scene.instantiate()
		get_tree().get_first_node_in_group("foreground_layer").add_child(thunder_ability_instance)
		LightAbilitySceneArray.push_back(thunder_ability_instance)
	reset_ability_data()

#重置闪电数值
func reset_ability_data():
	for ability in LightAbilitySceneArray:
		#初始化闪电数值
		ability.LightAmount = LightAmount
		ability.LightDistance = LightDistance
		ability.LightDamage = LightDamage

#闪电升级事件
func on_ability_upgrade_added(upgrade:AbilityUpgrade, current_upgrades: Dictionary):
	if upgrade.id == "闪电:距离":
		LightDistance += 50 
	elif upgrade.id == "闪电:伤害":
		LightDamage += 5
	elif upgrade.id == "闪电:人数":
		LightAmount += 1
	elif upgrade.id == "闪电:数量":
		LightAbilityNum += 1
		reset_ability_scene()
	elif upgrade.id == "闪电:频率":
		var percent_reduction = current_upgrades["闪电:频率"]["quantity"] * .1
		timer.wait_time = base_wait_time * (1 - percent_reduction)
		timer.start()
		return
	else:
		return
	reset_ability_data()

#闪电攻击事件
func on_time_out():
	for i in LightAbilitySceneArray:
		i.call_thunder_func()
