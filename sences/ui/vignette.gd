extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameEvents.player_damaged.connect(on_player_damaged)
	GameEvents.player_heal.connect(on_player_heal)


func on_player_damaged():
	$AnimationPlayer.play("hit")

func on_player_heal():
	$AnimationPlayer.play("heal")
