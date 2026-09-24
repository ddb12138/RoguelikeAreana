extends Node

signal exit_requested

@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $PreviewUI/Panel/Margin/VBox/HealthBar
@onready var health_label: Label = $PreviewUI/Panel/Margin/VBox/HealthLabel
@onready var trigger_label: Label = $PreviewUI/Panel/Margin/VBox/TriggerLabel

var trigger_count := 0

func _ready() -> void:
	health_component.current_health = 4
	health_component.health_heal.connect(_on_health_heal)
	$PreviewUI/Panel/Margin/VBox/HealButton.pressed.connect(trigger_heal)
	$PreviewUI/Panel/Margin/VBox/BackButton.pressed.connect(request_exit)
	_update_health_display()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode in [KEY_H, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		trigger_heal()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_TAB:
		$PreviewUI/Panel.visible = not $PreviewUI/Panel.visible
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		request_exit()

func request_exit() -> void:
	# 输入和按钮回调结束后再让实验室卸载预览节点。
	set_process_input(false)
	exit_requested.emit.call_deferred()

func trigger_heal() -> void:
	if health_component.current_health >= health_component.max_health:
		health_component.current_health = 4
	health_component.heal(1)

func _on_health_heal() -> void:
	trigger_count += 1
	GameEvents.emit_player_heal()
	_update_health_display()
	trigger_label.text = "已触发 %d 次　（每次恢复 1 点）" % trigger_count

func _update_health_display() -> void:
	health_bar.value = health_component.get_health_percent() * 100.0
	health_label.text = "模拟生命值：%d / %d" % [health_component.current_health, health_component.max_health]
