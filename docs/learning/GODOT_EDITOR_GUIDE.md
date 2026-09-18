# Godot 4.3 编辑器设置速查

配合 [主线学习指南](LEARNING_GUIDE.md) 和 [课程对照表](COURSE_MAP.md) 使用。

这里把“去哪里改”具体到场景、节点和属性。**数值已经按当前源码/场景核对；菜单中文名称可能随翻译略有差异，英文名和配置键用于辅助搜索。** 现有记录只确认了编辑器主菜单场景的整体界面，没有留下可复用截图；本指南因此使用稳定的英文属性名、节点路径和文字界面图定位，不用未经当前环境复核的截图冒充项目实况。打开 Godot 后可按文中的“截图核对点”自行留下与你本机版本完全一致的复习图。

打开编辑器、查看配置不等于运行游戏。执行练习前，请按 [隔离运行说明](../development/DEVELOPMENT.md#隔离运行) 准备副本和独立用户目录；当前运行项目或单独场景都会加载自动保存的 Autoload。

<a id="navigation"></a>
## 1. 先认编辑器的五个区域

| 区域 | 本次看到的位置/名称 | 用途 |
| --- | --- | --- |
| Scene 场景树 | 左上“场景” | 选择当前场景的节点，看父子装配 |
| FileSystem 文件系统 | 左下“文件系统” | 找 `.tscn`、`.gd`、`.tres` 等项目文件 |
| 2D / Script 工作区 | 顶部中央标签 | 切换地图/节点编辑和脚本阅读 |
| Inspector / Node | 右侧“检查器 / 节点” | 检查器看属性，节点页看信号和分组 |
| 底部面板 | 输出、调试器、音频、动画等 | 读日志、编辑总线或时间轴；部分面板选中对应对象才出现 |

操作一个功能时，先在 FileSystem 找场景并双击，再在 Scene 选具体节点，最后看 Inspector。单击资源文件时右侧可能展示资源，而不是场景树当前高亮节点；先看 Inspector 顶部对象名称，避免改错对象。

场景实例的子节点若不可编辑，优先打开它的原 `.tscn`。只需要本次实例不同的数值时，才考虑对实例做覆盖。Inspector 的回退箭头提示某个值偏离默认/继承值；不要为查看设置点击回退。

在编辑器“场景”菜单中可找到打开场景/快速打开相关命令；快捷键受 macOS 和键位设置影响，文档不要求记某个组合键。

<a id="project"></a>
## 2. 项目级设置：从 Project Settings 进入

入口为顶栏 **项目 → 项目设置（Project Settings）**。General 页面可使用搜索框；找不到高级属性时开启高级设置显示。

| 目的 | 页签/属性路径（英文辅助名） | 当前配置及证据 |
| --- | --- | --- |
| 游戏入口 | General → Application → Run → Main Scene | `res://sences/ui/main_menu.tscn`；键 `application/run/main_scene` |
| 项目名称 | Application → Config → Name | `blood` |
| 逻辑画布 | Display → Window → Size → Viewport Width / Height | 640 × 360 |
| 桌面窗口尺寸覆盖 | Display → Window → Size → Window Width / Height Override | 1920 × 1080；和逻辑视口不是同一层概念 |
| 拉伸方式 | Display → Window → Stretch → Mode | `viewport` |
| 初始窗口模式 | Display → Window → Size → Mode | `3`（Fullscreen）；另有 `mode.debug = 0` 的调试覆盖 |
| 像素贴图过滤 | Rendering → Textures → Canvas Textures → Default Texture Filter | `0`（Nearest），避免插值模糊 |
| 全局 UI 主题 | GUI → Theme → Custom | `res://resource/theme/theme.tres` |
| 鼠标模拟触屏 | Input Devices → Pointing → Emulate Touch From Mouse | true |
| 用户目录 | Application → Config → Use Custom User Dir / Custom User Dir Name | true / `2DBlood`；练习副本改成唯一测试名称 |
| 物理层名称 | Layer Names → 2D Physics | 地形、玩家、敌人、敌人碰撞、玩家拾取 |

完整来源：[project.godot](../../project.godot)。这里的 `application/run/main_scene` 表示 `[application]` 下的 `run/main_scene`，其他键同理。

**注册 Autoload：** 项目设置的“全局（Globals）→ 自动加载（Autoload）”区域，核对 GameEvents、MusicPlayer、ScreenTransition、MetaProgression、ChangelogPorgress。选入的是各自 `.tscn`，名称决定脚本中用什么全局标识访问。它们已经注册，复习时不需要重复添加。

**配置输入：** 项目设置 → 输入映射（Input Map）。现有动作是 `move_left/right/up/down`、`left_click` 和中文 `暂停`；移动绑定 WASD/方向键，暂停绑定 P。脚本读的是动作名，不直接判断键盘字母。

**分组：** 选节点 → 右侧“节点（Node）→ 分组（Groups）”；项目设置的全局分组区域也可查看已声明组名。角色必须实际加入对应 Group，仅声明全局名字不等于该角色已入组。

<a id="first-open"></a>
### 2.1 第一次打开项目时的操作路线

1. 启动 Godot 4.3，在项目管理器选择“导入（Import）”，定位项目根目录的 `project.godot`。不要选择某个 `.tscn` 当项目入口。
2. 等待右上角或底部的首次资源导入结束。导入期间出现的临时缓存缺失与稳定复现的脚本错误要分开判断；已知冷导入记录见[开发基线](../development/DEVELOPMENT.md#本次实际结果)。
3. 从 FileSystem 双击 `sences/ui/main_menu.tscn`，确认 Scene 树出现主菜单，再双击 `sences/main/main.tscn` 查看战斗装配。
4. 右上角“播放项目”使用 Project Settings 的 Main Scene；“播放当前场景”只运行当前 `.tscn`。单独运行组件场景缺少 Autoload 以外的父场景依赖时，报错不等于完整项目入口也坏了。
5. 第一次只查看，不保存 Godot 自动建议的批量资源升级。项目以 4.3 为基准；较新引擎重存 `.tscn/.tres` 可能产生大量与学习无关的差异。

**截图核对点 A：Project Settings。** 截图时保留窗口标题、左侧设置树、搜索框和右侧当前值。至少记录 Main Scene、Display/Window、Input Map、Autoload、2D Physics Layer Names 五页。图片文件若以后加入仓库，建议放在 `docs/images/editor/`，文件名使用 `project-main-scene.png`、`input-map.png` 等稳定用途名，不要用“截图1”。

<a id="scene-workflow"></a>
## 3. 创建、实例化、连接与运行时检查

### 3.1 新建一个可复用场景

以练习敌人为例，不修改正式项目也能重复这套动作：

1. 顶栏“场景 → 新建场景”，选择“其他节点”，搜索 `CharacterBody2D` 作为根。
2. 按 F2 或右键重命名为有意义的类型；在右侧 Node → Groups 将它加入练习用 Group。正式敌人的身份组是 `enemy`。
3. 点击 Scene 树上方“添加子节点”，加入 `Node2D` 并命名 `Visuals`；在其下加入 `Sprite2D`。外观整体翻转时只改 Visuals，不必翻转所有判定形状。
4. 在根下加入 `CollisionShape2D`，再在 Inspector 的 Shape 新建 CircleShape2D 等资源。只有节点没有 Shape 资源，碰撞仍不会发生。
5. 选择根并“附加脚本（Attach Script）”，检查模板第一行是 `extends CharacterBody2D`。保存 `.gd`，再把场景保存到学习副本目录。
6. 打开容器场景，把这个 `.tscn` 从 FileSystem 拖到 Scene 树，或点击“实例化子场景”。这会创建实例，不会复制一份彼此无关的节点定义。

### 3.2 Inspector 中的四类引用

| 字段类型 | 赋值方式 | 本项目例子 | 常见错法 |
| --- | --- | --- | --- |
| 普通数值/枚举 | 输入数值或下拉选择 | Max Speed、Process Mode | 只改脚本默认值，忽略场景实例覆盖 |
| Node 引用 | 从当前 Scene 树拖节点 | EnemyManager → ArenaTimeManager | 拖入 `.tscn` 文件，类型不匹配 |
| PackedScene | 从 FileSystem 拖 `.tscn` | Sword Ability、End Screen Scene | 以为赋值后已自动实例化 |
| Resource | 拖 `.tres` 或在字段中新建 | Theme、TileSet、AbilityUpgrade | 修改共享资源导致所有引用者一起变化 |

字段右侧的回退箭头表示它偏离继承/默认值；复习时不要为“看看默认值”随便点击。先悬停或打开原场景核对。

### 3.3 信号到底在哪里连接

选节点后切到右侧 **Node → Signals**，可以看到该节点声明的信号。双击一个信号并选择目标节点，Godot 会创建回调并把连接保存进场景。当前项目也大量在 `_ready()` 中连接，例如玩家把 `DamageIntervalTimer.timeout` 连接到回调。

排查顺序：先找发出者的 `signal` 声明或内置信号，再全局搜索 `.connect(`，之后查 `.tscn` 底部的 `[connection ...]`，最后确认 `.emit()` 或内置事件是否真的发生。Autoload `GameEvents` 是跨系统总线；局部节点能直接引用时，不必把所有事件都提升成全局信号。

### 3.4 Local 与 Remote 场景树

运行项目后，Scene 面板上方可从 **Local** 切换到 **Remote**：

- Local 是保存在 `.tscn` 中的编辑状态；Remote 是当前进程实际存在的节点树。
- 剑、敌人、飘字、升级界面和运行时安装的能力控制器只会在 Remote 中出现。
- 选择 Remote 节点后 Inspector 显示运行时值，适合确认生命、速度、Timer 和 Process Mode；修改值通常只是本次运行临时实验。
- 游戏暂停时 Remote 树仍可查看。可借此确认 UpgradeScreen 存在、普通战斗节点停止、Always UI 继续处理。
- 停止运行后 Remote 消失；需要保留的配置必须回 Local 修改对应源场景或资源。

**截图核对点 B：场景树。** 打开 `main.tscn`，截 Local 树中直接挂在 Main 下的四个 Manager 节点，以及 Entities、Foreground；运行后截 Remote 树中新生成的敌人与武器。两张图使用相同展开层级，最容易看出“场景模板”和“运行实例”的区别。

<a id="player"></a>
## 4. 玩家、摄像机和战斗装配

### 4.1 玩家移动、血量和拾取

打开 [player.tscn](../../sences/game_object/player/player.tscn)。

| 选择节点 | Inspector 属性 | 当前值/作用 |
| --- | --- | --- |
| 根 `player` | Motion Mode | Floating（1），俯视角移动 |
| `VelocityComponent` | Max Speed / Acceleration | 125 / 25；组件脚本默认值分别为 40 / 5 |
| `HealthComponent` | Max Health | 默认 10，玩家场景没有再次覆盖 |
| `DamageIntervalTimer` | Wait Time / One Shot | 0.5 / true；接触伤害节流 |
| `HealthBar` | Range → Max Value；Show Percentage | 1 / false；脚本赋生命比例 |
| `Visuals/Sprite2D` | Texture / Offset / Material | 玩家图片、相对脚底偏移和描边材质 |
| `PickupArea2D/CollisionShape2D` | Shape → Radius | 32，拾取范围 |
| `CollisonArea2D/CollisionShape2D` | Shape → Radius | 7，敌人接触检测 |
| 根下 `CollisionShape2D` | Shape → Radius | 5，移动实体碰撞 |
| `Abilities/SwordAbilityController` | Max Range / Sword Ability | 距离 150；引用剑实体场景（继承自控制器场景） |
| `BuffComponent` | Health Component / Velocity Component | 分别引用同级生命和移动组件 |

导出字段在 Inspector 常显示成带空格的英文标题，脚本变量仍是 `max_speed`、`health_component` 等。某些属性折叠在基类小节，可以用 Inspector 搜索。

### 4.2 主场景的依赖注入

打开 [main.tscn](../../sences/main/main.tscn)，选以下节点并核对导出字段：

| 节点 | 字段 → 目标 |
| --- | --- |
| `Main` | End Screen Scene → `end_screen.tscn` |
| `ArenaTimeUI` | Arena Time Manager → 同级 ArenaTimeManager |
| `ExperienceBar` | Experience Manager → 同级 ExperienceManager |
| `EnemyManager` | Arena Time Manager → 同级 ArenaTimeManager |
| `UpgradeManager` | **Expericen Manager** → 同级 ExperienceManager，保留原拼写 |
| `Entities` | Ordering → Y Sort Enabled = true；组 `entites_layer` |
| `Entities/Player` | Collision → Layer = 0；启用场景唯一名访问 |
| `Foreground` | 组 `foreground_layer` |

Godot 中可将场景树节点拖到对应导出 Node 字段。PackedScene 字段则拖 `.tscn` 文件。两种引用类型不能混用。

摄像机在 [game_camera.tscn](../../sences/game_object/game_camera/game_camera.tscn)。它的实际跟随与平滑在脚本 `_process()`，从 `player` Group 找人；如果“不跟随”，先查玩家分组和脚本，不要只找 Inspector 的平滑开关。

当前 `main.tscn` 的 Foreground 下还预放了 6 个经验瓶，根下还有 `test/Test.tscn` 实例。这是当前场景的实验/调试遗留，不属于课程所需的正式层级；复习时可以辨认，但没有明确清理任务时不要顺手删除。

<a id="collision"></a>
## 5. 碰撞设置：用实际矩阵排除数字歧义

选中 CharacterBody2D 或 Area2D → Inspector → Collision → Layer / Mask。编辑器显示的是 **层编号**，`.tscn` 保存的是 **位掩码**。第 1/2/3/4/5 层的数值分别是 1/2/4/8/16；9 表示同时开启第 1 与第 4 层。

| 对象 | Layer（自己所在层） | Mask（检测层） | 用途 |
| --- | --- | --- | --- |
| TileSet 的 Physics Layer 0 | 第 1 层（1） | 无（0） | 地形障碍 |
| 主场景 `Entities/Player` 根 | 无（0） | 默认第 1 层（1） | 玩家移动与地形碰撞 |
| 普通敌人根 | 第 4 层（8） | 第 1、4 层（9） | 地形和敌人间实体碰撞 |
| `HitboxComponent` | 第 3 层（4） | 无（0） | 提供攻击区域，给 Hurtbox 检测 |
| `HurtboxComponent` | 无（0） | 第 3 层（4） | 检测攻击 Area2D |
| 玩家 `CollisonArea2D` | 无（0） | 第 4 层（8） | 检测敌人 Body 进入/离开 |
| 玩家 `PickupArea2D` | 第 5 层（16） | 无（0） | 被经验瓶检测 |
| 经验瓶 `Area2D` | 无（0） | 第 5 层（16） | 检测玩家拾取 Area2D |

第 3 层名字虽然是“敌人”，实际在此用作攻击判定通道；第 2 层叫“玩家”，也不表示玩家实体当前一定勾选它。应以当前场景值为准。

具体排查步骤：

1. 确认碰撞对象类型：Body 对应 `body_entered`，Area 对应 `area_entered`。
2. 确认双方有有效 Shape，Shape 尺寸和位置覆盖了预期区域。
3. 确认检测方 Mask 能看到对方 Layer。
4. 确认 Monitoring / Monitorable 与 Disabled 没有阻断检测；剑/铁砧的 Disabled 受动画控制。
5. 找脚本 `_ready()` 的信号连接；本项目很多连接不显示为编辑器静态连接。
6. 在学习副本运行时，可用“调试 → 可见碰撞形状”辅助观察，再结合 Remote 场景树查看实际实例。

**截图核对点 C：碰撞矩阵。** 分别选剑的 Hitbox、普通敌人的 Hurtbox、玩家的接触检测区，截图时同时保留 Scene 路径、Inspector 的 Layer/Mask 勾选和 Shape。不要只截一排数字，否则以后无法判断截图属于哪个节点。

<a id="tilemap"></a>
## 6. 地图与 TileSet：两处编辑，两个职责

1. 打开 `main.tscn`，选 `TileMap`。先看 Inspector 的类型，它是 **TileMapLayer**。
2. Inspector 的 Tile Set 指向 [resource/tileset.tres](../../resource/tileset.tres)。点击资源查看配置，底部 TileSet 面板负责图集和瓷砖规则。
3. TileMap 面板负责把已有瓷砖画到场景里；保存后摆放数据在 `.tscn`。
4. 需要墙碰撞时，在 TileSet 资源的 Physics Layers 核对层 0，并在 TileSet 图集编辑中选择具体瓷砖，编辑对应 Physics Layer 0 的碰撞多边形。
5. 需要自动连接地面时，在 TileSet 的 Terrains 核对已有 `floor`，再编辑瓷砖的 terrain peering bits（邻接边/角）；回 TileMap 的 Terrains 绘制模式使用。

现有图集纹理引用 `asserts/environment/tilemap_packed.png`。不要把“新增了一个 Physics Layer”当成“所有砖都有碰撞”；每块砖是否配置碰撞多边形也要检查。若教程界面把多个图层放在一个 TileMap 下，先理解概念对应，当前项目不用为了复习退回旧节点类型。

<a id="animation"></a>
## 7. AnimationPlayer：找到脚本里看不见的逻辑

1. 打开目标场景，选择 `AnimationPlayer`。
2. 在底部“动画（Animation）”面板选择动画名，如剑 `swing`、玩家 `walk`。
3. 读左侧轨道路径：冒号前通常是目标节点路径，后面是属性。如 `Visuals/Sprite2D:rotation`。
4. 点击关键帧，核对时间、数值、插值方式；方法轨道还要看调用方法和参数。
5. 需要理解有效命中窗口时，同时对照视觉轨道和 `CollisionShape2D:disabled`，不要只播放图片。
6. 查 RESET 和自动播放动画，区分编辑器预览值与进入游戏后的值。

| 场景 | 动画/轨道重点 | 应读的行为 |
| --- | --- | --- |
| [玩家](../../sences/game_object/player/player.tscn) | `walk`、`RESET`；Visuals/Sprite2D 的 position/rotation/scale | 走路时的跳动、摆动和挤压 |
| [剑](../../sences/ability/sword_ability/sword_ability.tscn) | 自动播放 `swing`；碰撞 Disabled；根方法 `queue_free` | 有效攻击时间与释放 |
| [斧头](../../sences/ability/axe_ability/axe_ability.tscn) | Sprite2D 的 rotation | 图片自转；轨迹在脚本 Tween 中 |
| [巫师](../../sences/game_object/wizard_enemy/wizard_enemy.tscn) | `walk`、`disappear`；`set_is_moving` 方法轨道 | 何时追踪、何时减速 |
| [死亡组件](../../sences/component/death_component.tscn) | 粒子 emitting、根方法 queue_free | 脱离敌人后继续播放并清理 |
| [升级卡](../../sences/ui/ability_upgrade_card.tscn) | `in`、`selected`、`discard`；另有 HoverAnimationPlayer | 入场、悬停、选择、弃牌与声音 |
| [转场](../../sences/autoload/screen_transition.tscn) | percent、visible、`emit_transitioned_halfway` | 遮挡到中点时切换场景 |
| [铁砧](../../sences/ability/anvil_ability/anvil_ability.tscn) | Visuals.position、碰撞 Disabled、粒子 emitting、queue_free | 落地判定、冲击与生命周期 |

**想新增方法轨道时：** 动画面板添加轨道 → Call Method Track（调用方法轨道）→ 选择目标节点 → 在目标时间插入键 → 选择方法与参数。不要为了找入口真的在原项目插入键；这只是学习副本中的操作步骤。

**截图核对点 D：AnimationPlayer。** 最推荐记录剑的 `swing`：Scene 树选中 AnimationPlayer，底部选择 `swing`，同时展开 Sprite 视觉轨、CollisionShape2D 的 `disabled` 轨和根节点方法轨。把播放头停在碰撞启用附近，截图就能一眼说明“动画也是程序逻辑”。

<a id="resources"></a>
## 8. 资源、升级与刷怪参数

### 8.1 Inspector 中编辑资源

在 FileSystem 单击/双击 `.tres` 资源，使 Inspector 显示它。以 [axe.tres](../../resource/upgrades/axe.tres) 为例：

- Ability Controller Scene：斧头控制器 `.tscn`。
- ID：`斧头`，参与程序逻辑。
- Max Quantity：1，获得后不能重复解锁。
- Name / Description：卡牌显示内容。

创建一个新 `.tres` 后还需要在 `upgrade_manager.gd` 注册；当前不是自动扫描目录。改伤害要到对应控制器的计算逻辑，资源没有一个通用 Damage 字段。

| 想调整 | 去哪里 | 当前值或公式 |
| --- | --- | --- |
| 开局升级候选及权重 | [UpgradeManager._ready](../../sences/manager/upgrade_manager.gd) | 斧头/铁毡/巨剑各 20，剑攻速/伤害各 10，移速 5，闪电 30 |
| 一次展示几张卡 | 同脚本 `pick_upgrades()` | `for i in 2`，最多两张 |
| 剑升级上限 | [sword_damage.tres](../../resource/upgrades/sword_damage.tres)、[sword_rate.tres](../../resource/upgrades/sword_rate.tres) | 各 5 |
| 剑伤害 | [剑控制器脚本](../../sences/ability/sword_ability_controller/sword_ability_controller.gd) | 基础 5，每层伤害升级加基础值 15% |
| 剑频率 | 控制器 Timer 与升级回调 | 基础 Wait Time 默认 1，每层间隔减基础值 10% |
| 一局时长 | [arena_time_manager.tscn](../../sences/manager/arena_time_manager.tscn) → Timer | 300 秒 |
| 难度间隔 | ArenaTimeManager 脚本常量 | 5 秒 |
| 刷怪半径与避障 | EnemyManager 脚本 | 200，四方向射线尝试 |
| 敌人类型引用 | [enemy_manager.tscn](../../sences/manager/enemy_manager.tscn) 根节点 | 四个 PackedScene 字段 |
| 敌人血量与速度 | 各敌人场景中的 Health/VelocityComponent 实例 | 普通 10/40、巫师 20/70、蝙蝠 30/60、宝箱怪 50/60 |
| 掉落概率 | 敌人实例下 VialDropComponent → Drop Percent | 普通 0.3、巫师 0.5、蝙蝠 0.675、宝箱怪 1.0；以场景实例覆盖后的有效值为准 |
| 永久回血间隔 | [HealBuff.tscn](../../sences/buff/heal_buff/HealBuff.tscn) 根节点 `_trigger_intervals` | 15，首次触发见 BuffBase 逻辑 |

### 8.2 组件引用如何绑定

打开 `basic_enemy.tscn`，选择 HurtboxComponent、VialDropComponent、HitFlashComponent、DeathComponent，逐一检查导出字段。健康引用指向同级 HealthComponent；反馈组件的 Sprite 指向 `Visuals/Sprite2D`。VialDrop 的字段保留 `health_compoent` 拼写。

为什么某些组件场景单独打开没有这些引用？因为只有实例化到敌人场景后，才知道应绑定哪一个生命和 Sprite 节点。

<a id="ui"></a>
## 9. UI、主题、暂停和资源共享

### 9.1 布局在哪里调

打开 [upgrade_screen.tscn](../../sences/ui/upgrade_screen.tscn)：选 MarginContainer 查看 Layout/Anchors 是否覆盖屏幕；选 CardContainer 查看 Container Sizing（Size Flags）及 Theme Overrides → Constants → Separation。当前卡间距为 16。

打开 [ability_upgrade_card.tscn](../../sences/ui/ability_upgrade_card.tscn)：根是 PanelContainer；看 Custom Minimum Size、内部 MarginContainer 边距、VBoxContainer 间距、Label 换行和字体。选中被容器管理的孩子，优先调整布局参数而非手填 Position。

打开 [meta_menu.tscn](../../sences/ui/meta_menu.tscn)：场景树中沿 `ScrollContainer/MarginContainer/GridContainer` 查看，确认内容是滚动区域的子节点；根 Upgrades 数组决定生成哪些卡。

### 9.2 主题在哪里调

1. FileSystem 选择 [theme.tres](../../resource/theme/theme.tres)，打开底部 Theme 编辑器。
2. 选控件类型 Button、ProgressBar 或 HSlider，查看 Styles、Colors、Constants、Fonts 等。
3. Button 重点看各状态的 StyleBox；ProgressBar 看 background / fill；HSlider 看 slider、grabber_area 与 grabber 图标。
4. 只想改一个控件时，选它的 Inspector → Theme Overrides；想所有同类控件一致时改共用 Theme。
5. 字体默认来自 Theme 的 Default Font。当前 `cn_theme.tres` 未填字体，中文表现要另外检查。

### 9.3 暂停处理在哪里调

选场景根 → Inspector → Node → Process → Mode（可搜索 Process Mode）。

| 对象 | 当前设置 |
| --- | --- |
| UpgradeScreen / EndScreen / PauseMenu | Always（3） |
| ScreenTransition / MusicPlayer | Always（3） |
| 普通战斗节点 | 通常继承父级处理模式，随场景树暂停 |

设置面板 OptionsMenu 作为暂停菜单的孩子时，会继承父级处理规则；不能只看它在单独场景中的根设置推断所有运行情境。

### 9.4 受击材质共享在哪里看

选敌人的 HitFlashComponent，展开 Hit Flash Material；或选 Sprite2D 展开 Material。查看 Resource → Local To Scene 和 Shader Parameters（`lerp_percent` 等）。单纯改变 Resource 可能影响所有引用它的实例，应先理解它是共享资源还是场景本地副本。

暗角则打开 [vignette.tscn](../../sences/ui/vignette.tscn) → ColorRect → Material → Shader Parameters。`vignette_intensity`、`vignette_opacity`、`vignette_rgb` 同时受 AnimationPlayer 写入，Inspector 手调值可能在播放后被覆盖。

<a id="audio"></a>
## 10. 音频设置

底部“音频（Audio）”面板查看总线 `Master / sfx / music`，配置保存在 [default_bus_layout.tres](../../default_bus_layout.tres)。

选具体 AudioStreamPlayer 或 AudioStreamPlayer2D → Inspector 查看 Stream、Volume dB、Pitch Scale、Bus。随机组件还额外暴露 Streams 数组和音调随机范围。

| 功能 | 场景与节点 |
| --- | --- |
| 常驻音乐 | [music_player.tscn](../../sences/autoload/music_player.tscn) 根：Autoplay=true、Bus=music；Timer 等待 4 秒 |
| 玩家受击/治疗 | player.tscn 下 HitRandomStreamPlayer / HealRandomStreamPlayer |
| 敌人受击 | 敌人场景下 HitRandomAudioPlayerComponent |
| UI 点击 | [sound_button.tscn](../../sences/ui/sound_button.tscn) 下 RandomStreamPlayerComponent |
| 胜利/失败声音 | [end_screen.tscn](../../sences/ui/end_screen.tscn) 下 VictoryStreamPlayer / DefeatedStreamPlayer |
| 音量滑块 | [options_menu.tscn](../../sences/ui/options_menu.tscn) 的唯一名 MusicSlider / SfxSlider，Max Value=1 |

没有声音时先看播放器是否实际被触发，再看 Stream、Bus、总线静音与音量；不能只看到 `.ogg` 文件存在就认定播放链路完成。

<a id="export"></a>
## 11. 导出与发布

入口：**项目 → 导出（Export）**。当前 [export_presets.cfg](../../export_presets.cfg) 保存 Windows Desktop、Web、Android 三套预设。查看目标平台时，分别检查导出模板、平台参数、Resources 导出范围与文件过滤规则。

建议的发布步骤：

1. 在隔离副本通过入口、战斗、选卡、暂停、结算、商店的人工回归。
2. 检查目标平台使用的渲染器；当前项目是 Forward Plus，不能因为有 Web 预设就推断可直接正常发布 Web。
3. 检查运行时数据文件是否打包。`ChangeLog.md` 会被游戏读取；Android 当前包含规则为 `*.md`，Windows/Web 没有同样规则。新增学习文档也可能被 Android 广泛规则打包，应在正式发布时收窄到所需文件并验证。
4. 导出到独立目录，运行真正导出的版本，检查输入、字体、声音、窗口/触屏、存档与日志界面。
5. 再验证重启和升级存档兼容；不要删除真实存档来掩盖问题。

本次只核对预设存在和配置内容，没有执行平台导出。

## 12. 查一个设置时的固定句式

可以给自己留这样的笔记：

> 我想改变：玩家拾取范围。打开：player.tscn。选择：PickupArea2D/CollisionShape2D。属性：Shape → Radius。当前：32。影响：进入拾取动画的距离。验证：隔离副本中从远处接近经验瓶。

这个句式包含了修改入口、当前事实、预期效果和验证方法，比只记“去玩家那里调”更容易在几个月后重新接上思路。
