#!/usr/bin/env python3
"""
Phase 6 数据绑定测试
验证 UI/Camera/GameManager 的完整数据流
"""

import os
import sys

def test_hud_script():
    """测试 HUD 脚本的数据绑定方法"""
    print("✅ 测试 HUD 脚本数据绑定...")

    hud_script = "scenes/ui/game_hud.gd"
    if not os.path.exists(hud_script):
        print(f"❌ 文件不存在: {hud_script}")
        return False

    content = open(hud_script, 'r', encoding='utf-8').read()

    # 检查必需方法
    required_methods = [
        "update_health",
        "update_shield",
        "update_skill_cooldown",
        "update_combo",
        "_flash_low_health",
        "_flash_skill_ready"
    ]

    for method in required_methods:
        if f"func {method}" not in content:
            print(f"❌ 缺少方法: {method}")
            return False

    # 检查动画
    if "create_tween" not in content:
        print("❌ 缺少 Tween 动画")
        return False

    print("✅ HUD 脚本数据绑定完整")
    return True

def test_camera_script():
    """测试相机脚本的效果方法"""
    print("✅ 测试相机脚本效果...")

    camera_script = "scripts/camera/camera_controller.gd"
    if not os.path.exists(camera_script):
        print(f"❌ 文件不存在: {camera_script}")
        return False

    content = open(camera_script, 'r', encoding='utf-8').read()

    # 检查必需方法
    required_methods = [
        "add_shake",
        "set_fov_boost",
        "set_time_scale",
        "set_target",
        "_update_follow",
        "_update_shake",
        "_update_fov"
    ]

    for method in required_methods:
        if f"func {method}" not in content:
            print(f"❌ 缺少方法: {method}")
            return False

    print("✅ 相机脚本效果完整")
    return True

def test_damage_number():
    """测试伤害飘字系统"""
    print("✅ 测试伤害飘字系统...")

    scene_file = "scenes/ui/damage_number_3d.tscn"
    script_file = "scenes/ui/damage_number_3d.gd"

    if not os.path.exists(scene_file):
        print(f"❌ 场景文件不存在: {scene_file}")
        return False

    if not os.path.exists(script_file):
        print(f"❌ 脚本文件不存在: {script_file}")
        return False

    # 检查脚本方法
    content = open(script_file, 'r', encoding='utf-8').read()
    required_methods = ["set_damage", "set_text", "_start_animation"]

    for method in required_methods:
        if f"func {method}" not in content:
            print(f"❌ 缺少方法: {method}")
            return False

    # 检查场景包含 Label3D
    scene_content = open(scene_file, 'r', encoding='utf-8').read()
    if 'type="Label3D"' not in scene_content:
        print("❌ 场景缺少 Label3D 节点")
        return False

    print("✅ 伤害飘字系统完整")
    return True

def test_game_manager_integration():
    """测试 GameManager 的完整集成"""
    print("✅ 测试 GameManager 集成...")

    gm_script = "scripts/core/game_manager.gd"
    if not os.path.exists(gm_script):
        print(f"❌ 文件不存在: {gm_script}")
        return False

    content = open(gm_script, 'r', encoding='utf-8').read()

    # 检查所有回调方法
    required_callbacks = [
        "on_player_attack",
        "on_player_damaged",
        "on_player_died",
        "on_player_shield_changed",
        "on_skill_cast",
        "on_skill_cooldown",
        "on_enemy_damaged",
        "on_enemy_died",
        "spawn_damage_number"
    ]

    for callback in required_callbacks:
        if f"func {callback}" not in content:
            print(f"❌ 缺少回调: {callback}")
            return False

    # 检查 HUD 和 Camera 更新调用
    if "game_hud" not in content or "camera_controller" not in content:
        print("❌ 缺少 HUD 或 Camera 引用")
        return False

    print("✅ GameManager 集成完整")
    return True

def test_snow_island_connections():
    """测试 SnowIsland 场景的信号连接"""
    print("✅ 测试 SnowIsland 信号连接...")

    scene_script = "scenes/game/snow_island.gd"
    if not os.path.exists(scene_script):
        print(f"❌ 文件不存在: {scene_script}")
        return False

    content = open(scene_script, 'r', encoding='utf-8').read()

    # 检查 HUD 更新调用
    if "game_hud.update_health" not in content:
        print("❌ 缺少 HUD 血条更新")
        return False

    if "game_hud.update_combo" not in content:
        print("❌ 缺少 HUD Combo 更新")
        return False

    if "game_hud.update_skill_cooldown" not in content:
        print("❌ 缺少 HUD 技能冷却更新")
        return False

    # 检查 GameManager 连接
    if "GameManager.initialize()" not in content:
        print("❌ 缺少 GameManager 初始化")
        return False

    if "GameManager.set_hud" not in content or "GameManager.set_camera" not in content:
        print("❌ 缺少 GameManager HUD/Camera 设置")
        return False

    print("✅ SnowIsland 信号连接完整")
    return True

def main():
    print("=" * 60)
    print("Phase 6 数据绑定测试")
    print("=" * 60)

    tests = [
        ("HUD 数据绑定", test_hud_script),
        ("相机效果系统", test_camera_script),
        ("伤害飘字系统", test_damage_number),
        ("GameManager 集成", test_game_manager_integration),
        ("场景信号连接", test_snow_island_connections)
    ]

    results = []
    for name, test_func in tests:
        print(f"\n{'=' * 60}")
        print(f"测试: {name}")
        print('=' * 60)
        result = test_func()
        results.append((name, result))
        print()

    print("=" * 60)
    print("测试总结")
    print("=" * 60)

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for name, result in results:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"{status} - {name}")

    print()
    print(f"总计: {passed}/{total} 通过")

    if passed == total:
        print("\n🎉 所有数据绑定测试通过！")
        return 0
    else:
        print(f"\n❌ {total - passed} 个测试失败")
        return 1

if __name__ == "__main__":
    sys.exit(main())
