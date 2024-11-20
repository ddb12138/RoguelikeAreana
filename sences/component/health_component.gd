extends Node

#class_name能够让其他调用者获取到该类下的方法及定义,用于提示代码
class_name HealthComponent


signal died	# 死亡信号
signal health_changed # 健康变化信号（受打击）
signal health_heal

@export var max_health: float = 10

var current_health # 当前生命值

func _ready():
	current_health = max_health

# 供外部打击boxhit调用，造成伤害
func damage(damage_amount: float):
	current_health = clamp(current_health - damage_amount, 0, max_health)
	if damage_amount > 0 :
		health_changed.emit()
		#这里需要延迟调用,因为这里会释放掉敌人节点,但是敌人节点还需要被碰撞、经验落等使用
		Callable(check_death).call_deferred()
	else:
		health_heal.emit()	

	
# 供实体类调用，获取当前血量百分比	
func get_health_percent():
	if max_health <= 0:
		return 0
	return min(current_health / max_health, 1)	

func heal(heal_amount: int):
	damage(-heal_amount)

# 检查死亡： 发射信号，销毁实体
func check_death():
	if current_health == 0:
		died.emit()
		owner.queue_free()
	
