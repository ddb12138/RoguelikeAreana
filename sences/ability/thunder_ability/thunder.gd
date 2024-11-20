extends Line2D

var Arc:int =100 #扭曲次数
var RandRange = 10 #随机偏移幅度
var Division = 80 #随机分裂次数
var LightingPath:Array #闪电路径
var LightSpeed = 0 #闪电速度


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.timeout.connect(on_time_out)
	width = 1


var t: float = 300
var netPath:Array
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#netPath.append(Vector2(t,t))
	self.points = LightingPath
	#t += 1
	

func set_lighting():
	print("SHEZHI")
	self.modulate = Color(1,1,1,1)
	LightingPath.clear()
	LightingPath.append
		
	print(%a.global_position)
	#
	##a点位置
	LightingPath.append(%a.global_position)
	#
	##设置中间点位置
	for N in (Arc - 2):
		LightingPath.append(LightingPath.back() + ((%b.global_position - LightingPath.back())/(Arc - N - 1)) - Vector2(randf_range(-RandRange,RandRange), randf_range(-RandRange, RandRange)))
		if LightSpeed != 0:
			await get_tree().create_timer(LightSpeed /0.001, true).timeout

func on_time_out():
	set_lighting()
