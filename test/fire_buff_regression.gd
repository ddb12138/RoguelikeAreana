extends Node

# 仅在独立副本和专用 user:// 下运行，参见 docs/FIRE_BUFF.md。
var failures: int = 0
var checks: int = 0
var deaths: int = 0
var foreground: Node2D
var entities: Node2D

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func make_enemy(kind: String = "basic_enemy") -> Node2D:
	var scene = load("res://sences/game_object/%s/%s.tscn" % [kind, kind]) as PackedScene
	var enemy = scene.instantiate() as Node2D
	entities.add_child(enemy)
	enemy.set_process(false)
	enemy.get_node("AnimationPlayer").stop()
	enemy.get_node("BuffComponent").set_process(false)
	enemy.get_node("HealthComponent").max_health = 100.0
	enemy.get_node("HealthComponent").current_health = 100.0
	return enemy

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	foreground = Node2D.new()
	foreground.process_mode = Node.PROCESS_MODE_PAUSABLE
	foreground.add_to_group("foreground_layer")
	add_child(foreground)
	entities = Node2D.new()
	entities.process_mode = Node.PROCESS_MODE_PAUSABLE
	entities.add_to_group("entites_layer")
	add_child(entities)
	var player = Node2D.new()
	player.add_to_group("player")
	player.position = Vector2(1000, 1000)
	entities.add_child(player)
	await get_tree().process_frame
	await run_checks()
	get_tree().paused = false
	entities.queue_free()
	foreground.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("FIRE_REGRESSION: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)

func run_checks() -> void:
	var config = load("res://resource/buffs/sword_fire.tres") as BurnConfig
	var enemy = make_enemy()
	var manager = enemy.get_node("BuffComponent") as BuffManager
	var health = enemy.get_node("HealthComponent") as HealthComponent
	var hurtbox = enemy.get_node("HurtboxComponent") as HurtboxComponent
	var hitbox = HitboxComponent.new()
	hitbox.damage = 5.0
	hitbox.burn_config = config
	hurtbox.on_area_entered(hitbox)
	expect(health.current_health == 95.0, "剑直接伤害应立即结算")
	expect(manager.current_buff_list.size() == 1, "命中应挂载灼烧")
	manager.update_buff_by_delta(1.99)
	expect(health.current_health == 95.0, "首跳前不能扣灼烧血")
	manager.update_buff_by_delta(0.01)
	expect(health.current_health == 92.0, "第 2 秒应跳 3 点")
	var text = foreground.get_child(foreground.get_child_count() - 1)
	expect(text.get_node("Label").get_theme_color("font_color") == config.damage_color, "灼烧飘字应使用配置颜色")
	manager.update_buff_by_delta(4.5)
	expect(health.current_health == 86.0, "大 delta 应补齐第 4/6 秒且不越过到期时间")
	expect(manager.active_burn == null and manager.current_buff_list.is_empty(), "到期应移除状态")
	await get_tree().process_frame
	expect(not enemy.has_node("BurnVisual"), "到期应释放火焰视觉")

	manager.add_burn(config, hurtbox)
	var burn = manager.active_burn
	for i in range(4):
		manager.update_buff_by_delta(0.5)
		manager.add_burn(config, hurtbox)
	expect(health.current_health == 83.0, "连续刷新仍在第 2 秒跳伤")
	expect(manager.active_burn == burn and manager.current_buff_list.size() == 1, "刷新必须复用状态")
	var visuals: int = 0
	for child in enemy.get_children():
		if child.name == "BurnVisual":
			visuals += 1
	expect(visuals == 1, "刷新不能重复生成火焰")
	var before_position = burn.visual.global_position
	enemy.position += Vector2(25, 10)
	expect(burn.visual.global_position == before_position + Vector2(25, 10), "火焰必须跟随敌人移动")
	manager.set_process(true)
	var remaining = burn.remaining_time
	get_tree().paused = true
	for i in range(5):
		await get_tree().process_frame
	expect(is_equal_approx(burn.remaining_time, remaining), "暂停时灼烧计时不能变化")
	get_tree().paused = false
	await get_tree().process_frame
	await get_tree().process_frame
	expect(burn.remaining_time < remaining, "恢复后灼烧应继续计时")
	manager.set_process(false)

	var custom = BurnConfig.new()
	custom.duration = 2.5
	custom.tick_interval = 0.5
	custom.tick_damage = 1.25
	custom.damage_color = Color.MAGENTA
	var second = make_enemy("bat_enemy")
	var second_manager = second.get_node("BuffComponent") as BuffManager
	second_manager.add_burn(custom, second.get_node("HurtboxComponent"))
	second_manager.update_buff_by_delta(3.0)
	expect(second.get_node("HealthComponent").current_health == 93.75, "自定义间隔与小数伤害应生效，共五跳")
	expect(health.current_health == 83.0, "不同敌人状态应相互独立")
	expect(config.duration == 6.0 and config.tick_interval == 2.0, "共享 Resource 不应被计时修改")
	custom.duration = 0.2
	second_manager.add_burn(custom, second.get_node("HurtboxComponent"))
	second_manager.update_buff_by_delta(1.0)
	expect(second.get_node("HealthComponent").current_health == 93.75, "短于间隔的灼烧应无跳伤")
	custom.tick_interval = 0.0
	second_manager.add_burn(custom, second.get_node("HurtboxComponent"))
	expect(second_manager.active_burn == null, "非法间隔应拒绝创建")

	var wizard = make_enemy("wizard_enemy")
	var wizard_health = wizard.get_node("HealthComponent") as HealthComponent
	wizard_health.current_health = 51.0
	var wizard_manager = wizard.get_node("BuffComponent") as BuffManager
	wizard_manager.add_burn(config, wizard.get_node("HurtboxComponent"))
	wizard_manager.update_buff_by_delta(2.0)
	expect(wizard.is_angry, "灼烧跨半血应触发巫师状态")
	var animation = wizard.get_node("AnimationPlayer") as AnimationPlayer
	animation.advance(0.45)
	var playback = animation.current_animation_position
	wizard_manager.update_buff_by_delta(2.0)
	expect(is_equal_approx(animation.current_animation_position, playback), "后续灼烧不能重播巫师状态动画")
	animation.advance(0.3)
	expect(not wizard.is_moving, "巫师 0.7 秒动画方法轨道应正确调用")

	var mimic = make_enemy("mimic_chest_enemy")
	var mimic_health = mimic.get_node("HealthComponent") as HealthComponent
	mimic_health.current_health = 3.0
	mimic_health.died.connect(func(): deaths += 1)
	mimic.get_node("VialDropComponent").drop_percent = 1.0
	var mimic_manager = mimic.get_node("BuffComponent") as BuffManager
	mimic_manager.add_burn(config, mimic.get_node("HurtboxComponent"))
	mimic_manager.update_buff_by_delta(6.0)
	# 模拟同帧多个延迟死亡检查，必须只发一次信号。
	mimic_health.check_death.call_deferred()
	await get_tree().process_frame
	await get_tree().process_frame
	expect(deaths == 1, "灼烧击杀只发一次死亡信号")
	expect(not is_instance_valid(mimic), "灼烧击杀应释放敌人及其火焰")
	var vial_count: int = 0
	for child in entities.get_children():
		if child.scene_file_path == "res://sences/game_object/experience_vial/experience_vial.tscn":
			vial_count += 1
	expect(vial_count == 1, "灼烧击杀应正常且只掉落一份经验")

	var plain = make_enemy()
	var plain_hurtbox = plain.get_node("HurtboxComponent") as HurtboxComponent
	hitbox.burn_config = null
	plain_hurtbox.on_area_entered(hitbox)
	expect(plain.get_node("HealthComponent").current_health == 95.0, "普通武器伤害应保持")
	expect(plain.get_node("BuffComponent").active_burn == null, "普通武器不应附加灼烧")
	hitbox.free()
	var heal_manager = plain.get_node("BuffComponent") as BuffManager
	heal_manager.add_buff("buff_heal")
	heal_manager.update_buff_by_delta(0.01)
	expect(plain.get_node("HealthComponent").current_health == 96.0, "治疗仍在首帧触发")
	heal_manager.update_buff_by_delta(14.98)
	expect(plain.get_node("HealthComponent").current_health == 96.0, "治疗间隔保持 15 秒")
	heal_manager.update_buff_by_delta(0.02)
	expect(plain.get_node("HealthComponent").current_health == 97.0, "治疗后续触发应正常")

	var sword_scene = load("res://sences/ability/sword_ability/sword_ability.tscn") as PackedScene
	var sword = sword_scene.instantiate() as SwordAbility
	sword.burn_config = config
	foreground.add_child(sword)
	var sword_animation = sword.get_node("AnimationPlayer") as AnimationPlayer
	sword_animation.advance(0.2)
	await get_tree().process_frame
	expect(sword.hitbox_component.burn_config == config, "剑必须传递火焰配置")
	expect(sword.get_node("Sprite2D/Embers").emitting, "攻击窗口必须发射火星")
	sword_animation.advance(0.3)
	await get_tree().process_frame
	expect(not sword.get_node("Sprite2D/Embers").emitting, "攻击结束应停止发射并留时间消散")
	sword_animation.advance(0.3)
	await get_tree().process_frame
	await get_tree().process_frame
	expect(not is_instance_valid(sword), "剑和附属效果应随原动画释放")
