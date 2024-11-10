extends Node

@onready var back_button: Button = %BackButton
@onready var grid_container: GridContainer = %GridContainer

var change_log_card_scene = preload("res://sences/ui/changelog_card.tscn")

func _ready() -> void:
	back_button.pressed.connect(on_back_pressed)
	
	var datas = ChangelogPorgress.getChangeLogData()
	for data in datas:
		var change_log_card_instance = change_log_card_scene.instantiate()
		grid_container.add_child(change_log_card_instance)
		change_log_card_instance.setChangelogData(data)

func on_back_pressed():
	ScreenTransition.transition_to_scene("res://sences/ui/main_menu.tscn")
