# 实验室中的回血屏闪预览

- 入口：根目录 `Combat Lab.command`，进入图形配置页后点击“回血效果预览”。预览结束按 `Esc` 或“返回实验室”回到配置页；不再生成单独 command。
- 实验室副本只在预览期间暂停音乐，不创建正式战斗场景；使用同一个隔离用户目录和启动日志。正式主场景不引用预览。不要以原项目 F6 运行替代隔离入口。
- 场景：[heal_vignette_preview.tscn](../../test/heal_vignette_preview.tscn)；脚本：[heal_vignette_preview.gd](../../test/heal_vignette_preview.gd)。初始 4/10，H、Enter、空格或按钮触发 `HealthComponent.heal(1)`；满血时先重置到 4。Tab 隐藏／显示面板，按住键不连续触发。
- 事件：生命组件先加血 → health_heal → 预览转发 GameEvents.player_heal → 正式 Vignette 的 heal 动画。这里只模拟 Player 转发，不实例化完整玩家／Buff；不覆盖治疗粒子、音效或 15 秒周期。
- [Vignette](../../sences/ui/vignette.tscn)：0.55 秒，0.09 秒达到峰值，强度 0.92、透明度参数 0.17，末帧恢复基础色；取消自动播放，脚本初始化 RESET。Shader 参数乘积影响衰减，透明度参数不等于实际屏幕 alpha。
- 验证（2026-09-24）：Godot 4.3 隔离导入和实验室启动无脚本错误；Forward+ / Apple M4 实际渲染检查基准、治疗峰值、结束帧；实验室回归覆盖预览进入、实际回血、音乐暂停、Esc 返回、状态清理、表单保留和重复进入。按钮物理鼠标点击、受伤打断、完整战斗与其他平台未验证。
