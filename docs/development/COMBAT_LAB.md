# 战斗实验室 AI 开发说明

更新：2026-09-23。遵循根目录 [AGENTS.md](../../AGENTS.md)；人工操作、示意图、核心 GDScript 讲解见 [Word 手册](../manuals/战斗实验室操作与实现手册.docx)。本文只维护功能约定、源码入口和验证要求。

## 入口与模式

- macOS 双击根目录 [`Combat Lab.command`](../../Combat%20Lab.command)，或在项目根目录运行 `python3 tools/run_combat_lab.py`：创建隔离副本、独立存档，完成导入后打开图形配置页。
- 提供任一实验参数（`--enemy`、`--weapon`、`--max-enemies`、`--spawn-interval`、`--vulnerable`），或 `--no-gui`、`--headless`、`--frames`：跳过配置页直接开始。只有 `--godot` 时仍打开配置页。
- 独立场景 [`combat_lab.tscn`](../../test/combat_lab/combat_lab.tscn) 的 `auto_start` 默认 `false`；Inspector 值初始化表单。设为 `true` 或传 Godot `--lab-*` 参数可直启，参数覆盖相应导出值。
- 正式主菜单、主场景不引用实验室。直接在原项目 F6 会加载 Autoload 并可能写真实存档；配置页的目录前缀提示不能阻止写入。隔离要求见 [开发基线](DEVELOPMENT.md#隔离运行)。

```sh
# 图形配置页
python3 tools/run_combat_lab.py
# 只观察宝箱怪 AI
python3 tools/run_combat_lab.py --enemy 宝箱怪 --weapon 无
# 直接测试闪电分支
python3 tools/run_combat_lab.py --weapon 闪电 --max-enemies 8 --spawn-interval 0.5
```

## 功能约定

| 项目 | 当前行为 |
| --- | --- |
| 配置 | 怪物：普通敌人／巫师／蝙蝠／宝箱怪；武器：无／剑／斧头／铁毡／巨剑／闪电 |
| 默认 | 宝箱怪、普通剑、同屏 1、间隔 2 秒、免接触伤害；上限范围 1–100，间隔 0.1–30 秒 |
| 生成 | 开始时生成一只；随后每个间隔最多补一只，达到同屏上限停止；难度不会扩池；停止局长计时 |
| 武器 | 开局只保留所选武器；非剑先移除默认剑，再走正式解锁；剑的火焰通过正式升级卡牌获得 |
| 升级 | U 或按钮补齐当前等级经验，沿用真实选卡和暂停；仅匹配武器 ID 或 `武器名:` 前缀；每轮最多两项、不重复、遵循资源上限 |
| 边界 | 无武器／巨剑无后续强化；升满、暂停、配置阶段不能再升级；没有运行中返回配置页、无限升级或自动选卡 |
| 免伤 | 只免玩家接触伤害，不关闭 AI、碰撞或宝箱怪吸力 |

升级 ID 以 `.tres` 为准，例如 `闪电:伤害`、`闪电:频率`；不可按卡面名称推测。各武器公式和上限见 [武器索引](../weapons/README.md)。

## 源码与必须保留的顺序

| 职责 | 入口与约束 |
| --- | --- |
| 隔离启动 | [`run_combat_lab.py`](../../tools/run_combat_lab.py)：Python 仅复制项目、改副本用户目录、导入和启动；保留临时副本与日志 |
| 表单与状态 | [`combat_lab.gd`](../../test/combat_lab/combat_lab.gd)：`CONFIGURING → STARTING → RUNNING`，错误进入 `FAILED`；禁止重复创建战斗场景 |
| 场景注入 | `start_experiment()` 在 `add_child(arena)` 前设置怪物、武器过滤和玩家免伤；所有节点 ready 后才 `apply_upgrade()` 安装非剑武器 |
| 怪物过滤 | [`enemy_manager.gd`](../../sences/manager/enemy_manager.gd)：`test_enemy_scene == null` 保留正式生成；测试模式忽略难度扩池并限制数量 |
| 升级过滤 | [`upgrade_manager.gd`](../../sences/manager/upgrade_manager.gd)：`test_weapon_id == ""` 保留正式池；每次抽卡筛选，包括动态加入的升级 |
| 快速升级 | `request_level_up()` 调用 [`ExperienceManager`](../../sences/manager/experience_manager.gd)，不发送拾取事件，不额外增加局外货币 |

新增怪物／武器同步检查种类数组、`export_enum`、路径映射、启动器 `choices`、升级 ID 前缀和 [实验室回归](../../test/combat_lab/regression.gd)。保持正式模式测试字段默认关闭；学习代码节选放在 Word 第 5–6 章，修改时一并更新。

## 验证与维护

- 行为变更按 [开发基线](DEVELOPMENT.md) 在隔离副本运行导入及 `test/combat_lab/regression.tscn`，检查失败数和完整错误输出；不能以帧数退出当作通过。
- 表单变更还需实机检查：默认不创建战斗场景、武器与火焰控件联动、单次启动、直接模式、错误配置、隔离提示及窗口布局。
- [2026-09-20 验证记录](../verification/combat-lab-20260920/README.md) 为历史证据；截图收录 Word 附录 A，火焰历史画面在附录 B。
- 2026-09-23 将火焰剑接入正式升级卡牌；隔离回归已通过 339 项，覆盖开局无火焰、正式池包含 `剑:火焰附魔`、三条火焰强化路线、满级数值、选择卡牌后生效和卡牌上限。退出仍报告既有的 ObjectDB／资源未释放诊断。长时间性能、完整通关、配置页人工点击、移动端／Web 未验证；闪电已有风险见 [THUNDER.md](../weapons/THUNDER.md)。
- 入口、参数或行为变化时，同步本文、Word 手册、[总导航](../README.md)；规则由 [AGENTS.md](../../AGENTS.md) 统一维护。Markdown 不嵌截图，历史日志保留原日期与边界。
