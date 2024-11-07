extends Node

@export var expericen_manager: Node
@export var upgrade_screen_scene: PackedScene

var current_upgrades = {}
var upgrade_pool: WeightedTable = WeightedTable.new()

var upgrade_axe = preload("res://resource/upgrades/axe.tres")
var upgrade_axe_damage = preload("res://resource/upgrades/axe_damage.tres")
var upgrade_sword_rate = preload("res://resource/upgrades/sword_rate.tres")
var upgrade_sword_damage = preload("res://resource/upgrades/sword_damage.tres")
var upgrade_player_speed = preload("res://resource/upgrades/player_speed.tres")
var upgrade_anvil = preload("res://resource/upgrades/anvil.tres")
var upgrade_anvil_damage = preload("res://resource/upgrades/anvil_damage.tres")
var upgrade_anvil_amount = preload("res://resource/upgrades/anvil_amount.tres")
var upgrade_huge_sword = preload("res://resource/upgrades/huge_sword.tres")


func _ready() -> void:
	upgrade_pool.add_item(upgrade_axe, 20)
	upgrade_pool.add_item(upgrade_anvil, 20)
	upgrade_pool.add_item(upgrade_huge_sword, 20)
	upgrade_pool.add_item(upgrade_sword_rate, 10)
	upgrade_pool.add_item(upgrade_sword_damage, 10)
	upgrade_pool.add_item(upgrade_player_speed, 5)
	

	expericen_manager.level_up.connect(on_level_up)
	

func apply_upgrade(upgrade: AbilityUpgrade):
	var has_upgrade = current_upgrades.has(upgrade.id)	
	if !has_upgrade:
		current_upgrades[upgrade.id] = {
			"resource" : upgrade,
			"quantity": 1
		}
	else:
		current_upgrades[upgrade.id]["quantity"] += 1
	if upgrade.max_quantity > 0:
		var current_quantity = current_upgrades[upgrade.id]["quantity"]	
		if current_quantity == upgrade.max_quantity:
			upgrade_pool.remove_item(upgrade)	
			
	update_upgrade_pool(upgrade)		
	GameEvents.emit_ability_upgrade_added(upgrade, current_upgrades)

func update_upgrade_pool(chosen_upgrade: AbilityUpgrade):
	if chosen_upgrade.id == upgrade_axe.id:
		upgrade_pool.add_item(upgrade_axe_damage, 10)
		return
	if chosen_upgrade.id == upgrade_anvil.id:
		upgrade_pool.add_item(upgrade_anvil_damage, 10)
		upgrade_pool.add_item(upgrade_anvil_amount, 10)
		return
	
func pick_upgrades():
	var chosen_upgrades: Array[AbilityUpgrade] = []
	for i in 2:
		if upgrade_pool.items.size() == chosen_upgrades.size():
			break
		var chosen_upgrade = upgrade_pool.pick_item(chosen_upgrades)
		chosen_upgrades.append(chosen_upgrade)
	return chosen_upgrades
	
func on_level_up(current_level:int):
	var upgrade_screen_instance = upgrade_screen_scene.instantiate()
	add_child(upgrade_screen_instance)
	var chosen_upgrades = pick_upgrades()
	upgrade_screen_instance.set_ability_upgrades(chosen_upgrades)
	upgrade_screen_instance.upgrade_selected.connect(on_upgrade_selected)

	
func on_upgrade_selected(upgrade: AbilityUpgrade):
	apply_upgrade(upgrade)
	
