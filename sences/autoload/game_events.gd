extends Node
#项目-项目设置-全局-添加本场景
#会在游戏刚初始化时,初始该场景并且将值赋给全局
signal experience_vial_collected(number: float)
signal ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary)
signal player_damaged
signal player_heal

func emit_experience_vial_collected(number: float):
	experience_vial_collected.emit(number)
	
func emit_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary):
		ability_upgrade_added.emit(upgrade, current_upgrades)	

func emit_player_damaged():
	player_damaged.emit()

func emit_player_heal():
	player_heal.emit()
