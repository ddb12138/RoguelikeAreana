#!/usr/bin/env python3
"""Create an isolated project copy, import it, and launch the combat lab."""

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ENEMY = '宝箱怪'
DEFAULT_WEAPON = '剑'
DEFAULT_MAX_ENEMIES = 1
DEFAULT_SPAWN_INTERVAL = 2.0


def main():
    parser = argparse.ArgumentParser(
        description=(
            '不提供实验参数时打开图形配置页；提供任一实验参数时直接启动，'
            '用于自动化或高级调试。两种方式都会先创建隔离副本和独立存档。'
        )
    )
    parser.add_argument('--enemy', choices=['普通敌人', '巫师', '蝙蝠', '宝箱怪'])
    parser.add_argument('--weapon', choices=['无', '剑', '斧头', '铁毡', '巨剑', '闪电'])
    parser.add_argument('--max-enemies', type=int, help='同屏怪物上限 1–100')
    parser.add_argument('--spawn-interval', type=float, help='补怪间隔 0.1–30 秒')
    parser.add_argument('--vulnerable', action='store_true', help='恢复玩家接触伤害')
    parser.add_argument('--no-gui', action='store_true', help='跳过配置页并使用未指定项的默认值')
    parser.add_argument('--godot', default='/Applications/Godot.app/Contents/MacOS/Godot')
    parser.add_argument('--headless', action='store_true')
    parser.add_argument('--frames', type=int, help='固定 60 FPS 的运行帧数上限')
    args = parser.parse_args()

    if args.frames is not None and args.frames <= 0:
        parser.error('--frames must be positive')
    if args.max_enemies is not None and not 1 <= args.max_enemies <= 100:
        parser.error('怪物上限必须为 1–100')
    if args.spawn_interval is not None and not 0.1 <= args.spawn_interval <= 30.0:
        parser.error('生成间隔必须为 0.1–30 秒')

    explicit_lab_option = any((
        args.enemy is not None,
        args.weapon is not None,
        args.max_enemies is not None,
        args.spawn_interval is not None,
        args.vulnerable,
    ))
    direct_mode = explicit_lab_option or args.no_gui or args.headless or args.frames is not None

    godot = Path(args.godot).expanduser()
    if not godot.is_file():
        parser.error('找不到 Godot 可执行文件：' + str(godot))
    version = subprocess.check_output([str(godot), '--version'], text=True).strip()
    if not version.startswith('4.3.'):
        parser.error('本项目要求 Godot 4.3，实际为 ' + version)

    workspace = Path(tempfile.mkdtemp(prefix='blood-combat-lab-'))
    project = workspace / 'project'
    shutil.copytree(
        ROOT,
        project,
        ignore=shutil.ignore_patterns(
            '.git', '.godot', '__pycache__', '*.zip', '*.exe', '*.apk', '*.pck'
        ),
    )
    settings = project / 'project.godot'
    isolated_user_dir = 'Codex-' + workspace.name
    text, count = re.subn(
        r'^config/custom_user_dir_name=.*$',
        'config/custom_user_dir_name="' + isolated_user_dir + '"',
        settings.read_text(encoding='utf-8'),
        count=1,
        flags=re.M,
    )
    if count != 1 or 'config/use_custom_user_dir=true' not in text:
        raise RuntimeError('无法确认隔离用户目录，未启动 Godot')
    settings.write_text(text, encoding='utf-8')
    print(
        '引擎:', version,
        '\n启动模式:', '直接启动' if direct_mode else '图形配置页',
        '\n副本及日志:', workspace,
        '\n独立用户目录:', isolated_user_dir,
        flush=True,
    )

    # 现有项目的冷导入可能产生缓存错误，因此保留冷、热两轮日志。
    for name in ['import-cold', 'import-warm']:
        result = subprocess.run(
            [str(godot), '--headless', '--path', str(project), '--editor', '--import', '--quit'],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        (workspace / (name + '.log')).write_text(result.stdout, encoding='utf-8')
        has_script_error = re.search(r'\b(?:ERROR|Parse Error|SCRIPT ERROR):', result.stdout)
        if result.returncode or (name == 'import-warm' and has_script_error):
            print(result.stdout)
            raise SystemExit(result.returncode or 1)

    cmd = [str(godot), '--path', str(project)]
    if args.headless:
        cmd.append('--headless')
    if args.frames is not None:
        cmd += ['--fixed-fps', '60', '--quit-after', str(args.frames)]
    cmd.append('res://test/combat_lab/combat_lab.tscn')

    if direct_mode:
        enemy = args.enemy if args.enemy is not None else DEFAULT_ENEMY
        weapon = args.weapon if args.weapon is not None else DEFAULT_WEAPON
        max_enemies = args.max_enemies if args.max_enemies is not None else DEFAULT_MAX_ENEMIES
        spawn_interval = (
            args.spawn_interval
            if args.spawn_interval is not None
            else DEFAULT_SPAWN_INTERVAL
        )
        cmd += [
            '--',
            '--lab-direct',
            '--lab-enemy=' + enemy,
            '--lab-weapon=' + weapon,
            '--lab-max-enemies=' + str(max_enemies),
            '--lab-spawn-interval=' + str(spawn_interval),
        ]
        if args.vulnerable:
            cmd.append('--lab-vulnerable')

    with (workspace / 'run.log').open('w', encoding='utf-8') as log:
        result = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT)
    print((workspace / 'run.log').read_text(encoding='utf-8'))
    print('保留副本和专用存档供复查；不会删除或改写 2DBlood。')
    raise SystemExit(result.returncode)


if __name__ == '__main__':
    main()
