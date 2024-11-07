extends CanvasLayer

@onready var panel_container: PanelContainer = %PanelContainer

var is_closing
var option_menu_scene = preload("res://sences/ui/options_menu.tscn")

func _ready() -> void:
	get_tree().paused = true
	panel_container.pivot_offset = panel_container.size / 2
	%ResumeButton.pressed.connect(on_resume_pressed)
	%OptionsButton.pressed.connect(on_options_pressed)
	%QuitButton.pressed.connect(on_quit_pressed)

	
	$AnimationPlayer.play("default")

	var tween = create_tween()
	tween.tween_property(panel_container, "scale", Vector2.ZERO, 0)
	tween.tween_property(panel_container, "scale", Vector2.ONE, .3)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("暂停"):
		close()
		get_tree().root.set_input_as_handled()

func close():
	if is_closing:
		return
	
	is_closing = true
	$AnimationPlayer.play_backwards("default")

	var tween = create_tween()
	tween.tween_property(panel_container, "scale", Vector2.ONE, 0)
	tween.tween_property(panel_container, "scale", Vector2.ZERO, .3)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	
	get_tree().paused = false
	queue_free()

func on_resume_pressed():
	close()

func on_options_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway	
	var option_menu_scene = option_menu_scene.instantiate()
	add_child(option_menu_scene)
	option_menu_scene.back_pressed.connect(on_options_back_pressed.bind(option_menu_scene))
	
func on_quit_pressed():
	get_tree().pause = false
	get_tree().change_scene_to_file("res://sences/main/main.tscn")
	
func on_options_back_pressed(options_menu:Node)	:
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway		
	options_menu.queue_free()
	
