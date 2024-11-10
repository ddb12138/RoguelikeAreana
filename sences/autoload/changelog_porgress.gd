extends Node

const CHANGE_LOG_FILE_PATH = "res://ChangeLog.md"

const SPLIT_SYMBOL = "---"

var changelog_data:  Array[ChangelogEntity]
func _ready():
	load_changelog_file()
	
func load_changelog_file():
	if !FileAccess.file_exists(CHANGE_LOG_FILE_PATH):
		print("读取不到日志更新文件")
		return []
	var file = FileAccess.open(CHANGE_LOG_FILE_PATH, FileAccess.READ)	
	var change_log_data = file.get_as_text()
	changelog_data = parse_changelog_markdown(change_log_data)

func parse_changelog_markdown(content: String) -> Array:
	var task_blocks = content.split(SPLIT_SYMBOL)

	var tasks: Array[ChangelogEntity] = []
	
	for block in task_blocks:
		# 过滤掉空行
		if block.lstrip("").length() == 0:
			continue
		
		var task_data = {}
		var lines = block.split("\n")
		
		
		var kvMap:Dictionary = {}
		for line in lines:
			if line.lstrip("").length() == 0:
				continue
			
			var info = line.split(":")
			var k = info[0]
			var v = info[1]
			kvMap[k] = v
			
		var nowTask = ChangelogEntity.new(kvMap)
		tasks.append(nowTask)
	
	return tasks


func getChangeLogData() ->  Array[ChangelogEntity]:
	return changelog_data
