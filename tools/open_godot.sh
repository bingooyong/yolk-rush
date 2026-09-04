#!/bin/bash
# Yolk Rush - Godot 编辑器快速启动
# 用法: ./tools/open_godot.sh [scene]

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"

SCENE="${1:-scenes/game/snow_island.tscn}"

echo "🥚 Yolk Rush - 启动 Godot 编辑器"
echo "================================================"
echo "项目: $PROJECT_ROOT"
echo "场景: $SCENE"
echo ""

if [ ! -f "$GODOT" ]; then
    echo "❌ 错误: Godot 未找到"
    exit 1
fi

# 如果提供了场景参数，直接运行该场景
if [ "$1" != "" ]; then
    echo "🎮 直接运行场景: $SCENE"
    "$GODOT" --path "$PROJECT_ROOT" "$SCENE"
else
    echo "🎨 打开 Godot 编辑器..."
    "$GODOT" --editor --path "$PROJECT_ROOT"
fi
