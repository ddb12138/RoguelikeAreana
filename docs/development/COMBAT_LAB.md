# 战斗实验场：只测试指定怪物和武器

更新日期：2026-09-20。独立入口为 [combat_lab.tscn](../../test/combat_lab/combat_lab.tscn)，没有挂进正式主场景，正常 F6 主场景或 F5 主菜单均不启用测试覆盖。

## 最快的使用方式

在项目根目录终端执行，脚本会复制当前工作区、隔离存档、导入后打开游戏窗口：

```sh
# 只生成宝箱怪，不装备武器，观察唤醒、追逐、吸力和休眠。
python3 tools/run_combat_lab.py --enemy 宝箱怪 --weapon 无

# 只使用斧头，所有升级卡都属于斧头。
python3 tools/run_combat_lab.py --enemy 普通敌人 --weapon 斧头

# 火焰剑／普通剑对照。
python3 tools/run_combat_lab.py --enemy 蝙蝠 --weapon 剑
python3 tools/run_combat_lab.py --enemy 蝙蝠 --weapon 剑 --no-fire

# 多目标闪电：最多 8 个敌人，每 0.5 秒补一个。
python3 tools/run_combat_lab.py --enemy 蝙蝠 --weapon 闪电 --max-enemies 8 --spawn-interval 0.5

# 要测试真实接触伤害和死亡，显式关闭免伤。
python3 tools/run_combat_lab.py --enemy 宝箱怪 --weapon 无 --vulnerable
```

窗口中使用 WASD 移动、P 暂停；**按 U 或点击“升一级”**立即进入真实升级选卡，无需杀怪攒经验。选完后恢复战斗，直到该武器所有强化满级；不会切换到其他武器卡牌。

| 可选项 | 值／默认 | 意义 |
| --- | --- | --- |
| `--enemy` | 普通敌人／巫师／蝙蝠／宝箱怪，默认宝箱怪 | 全程只生成这一类，第一次立即生成 |
| `--weapon` | 无／剑／斧头／铁毡／巨剑／闪电，默认剑 | 开局只装备此武器；非剑会移除默认剑 |
| `--max-enemies` | 1–100，默认 1 | 同屏怪物上限；死亡／移除后按间隔补充 |
| `--spawn-interval` | 0.1–30 秒，默认 2 | 每次最多补一只，不随局内难度改变 |
| `--no-fire` | 默认不传 | 剑关闭火焰，其他武器本来就无火焰 |
| `--vulnerable` | 默认不传 | 默认免玩家接触伤害；传入后恢复受伤，不影响吸力和移动 |
| `--godot` | 默认本机 Godot.app 路径 | 其他机器指定 Godot 4.3 可执行文件 |
| `--headless --frames 600` | 默认无 | 自动冒烟用，固定 60 FPS、最多 600 帧；不是视觉验收 |

实验场停止局长 Timer 和难度推进，因此不会在 300 秒自动胜利；没有把怪物 AI 冻结。宝箱怪仍在距玩家 200 的通常生成半径外，需要走近其唤醒范围；巫师仍遵循原半血行为。

## 满级和无强化项怎么处理

- 剑：伤害、攻速各 5 次，总计 10 次选择。
- 斧头：伤害 5 次。
- 铁毡：伤害、数量各 5 次，总计 10 次。
- 闪电：距离 2、伤害 5、人数 5、数量 2、频率 5，总计 19 次。
- 巨剑：当前只有解锁项，实验场已开局装备，后续无强化选项。
- 无武器：只观察怪物，无升级选项。

没有候选时按钮禁用，后续经验升级也不创建空窗口。测试尊重现有上限，不无限堆叠升级。各公式和实现见 [武器学习手册](../weapons/README.md)。

## 在 Godot Inspector 中调整

推荐先用启动脚本生成隔离副本，从终端输出找到副本的 `project/`，在 Godot 打开**副本**，再打开 `test/combat_lab/combat_lab.tscn`，选中根节点 CombatLab：

- `Enemy Kind` / `Weapon Kind`：怪物与武器。
- `Max Enemies` / `Spawn Interval`：数量上限和补怪间隔。
- `Invulnerable`：免接触伤害。
- `Sword Fire`：剑是否附魔。

F6 运行当前实验场。若直接在原项目 F6，Autoload 仍会写真实存档；实验场本身不能阻止 Autoload 在它加载前读写，所以自动验证必须使用隔离启动器。命令行参数会覆盖 Inspector 对应选项；单独 F6 没有命令行覆盖。

调整敌人的伤害、唤醒距离或武器参数，仍修改原有资源／场景；实验场负责缩小测试范围，不复制一份战斗逻辑。改原工作区后重新运行启动器，才会把最新修改带进新副本。

## 核心实现与学习点

[combat_lab.gd](../../test/combat_lab/combat_lab.gd) 在主场景入树**之前**注入测试参数：

```gdscript
arena = MAIN_SCENE.instantiate()
var enemy_manager = arena.get_node("EnemyManager")
enemy_manager.test_enemy_scene = load(ENEMY_PATHS[enemy_kind])
enemy_manager.test_max_enemies = max_enemies
enemy_manager.test_spawn_interval = spawn_interval
upgrade_manager = arena.get_node("UpgradeManager")
upgrade_manager.test_weapon_id = weapon_kind
```

因为子节点 `_ready()` 要根据参数初始化，不能等 `add_child(arena)` 之后才改生成池。玩家准备好后再调用正式 `apply_upgrade()` 安装武器，这时它已订阅全局升级信号。

[EnemyManager](../../sences/manager/enemy_manager.gd) 的可选 `test_enemy_scene` 默认为 null；设置时只把指定怪放入池，并在难度事件中提前返回。不只是将开局权重设为 0，因此第 15／30／40 秒不会又加入别的怪。

[UpgradeManager](../../sences/manager/upgrade_manager.gd) 每次抽卡时按稳定 ID 筛选，默认空字符串允许全部：

```gdscript
if test_weapon_id.is_empty() or upgrade.id == test_weapon_id or upgrade.id.begins_with(test_weapon_id + ":"):
	candidates.add_item(upgrade, entry["weight"])
```

因此“斧头”能匹配解锁与“斧头:伤害升级”，但不匹配玩家移速。解锁后的新强化同样被筛选；最多两张且不重复。

[一键升级](../../test/combat_lab/combat_lab.gd) 直接给 ExperienceManager 补到本级目标值，经过真实 `level_up` 信号和卡牌 UI；没有发经验拾取事件，因此这次调试升级不额外发局外货币。正常拾取仍按游戏规则执行，并写入**隔离存档**。

[启动脚本](../../tools/run_combat_lab.py) 不改原 `project.godot`：每次创建新的临时副本，并替换副本的 `config/custom_user_dir_name`。原始 `2DBlood` 不受影响。保留副本、冷／热导入日志和 run.log 供复查；清理时仅删除该次副本和 `Codex-blood-combat-lab-*` 对应专用用户目录。

## 验证

专项回归场景：[regression.tscn](../../test/combat_lab/regression.tscn)。准备隔离副本并导入后运行：

```sh
"$GODOT_BIN" --headless --path "$CHECK_PROJECT" --fixed-fps 60 --quit-after 1200 res://test/combat_lab/regression.tscn
```

覆盖所有武器单独安装、每条升级分支与上限、实际满级属性、卡牌暂停和恢复、无候选清理、指定怪物生成与补充、数量上限、难度隔离、免伤切换以及正常模式默认值。验证结果和实际截图见 [验证记录](../verification/combat-lab-20260920/README.md)。

实验场是交互调试入口，不等于自动测试通过；自动退出码 0 也不代表没有错误。闪电原有异步引用／暂停风险、完整通关、平台导出和高怪物数量性能需分别验证，详见 [闪电页](../weapons/THUNDER.md)。
