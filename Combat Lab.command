#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ ! -x "$GODOT_BIN" ] && command -v godot >/dev/null 2>&1; then
  GODOT_BIN="$(command -v godot)"
fi
if [ ! -x "$GODOT_BIN" ] && command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN="$(command -v godot4)"
fi

python3 "$SCRIPT_DIR/tools/run_combat_lab.py" --godot "$GODOT_BIN"
status=$?

if [ "$status" -ne 0 ]; then
  echo
  echo "战斗实验室启动失败（退出码 $status）。"
  echo "请保留上方错误信息，按回车关闭窗口。"
  read -r
fi

exit "$status"
