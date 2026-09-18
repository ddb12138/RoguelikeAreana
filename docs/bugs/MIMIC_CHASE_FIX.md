# Bug 修复单：宝箱怪进入追逐动画后不移动

状态：工作区已修复，待提交  
日期：2026-09-17  
模块：宝箱怪状态机、AnimationPlayer、吸力与玩家移动  
主问题：宝箱怪完成唤醒表现后，可能已经播放 `chase` 动画，但仍停在原地不追逐玩家

> 本文中的“修改前”指当前 Git `HEAD` 中的旧实现，“修改后”指 2026-09-17 工作区中的待提交实现。行为参数采用 `mimic_chest_enemy.tscn` 的实例配置值，而不是脚本中的默认值。

## 文档目的

本文单独记录宝箱怪“进入追逐动画后不移动”的问题现象、复现条件、根本原因、修复思路、修改前后代码、关联修复、影响文件和验证结果，作为本次代码提交的 Bug 修复说明。

## 问题现象

### 用户可见表现

玩家进入宝箱怪的唤醒范围后，宝箱正常播放打开动画，随后画面也切换为跳动的 `chase` 动画，但宝箱可能停在原地，不向玩家移动。此时视觉表现与实际逻辑状态不一致：

```text
AnimationPlayer 当前动画 = chase
isChasing = false
```

旧版移动代码只在 `isChasing` 为 `true` 时运行，所以仅仅播放 `chase` 动画并不等于真正进入追逐：

```gdscript
if isChasing:
    suction_ability.apply_suction(self)
    velocity_component.accelerate_to_player()
    velocity_component.move(self)
```

### 触发条件

该问题与 `wakeup` 动画末尾多个方法键的时序有关。它不是每次必现：是否触发取决于 AnimationPlayer 某次更新跨过了哪些关键帧，以及动画方法回调与宝箱 `_process()` 的执行时序。因此在不同处理帧率或不同帧时间波动下，可能表现为偶发卡住。

### 最小复现时序

旧 `wakeup` 动画长度为 0.600 秒，方法轨道末尾依次安排了：

| 时间 | 方法 | 结果 |
| --- | --- | --- |
| 0.590 秒 | `set_play_state(false)` | 解除“正在播放过渡动画”的锁 |
| 0.595 秒 | `play_chase()` | 立即把当前动画从 `wakeup` 切换为 `chase` |
| 0.600 秒 | `set_chasing_state(true)` | 才允许 `_process()` 执行追逐移动 |

如果一次动画推进只跨过 0.595 秒，`play_chase()` 会先执行，把当前动画切换为 `chase`。只要在后续动画推进前没有其他代码再次切换动画，AnimationPlayer 下一次推进的就是从 0 秒开始的 `chase`，而不是从 0.595 秒继续前进的 `wakeup`；因此 `wakeup` 在 0.600 秒的方法键可能永远不会再被经过。

旧实现还存在一条相关的重入路径：0.590 秒已经把 `isPlayingAnimation` 解除，但 `isChasing` 仍为 `false`。如果玩家仍在唤醒范围内，宝箱的 `_process()` 可能再次满足唤醒条件并重新调用 `play_wake_up()`。所以旧状态既可能卡在“播放 chase 但未追逐”，也可能在末尾重新播放 wakeup；两者都来自逻辑状态被拆散在相邻动画键和逐帧判断中。

## 根本原因

根本原因是把同一个行为状态拆给了两个不可靠地同步的系统：

```text
视觉状态：由 AnimationPlayer 当前动画表示
逻辑状态：由 isPlayingAnimation 和 isChasing 表示
状态切换：又分散在动画方法轨道的多个时间点
```

旧脚本使用两个独立布尔值：

```gdscript
var isPlayingAnimation: bool = false
@export var isChasing: bool = false
```

`play_chase()` 只负责切换动画：

```gdscript
func play_chase():
    animation_player.play("chase")
```

真正允许移动的 `isChasing = true` 却安排在当前动画后面的另一个方法键中。调用 `AnimationPlayer.play("chase")` 是立即替换当前动画，不是把新动画排在 `wakeup` 之后。因而代码隐含的前提——“切换动画后，旧动画上剩余的方法键仍会执行”——并不成立。

用两条时间轴表示如下：

```text
wakeup：0.000 ───── 0.590 ─ 0.595 ─ 0.600
                              │          └─ isChasing = true
                              └─ play("chase")，离开本时间轴

chase：                     0.000 ─ 0.016 ─ 继续
                              ↑
                         下一次推进的新时间轴
```

所以问题不是追踪方向、加速度或 `move_and_slide()` 本身失效，而是追逐移动的入口条件没有可靠地打开。

在未修复版本中使用真实 AnimationPlayer 手动推进：先推进 0.595 秒并等待延迟方法调用，再推进 0.02 秒，曾得到：

```text
animation=chase isChasing=false
```

这直接证明旧版能够进入视觉动画与逻辑状态不同步的组合，而不只是从源码推测。

旧 `sleep` 动画也有同类隐患：它在 0.590 秒调用 `play_idle()` 切走当前动画，却把 `set_play_state(false)` 放在 0.600 秒，可能导致动画锁未清除。

此外，旧实现还暴露出一个独立但相关的生命周期问题：休眠时会关闭吸力，却没有在后续再次进入追逐时可靠地重新开启吸力。

## 修改前后的代码对比

### 1. 状态表示：两个布尔值改为单一枚举状态

修改前：

```gdscript
var isPlayingAnimation: bool = false
@export var isChasing: bool = false
```

修改后：

```gdscript
enum State { IDLE, WAKING, CHASING, SLEEPING }
var state: State = State.IDLE
```

修改后的任意时刻只有一个明确状态，避免出现“动画在追逐、逻辑未追逐”等无效组合。

### 2. 状态推进：动画方法轨道改为完成信号

修改前，`wakeup` 动画的方法轨道负责按时间分别修改多个字段和切换动画：

```text
0.590  set_play_state(false)
0.595  play_chase()
0.600  set_chasing_state(true)
```

修改后，场景中删除这条状态方法轨道，在 `_ready()` 中监听非循环动画真正完成：

```gdscript
func _ready() -> void:
    $HurtboxComponent.hit.connect(on_hit)
    animation_player.animation_finished.connect(on_animation_finished)
    player = get_tree().get_first_node_in_group("player") as Node2D
    enter_state(State.IDLE)
```

动画完成后再推进逻辑状态：

```gdscript
func on_animation_finished(animation_name: StringName) -> void:
    if animation_name == &"wakeup" && state == State.WAKING:
        if is_instance_valid(player) \
                && !player.is_queued_for_deletion() \
                && player.global_position.distance_to(global_position) <= sleep_range:
            enter_state(State.CHASING)
        else:
            enter_state(State.SLEEPING)
    elif animation_name == &"sleep" && state == State.SLEEPING:
        enter_state(State.IDLE)
```

`animation_name` 和当前 `state` 同时参与判断，可避免已过期的动画完成事件错误地改变新状态。

### 3. 进入追逐：逻辑、吸力和动画原子化处理

修改前，追逐相关动作散落在动画轨道、`_process()` 和吸力组件中：

```gdscript
func play_chase():
    animation_player.play("chase")

func set_chasing_state(state: bool):
    isChasing = state
```

修改后，进入 `CHASING` 的同一次函数调用同时设置状态、开启吸力和播放动画：

```gdscript
func enter_state(next_state: State) -> void:
    state = next_state
    if state == State.CHASING:
        suction_ability.turn_on_suction()
        animation_player.play("chase")
        return
```

真正移动也只由明确状态控制：

```gdscript
if state == State.CHASING:
    velocity_component.accelerate_to_player()
    velocity_component.move(self)
```

### 4. 离开追逐：统一停止移动和吸力

修改前，停止追逐、关闭吸力、切换动画和动画锁清理分散在不同位置。

修改后，所有非追逐状态统一执行：

```gdscript
suction_ability.turn_off_suction()
velocity = Vector2.ZERO
velocity_component.velocity = Vector2.ZERO
```

进入闭合状态时立即应用重置姿态，再播放 `sleep`：

```gdscript
State.SLEEPING:
    animation_player.play("RESET")
    animation_player.advance(0)
    animation_player.play("sleep")
```

这避免追逐动画留下的旋转、缩放或压扁姿态污染闭合动画。

## 修复思路与实现

本次没有只把 0.600 秒的方法键移到 0.595 秒之前。那样虽然可能掩盖当前现象，但状态仍然分散在动画资源和脚本中，后续修改动画时很容易再次引入时序错误。

采用的思路是：

1. 用四态状态机表达完整生命周期：`IDLE → WAKING → CHASING → SLEEPING → IDLE`。
2. 动画只负责表现，不再通过末尾的多个方法键拼装核心逻辑状态。
3. 使用 `animation_finished` 作为 `WAKING → CHASING` 和 `SLEEPING → IDLE` 的明确边界。
4. 用 `enter_state()` 集中维护进入状态时的动画、速度和吸力，保证这些结果同步发生。
5. 用两个距离阈值形成迟滞区：休息时距离不大于 100 像素才唤醒，已经激活后距离大于 150 像素才休眠，避免边界附近频繁开合。
6. 玩家或吸力源失效时进行有效性检查，安全关闭追逐和吸力。

新流程为：

```text
玩家进入唤醒范围
    ↓
enter_state(WAKING)
    ↓
完整播放 wakeup
    ↓ animation_finished
再次确认玩家仍在休眠范围内
    ↓
enter_state(CHASING)
    ├─ state = CHASING
    ├─ 开启吸力
    └─ 播放 chase
    ↓
_process() 根据 CHASING 执行追逐移动
```

如果玩家在唤醒过程中已经远离，则不会强行开始追逐，而是进入 `SLEEPING`。

## 关联修复：吸力生命周期与移动所有权

### 再次唤醒没有吸力

旧版初始 `turnSwitch` 为 `true`，休眠时调用 `turn_off_suction()` 将其关闭，但再次唤醒没有对称的开启流程。新版把吸力默认状态改为关闭，并使每一次进入 `CHASING` 都显式调用 `turn_on_suction()`；离开追逐时统一调用 `turn_off_suction()`。

修改后的开关逻辑：

```gdscript
func turn_off_suction() -> void:
    turnSwitch = false
    remove_from_group("suction_sources")

func turn_on_suction() -> void:
    turnSwitch = true
    add_to_group("suction_sources")
```

后续全仓核对确认旧拼写入口无调用，已删除兼容转发方法；开启吸力统一使用 `turn_on_suction()`。

### 避免宝箱直接移动玩家

旧版由每个宝箱怪直接覆盖玩家速度并调用移动：

```gdscript
var desired_velocity = direction * suction_strength
player.velocity = desired_velocity
player.move_and_slide()
```

这会与玩家脚本自己的移动竞争。同一帧内，怪物和玩家可能各调用一次 `move_and_slide()`；多个宝箱还可能按节点处理顺序彼此覆盖速度。

新版 SuctionAbility 只计算并返回朝向吸力源的外部速度：

```gdscript
func get_suction_velocity(target: Node2D) -> Vector2:
    if !turnSwitch || !is_instance_valid(source) || source.is_queued_for_deletion():
        return Vector2.ZERO
    if !is_instance_valid(target) || target.is_queued_for_deletion():
        return Vector2.ZERO
    var offset = source.global_position - target.global_position
    if offset.length_squared() > suction_range * suction_range:
        return Vector2.ZERO
    return offset.normalized() * suction_strength
```

活动吸力组件加入 `suction_sources` 组，由玩家每帧统一汇总：

```gdscript
var suction_velocity = Vector2.ZERO
for source in get_tree().get_nodes_in_group("suction_sources"):
    suction_velocity += source.get_suction_velocity(self)
velocity_component.move(self, suction_velocity)
```

最终速度为：

```text
最终速度 = 玩家输入速度 + 所有有效吸力速度的向量和
```

VelocityComponent 只调用一次 `move_and_slide()`，并避免把临时吸力写回持久输入速度：

```gdscript
func move(character_body: CharacterBody2D, external_velocity: Vector2 = Vector2.ZERO):
    character_body.velocity = velocity + external_velocity
    character_body.move_and_slide()
    if external_velocity.is_zero_approx():
        velocity = character_body.velocity
    else:
        for i in character_body.get_slide_collision_count():
            var normal = character_body.get_slide_collision(i).get_normal()
            if velocity.dot(normal) < 0:
                velocity = velocity.slide(normal)
```

因此吸力结束后不会残留漂移，多个吸力源可以相加或抵消，碰撞仍由玩家这一次移动统一处理。

## 本次涉及的文件

### 核心修复文件

| 文件 | 修改内容 | 与主 Bug 的关系 |
| --- | --- | --- |
| `sences/game_object/mimic_chest_enemy/mimic_chest_enemy.gd` | 用四态状态机替代两个布尔值；监听 `animation_finished`；集中处理动画、追逐、速度和吸力 | 主修复 |
| `sences/game_object/mimic_chest_enemy/mimic_chest_enemy.tscn` | 删除 `wakeup` 与 `sleep` 中用于切换逻辑状态的方法轨道，保留视觉动画轨道 | 主修复 |

### 关联行为修复文件

| 文件 | 修改内容 | 作用 |
| --- | --- | --- |
| `sences/ability/suction_ability/suction_ability.gd` | 吸力改为显式开关和活动源注册；只计算外部速度，不直接移动玩家 | 修复重复唤醒吸力，消除移动所有权冲突 |
| `sences/game_object/player/player.gd` | 汇总 `suction_sources` 中所有有效吸力并与输入速度合成 | 保留玩家控制并支持多个吸力源 |
| `sences/component/velocity_component.gd` | `move()` 支持临时外部速度且只执行一次碰撞移动 | 防止吸力写回持久速度和停止后漂移 |

### 回归测试文件

| 文件 | 作用 |
| --- | --- |
| `test/mimic_regression.gd` | 自动断言动画末尾时序、真实追逐、重复唤醒、吸力合成、碰撞、暂停和节点释放 |
| `test/mimic_regression.tscn` | 独立回归测试场景入口 |

### 说明与提交配套文件

| 文件 | 作用 |
| --- | --- |
| `docs/bugs/MIMIC_CHASE_FIX.md` | 本 Bug 的独立修复单 |
| `docs/monsters/MIMIC_CHEST.md` | 宝箱怪当前玩法、参数、状态机、吸力设计和行为边界的长期说明 |
| `resource/Beastiary/mimic_enemy.tres` | 更新游戏内图鉴描述，使其符合修复后的行为 |
| `docs/development/DEVELOPMENT.md` | 增加宝箱怪回归命令与已验证范围 |
| `docs/architecture/ARCHITECTURE.md` | 更新宝箱怪状态机、吸力数据流和运行时 Group 描述 |
| `README.md`、`AGENTS.md` | 增加宝箱怪说明及测试入口索引；其中 README 当前还混有通用学习导航改动 |

其中前五个代码/场景文件构成本次行为修改；测试文件用于防止回归；`docs/monsters/MIMIC_CHEST.md` 是功能说明，本文件则专门记录 Bug 的发现与修复过程。

当前工作区还包含 `docs/learning/COURSE_MAP.md`、`docs/learning/GODOT_EDITOR_GUIDE.md`、`docs/learning/LEARNING_GUIDE.md` 等通用学习文档，它们不属于本 Bug 修复。准备提交时应将它们拆到其他提交；由于 README 同时引用这些学习文档与本修复单，需要按变更块选择暂存，而不是把 README 的全部改动都默认归入本 Bug。

## 解决的问题与行为结果

本次修改解决或改善了以下行为：

1. 已消除本次由 `wakeup` 方法轨道时序造成的“播放 `chase` 但逻辑未进入追逐”路径。
2. `wakeup` 完整结束后才允许追逐，动画表现与逻辑状态保持一致。
3. 玩家在唤醒期间远离时，宝箱会取消激活并闭合，而不是动画结束后无条件追逐。
4. 退出追逐时立即清零宝箱速度并关闭吸力，不在闭合期间继续滑动或拉扯玩家。
5. 宝箱完成休眠后可以再次唤醒，并在每次进入追逐时恢复吸力。
6. 玩家输入与吸力按速度向量合成，不再互相覆盖。
7. 多个宝箱的吸力可以按方向增强、抵消或改变合力方向。
8. 吸力关闭或吸力源释放后不留下永久速度。
9. 玩家与地形的碰撞仍通过一次 `move_and_slide()` 处理，吸力不能直接把玩家移动穿过碰撞体。
10. 玩家节点失效时，宝箱安全回到休息状态并关闭吸力。

## 验证与回归

测试使用真实玩家场景和宝箱怪场景，不使用第三方测试框架。运行入口为：

```sh
"$GODOT_BIN" --headless --path "$CHECK_PROJECT" --fixed-fps 60 res://test/mimic_regression.tscn
```

项目启动会读写 `user://game.save`，因此必须按 `docs/development/DEVELOPMENT.md` 使用隔离项目副本和独立用户目录，不应直接拿真实存档执行自动测试。

已记录的验证环境为 Godot `4.3.stable.official.77dcf97d8`，测试日期为 2026-09-17，使用独立项目副本和独立用户目录。运行日志没有作为仓库文件保留；以下结果来自当次运行记录，本修复单同时保存了命令、覆盖范围和已知退出诊断：

- 在 30、60、144、240 固定处理帧率下各通过 32 项断言。
- 手动推进 AnimationPlayer 到 0.595 秒，确认新实现仍保持 `WAKING`；跨过动画末尾后才进入 `CHASING`。
- 验证进入追逐后宝箱真实位置向玩家移动，而不只检查动画名称。
- 验证三次完整唤醒、休眠和再次唤醒循环，追逐与吸力均恢复。
- 以 125 像素代表点分别验证追逐和休息状态在 100～150 像素迟滞区内保持；同时验证唤醒期间远离后取消激活。当前自动测试没有逐一覆盖 100、刚大于 100、150、刚大于 150 四个精确边界点。
- 验证静止玩家受吸力、玩家可反向输入、相反吸力源抵消、超出范围无吸力、停止后无残留速度。
- 验证地形碰撞、暂停、吸力源释放和玩家释放。
- 导入与回归运行未出现脚本解析或运行错误。
- 原战斗场景额外运行 1200 帧，难度推进、经验拾取、受伤和死亡链路执行，无脚本运行错误。该冒烟用于确认共享 VelocityComponent 没有破坏早期战斗链路，但没有运行到宝箱怪自然加入生成池；宝箱行为由独立回归场景覆盖。

回归场景全部完成时输出：

```text
MIMIC_REGRESSION failures=0
```

退出时仍有项目既存的 ObjectDB / resource 未释放诊断，本次未将其归因于宝箱怪修复，也未在本次范围内处理。Headless 自动回归不替代图形表现、完整实战难度和触屏手感的人工验收。

## 风险、边界与未解决事项

本次修复保证状态与移动链路一致，但没有改变以下设计边界：

- 宝箱怪仍使用直线追踪，没有寻路；被墙体或敌群阻挡时可能看似不前进，应与本 Bug 的“逻辑未进入追逐”区分。
- 吸力只按距离判断，没有地形视线检测；墙后仍可能计算拉力，但碰撞会阻止玩家穿墙。
- 多个吸力源直接做向量求和，当前没有总吸力上限；大量宝箱同时作用时可能超过玩家移动能力，需要通过实战调参。
- 玩家在吸力作用下的最终 `CharacterBody2D.velocity` 可能改变角色朝向表现，需要图形环境人工检查是否符合预期。
- 玩家节点释放后宝箱会回到 `IDLE`，但当前脚本不会自动寻找之后新生成的玩家；通常一局只有一个玩家实例，因此未在本次扩展重生流程。
- 项目继续在 `_process()` 中移动角色。本次保持现有架构，没有把整个项目迁移至 `_physics_process()`。

## 提交摘要

建议提交标题：

```text
fix: 修复宝箱怪唤醒后不追逐及重复唤醒吸力失效
```

建议提交正文：

```text
- 将宝箱怪的动画布尔控制改为 IDLE/WAKING/CHASING/SLEEPING 状态机
- 使用 animation_finished 推进状态，移除动画轨道中的逻辑切换方法键
- 统一追逐状态的移动、吸力开关和动画生命周期
- 将吸力改为玩家侧外部速度合成，避免重复 move_and_slide 和速度覆盖
- 新增宝箱怪独立回归场景及 Bug 修复说明
```

提交前建议至少确认工作区状态、已跟踪差异和所有新文件：

```sh
git status --short --untracked-files=all
git ls-files --others --exclude-standard
git diff --check
git diff -- sences/game_object/mimic_chest_enemy/
git diff -- sences/ability/suction_ability/suction_ability.gd \
  sences/component/velocity_component.gd \
  sences/game_object/player/player.gd
git diff --no-index /dev/null docs/bugs/MIMIC_CHASE_FIX.md
git diff --no-index /dev/null docs/monsters/MIMIC_CHEST.md
git diff --no-index /dev/null test/mimic_regression.gd
git diff --no-index /dev/null test/mimic_regression.tscn
```

`git diff` 和 `git diff --check` 不会检查尚未跟踪的新文件。选择好本次提交内容并暂存后，再检查实际将要提交的快照：

```sh
git diff --cached --check
git diff --cached --stat
git diff --cached
```

如果需要拆分提交，建议将代码、场景、回归测试和本修复单放在同一个 Bug 修复提交中；通用学习文档可以另行提交。README 当前同时包含两类导航，建议使用按变更块暂存，只把宝箱怪修复单链接归入本次提交。
