extends Node

#管理meta技能

const SAVE_FILE_PATH = "user://game.save"

var save_data: Dictionary = {
	"meta_upgrade_currency" : 0,
	"meta_upgrades": {}
}

func _ready():
	GameEvents.experience_vial_collected.connect(on_experience_collected)
	load_save_file()
	add_meta_upgrade(load("res://resource/meta_upgrades/experience_gain.tres"))
	add_meta_upgrade(load("res://resource/meta_upgrades/health_regeneration.tres"))

#获取meta初始化buff增益效果
func get_meta_buff_upgrade_info() -> Dictionary:
	var upgrade_info_map = save_data["meta_upgrades"] as Dictionary 
	var buff_map = {} # {key: buff_name, value:quantity}
	if upgrade_info_map.size() == 0:
		return buff_map
	for id in upgrade_info_map:
		var idStr = id as String
		if idStr.begins_with("buff_"):
			buff_map[id] = upgrade_info_map[id]["quantity"]
	return buff_map

func get_upgrade_count(id:String):
	if !save_data["meta_upgrades"].has(id):
		return save_data["meta_upgrades"][id]["quantity"]
	return 0
	
func add_meta_upgrade(upgrade: MetaUpgrade):
	if !save_data["meta_upgrades"].has(upgrade.id):
		save_data["meta_upgrades"][upgrade.id] = {
			"quantity" : 0
		}
	save_data["meta_upgrades"][upgrade.id]["quantity"] += 1
	save()

#region 文件存储、读取
#加载文件
func load_save_file():
	if !FileAccess.file_exists(SAVE_FILE_PATH):
		print("读取不到配置文件!!!")
		return
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)	
	save_data = file.get_var()

#保存文件
func save():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_var(save_data)	
	print("读取到的save Data:", save_data)
#endregion

#region 信号监听区域
#经验变化区域
func on_experience_collected(number: float):
	save_data["meta_upgrade_currency"] += number
	save()
#endregion
