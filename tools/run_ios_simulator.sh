#!/bin/bash
# Yolk Rush - iOS 模拟器运行脚本
# 用法: ./tools/run_ios_simulator.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
EXPORT_PRESET="iOS"
BUILD_DIR="$PROJECT_ROOT/build/ios"
APP_NAME="YolkRush"

echo "🥚 Yolk Rush - iOS 模拟器构建与运行"
echo "================================================"

# 检查 Godot
if [ ! -f "$GODOT" ]; then
    echo "❌ 错误: Godot 未找到在 /Applications/Godot.app"
    exit 1
fi

echo "✅ Godot 路径: $GODOT"

# 检查 Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 错误: Xcode 未安装或未在 PATH 中"
    exit 1
fi

echo "✅ Xcode 已安装"

# 创建构建目录
mkdir -p "$BUILD_DIR"

# 导出 iOS 项目
echo ""
echo "📦 正在导出 iOS 项目..."
"$GODOT" --headless --export-debug "$EXPORT_PRESET" "$BUILD_DIR/$APP_NAME.xcodeproj" "$PROJECT_ROOT/project.godot"

if [ $? -ne 0 ]; then
    echo "❌ 导出失败"
    exit 1
fi

echo "✅ 导出成功"

# 列出可用的模拟器
echo ""
echo "📱 可用的 iOS 模拟器:"
xcrun simctl list devices available | grep "iPhone"

# 选择一个模拟器（默认选择最新的 iPhone）
SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | tail -1 | grep -oE "\(([A-F0-9-]+)\)" | tr -d "()")

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ 错误: 未找到可用的 iPhone 模拟器"
    exit 1
fi

SIMULATOR_NAME=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | sed 's/^ *//g' | cut -d'(' -f1 | sed 's/ *$//')
echo ""
echo "🎯 使用模拟器: $SIMULATOR_NAME ($SIMULATOR_ID)"

# 启动模拟器
echo ""
echo "🚀 正在启动模拟器..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || echo "模拟器已在运行"
open -a Simulator

# 构建并安装到模拟器
echo ""
echo "🔨 正在构建并安装到模拟器..."
cd "$BUILD_DIR"

# 使用 xcodebuild 构建
xcodebuild -project "$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Debug \
    -destination "id=$SIMULATOR_ID" \
    build

if [ $? -ne 0 ]; then
    echo "❌ 构建失败"
    exit 1
fi

# 查找生成的 .app
APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ 错误: 未找到生成的 .app 文件"
    exit 1
fi

echo "✅ 应用路径: $APP_PATH"

# 安装到模拟器
echo ""
echo "📲 正在安装到模拟器..."
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

# 获取 Bundle ID
BUNDLE_ID="com.yolkrush.game"  # 从 export_presets.cfg 读取

# 启动应用
echo ""
echo "🎮 正在启动应用..."
xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"

echo ""
echo "✅ 成功！应用已在 iOS 模拟器中运行"
echo ""
echo "💡 提示:"
echo "  - 使用 WASD 移动（需要连接键盘）"
echo "  - 使用鼠标模拟触摸输入"
echo "  - 空格键跳跃"
echo ""
echo "📊 如需查看日志:"
echo "  xcrun simctl spawn $SIMULATOR_ID log stream --predicate 'processImagePath contains \"$APP_NAME\"'"
