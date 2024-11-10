extends CanvasLayer

@export var upgrades: Array[MetaUpgrade] = []

@onready var grid_container: GridContainer = %GridContainer
@onready var back_button: Button = %BackButton

var meta_upgrade_card_scene = preload("res://sences/ui/meta_upgrade_card.tscn")

func _ready() -> void:
	back_button.pressed.connect(on_back_pressed)
	
	for upgrade in upgrades:
		var meta_upgrade_card_instance = meta_upgrade_card_scene.instantiate()
		grid_container.add_child(meta_upgrade_card_instance)
		meta_upgrade_card_instance.set_meta_upgrade(upgrade)

func on_back_pressed():
	ScreenTransition.transition_to_scene("res://sences/ui/main_menu.tscn")
