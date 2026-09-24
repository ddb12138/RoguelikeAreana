extends Node

const LAB = preload("res://test/combat_lab/combat_lab.tscn")
var checks: int = 0
var failures: int = 0

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await run_checks()
	print("COMBAT_LAB_REGRESSION: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)

func run_checks() -> void:
	# 默认入口必须停在配置页，直到用户明确点击开始。
	var config_lab = LAB.instantiate()
	add_child(config_lab)
	expect(config_lab.state == config_lab.LabState.CONFIGURING, "默认入口显示配置页")
	expect(config_lab.arena == null, "点击开始前不实例化正式战斗")
	expect(config_lab.configuration_layer.visible, "配置页保持可见")
	expect(config_lab.enemy_option.item_count == 4, "怪物选项完整")
	expect(config_lab.weapon_option.item_count == 6, "武器选项完整")
	expect(config_lab.max_enemies_spin.min_value == 1 and config_lab.max_enemies_spin.max_value == 100, "怪物上限约束正确")
	expect(is_equal_approx(config_lab.spawn_interval_spin.min_value, 0.1) and is_equal_approx(config_lab.spawn_interval_spin.max_value, 30.0), "补怪间隔约束正确")
	expect(config_lab.sword_fire_check.disabled, "火焰剑通过正式升级卡牌获得")
	config_lab.select_option_text(config_lab.enemy_option, "蝙蝠")
	config_lab.select_option_text(config_lab.weapon_option, "闪电")
	config_lab.max_enemies_spin.value = 3
	config_lab.spawn_interval_spin.value = 1.5
	config_lab.invulnerable_check.button_pressed = false
	var music_paused_before: bool = MusicPlayer.stream_paused
	var timer_paused_before: bool = MusicPlayer.get_node("Timer").paused
	config_lab.get_node("%HealPreviewButton").pressed.emit()
	expect(config_lab.state == config_lab.LabState.PREVIEW, "配置页按钮进入回血预览")
	expect(config_lab.arena == null and not config_lab.configuration_layer.visible, "预览不生成战斗并隐藏配置页")
	expect(MusicPlayer.stream_paused and MusicPlayer.get_node("Timer").paused, "预览暂停音乐和重播计时")
	var preview = config_lab.heal_preview
	preview.trigger_heal()
	expect(preview.health_component.current_health == 5 and preview.trigger_count == 1, "预览实际回血一次")
	config_lab.start_heal_preview()
	config_lab.start_experiment()
	expect(config_lab.heal_preview == preview and config_lab.arena == null, "预览期间防止重复启动或混入战斗")
	preview.request_exit()
	await get_tree().process_frame
	await get_tree().process_frame
	expect(config_lab.state == config_lab.LabState.CONFIGURING and config_lab.heal_preview == null, "预览返回配置页并释放")
	expect(config_lab.configuration_layer.visible, "返回后配置页可见")
	expect(MusicPlayer.stream_paused == music_paused_before and MusicPlayer.get_node("Timer").paused == timer_paused_before, "返回恢复原音乐状态")
	expect(config_lab.weapon_option.get_item_text(config_lab.weapon_option.selected) == "闪电" and config_lab.max_enemies_spin.value == 3, "预览往返保留表单")
	config_lab.start_heal_preview()
	expect(config_lab.heal_preview.health_component.current_health == 4 and config_lab.heal_preview.trigger_count == 0, "重新进入从初始生命开始")
	config_lab.close_heal_preview()
	await get_tree().process_frame
	config_lab.start_from_form()
	expect(config_lab.state == config_lab.LabState.RUNNING and config_lab.arena != null, "开始按钮进入战斗")
	expect(not config_lab.configuration_layer.visible, "战斗开始后隐藏配置页")
	var configured_arena = config_lab.arena
	var configured_spawner = configured_arena.get_node("EnemyManager")
	var configured_player = configured_arena.get_node("Entities/Player")
	expect(config_lab.enemy_kind == "蝙蝠" and configured_spawner.test_max_enemies == 3, "GUI 怪物配置写入正式管理器")
	expect(is_equal_approx(configured_spawner.timer.wait_time, 1.5), "GUI 补怪间隔写入正式计时器")
	expect(not configured_player.test_invulnerable, "GUI 受伤设置写入玩家")
	expect(configured_player.get_node("Abilities").get_child_count() == 1 and configured_player.get_node("Abilities").get_child(0).name == "ThunderAbilityController", "GUI 武器通过正式流程安装")
	config_lab.start_experiment()
	expect(config_lab.arena == configured_arena, "重复开始不会创建第二个战斗场")
	config_lab.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	var expected_steps = {"无": 0, "剑": 26, "斧头": 5, "铁毡": 10, "巨剑": 0, "闪电": 19}
	for weapon in expected_steps:
		var lab = LAB.instantiate()
		lab.weapon_kind = weapon
		lab.enemy_kind = "宝箱怪"
		lab.auto_start = true
		add_child(lab)
		var arena = lab.arena
		var player = arena.get_node("Entities/Player")
		var manager = lab.upgrade_manager
		var spawner = arena.get_node("EnemyManager")
		expect(player.get_node("Abilities").get_child_count() == (0 if weapon == "无" else 1), "应只安装所选武器：" + weapon)
		if weapon == "剑":
			expect(player.get_node("Abilities/SwordAbilityController").burn_config == null, "开局剑没有火焰 Buff")
		expect(arena.get_node("ArenaTimeManager/Timer").is_stopped(), "实验场不自动计时结算")
		for difficulty in [3, 6, 8, 60]:
			spawner.on_arena_difficulty_increased(difficulty)
		expect(spawner.enemy_table.items.size() == 1 and spawner.number_to_swpan == 1, "难度不能混入其他敌人")
		expect(is_equal_approx(spawner.timer.wait_time, lab.spawn_interval), "实验场间隔不随难度变化")
		spawner.on_timer_timeout()
		expect(get_tree().get_nodes_in_group("enemy").size() == 1, "固定敌人上限生效")
		var enemy = get_tree().get_first_node_in_group("enemy")
		expect(enemy.scene_file_path == lab.ENEMY_PATHS["宝箱怪"], "实际实例化指定敌人")
		enemy.queue_free()
		await get_tree().process_frame
		spawner.on_timer_timeout()
		expect(get_tree().get_nodes_in_group("enemy").size() == 1, "敌人移除后继续补充同类")
		var hp = player.health_component.current_health
		player.number_colliding_bodies = 1
		player.check_deal_damage()
		expect(player.health_component.current_health == hp, "可选免接触伤害生效")
		player.test_invulnerable = false
		player.damage_interval_timer.stop()
		player.check_deal_damage()
		expect(player.health_component.current_health == hp - 1, "关闭选项后恢复接触伤害")
		player.test_invulnerable = true
		if lab.has_upgrades():
			lab.request_level_up()
			expect(get_tree().paused, "一键升级打开真实暂停卡牌")
			var screen = manager.get_child(manager.get_child_count() - 1)
			expect(screen.card_container.get_child_count() in [1, 2], "只展示存在的卡牌")
			var chosen = manager.pick_upgrades()[0]
			screen.on_upgrade_selected(chosen)
			await get_tree().create_timer(0.8).timeout
			expect(not get_tree().paused, "选卡后恢复战斗")
		var steps: int = 1 if expected_steps[weapon] > 0 else 0
		while lab.has_upgrades() and steps < 40:
			var choices = manager.pick_upgrades()
			var ids: Array[String] = []
			for choice in choices:
				expect(choice.id.begins_with(weapon + ":"), "定向升级不混入其他武器")
				expect(choice.id not in ids, "抽卡不能重复")
				ids.append(choice.id)
			manager.apply_upgrade(choices[0])
			steps += 1
		expect(steps == expected_steps[weapon], "应尊重资源上限：" + weapon)
		expect(manager.pick_upgrades().is_empty(), "满级后不回退其他选项")
		var count = manager.get_child_count()
		manager.on_level_up(99)
		expect(not get_tree().paused and manager.get_child_count() == count, "满级后不创建空升级窗口")
		var controller = player.get_node("Abilities").get_child(0) if weapon != "无" else null
		match weapon:
			"剑":
				expect(is_equal_approx(controller.additional_damage_percent, 1.75) and is_equal_approx(controller.get_node("Timer").wait_time, 0.5), "剑满级数值")
				expect(controller.burn_config != null and manager.current_upgrades.has("剑:火焰附魔"), "选择火焰卡牌后剑启用灼烧")
				expect(manager.current_upgrades.has("剑:火焰伤害升级") and manager.current_upgrades.has("剑:火焰持续升级") and manager.current_upgrades.has("剑:火焰频率升级"), "火焰卡牌解锁三条强化路线")
				expect(is_equal_approx(controller.burn_config.tick_damage, 8.0) and is_equal_approx(controller.burn_config.duration, 11.0) and is_equal_approx(controller.burn_config.tick_interval, 1.0), "火焰三条路线满级数值")
			"斧头":
				expect(is_equal_approx(controller.additional_damage_percent, 1.5), "斧头满级数值")
			"铁毡":
				expect(controller.anvil_count == 5 and is_equal_approx(controller.additional_damage_percent, 1.5), "铁毡满级数值")
			"闪电":
				expect(controller.LightAbilityNum == 3 and controller.LightAmount == 8 and controller.LightDamage == 30 and controller.LightDistance == 200 and is_equal_approx(controller.timer.wait_time, 2.5), "闪电满级数值")
		lab.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	for kind in ["普通敌人", "巫师", "蝙蝠"]:
		var lab = LAB.instantiate()
		lab.enemy_kind = kind
		lab.weapon_kind = "无"
		lab.max_enemies = 3
		lab.spawn_interval = 1.5
		lab.auto_start = true
		add_child(lab)
		var spawner = lab.arena.get_node("EnemyManager")
		for i in range(5):
			spawner.on_timer_timeout()
		var enemies = get_tree().get_nodes_in_group("enemy")
		expect(enemies.size() == 3, "自定义怪物上限：" + kind)
		for enemy in enemies:
			expect(enemy.scene_file_path == lab.ENEMY_PATHS[kind], "只生成所选怪物：" + kind)
		expect(is_equal_approx(spawner.timer.wait_time, 1.5), "自定义补怪间隔")
		lab.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	# 正式场景不激活任何测试覆盖。
	var normal = load("res://sences/main/main.tscn").instantiate()
	add_child(normal)
	var enemy_manager = normal.get_node("EnemyManager")
	for difficulty in [3, 6, 8]:
		enemy_manager.on_arena_difficulty_increased(difficulty)
	expect(enemy_manager.enemy_table.items.size() == 4, "正常难度仍加入四种怪")
	expect(enemy_manager.number_to_swpan == 3, "正常难度仍增加生成数")
	var upgrades = normal.get_node("UpgradeManager")
	expect(upgrades.test_weapon_id.is_empty() and upgrades.upgrade_pool.items.size() == 8, "正式初始升级池包含火焰剑卡牌")
	expect(normal.get_node("Entities/Player/Abilities/SwordAbilityController").burn_config == null, "正式默认剑不带火焰 Buff")
	upgrades.test_weapon_id = "闪电"
	var initial = upgrades.pick_upgrades()
	expect(initial.size() == 1 and initial[0].id == "闪电", "尚未解锁时只提供指定武器解锁")
	upgrades.apply_upgrade(initial[0])
	expect(upgrades.pick_upgrades().size() == 2, "解锁后动态过滤强化池")
	expect(not normal.get_node("Entities/Player").test_invulnerable, "正式玩家仍正常受伤")
	normal.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
