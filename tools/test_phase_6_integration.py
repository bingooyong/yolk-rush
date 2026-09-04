#!/usr/bin/env python3
"""
Phase 6 集成测试 - 验证所有系统正确集成
"""

import os
import sys

def test_scene_files():
    """测试场景文件是否存在"""
    print("🧪 测试场景文件...")

    scenes = [
        "scenes/ui/game_hud.tscn",
        "scenes/camera/camera_rig.tscn",
        "scenes/game/snow_island.tscn"
    ]

    for scene in scenes:
        if not os.path.exists(scene):
            print(f"  ❌ 场景文件不存在: {scene}")
            return False
        print(f"  ✅ {scene}")

    return True

def test_autoload_config():
    """测试 Autoload 配置"""
    print("\n🧪 测试 Autoload 配置...")

    with open("project.godot", "r") as f:
        content = f.read()

    autoloads = [
        ("App", "scripts/core/app.gd"),
        ("AudioManager", "scripts/audio/audio_manager.gd"),
        ("GameManager", "scripts/core/game_manager.gd")
    ]

    for name, path in autoloads:
        if name not in content or path not in content:
            print(f"  ❌ Autoload 未配置: {name} ({path})")
            return False
        print(f"  ✅ {name}")

    return True

def test_scene_integration():
    """测试场景集成"""
    print("\n🧪 测试场景集成...")

    # 检查 snow_island.tscn 是否引用了新场景
    with open("scenes/game/snow_island.tscn", "r") as f:
        content = f.read()

    required = [
        "camera_rig.tscn",
        "game_hud.tscn"
    ]

    for item in required:
        if item not in content:
            print(f"  ❌ Snow Island 未集成: {item}")
            return False
        print(f"  ✅ {item} 已集成")

    return True

def test_script_connections():
    """测试脚本连接"""
    print("\n🧪 测试脚本连接...")

    # 检查 snow_island.gd 是否连接了 GameManager
    with open("scenes/game/snow_island.gd", "r") as f:
        content = f.read()

    required = [
        "GameManager",
        "set_hud",
        "set_camera",
        "on_player_attack",
        "on_player_damaged",
        "on_skill_cast"
    ]

    for item in required:
        if item not in content:
            print(f"  ❌ 缺少 GameManager 调用: {item}")
            return False
        print(f"  ✅ {item}")

    return True

def main():
    print("=" * 60)
    print("Phase 6 集成测试")
    print("=" * 60)

    tests = [
        ("场景文件", test_scene_files),
        ("Autoload配置", test_autoload_config),
        ("场景集成", test_scene_integration),
        ("脚本连接", test_script_connections)
    ]

    results = []
    for name, test_func in tests:
        result = test_func()
        results.append((name, result))

    print("\n" + "=" * 60)
    print("测试结果汇总")
    print("=" * 60)

    passed = sum(1 for _, r in results if r)
    total = len(results)

    for name, result in results:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"{status} - {name}")

    print(f"\n总计: {passed}/{total} 通过")

    if passed == total:
        print("\n🎉 所有集成测试通过！")
        return 0
    else:
        print("\n❌ 部分测试失败")
        return 1

if __name__ == "__main__":
    sys.exit(main())
