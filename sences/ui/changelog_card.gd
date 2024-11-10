extends PanelContainer

@onready var title_label: Label = %TitleLabel
@onready var content_label: Label = %ContentLabel
@onready var date_label: Label = %DateLabel
@onready var texture_rect: TextureRect = %TextureRect

var right_texture = preload("res://asserts/ui/true.png")
var false_texture = preload("res://asserts/ui/false.png")

func setChangelogData(entity:ChangelogEntity):
	title_label.text = entity.title
	content_label.text = entity.content
	date_label.text = "Date: " + entity.date
	if entity.compelete:
		texture_rect.texture = right_texture
	else:
		texture_rect.texture = false_texture
