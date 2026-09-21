# AI 协作指南

## 项目与阅读顺序

这是 Godot 4.3 / GDScript 的俯视角 2D 生存动作游戏，项目名 `blood`。采用场景组合、可复用组件、Resource 配置和信号通信。

- 开始任务先看 `git status --short`，保留用户已有修改。
- 首次进入项目先读 `docs/architecture/ARCHITECTURE.md`；执行和验证前读 `docs/development/DEVELOPMENT.md`。
- 修改一个模块时，同时读相关 `.gd`、`.tscn`、`.tres`；文档是导航，当前源码与场景绑定是事实来源。
- 默认用中文解释结果，区分源码推断、实际验证和未验证内容。

## 关键入口

- 项目配置：`project.godot`；启动场景：`sences/ui/main_menu.tscn`。
- 战斗场景：`sences/main/main.tscn`；玩家：`sences/game_object/player/`。
- 局内管理：`sences/manager/`；通用组件：`sences/component/`。
- 武器实体与控制器：`sences/ability/`；升级资源：`resource/upgrades/`；学习手册：`docs/weapons/README.md`。
- 定向测试：`docs/development/COMBAT_LAB.md`；隔离启动器 `tools/run_combat_lab.py`；独立实验场 `test/combat_lab/combat_lab.tscn`。
- 宝箱怪的玩法、状态机和吸力约定：`docs/monsters/MIMIC_CHEST.md`。
- 事件总线：`sences/autoload/game_events.gd`；局外成长与存档：`sences/autoload/meta_progression.gd`。

## 修改约定

- 保持 Godot 4.3 兼容；不要顺手迁移引擎、渲染器或批量重存场景。
- 遵循现有组合方式，优先复用 HealthComponent、VelocityComponent、HurtboxComponent 等，不为小功能另起架构。
- 延续文件已有格式，GDScript 使用 Tab 缩进；新增代码优先清晰类型和 `snake_case`，避免整库格式化。
- **保留现有拼写**：`sences`、`asserts`、`entites_layer`、`ChangelogPorgress`、`expericen_manager` 等可能是路径、Group、Autoload 或序列化字段。改名必须是明确任务，并同时更新引用。
- 升级 `id` 是逻辑键，部分还用于存档；中文 ID（如 `剑:伤害升级`、`经验获取`）与 `buff_heal` 不只是显示文案。修改显示文字优先改 `name`、`title`、`description`。
- 节点名、`$Node`、`%UniqueNode`、`NodePath`、导出属性、Groups、碰撞层、信号连接必须一起核对。注意主场景对实例属性的覆盖。
- 修改动画相关函数前检查 `.tscn` 的 AnimationPlayer 方法轨道；武器释放、敌人状态切换、转场信号可能由轨道调用，不能仅凭脚本引用判断函数未使用。
- 手工编辑 `.tscn` / `.tres` 应保持最小差异，保留 UID、资源 ID 和地图数据；不要编造 UID。资源依赖变化后核对 `load_steps` 与引用。
- 保持战斗暂停、升级暂停和结算的 `process_mode` 行为。现有移动主要在 `_process()`；切换物理更新时机属于单独行为改动。
- `.godot/` 是生成缓存，不编辑或提交。仓库已跟踪的 `.import` 文件不要一概删除；不要顺手清理 `.tmp`、美术源文件和实验场景。
- `ChangeLog.md` 被游戏解析，使用 `---` 分块和 `标题:…` 等键值行；不要当普通 Markdown 随意增加标题或列表。新技术说明写入 `docs/`。

## 运行与验证

- 基准引擎为 Godot `4.3.stable.official.77dcf97d8`。本次机器可执行文件：`/Applications/Godot.app/Contents/MacOS/Godot`；其他机器先检测路径和版本。
- **启动游戏会写存档**：MetaProgression 在 `_ready()` 中自动增加两项升级并保存。自动运行使用项目副本，并只在副本中将 `config/custom_user_dir_name` 改为唯一测试目录；仅复制项目仍会共用原存档。
- `user://game.save` 的数据结构和已有升级 ID 必须保持兼容；不要删除真实存档来解决测试问题。
- 依照 `docs/development/DEVELOPMENT.md` 做导入检查、受影响场景的运行检查及必要的人工回归。检查完整错误输出，退出码为 0 不代表无错误。
- 当前没有 GUT/GdUnit；`test/Test.tscn` 是挂在主场景里的实验节点。独立回归包括 `test/mimic_regression.tscn`、`test/fire_buff_regression.tscn` 和 `test/combat_lab/regression.tscn`，需按开发文档在隔离副本中运行；实验节点不能当测试通过证据。
- 纯文档修改核对路径、源码事实和差异即可。行为修改选择针对性验证，不为低影响修改搭建无关测试体系。
- 报告具体改动、验证范围、遗留错误和未测项；不要将 headless 启动成功描述为画面、手感或完整通关验证。

## 知识维护

结构、事件链路、存档结构或运行方法变化时，同步更新相关文档。已知问题见 `docs/development/DEVELOPMENT.md`，修复后更新状态；不要将现有缺陷当作新功能必须遵循的设计。

### 武器说明与学习文档（必须同步）

- 新增、修改武器、强化数值／上限、攻击方式、动画碰撞窗口或变种时，在同一次任务中同步更新 `docs/weapons/` 的对应武器页及索引；变种／行为更新追加到 `docs/weapons/VARIANTS.md`。不能只改代码或仅留聊天说明。
- 每个武器页至少包括：简要玩法、默认参数及 `.gd/.tscn/.tres` 来源、解锁条件、真实升级 ID、上限与计算公式、核心 GDScript 代码节选及解释、关键节点／动画轨道、变种状态、验证范围和已知限制。项目以学习为主，说明“为何这样写”以及配置如何传到最终伤害。
- 代码块必须对应当前源码并链接来源；教学伪代码和省略内容应明确标注。区分已实现变种、数值强化和未来设想，不将资源图片或函数名当作行为证据。
- 新武器同时检查实验场枚举、路径映射和升级 ID 前缀过滤；保留测试配置默认关闭、正式主场景不引用实验场的边界。定向测试方式变化时同步更新 `docs/development/COMBAT_LAB.md`。
- 文档总导航维护 `docs/README.md`。以 `docs/architecture/`、`docs/development/` 为现行入口；根层旧文档保留历史记录时必须标注，避免两份现状相互矛盾。
