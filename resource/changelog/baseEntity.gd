extends Resource
class_name ChangelogEntity

@export var title: String
@export var content: String
@export var date: String
@export var compelete: bool

#title:String, content:String, date:String, compelete:bool
func _init(data:Dictionary ) -> void:
	title = data["标题"]
	content = data["内容"]
	date = data["日期"]
	var iscompelete = data["完成度"]
	if iscompelete == "已完成":
		compelete = true
	else:
		compelete = false
