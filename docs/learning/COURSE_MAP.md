# 81 节课程与当前实现对照

保留你给出的课程英文标题和时长，用 A～F 区分每组重新从 1 开始的编号。共 **6 + 23 + 26 + 6 + 14 + 6 = 81 节**。

每行给出“学习时先问什么”和当前代码入口；同名 `.gd` / `.tscn` 应一起打开。这里没有视频内容可逐帧核实，主题对应不表示现在代码仍是当时那一课的最终版本。Checkpoint、Conclusion 和历史 Bug Fix 不凭标题推断具体改动。

映射措辞也表示可靠度：“对应/当前实现”表示能在代码中直接找到主题；“按主题对应”表示当前有同类实现但无法确认就是视频中的原对象；“无法断言/不推定”表示只能给复习入口，不能还原历史步骤。遇到当前已知缺陷时，本表描述设计目标，并显式链接现状，不把 Bug 当成推荐实现。

完整解释见 [主线指南](LEARNING_GUIDE.md)，操作位置见 [Godot 设置速查](GODOT_EDITOR_GUIDE.md)。

<a id="a"></a>
## A. 环境与可移动世界（6 节）

| 编号 | 原课程 / 时长 | 思考与设计重点 | 当前实现入口 / 编辑器定位 |
| --- | --- | --- | --- |
| A01 | Godot Download and Setup · 04:55 | 先确定引擎版本、入口和运行环境 | [project.godot](../../project.godot)、[首次打开项目](GODOT_EDITOR_GUIDE.md#first-open)、[环境说明](../development/DEVELOPMENT.md)；基准 Godot 4.3，不顺手迁移版本 |
| A02 | Creating the Player · 12:45 | 可显示、可碰撞、可复用的角色需要哪些节点？ | [player.tscn](../../sences/game_object/player/player.tscn)；CharacterBody2D、Visuals/Sprite2D、CollisionShape2D |
| A03 | Player Movement · 15:59 | 输入如何变成方向、目标速度与碰撞位移？ | [player.gd](../../sences/game_object/player/player.gd)、[VelocityComponent](../../sences/component/velocity_component.gd)；Input Map、Max Speed、Acceleration |
| A04 | Creating a TileMap · 11:19 | 哪些数据属于瓷砖规则，哪些属于地图摆放？ | [main.tscn](../../sences/main/main.tscn) 的 TileMapLayer、[tileset.tres](../../resource/tileset.tres)；[地图设置](GODOT_EDITOR_GUIDE.md#tilemap) |
| A05 | Game Camera · 12:57 | 谁是跟随目标，如何平滑而不写死节点路径？ | [game_camera.gd](../../sences/game_object/game_camera/game_camera.gd)；player Group、global_position 插值 |
| A06 | Checkpoint · 00:32 | 能否只用移动、地图、摄像机形成可运行检查点？ | 当前仓库没有单独标记这一课的历史场景；按[阶段 A 验收](LEARNING_GUIDE.md#checkpoints)核对可移动世界，不把现有完整项目误当作当时检查点 |

建议产出：画出 Player 节点树，写明每个子节点职责，解释为什么视觉翻转不必翻转拾取区。详见 [主线第 2 节](LEARNING_GUIDE.md#world)。

<a id="b"></a>
## B. 战斗与成长闭环（23 节）

| 编号 | 原课程 / 时长 | 思考与设计重点 | 当前实现入口 / 编辑器定位 |
| --- | --- | --- | --- |
| B01 | Creating a Rat Enemy · 09:39 | 敌人的方向来源如何与玩家区别、移动如何复用？ | [basic_enemy.gd](../../sences/game_object/basic_enemy/basic_enemy.gd)、[场景](../../sences/game_object/basic_enemy/basic_enemy.tscn)；enemy Group、VelocityComponent |
| B02 | Creating the First Sword Ability · 18:33 | 把释放决策和一次攻击实体分开 | [剑控制器](../../sences/ability/sword_ability_controller/sword_ability_controller.gd)、[剑场景](../../sences/ability/sword_ability/sword_ability.tscn)；PackedScene 与 Timer |
| B03 | Introduction to AnimationPlayer · 13:23 | 用时间轴控制属性、命中窗口和结束动作 | 剑场景 AnimationPlayer → swing；[轨道速查](GODOT_EDITOR_GUIDE.md#animation) |
| B04 | Targeting Enemies With Sword Ability · 11:50 | 如何筛范围、选最近目标、朝向目标？ | 剑控制器 `on_timer_timeout()`；距离平方、filter、sort_custom、angle |
| B05 | Destroying Enemies · 14:43 | 攻击怎样让实体结束生命周期？ | [HurtboxComponent](../../sences/component/hurtbox_component.gd) → [HealthComponent](../../sences/component/health_component.gd)；当前已演进为组件链 |
| B06 | Project Settings Tweaks · 04:01 | 哪些显示/输入规则应该属于项目级？ | [项目设置速查](GODOT_EDITOR_GUIDE.md#project)；视口 640×360、viewport 拉伸、Nearest、命名碰撞层；不推定视频改了完全相同选项 |
| B07 | Spawning Enemies Automatically · 13:07 | 从手放一个敌人走向持续生成 | [enemy_manager.gd](../../sences/manager/enemy_manager.gd)、[场景](../../sences/manager/enemy_manager.tscn)；Timer、实例化、父层、生成位置 |
| B08 | Improving the Game Feel · 07:28 | 逻辑成立后，怎样让移动与攻击易于感知？ | [VelocityComponent](../../sences/component/velocity_component.gd)、玩家/敌人 Visuals、剑 swing；当前反馈比本阶段更丰富 |
| B09 | Creating the Game Loop Foundation · 18:01 | 谁定义一局开始、计时与结束？ | [ArenaTimeManager](../../sences/manager/arena_time_manager.gd)、[ArenaTimeUI](../../sences/ui/arena_time_ui.gd)、[main.gd](../../sences/main/main.gd) |
| B10 | Experience Drops · 08:57 | 敌人死亡如何留下独立存在的奖励？ | [VialDropComponent](../../sences/component/vial_drop_component.gd)、[经验瓶场景](../../sences/game_object/experience_vial/experience_vial.tscn)；died、掉落概率、拾取碰撞 |
| B11 | Experience Tracking · 09:24 | 谁持有经验状态，怎样让多系统知道拾取？ | [GameEvents](../../sences/autoload/game_events.gd)、[ExperienceManager](../../sences/manager/experience_manager.gd)；experience_updated、level_up |
| B12 | Creating a Health Component · 17:34 | 同一套血量能力如何给玩家与敌人复用？ | [health_component.gd](../../sences/component/health_component.gd)；max_health、damage、died、延迟删除 |
| B13 | Implementing Damage · 12:24 | 攻击区与受击区如何解耦？ | [Hitbox](../../sences/component/hitbox_component.gd)、[Hurtbox](../../sences/component/hurtbox_component.gd)；[碰撞矩阵](GODOT_EDITOR_GUIDE.md#collision) |
| B14 | Creating an Experience Bar · 11:16 | UI 应显示状态，还是拥有状态？ | [experience_bar.gd](../../sences/ui/experience_bar.gd)、[场景](../../sences/ui/experience_bar.tscn)；主场景绑定 Experience Manager，Max Value=1 |
| B15 | Using Custom Resources for Upgrades · 15:24 | 怎样用可编辑数据描述升级？ | [AbilityUpgrade](../../resource/upgrades/ability_upgrade.gd)、[sword_rate.tres](../../resource/upgrades/sword_rate.tres)；Inspector 中编辑 ID/上限/文本 |
| B16 | Upgrade UI Groundwork · 15:57 | 容器怎样排列独立卡牌？ | [upgrade_screen.tscn](../../sences/ui/upgrade_screen.tscn)、[ability_upgrade_card.tscn](../../sences/ui/ability_upgrade_card.tscn)；CanvasLayer、HBoxContainer、PanelContainer |
| B17 | Enabling Upgrade Selection · 09:41 | 点击哪张卡如何传回具体资源？ | [ability_upgrade_card.gd](../../sences/ui/ability_upgrade_card.gd)、[upgrade_screen.gd](../../sences/ui/upgrade_screen.gd)；gui_input、selected、bind(upgrade) |
| B18 | Making the Upgrade Functional · 07:51 | 卡牌选择如何改变真实武器参数？ | [UpgradeManager.apply_upgrade](../../sences/manager/upgrade_manager.gd) → GameEvents → 剑控制器升级回调 |
| B19 | Improving the Scene Tree Structure · 06:16 | 按职责和渲染顺序组织节点 | [main.tscn](../../sences/main/main.tscn)；四个 Manager 直接挂在 Main 下，Entities/Foreground 分层，UI 使用 CanvasLayer；关注 Y Sort 与生命周期 |
| B20 | Adding Player Health · 14:24 | 敌人贴身时怎样按间隔伤害玩家？ | [player.gd](../../sences/game_object/player/player.gd) 的 `check_deal_damage()`；CollisonArea2D、DamageIntervalTimer=0.5 |
| B21 | Player Health Bar · 16:34 | 怎样把生命组件变化同步到角色头顶？ | player.tscn → HealthBar；`update_health_display()`、health_changed/health_heal |
| B22 | Creating the Victory Screen · 11:59 | 生存满时长后怎样停止战斗并给去向？ | ArenaTimeManager timeout → [EndScreen](../../sences/ui/end_screen.gd)；Process Mode=Always、暂停场景树 |
| B23 | Creating the Defeat Screen · 06:31 | 胜败可复用多少界面结构？ | Main `on_player_died()` → EndScreen `set_defeat()`；更换文案与 jingle |

建议产出：不看目录，口述一次“剑命中 → 死亡 → 掉瓶 → 拾取 → 升级 → 剑更强”的调用链。详见 [战斗](LEARNING_GUIDE.md#combat) 与 [升级](LEARNING_GUIDE.md#upgrades)。

<a id="c"></a>
## C. 内容扩展与表现完善（26 节）

| 编号 | 原课程 / 时长 | 思考与设计重点 | 当前实现入口 / 编辑器定位 |
| --- | --- | --- | --- |
| C01 | Increase Difficulty Over Time · 13:36 | 时间怎样影响刷怪间隔和组成？ | ArenaTimeManager 的 `DIFFICULTY_INTERVAL` → EnemyManager 的 `on_arena_difficulty_increased()` |
| C02 | Improving the TileMap · 13:15 | 用地形连接规则减少手工拼图 | [tileset.tres](../../resource/tileset.tres) 的 floor Terrain、peering bits、碰撞多边形；TileSet/TileMap 面板 |
| C03 | Preventing Invalid Spawning · 18:26 | 候选位置怎样避开地形遮挡？ | [EnemyManager.get_spawn_position](../../sences/manager/enemy_manager.gd)；地形射线、90° 换方向，当前并非绝对合法性保证 |
| C04 | Creating an Axe Ability · 22:00 | 位置如何写成角度和半径的函数？ | [axe_ability.gd](../../sences/ability/axe_ability/axe_ability.gd)、[场景](../../sences/ability/axe_ability/axe_ability.tscn)；Tween 展开轨迹、AnimationPlayer 自转 |
| C05 | Enabling Acquisition of Axe Ability · 17:15 | 升级资源如何安装新控制器？ | [Ability 类型](../../resource/upgrades/ability.gd)、[axe.tres](../../resource/upgrades/axe.tres)、Player `on_ability_upgrade_added()` |
| C06 | Prevent Abilities from Being Chosen Twice · 09:40 | 区分同轮去重和达到上限后移除 | [UpgradeManager](../../sences/manager/upgrade_manager.gd) 的 pick/apply、[WeightedTable](../../scripts/weighted_table.gd) 的 exclude；axe Max Quantity=1 |
| C07 | Animating the Player · 19:17 | 用位置/旋转/缩放让单张 Sprite 有生命感 | [player.tscn](../../sences/game_object/player/player.tscn) → AnimationPlayer → walk/RESET；Visuals 与碰撞分离 |
| C08 | Animating the Enemy · 16:23 | 相同外观动画如何给不同实体复用思路？ | [basic_enemy.tscn](../../sences/game_object/basic_enemy/basic_enemy.tscn) → walk；脚本按速度翻转 Visuals |
| C09 | Animating Enemy Death · 10:26 | 敌人被删除后粒子如何继续播放？ | [DeathComponent](../../sences/component/death_component.gd)、[场景](../../sences/component/death_component.tscn)；移出原父节点、播放后清理 |
| C10 | Adding a Wizard Enemy · 25:53 | 新敌人怎样复用组件，只更换行为和配置？ | [wizard_enemy.gd](../../sences/game_object/wizard_enemy/wizard_enemy.gd)、[场景](../../sences/game_object/wizard_enemy/wizard_enemy.tscn)；走停、20 血、70 速度 |
| C11 | Using a Weighted Table for Enemy Spawning · 11:59 | 新敌人加入后如何表达相对出现概率？ | [weighted_table.gd](../../scripts/weighted_table.gd)、EnemyManager；累加权重与阶段解锁 |
| C12 | Animating the Wizard · 11:11 | 动画如何同时驱动表现与运动开关？ | wizard_enemy.tscn → walk/disappear；方法轨道 `set_is_moving(bool)` |
| C13 | Animating the Experience Vial Pickups · 20:34 | 拾取触发后如何避免重复收集，并飞向移动目标？ | [experience_vial.gd](../../sences/game_object/experience_vial/experience_vial.gd)；延迟禁用形状、tween_collect、最终 collect |
| C14 | Adding a Custom Font · 06:22 | 如何让字体成为全局样式的一部分？ | [theme.tres](../../resource/theme/theme.tres) → Default Font；项目 GUI/Theme；`cn_theme.tres` 当前未设置字体 |
| C15 | Adding Floating Damage Text · 20:53 | 怎样让受击位置产生短命反馈？ | Hurtbox `showDamageText()` → [floating_text.gd](../../sences/ui/floating_text.gd)；前景层、位移/缩放 Tween、queue_free |
| C16 | Implementing a Flash on Enemy Hit · 28:40 | Shader 参数怎样配合 Tween，多个实例怎样隔离？ | [HitFlashComponent](../../sences/component/hit_flash_component.gd)、[shader](../../sences/component/hit_flash_component.gdshader)；Local To Scene、lerp_percent |
| C17 | Adding Ability Damage Upgrades · 30:03 | 按次数重算倍率如何避免意外复利？ | [sword_damage.tres](../../resource/upgrades/sword_damage.tres)、[axe_damage.tres](../../resource/upgrades/axe_damage.tres)；各控制器升级回调 |
| C18 | Introduction to UI Theming · 12:08 | 共享风格与单控件覆盖如何分工？ | [theme.tres](../../resource/theme/theme.tres)；Theme 编辑器与 Theme Overrides |
| C19 | Finalizing Upgrade Card Theme · 13:22 | 背景、边距、字体、最小尺寸如何协同？ | [ability_upgrade_card.tscn](../../sences/ui/ability_upgrade_card.tscn)；PanelContainer、内部容器与标签样式 |
| C20 | Animating the Upgrade Card · 23:18 | 入场、悬停、选择与弃牌分别怎样表达？ | 卡牌 AnimationPlayer 和 HoverAnimationPlayer；[脚本](../../sences/ui/ability_upgrade_card.gd) 的 play_in/select_card/play_discard |
| C21 | Improving the Upgrade Selection Screen · 04:25 | 暂停与错峰入场如何让玩家看清选项？ | [upgrade_screen.gd](../../sences/ui/upgrade_screen.gd)；每张延迟 0.2 秒、选后退出动画 |
| C22 | Applying a Style to the Experience Bar · 03:53 | 用比例显示与主题样式分离数值和外观 | [experience_bar.tscn](../../sences/ui/experience_bar.tscn)、theme.tres 的 ProgressBar fill/background |
| C23 | Animating Victory and Defeat Screens · 08:48 | 为什么缩放动画需要正确的中心点？ | [end_screen.gd](../../sences/ui/end_screen.gd)；pivot_offset=size/2、Tween 缩放、暂停下处理 |
| C24 | Applying Styles to the Buttons · 08:28 | 正常、悬停、按下、禁用需要不同反馈 | theme.tres 的 Button/styles；[sound_button.tscn](../../sences/ui/sound_button.tscn) 复用按钮行为 |
| C25 | Creating a Player Move Speed Upgrade · 07:11 | 同一事件如何同时支持武器和角色数值升级？ | [player_speed.tres](../../resource/upgrades/player_speed.tres)、Player 升级回调；每层初始速度 +10%，上限 2 |
| C26 | Adding a Vignette · 13:20 | 屏幕效果如何订阅玩家事件而不参与扣血？ | [vignette.gd](../../sences/ui/vignette.gd)、[场景](../../sences/ui/vignette.tscn)、[shader](../../sences/ui/vignette.gdshader)；ColorRect 材质参数动画 |

建议产出：用动画编辑器找到三个“脚本里没有直接调用”的方法轨道；解释它们为什么属于运行逻辑。详见 [动画与反馈](LEARNING_GUIDE.md#feedback)。

<a id="d"></a>
## D. 声音（6 节）

| 编号 | 原课程 / 时长 | 思考与设计重点 | 当前实现入口 / 编辑器定位 |
| --- | --- | --- | --- |
| D01 | Adding SFX - Part 1 · 15:40 | 世界事件如何触发有位置的音效？ | [random_stream_player_2d_component.gd](../../sences/component/random_stream_player_2d_component.gd)；玩家/敌人/经验瓶实例 |
| D02 | Adding SFX - Part 2 · 06:35 | 如何减少重复声音的机械感？ | 同组件的 Streams、Randomize Pitch、Min/Max Pitch；死亡组件也使用随机播放器；两课按主题合并定位 |
| D03 | Adding SFX to UI Elements - Part 1 · 07:51 | UI 声音为何使用非 2D 播放器？ | [random_stream_player_component.gd](../../sences/component/random_stream_player_component.gd)、[sound_button.gd](../../sences/ui/sound_button.gd) |
| D04 | Adding SFX to UI Elements - Part 2 · 03:27 | 声音时点怎样与卡牌动画同步？ | [ability_upgrade_card.tscn](../../sences/ui/ability_upgrade_card.tscn)、[meta_upgrade_card.tscn](../../sences/ui/meta_upgrade_card.tscn) 的音效方法轨道；不推断课程两部分的原始分界 |
| D05 | Adding Victory and Defeat Jingles · 05:09 | 胜败共用界面，声音怎样区分？ | [end_screen.gd](../../sences/ui/end_screen.gd) 的 play_jingle；场景中的 VictoryStreamPlayer/DefeatedStreamPlayer |
| D06 | Adding Music · 08:36 | 音乐怎样跨场景持续并循环？ | [music_player.gd](../../sences/autoload/music_player.gd)、[场景](../../sences/autoload/music_player.tscn)；Autoload、music 总线、结束后等待重播 |

建议产出：找出一个世界音效、一个 UI 音效、一段音乐的“触发点 → 播放器 → 总线”。详见 [音频指南](LEARNING_GUIDE.md#audio)。

<a id="e"></a>
## E. 菜单、永久成长与发布（14 节）

| 编号 | 原课程 / 时长 | 思考与设计重点 | 当前实现入口 / 编辑器定位 |
| --- | --- | --- | --- |
| E01 | Creating a Main Menu · 07:59 | 什么是入口场景，哪些按钮切换场景？ | [main_menu.gd](../../sences/ui/main_menu.gd)、[场景](../../sences/ui/main_menu.tscn)；Project Settings → Main Scene |
| E02 | Creating an Options Menu · 23:02 | 如何把界面操作映射到引擎窗口/音频 API？ | [options_menu.gd](../../sences/ui/options_menu.gd)；DisplayServer、AudioServer、linear_to_db/db_to_linear |
| E03 | Styling the Options Menu Sliders · 11:25 | 滑块轨道、填充、拖动点分别在哪里设？ | [theme.tres](../../resource/theme/theme.tres) 的 HSlider Styles/Icons；[options_menu.tscn](../../sences/ui/options_menu.tscn) 的 0～1 滑块 |
| E04 | Creating a Pause Menu · 19:05 | 暂停场景树后谁还能接收恢复输入？ | [main.gd](../../sences/main/main.gd)、[pause_menu.gd](../../sences/ui/pause_menu.gd)、[场景](../../sences/ui/pause_menu.tscn)；暂停动作、Always、close；退出属性存在已知问题 |
| E05 | Adding a Scene Transition Effect · 19:03 | 切场景应发生在动画哪个时点？ | [screen_transition.gd](../../sences/autoload/screen_transition.gd)、[场景](../../sences/autoload/screen_transition.tscn)；Shader percent、方法轨道、transitioned_halfway |
| E06 | Creating a Meta Progression System · 13:04 | 局内和永久状态的生命周期怎样分开？ | [MetaProgression](../../sences/autoload/meta_progression.gd)、[MetaUpgrade 类型](../../resource/meta_upgrades/meta_progression.gd)；经验瓶同时累积永久货币 |
| E07 | Saving and Loading Meta Progression Data · 06:58 | 数据放哪里、用什么结构、何时写？ | MetaProgression 的 load_save_file/save；FileAccess.store_var/get_var、user://game.save；当前启动有自动增加升级副作用 |
| E08 | Creating the Meta Upgrade Card · 15:55 | 卡牌怎样显示数据且不复制存档逻辑？ | [meta_upgrade_card.gd](../../sences/ui/meta_upgrade_card.gd)、[场景](../../sences/ui/meta_upgrade_card.tscn)；title、description、进度、次数 |
| E09 | Allowing Player to Purchase Meta Upgrades · 19:13 | 购买后怎样扣款、保存、刷新所有卡？ | `on_purchase_pressed()` → MetaProgression → `call_group`；[meta_menu.tscn](../../sences/ui/meta_menu.tscn) 的 Upgrades 数组 |
| E10 | Improving the Meta Upgrade Card · 22:57 | 余额不足和满级时如何明确反馈？ | `update_progress()`；PurchaseButton.disabled、Max、ProgressLabel、CountLabel 与 selected 动画 |
| E11 | Adding a ScrollContainer to the Meta Upgrade Screen · 09:54 | 内容超过视口时怎样滚动而不是挤坏布局？ | [meta_menu.tscn](../../sences/ui/meta_menu.tscn) → ScrollContainer/MarginContainer/GridContainer |
| E12 | Exporting the Game for Publishing · 21:36 | 编辑器可运行与目标平台可发布有哪些差别？ | [export_presets.cfg](../../export_presets.cfg)、[导出速查](GODOT_EDITOR_GUIDE.md#export)；模板、渲染器、数据文件、真实导出回归 |
| E13 | Fixing an Enemy Spawning Bug · 03:25 | 修复后需要什么边界测试，而不是只看一处正常？ | 当前 [EnemyManager.get_spawn_position](../../sences/manager/enemy_manager.gd)；四方向全遮挡仍有边界，无法断言与视频所修 Bug 完全相同 |
| E14 | Conclusion · 02:01 | 能否独立解释并扩展整个闭环？ | 完成[七次练习](LEARNING_GUIDE.md#practice)与[阶段验收](LEARNING_GUIDE.md#checkpoints)；结课证明是独立完成小扩展，不是一个单独代码模块 |

建议产出：画出“主菜单 → 战斗 → 结算 → 商店 → 主菜单”，并在每条边标明是否解除暂停、是否保存、是否等待转场。详见 [菜单](LEARNING_GUIDE.md#menus)、[永久成长](LEARNING_GUIDE.md#meta)。

<a id="f"></a>
## F. 后续内容与练习（6 节）

| 编号 | 原课程 / 时长 | 思考与设计重点 | 当前实现入口 / 编辑器定位 |
| --- | --- | --- | --- |
| F01 | Adding Another Enemy Type · 09:21 | 新敌人怎样从现有组件组合中产生差异？ | 按主题对应 [bat_enemy.gd](../../sences/game_object/bat_enemy/bat_enemy.gd)、[场景](../../sences/game_object/bat_enemy/bat_enemy.tscn)；30 血、60 速度、难度 6 入池；标题本身不证明视频敌人外观 |
| F02 | Creating an Anvil Ability · 16:02 | 怎样把落点、下落视觉和伤害窗口分离？ | [铁砧控制器](../../sences/ability/anvil_ability_controller/anvil_ability_controller.gd)、[实体场景](../../sences/ability/anvil_ability/anvil_ability.tscn)；资源 ID 为原拼写“铁毡” |
| F03 | Adding a Health Regeneration Meta Upgrade · 11:40 | 永久升级怎样在新一局给玩家安装持续效果？ | [health_regeneration.tres](../../resource/meta_upgrades/health_regeneration.tres) → Player.init_meta_buff → [BuffManager](../../sences/component/buff_component.gd) → [HealBuff](../../sences/buff/heal_buff/heal_buff.gd)；当前已扩展成 Buff 系统 |
| F04 | Adding an Anvil Ability Upgrade · 09:39 | 获得武器后怎样解锁伤害/数量强化？ | [anvil_damage.tres](../../resource/upgrades/anvil_damage.tres)、[anvil_amount.tres](../../resource/upgrades/anvil_amount.tres)、UpgradeManager.update_upgrade_pool 与控制器升级回调 |
| F05 | Fixing UI Sizing and Increasing Enemy Count · 06:05 | 布局边界和战斗压力是两个独立调整维度 | UI 场景的 Custom Minimum Size / Size Flags；EnemyManager 的 `number_to_swpan`；不把现值当成该课唯一变更 |
| F06 | Adding Anvil Impact Particles · 11:48 | 冲击粒子应何时开始，多久清理？ | anvil_ability.tscn → GPUParticles2D、Process Material、One Shot；AnimationPlayer 的 emitting 与 queue_free 轨道 |

建议产出：不改 Player 的武器专用逻辑，为一种练习武器补齐实体、控制器、解锁资源、强化资源和池注册。再读 [课程外扩展](LEARNING_GUIDE.md#extensions)，比较巨剑、闪电、宝箱怪如何复用或偏离这套方式。

## 回看时怎样用这张表

先选一行，说出它要解决的问题；打开链接看入口；沿脚本引用打开配套场景；在编辑器确认关键节点和导出字段；最后回主线指南解释它与上下游的联系。不必按视频时长连续重看，先恢复“数据流到哪里、事件由谁发出”，再补具体 API 记忆。
