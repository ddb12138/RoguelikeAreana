# 文档导航

人工阅读从 [战斗实验室操作与实现手册（Word）](manuals/战斗实验室操作与实现手册.docx) 开始：图形配置、操作示意、GDScript 核心实现及历史截图集中在一个文件中。

Markdown 作为 AI 开发说明：先读根目录 [AGENTS.md](../AGENTS.md)，再按任务查阅下表。源码和场景绑定是事实来源，文档保留功能、配置、实现入口及验证边界，不嵌入截图。

| 目录／入口 | 用途 |
| --- | --- |
| [architecture/ARCHITECTURE.md](architecture/ARCHITECTURE.md) | 项目结构、职责和数据流；首次进入必读 |
| [development/DEVELOPMENT.md](development/DEVELOPMENT.md) | 环境、隔离运行、验证和已知问题；执行前必读 |
| [development/COMBAT_LAB.md](development/COMBAT_LAB.md) | 实验室模式、配置、源码约定和定向验证 |
| [development/HEAL_PREVIEW.md](development/HEAL_PREVIEW.md) | 实验室内回血屏闪预览入口、事件链与验证 |
| [weapons/README.md](weapons/README.md) | 五种武器、强化 ID／公式、核心代码；[公共实现](weapons/IMPLEMENTATION.md)、[变种记录](weapons/VARIANTS.md) |
| [monsters/MIMIC_CHEST.md](monsters/MIMIC_CHEST.md) | 宝箱怪玩法与状态机；[追逐修复记录](bugs/MIMIC_CHASE_FIX.md) |
| [FIRE_BUFF.md](FIRE_BUFF.md) | 火焰附魔、灼烧规则和验证证据 |
| [资源网站推荐/README.md](资源网站推荐/README.md) | 美术来源、下载选择和许可说明 |
| [learning/LEARNING_GUIDE.md](learning/LEARNING_GUIDE.md) | 保留的课程与源码参考；[课程地图](learning/COURSE_MAP.md)、[编辑器说明](learning/GODOT_EDITOR_GUIDE.md) |
| [verification/combat-lab-20260920/README.md](verification/combat-lab-20260920/README.md) | 历史实验室验证记录；其他专题日志保留在 `verification/` 对应日期目录 |

维护约定：人用教程和插图放 `manuals/*.docx`，AI 说明按模块放 Markdown；入口或行为变化时同步两者。文档图片直接嵌入 Word，确认已嵌入且无引用后再删除独立 PNG；游戏资源图片不受此规则影响。移动文档同步更新导航与相对链接，历史证据不改写为当前验收结论。
