# 开发与验证基线

记录日期：2026-09-17。基准提交：`96cb1c0`。本次建立知识文档，没有修改玩法代码、场景、资源或真实存档。

## AI 指南的使用

根目录 `AGENTS.md` 是项目级协作约定，`docs/architecture/ARCHITECTURE.md` 是知识导航，本文件记录验证方式和现有问题。

Codex 会在启动时发现项目指令；标准文件名是 **AGENTS.md**，不是 AGENT.md。保存到仓库后，后续从此项目启动的新会话即可读取，不需要安装 Godot 插件或复制整段提示词。已经打开的会话可以显式要求读取该文件；需要重新发现指令时启动新会话。

依据：[OpenAI 官方 AGENTS.md 文档](https://developers.openai.com/codex/guides/agents-md/)。其他 AI 工具是否自动读取该名称，需要遵循各自的配置。当前项目规模适合一份精简根指令配合按需阅读的文档，无需先引入索引服务。

## 本机环境

```sh
GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
"$GODOT_BIN" --version
```

本次输出 `4.3.stable.official.77dcf97d8`。系统 PATH 没有 `godot` / `godot4`，所以使用 app 内的可执行文件。其他机器自行定位 Godot 4.3，不把本机绝对路径写进游戏代码。

## 隔离运行

MetaProgression 会在每次启动游戏时写 `user://game.save`，仅切换启动场景也会加载 Autoload。不要直接在真实存档上做反复自动冒烟检查。

1. 将工作区复制到系统临时目录，包含需要验证的未提交变更，排除 `.git/`、`.godot/` 和已有导出产物。
2. **只在副本**的 `project.godot` 将 `config/custom_user_dir_name="2DBlood"` 替换为唯一值，例如 `CodexBaseline-日期-随机标识`，保留 `config/use_custom_user_dir=true`。不要改原项目配置。
3. 在副本先导入，再启动入口/目标场景，将 stdout 和 stderr 保存为日志。
4. 实验结束仅清理本次创建的副本与专用用户目录；不删除 `2DBlood`。

以下是准备好隔离副本后的命令模板，`CHECK_PROJECT` 需要替换为实际副本路径：

```sh
GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
CHECK_PROJECT="/绝对路径/隔离副本"

# 首次生成资源缓存并检查导入。
"$GODOT_BIN" --headless --path "$CHECK_PROJECT" --editor --import --quit

# 主菜单：180 个处理帧，固定 delta 1/60 秒。
"$GODOT_BIN" --headless --path "$CHECK_PROJECT" --fixed-fps 60 --quit-after 180

# 战斗场景：1200 个处理帧；死亡或升级可能令场景树暂停。
"$GODOT_BIN" --headless --path "$CHECK_PROJECT" --fixed-fps 60 --quit-after 1200 res://sences/main/main.tscn
```

`--quit-after` 是帧数，不是秒数；headless 固定步进也不表示相同的墙钟运行时间。每次运行均检查 `SCRIPT ERROR`、`Parse Error`、`ERROR` 和 `WARNING`，不能只判断退出码。

## 本次实际结果

本次使用 Git 跟踪文件建立独立副本，原项目工作区当时干净；副本只改测试用户目录。隔离项目标识为 `roguelike-baseline-s0v17nv_`，用户目录为 `CodexBaseline-roguelike-baseline-s0v17nv_`。

| 检查 | 结果 | 能说明什么 |
| --- | --- | --- |
| 静态资源路径 | 330 处带引号的 `res://` 引用目标均存在 | 文件存在；不验证所有动态路径、UID 或节点绑定 |
| 全新副本第一次导入 | 退出 0，但报告主题字体/UI 及音乐/转场导入缓存缺失 | 保留为冷导入现象，不能宣称零错误 |
| 主菜单 180 帧 | 退出 0；发生自动升级和保存；退出时有对象/资源未释放信息 | 入口可加载，不包含按钮交互验证 |
| 战斗场景 1200 帧 | 退出 0；观察到难度 1/2、伤害、经验拾取、玩家死亡与保存 | 主要早期战斗逻辑实际运行；不是完整通关 |
| 缓存生成后再次导入 | 退出 0，仅输出引擎版本，无错误或警告 | 首次报告的缓存缺失在本次重新导入中未再出现 |

主菜单与战斗运行日志未出现 `SCRIPT ERROR`。两次退出都报告 `ObjectDB instances leaked at exit`，分别有 1 / 27 个 resource 仍被使用，原因尚未定位。有限帧退出与正常 UI 退出不同，不能据此直接断言完整游戏会持续泄漏，也不能忽略这些输出。

实际确认存档启动副作用：主菜单首次启动将 `经验获取`、`buff_heal` 设为 1；随后战斗启动把两者增加为 2，其中治疗资源配置上限为 1。

本轮未做画面/声音验证、完整 300 秒生存、所有武器升级、商店交互、真实触屏或任何平台导出。

## 已知问题与待验证项

以下是建立基线时发现的现状，本轮未修复。除明确标为运行观察的项，其余来自源码静态分析，修复时应先建立针对性复现。

| 项目 | 证据位置与当前行为 | 建议验证 |
| --- | --- | --- |
| 启动自动增加永久升级（已运行观察） | `sences/autoload/meta_progression.gd::_ready()` 每次调用两次 `add_meta_upgrade()`；该函数没有上限约束 | 隔离存档连续启动，区分初始化与实际购买 |
| 查询升级数量分支反向 | 同文件 `get_upgrade_count()` 在 key 不存在时读取该 key，存在时返回 0 | 已购买/未购买各验证一次，避免经验升级失效或缺键错误 |
| 掉落加成未用于随机判断 | `sences/component/vial_drop_component.gd::on_died()` 计算 `adjusted_drop_percent`，实际比较 `drop_percent` | 与数量查询一同修复，验证加成前后概率输入 |
| 暂停菜单退出属性疑似错误 | `sences/ui/pause_menu.gd::on_quit_pressed()` 使用 `get_tree().pause`，其他地方使用 `paused`；目标是战斗场景 | 点击按钮复现错误，并确认产品预期是重开还是返回主菜单 |
| 图鉴尚未发现菜单入口 | `sences/ui/monster_menu.*`、`resource/Beastiary/` 已存在，主菜单脚本未连接 | 确认是否属于待完成功能，补入口前先明确交互 |
| 实验节点进入正式战斗 | `main.tscn` 挂有 `test/Test.tscn`；Timer 默认不自动启动；回调直接调用未初始化治疗实例 | 不能当测试套件运行，也不要在无相关任务时删除 |
| Buff 清理与层数（部分修复） | 2026-09-19 已补过期释放和单实例灼烧；Player 初始化仍只使用 Buff key，不使用 quantity | [火焰实现与回归](../FIRE_BUFF.md)；永久 Buff 层数仍待设计 |
| 异步攻击持有敌人引用 | `thunder.gd` 在多次 await 之间保留敌人列表，仅有 null 判断 | 高频攻击、目标死亡、退出战斗时验证对象有效性 |
| 冷导入和退出诊断 | 本节运行记录 | 独立复现，区分导入阶段、强制结束与正常退出 |

此外，Web 预设与项目 Forward Plus 的组合需要单独验证兼容性；`ChangeLog.md` 是运行时数据，当前 Android 配置显式包含 `*.md`，Windows/Web 没有相同包含规则，后续应检查打包后的日志数据可用性。新增开发文档还可能被 Android 的广泛 `*.md` 规则带入包中；发布前可将包含范围收窄到实际运行时文件，并验证日志菜单。本轮不改导出配置。

## 后续修改的最低回归范围

- **战斗**：从主菜单开始、键盘/摇杆移动、自动攻击、受击与治疗、敌人死亡掉落、经验拾取、死亡结算。
- **升级**：达到 5 点初始经验，出现最多两张不同卡；选择后恢复战斗；新武器生成，数值升级生效，到上限后退出池。
- **难度**：必要时在隔离副本中控制条件，确认 15/30/40 秒对应巫师/蝙蝠/宝箱怪解锁；不将测试加速设置提交回项目。
- **暂停/菜单**：P 暂停和恢复、设置返回、结算返回、正常退出；关注暂停状态下 UI 是否仍能工作。
- **永久成长**：使用专用测试存档检查货币、购买、上限、重启读取；存档修复应覆盖旧数据。
- **表现/平台**：修改画面、shader、输入或导出设置时，必须在对应渲染/设备环境检查；headless 不能替代。

仅执行与改动相关的项目；记录已验证与未验证范围。如果开始建设自动测试，优先覆盖 WeightedTable、经验等级和存档/升级逻辑等有明确输入输出的部分。

## 后续更新：宝箱怪回归（2026-09-17）

上述初始基线保留为历史记录。本次修复了宝箱唤醒动画提前切换导致“播放追逐但没有移动”的问题，补齐再次唤醒的吸力恢复，并将吸力整合到玩家一次移动中。详细证据、参数及实现见 [宝箱怪声明](../monsters/MIMIC_CHEST.md)。

新增无第三方依赖的自动断言场景 `test/mimic_regression.tscn`，与原有 `test/Test.tscn` 实验场景独立。先按上文准备隔离副本，再执行：

```sh
"$GODOT_BIN" --headless --path "$CHECK_PROJECT" --fixed-fps 60 res://test/mimic_regression.tscn
```

已在 30 / 60 / 144 / 240 固定帧率下各通过 32 项断言，包括真实追逐位移、重复唤醒、休眠停止、吸力方向、输入叠加、多源合成、碰撞、暂停与节点释放。退出时仍有初始基线中的 ObjectDB / resource 清理诊断；未出现脚本运行错误。图形与触屏手感尚未人工验收。

共享移动组件修改后，原战斗场景另运行 1200 帧：难度推进、经验拾取、受伤和死亡均执行，退出码 0，无脚本错误；退出报告 ObjectDB / 25 resources 未释放，仍待独立排查。

## 定向实验场与武器学习（2026-09-20）

新增 [战斗实验场](COMBAT_LAB.md) 和 `tools/run_combat_lab.py`：自动创建隔离副本／存档，固定怪物，开局仅装备指定武器，只提供该武器强化，按 U 升级。正式场景默认不启用测试覆盖。2026-09-20 版本验证见 [专项记录](../verification/combat-lab-20260920/README.md)。

当前入口（2026-09-23 源码核对）：双击 `Combat Lab.command` 或无参数运行启动器，先显示图形配置页；提供实验参数或 `--no-gui` 可直接开始。操作图、核心 GDScript 讲解及历史截图见 [Word 手册](../manuals/战斗实验室操作与实现手册.docx)，AI 修改约定见上方实验场说明。旧验证记录不覆盖新增配置页，本次文档整理未重新运行游戏。

武器说明、升级上限、公式与核心 GDScript 见 [武器手册](../weapons/README.md)。2026-09-19 的火焰实现与 34 项回归见 [火焰专题](../FIRE_BUFF.md)。
