extends Line2D

@export var Arc:int =10 #扭曲次数
@export var RandRange = 10 #随机偏移幅度
@export var Division = 80 #随机分裂次数
@export var LightingPath:Array #闪电路径
@export var LightSpeed = 0.001 #闪电速度
@export var LightWidth = 1 #闪电粗细
@export var LightAmount = 5 #闪电次数
@export var LightDistance = 200 #闪电有效距离
@export var LightDamage = 2 #闪电伤害
var player: Node	#玩家
var LightEnemies:Array	#击中敌人(首位为0)

func _ready() -> void:	
	width = LightWidth
	player = get_tree().get_first_node_in_group("player")
	#$Timer.timeout.connect(on_time_out)
func _process(delta: float) -> void:
	self.points = LightingPath

#寻找最近的N个敌人
func findNearestEnemy():
	#获取周围半径内的敌人
	var enemies = get_tree().get_nodes_in_group("enemy");
	enemies = enemies.filter(func(enemy:Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) < pow(LightDistance, 2)	
	)
	if enemies.size() == 0:
		return
	
	var iterNum = min(LightAmount, enemies.size())
	#寻找敌人路径
	for i in iterNum :
		LightEnemies.append(enemies[i])
	LightEnemies.shuffle()	
	#绘制闪电
	var from:Vector2 = player.global_position #来源
	var to:Vector2 #去往
	for i in range(0, LightEnemies.size()):
		var toEnemy = LightEnemies[i]
		if toEnemy == null: continue
		to = toEnemy.global_position
		toEnemy.hurtbox_component.on_hit(LightDamage)
		await draw_lighting(from, to) #绘制函数放在最后
		from = to

#绘画闪电
func draw_lighting(from: Vector2, to: Vector2):
	self.modulate = Color(1,1,1,1) #设置透明度不为0
	LightingPath.clear()
	
	
	#起点位置
	LightingPath.append(from)
	#
	##设置中间点位置
	for N in (Arc - 2):
		LightingPath.append(LightingPath.back() + ((to - LightingPath.back())/(Arc - N - 1)) - Vector2(randf_range(-RandRange,RandRange), randf_range(-RandRange, RandRange)))
		if LightSpeed != 0:
			await get_tree().create_timer(LightSpeed /1, true).timeout
	
	LightingPath.append(to)

func call_thunder_func():
	await findNearestEnemy()
	LightEnemies.clear()
	LightingPath.clear()

func on_time_out():
	draw_lighting(%a.global_position, %b.global_position)
