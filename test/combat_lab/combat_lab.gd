extends Node

const MAIN_SCENE = preload("res://sences/main/main.tscn")
const CHINESE_FONT = preload("res://resource/theme/BasicChineseLine.ttf")
const ENEMY_KINDS: Array[String] = ["普通敌人", "巫师", "蝙蝠", "宝箱怪"]
const WEAPON_KINDS: Array[String] = ["无", "剑", "斧头", "铁毡", "巨剑", "闪电"]
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

enum LabState { CONFIGURING, STARTING, RUNNING, FAILED }

@export_enum("普通敌人", "巫师", "蝙蝠", "宝箱怪") var enemy_kind: String = "宝箱怪"
@export_enum("无", "剑", "斧头", "铁毡", "巨剑", "闪电") var weapon_kind: String = "剑"
@export_range(1, 100, 1) var max_enemies: int = 1
@export_range(0.1, 30.0, 0.1) var spawn_interval: float = 2.0
@export var invulnerable: bool = true
# 回归测试和 Inspector 可显式跳过配置页；普通启动保持 false。
@export var auto_start: bool = false

@onready var configuration_layer: CanvasLayer = $ConfigurationLayer
@onready var enemy_option: OptionButton = %EnemyOption
@onready var weapon_option: OptionButton = %WeaponOption
@onready var max_enemies_spin: SpinBox = %MaxEnemiesSpin
@onready var spawn_interval_spin: SpinBox = %SpawnIntervalSpin
@onready var invulnerable_check: CheckButton = %InvulnerableCheck
@onready var sword_fire_check: CheckButton = %SwordFireCheck
@onready var isolation_label: Label = %IsolationLabel
@onready var start_button: Button = %StartButton

var state: LabState = LabState.CONFIGURING
var arena: Node
var upgrade_manager: Node
var experience_manager: Node
var status_label: Label
var level_button: Button

func _ready() -> void:
	setup_configuration_form()
	var has_command_line_configuration = parse_command_line_configuration()
	if not configuration_is_valid():
		fail_startup("战斗实验室：未知怪物或武器名称。")
		return
	if auto_start or has_command_line_configuration:
		start_experiment()
	else:
		show_configuration()

func setup_configuration_form() -> void:
	enemy_option.clear()
	for kind in ENEMY_KINDS:
		enemy_option.add_item(kind)
	weapon_option.clear()
	for kind in WEAPON_KINDS:
		weapon_option.add_item(kind)
	start_button.pressed.connect(start_from_form)
	weapon_option.item_selected.connect(on_weapon_selected)
	write_configuration_to_form()
	var user_dir_name = str(ProjectSettings.get_setting("application/config/custom_user_dir_name", ""))
	if user_dir_name.begins_with("Codex-blood-combat-lab-"):
		isolation_label.text = "独立存档已启用 · 正式进度不会被改写"
		isolation_label.modulate = Color("91d9a7")
	else:
		isolation_label.text = "当前不是隔离副本 · 请使用 Combat Lab.command 启动"
		isolation_label.modulate = Color("ffc66d")

func parse_command_line_configuration() -> bool:
	var has_lab_argument = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lab-enemy="):
			enemy_kind = arg.trim_prefix("--lab-enemy=")
			has_lab_argument = true
		elif arg.begins_with("--lab-weapon="):
			weapon_kind = arg.trim_prefix("--lab-weapon=")
			has_lab_argument = true
		elif arg.begins_with("--lab-max-enemies="):
			max_enemies = clampi(arg.trim_prefix("--lab-max-enemies=").to_int(), 1, 100)
			has_lab_argument = true
		elif arg.begins_with("--lab-spawn-interval="):
			spawn_interval = clampf(arg.trim_prefix("--lab-spawn-interval=").to_float(), 0.1, 30.0)
			has_lab_argument = true
		elif arg == "--lab-vulnerable":
			invulnerable = false
			has_lab_argument = true
		elif arg == "--lab-direct":
			has_lab_argument = true
	write_configuration_to_form()
	return has_lab_argument

func configuration_is_valid() -> bool:
	return ENEMY_PATHS.has(enemy_kind) and weapon_kind in WEAPON_KINDS

func write_configuration_to_form() -> void:
	select_option_text(enemy_option, enemy_kind)
	select_option_text(weapon_option, weapon_kind)
	max_enemies_spin.value = max_enemies
	spawn_interval_spin.value = spawn_interval
	invulnerable_check.button_pressed = invulnerable
	on_weapon_selected(weapon_option.selected)

func select_option_text(option: OptionButton, text: String) -> void:
	for index in range(option.item_count):
		if option.get_item_text(index) == text:
			option.select(index)
			return

func show_configuration() -> void:
	state = LabState.CONFIGURING
	configuration_layer.show()
	start_button.disabled = false
	start_button.grab_focus()

func start_from_form() -> void:
	if state != LabState.CONFIGURING:
		return
	enemy_kind = enemy_option.get_item_text(enemy_option.selected)
	weapon_kind = weapon_option.get_item_text(weapon_option.selected)
	max_enemies = int(max_enemies_spin.value)
	spawn_interval = float(spawn_interval_spin.value)
	invulnerable = invulnerable_check.button_pressed
	start_experiment()

func start_experiment() -> void:
	if state == LabState.STARTING or state == LabState.RUNNING:
		return
	if not configuration_is_valid():
		fail_startup("战斗实验室：配置无效，无法开始实验。")
		return
	state = LabState.STARTING
	start_button.disabled = true

	var next_arena = MAIN_SCENE.instantiate()
	var enemy_manager = next_arena.get_node("EnemyManager")
	enemy_manager.test_enemy_scene = load(ENEMY_PATHS[enemy_kind])
	enemy_manager.test_max_enemies = max_enemies
	enemy_manager.test_spawn_interval = spawn_interval
	upgrade_manager = next_arena.get_node("UpgradeManager")
	upgrade_manager.test_weapon_id = weapon_kind
	experience_manager = next_arena.get_node("ExperienceManager")
	var player = next_arena.get_node("Entities/Player")
	player.test_invulnerable = invulnerable
	var default_sword = player.get_node("Abilities/SwordAbilityController")
	if weapon_kind != "剑":
		default_sword.free()

	arena = next_arena
	add_child(arena)
	# 所有节点 ready 后，Player 已订阅解锁信号；复用正式解锁流程。
	if WEAPON_PATHS.has(weapon_kind):
		upgrade_manager.apply_upgrade(load(WEAPON_PATHS[weapon_kind]))
	var time_manager = arena.get_node("ArenaTimeManager")
	time_manager.set_process(false)
	time_manager.get_node("Timer").stop()
	build_panel()
	enemy_manager.on_timer_timeout()
	configuration_layer.hide()
	state = LabState.RUNNING

func fail_startup(message: String) -> void:
	state = LabState.FAILED
	push_error(message)
	# headless（自动化）模式没有窗口可交互，直接以失败码退出，避免挂住进程。
	if "--headless" in OS.get_cmdline_args() or DisplayServer.get_name() == "headless":
		get_tree().quit(1)
		return
	if is_instance_valid(isolation_label):
		isolation_label.text = message
		isolation_label.modulate = Color("ff7f73")
		configuration_layer.show()
		start_button.disabled = true
	else:
		get_tree().quit(1)

func on_weapon_selected(index: int) -> void:
	if index < 0 or index >= weapon_option.item_count:
		return
	var is_sword = weapon_option.get_item_text(index) == "剑"
	sword_fire_check.disabled = true
	sword_fire_check.button_pressed = false
	sword_fire_check.tooltip_text = "火焰剑现在通过正式升级卡牌获得"

func build_panel() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 5
	canvas.name = "RuntimePanel"
	add_child(canvas)
	var panel = PanelContainer.new()
	panel.position = Vector2(8, 28)
	canvas.add_child(panel)
	var rows = VBoxContainer.new()
	panel.add_child(rows)
	status_label = Label.new()
	status_label.add_theme_font_override("font", CHINESE_FONT)
	status_label.add_theme_font_size_override("font_size", 12)
	rows.add_child(status_label)
	level_button = Button.new()
	level_button.text = "升一级（U）"
	level_button.add_theme_font_override("font", CHINESE_FONT)
	level_button.add_theme_font_size_override("font_size", 12)
	level_button.pressed.connect(request_level_up)
	rows.add_child(level_button)
	update_status()

func _process(_delta: float) -> void:
	if state == LabState.RUNNING and is_instance_valid(status_label):
		update_status()

func _unhandled_key_input(event: InputEvent) -> void:
	if state != LabState.RUNNING:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_U:
		request_level_up()
		get_viewport().set_input_as_handled()

func has_upgrades() -> bool:
	if state != LabState.RUNNING or not is_instance_valid(upgrade_manager):
		return false
	for entry in upgrade_manager.upgrade_pool.items:
		var upgrade = entry["item"] as AbilityUpgrade
		if upgrade.id == weapon_kind or upgrade.id.begins_with(weapon_kind + ":"):
			return true
	return false

func request_level_up() -> void:
	if state != LabState.RUNNING or get_tree().paused or not has_upgrades():
		return
	experience_manager.increment_experience(experience_manager.target_experience - experience_manager.current_experience)

func update_status() -> void:
	var available = has_upgrades()
	var current_state = "U 升级 / P 暂停" if available else "此武器已无升级选项"
	status_label.text = "实验室：%s / %s\n同屏上限 %d · %s\n%s" % [enemy_kind, weapon_kind, max_enemies, "免接触伤害" if invulnerable else "正常受伤", current_state]
	level_button.disabled = not available
