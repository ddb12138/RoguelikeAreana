extends Node
class_name BuffBase

@export var _isPermanent:bool #是否永久生效
@export var _parentNode:Node2D #挂载父节点
@export var _duration: float #总时长
@export var _used_duration: float #已用时长
@export var _trigger_times: int #触发次数
@export var _trigger_intervals: float #触发间隔时间
@export var _effect_func: Callable #实际功能函数
@export var _heath_component:HealthComponent	 #健康组件,由buff组件负责初始化
@export var _velocity_component: Node #速度组件,由buff组件负责初始化
@export var _gpu_2d: GPUParticles2D #播放粒子效果组件

#随时间变化相关参数
func calculate_time_pass(delta:float):
	_used_duration += delta

#尝试能否激活buff
func try_active_buff() -> bool:
	var last_active_time = _trigger_times * _trigger_intervals
	if last_active_time < _used_duration:
		return true
	return false
	

func check_buff_alive() -> bool:
	return _duration > _used_duration || _isPermanent

#子类实现: buff调用函数
func apply_buff():
	_trigger_times += 1
	pass

#子类实现: buff销毁函数
func destory_buff():
	pass
