# 巨剑：按方向轮换的蓄力攻击

核查日期：2026-09-20。

## 简要说明与入口

[huge_sword.tres](../../resource/upgrades/huge_sword.tres) 的 ID 是 `巨剑`，解锁上限 1。它是独立武器，不要求先把剑升满，也不是自动进化得到。

[控制器](../../sences/ability/huge_sword_ability_controller/huge_sword_ability_controller.gd) / [场景](../../sences/ability/huge_sword_ability_controller/huge_sword_ability_controller.tscn) 每 8 秒生成一把，基础伤害 25；朝向从 0° 开始，每次生成增加 45°。

## 升级选项与变种

当前仅有 `巨剑` 解锁卡；没有伤害、攻速或数量强化资源，UpgradeManager 也没有巨剑后续池分支。实验场开局安装后会显示“此武器已无升级选项”，这不是测试失效。没有已实现变种。

## 核心 GDScript

控制器生成逻辑节选：

```gdscript
var huge_sword_instance = huge_sword_ability_scene.instantiate() as Node2D
foreground.add_child(huge_sword_instance)
huge_sword_instance.base_rotation = now_rotation_angle
huge_sword_instance.global_position = player.global_position
huge_sword_instance.hitbox_component.damage = base_damage
now_rotation_angle += per_rotation_angle
```

[实体](../../sences/ability/huge_sword_ability/huge_sword_ability.gd) 跟随位置的核心语句节选：

```gdscript
current_direction = Vector2.RIGHT.rotated(deg_to_rad(base_rotation))
global_position = player.global_position + (Vector2.UP * player_offset_y) + (current_direction * RADIUS)
rotation_degrees = base_rotation + 90
```

`RADIUS = 10`，`player_offset_y = 8`。位置每帧跟随玩家，方向在单次生命周期中固定；每次发射方向才推进 45°。源码中还有每帧 `print(current_direction)`，目前会刷日志，本文不把它当作功能所必需。

## 场景动画

[huge_sword_ability.tscn](../../sences/ability/huge_sword_ability/huge_sword_ability.tscn) 的动画为 2 秒：0–1 秒关闭碰撞，1 秒启用；同时放大 Sprite、移动和缩放碰撞形状；2 秒方法轨道调用 `queue_free()`。虽然资源标记了循环，节点会在末尾方法轨道被释放，不能仅看到 `loop_mode` 就判断会永久攻击。

## 定向验证与更新

```sh
python3 tools/run_combat_lab.py --enemy 宝箱怪 --weapon 巨剑
```

至少等待 8 秒观察第一把巨剑，之后检查朝向轮换、跟随玩家与碰撞时机。实验场回归覆盖单武器安装、无强化时不出现空窗口；没有验证巨剑的每个朝向命中效果。2026-09-20 建立本文与定向入口，未增加升级或变种；见 [VARIANTS.md](VARIANTS.md)。
