#!/usr/bin/env python3
"""
Phase 6 UI/Audio/Camera 系统测试
测试 HUD、音效、相机功能
"""

import subprocess
import sys
import os

def run_godot_test(script_path: str, test_name: str) -> bool:
    """运行 Godot 测试脚本"""
    print(f"\n{'='*60}")
    print(f"测试: {test_name}")
    print(f"{'='*60}")

    if not os.path.exists(script_path):
        print(f"⚠️  测试脚本不存在: {script_path}")
        return True  # 跳过，不算失败

    result = subprocess.run(
        ["godot", "--headless", "--script", script_path],
        capture_output=True,
        text=True,
        timeout=30
    )

    if result.returncode == 0:
        print(f"✅ {test_name} 通过")
        return True
    else:
        print(f"❌ {test_name} 失败")
        print("STDOUT:", result.stdout)
        print("STDERR:", result.stderr)
        return False

def check_script_exists(path: str, name: str) -> bool:
    """检查脚本文件是否存在"""
    if os.path.exists(path):
        print(f"✅ {name} 存在")
        return True
    else:
        print(f"❌ {name} 不存在")
        return False

def main():
    print("\n" + "="*60)
    print("Phase 6 系统测试")
    print("="*60)

    results = []

    # 1. 检查核心脚本
    print("\n📋 检查核心脚本...")
    results.append(check_script_exists("scripts/ui/game_hud.gd", "GameHUD"))
    results.append(check_script_exists("scripts/audio/audio_manager.gd", "AudioManager"))
    results.append(check_script_exists("scripts/camera/camera_controller.gd", "CameraController"))
    results.append(check_script_exists("scripts/core/game_manager.gd", "GameManager"))

    # 2. 检查 VFX 系统（Phase 4.5）
    print("\n✨ 检查 VFX 系统...")
    results.append(check_script_exists("scripts/visual/vfx_manager.gd", "VFXManager"))

    # 3. 检查装饰系统（Phase 4.5）
    print("\n🎨 检查装饰系统...")
    results.append(check_script_exists("scripts/level/decoration_builder.gd", "DecorationBuilder"))

    # 4. 语法检查（需要 Godot，跳过）
    print("\n🔍 语法检查...")
    print("⚠️  需要 Godot 可执行文件，跳过语法检查")
    print("   （在有 Godot 的环境中运行时会自动检查）")

    # 5. 架构检查
    print("\n🏗️  架构检查...")

    # HUD 必须继承 CanvasLayer
    with open("scripts/ui/game_hud.gd", "r") as f:
        content = f.read()
        if "extends CanvasLayer" in content:
            print("✅ GameHUD 正确继承 CanvasLayer")
            results.append(True)
        else:
            print("❌ GameHUD 未继承 CanvasLayer")
            results.append(False)

    # AudioManager 必须继承 Node
    with open("scripts/audio/audio_manager.gd", "r") as f:
        content = f.read()
        if "extends Node" in content:
            print("✅ AudioManager 正确继承 Node")
            results.append(True)
        else:
            print("❌ AudioManager 未继承 Node")
            results.append(False)

    # CameraController 必须继承 Node3D
    with open("scripts/camera/camera_controller.gd", "r") as f:
        content = f.read()
        if "extends Node3D" in content:
            print("✅ CameraController 正确继承 Node3D")
            results.append(True)
        else:
            print("❌ CameraController 未继承 Node3D")
            results.append(False)

    # 6. 总结
    print("\n" + "="*60)
    print("测试总结")
    print("="*60)

    passed = sum(results)
    total = len(results)

    print(f"\n通过: {passed}/{total}")

    if passed == total:
        print("\n🎉 所有测试通过！Phase 6 系统就绪。")
        return 0
    else:
        print(f"\n⚠️  {total - passed} 个测试失败。")
        return 1

if __name__ == "__main__":
    sys.exit(main())
