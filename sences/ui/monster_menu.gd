extends Control


var basic_enemy = preload("res://resource/Beastiary/basic_enemy.tres")
var wizard_enemy = preload("res://resource/Beastiary/wizard_enemy.tres")
var bat_enemy = preload("res://resource/Beastiary/bat_enemy.tres")
var mimic_enemy = preload("res://resource/Beastiary/mimic_enemy.tres")

var enemy_list = [basic_enemy, wizard_enemy, bat_enemy, mimic_enemy]

func _ready() -> void:
	load_enemy_list()

func load_enemy_list():
	for enemy in enemy_list:
		var enemy_button = Button.new()
		enemy_button.text = enemy.name
		enemy_button.connect("pressed", load_enemy_info_press.bind(enemy))
		%EnemyList.add_child(enemy_button)

func load_enemy_info_press(resource:Resource):
	%TextureRect.texture = resource.picture
	%Name.text = resource.name
	%Damage.text = resource.damage
	%Health.text = resource.health
	%Description.text = resource.description
