#!/usr/bin/env python3
"""Copy the workspace, isolate user://, import, and launch a focused combat lab."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--enemy', choices=['普通敌人', '巫师', '蝙蝠', '宝箱怪'], default='宝箱怪')
    parser.add_argument('--weapon', choices=['无', '剑', '斧头', '铁毡', '巨剑', '闪电'], default='剑')
    parser.add_argument('--max-enemies', type=int, default=1, help='同屏怪物上限 1–100')
    parser.add_argument('--spawn-interval', type=float, default=2.0, help='补怪间隔 0.1–30 秒')
    parser.add_argument('--no-fire', action='store_true', help='剑关闭火焰附魔')
    parser.add_argument('--vulnerable', action='store_true', help='恢复玩家接触伤害')
    parser.add_argument('--godot', default='/Applications/Godot.app/Contents/MacOS/Godot')
    parser.add_argument('--headless', action='store_true')
    parser.add_argument('--frames', type=int, help='固定 60 FPS 的运行帧数上限')
    args = parser.parse_args()
    if args.frames is not None and args.frames <= 0:
        parser.error('--frames must be positive')
    if not 1 <= args.max_enemies <= 100 or not 0.1 <= args.spawn_interval <= 30.0:
        parser.error('怪物上限必须为 1–100，生成间隔必须为 0.1–30 秒')
    version = subprocess.check_output([args.godot, '--version'], text=True).strip()
    if not version.startswith('4.3.'):
        parser.error('本项目要求 Godot 4.3，实际为 ' + version)
    workspace = Path(tempfile.mkdtemp(prefix='blood-combat-lab-'))
    project = workspace / 'project'
    shutil.copytree(ROOT, project, ignore=shutil.ignore_patterns('.git', '.godot', '__pycache__', '*.zip', '*.exe', '*.apk', '*.pck'))
    settings = project / 'project.godot'
    text, count = re.subn(r'^config/custom_user_dir_name=.*$', 'config/custom_user_dir_name="Codex-' + workspace.name + '"', settings.read_text(), count=1, flags=re.M)
    if count != 1 or 'config/use_custom_user_dir=true' not in text:
        raise RuntimeError('无法确认隔离用户目录，未启动 Godot')
    settings.write_text(text)
    print('引擎:', version, '\n副本及日志:', workspace, '\n独立用户目录:', 'Codex-' + workspace.name, flush=True)
    # Existing cold-import cache errors require a second pass; preserve both logs.
    for name in ['import-cold', 'import-warm']:
        result = subprocess.run([args.godot, '--headless', '--path', str(project), '--editor', '--import', '--quit'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        (workspace / (name + '.log')).write_text(result.stdout)
        if result.returncode or (name == 'import-warm' and re.search(r'\b(?:ERROR|Parse Error|SCRIPT ERROR):', result.stdout)):
            print(result.stdout)
            raise SystemExit(result.returncode or 1)
    cmd = [args.godot, '--path', str(project)]
    if args.headless:
        cmd.append('--headless')
    if args.frames:
        cmd += ['--fixed-fps', '60', '--quit-after', str(args.frames)]
    cmd += ['res://test/combat_lab/combat_lab.tscn', '--', '--lab-enemy=' + args.enemy, '--lab-weapon=' + args.weapon, '--lab-max-enemies=' + str(args.max_enemies), '--lab-spawn-interval=' + str(args.spawn_interval)]
    if args.no_fire:
        cmd.append('--lab-no-fire')
    if args.vulnerable:
        cmd.append('--lab-vulnerable')
    with (workspace / 'run.log').open('w') as log:
        result = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT)
    print((workspace / 'run.log').read_text())
    print('保留副本和专用存档供复查；不会删除或改写 2DBlood。')
    raise SystemExit(result.returncode)

if __name__ == '__main__':
    main()
