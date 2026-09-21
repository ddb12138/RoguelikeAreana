extends Node

const MAIN_SCENE = preload("res://sences/main/main.tscn")
const ENEMY_PATHS = {
	"普通敌人": "res://sences/game_object/basic_enemy/basic_enemy.tscn",
	"巫师": "res://sences/game_object/wizard_enemy/wizard_enemy.tscn",
	"蝙蝠": "res://sences/game_object/bat_enemy/bat_enemy.tscn",
	"宝箱怪": "res://sences/game_object/mimic_chest_enemy/mimic_chest_enemy.tscn",
}
const WEAPON_PATHS = {
	"斧头": "res://resource/upgrades/axe.tres",
	"铁毡": "res://resource/upgrades/anvil.tres",
	"巨剑": "res://resource/upgrades/huge_sword.tres",
	"闪电": "res://resource/upgrades/thunder.tres",
}

@export_enum("普通敌人", "巫师", "蝙蝠", "宝箱怪") var enemy_kind: String = "宝箱怪"
@export_enum("无", "剑", "斧头", "铁毡", "巨剑", "闪电") var weapon_kind: String = "剑"
@export_range(1, 100, 1) var max_enemies: int = 1
@export_range(0.1, 30.0, 0.1) var spawn_interval: float = 2.0
@export var invulnerable: bool = true
@export var sword_fire: bool = true

var arena: Node
var upgrade_manager: Node
var experience_manager: Node
var status_label: Label
var level_button: Button

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lab-enemy="):
			enemy_kind = arg.trim_prefix("--lab-enemy=")
		elif arg.begins_with("--lab-weapon="):
			weapon_kind = arg.trim_prefix("--lab-weapon=")
		elif arg.begins_with("--lab-max-enemies="):
			max_enemies = clampi(arg.trim_prefix("--lab-max-enemies=").to_int(), 1, 100)
		elif arg.begins_with("--lab-spawn-interval="):
			spawn_interval = clampf(arg.trim_prefix("--lab-spawn-interval=").to_float(), 0.1, 30.0)
		elif arg == "--lab-no-fire":
			sword_fire = false
		elif arg == "--lab-vulnerable":
			invulnerable = false
	if not ENEMY_PATHS.has(enemy_kind) or (weapon_kind not in ["无", "剑"] and not WEAPON_PATHS.has(weapon_kind)):
		push_error("战斗实验场：未知怪物或武器名称。")
		get_tree().quit(1)
		return
	arena = MAIN_SCENE.instantiate()
	var enemy_manager = arena.get_node("EnemyManager")
	enemy_manager.test_enemy_scene = load(ENEMY_PATHS[enemy_kind])
	enemy_manager.test_max_enemies = max_enemies
	enemy_manager.test_spawn_interval = spawn_interval
	upgrade_manager = arena.get_node("UpgradeManager")
	upgrade_manager.test_weapon_id = weapon_kind
	experience_manager = arena.get_node("ExperienceManager")
	var player = arena.get_node("Entities/Player")
	player.test_invulnerable = invulnerable
	var default_sword = player.get_node("Abilities/SwordAbilityController")
	if weapon_kind != "剑":
		default_sword.free()
	elif not sword_fire:
		default_sword.burn_config = null
	add_child(arena)
	# 所有节点 ready 后，Player 已订阅解锁信号；复用正式解锁流程。
	if WEAPON_PATHS.has(weapon_kind):
		upgrade_manager.apply_upgrade(load(WEAPON_PATHS[weapon_kind]))
	var time_manager = arena.get_node("ArenaTimeManager")
	time_manager.set_process(false)
	time_manager.get_node("Timer").stop()
	build_panel()
	enemy_manager.on_timer_timeout()

func build_panel() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	var panel = PanelContainer.new()
	panel.position = Vector2(8, 28)
	canvas.add_child(panel)
	var rows = VBoxContainer.new()
	panel.add_child(rows)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 12)
	rows.add_child(status_label)
	level_button = Button.new()
	level_button.text = "升一级（U）"
	level_button.add_theme_font_size_override("font_size", 12)
	level_button.pressed.connect(request_level_up)
	rows.add_child(level_button)
	update_status()

func _process(_delta: float) -> void:
	if is_instance_valid(status_label):
		update_status()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_U:
		request_level_up()
		get_viewport().set_input_as_handled()

func has_upgrades() -> bool:
	for entry in upgrade_manager.upgrade_pool.items:
		var upgrade = entry["item"] as AbilityUpgrade
		if upgrade.id == weapon_kind or upgrade.id.begins_with(weapon_kind + ":"):
			return true
	return false

func request_level_up() -> void:
	if get_tree().paused or not has_upgrades():
		return
	experience_manager.increment_experience(experience_manager.target_experience - experience_manager.current_experience)

func update_status() -> void:
	var available = has_upgrades()
	var state = "U 升级 / P 暂停" if available else "此武器已无升级选项"
	status_label.text = "实验场：%s / %s\n同屏上限 %d · %s\n%s" % [enemy_kind, weapon_kind, max_enemies, "免接触伤害" if invulnerable else "正常受伤", state]
	level_button.disabled = not available
