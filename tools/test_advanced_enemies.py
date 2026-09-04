#!/usr/bin/env python3
"""测试 Phase 5 高级敌人 AI"""

import subprocess
import sys
from pathlib import Path

def main():
    print("=" * 60)
    print("Phase 5: 高级敌人 AI 测试")
    print("=" * 60)
    print()

    # 检查 Godot 是否可用
    godot_path = "/Applications/Godot.app/Contents/MacOS/Godot"
    if not Path(godot_path).exists():
        print("❌ Godot 未找到")
        return 1

    # 验证敌人定义文件
    enemy_def = Path("data/enemies/enemy_types.json")
    if not enemy_def.exists():
        print("❌ 敌人定义文件不存在")
        return 1

    print("✓ 敌人定义文件存在")

    # 验证脚本文件
    required_files = [
        "scripts/ai/advanced_enemy.gd",
        "scenes/enemies/melee_assassin.tscn",
        "scenes/enemies/ranged_archer.tscn",
        "scenes/enemies/tank_guardian.tscn"
    ]

    for file_path in required_files:
        if not Path(file_path).exists():
            print(f"❌ 缺少文件: {file_path}")
            return 1
        print(f"✓ {file_path}")

    print()
    print("=" * 60)
    print("启动游戏测试高级敌人 AI")
    print("=" * 60)
    print()
    print("敌人类型:")
    print("  🗡️  暗影刺客 x2 - 快速接近，高伤害")
    print("  🏹 冰霜射手 x2 - 保持距离，持续输出")
    print("  🛡️  岩石守卫 x1 - 高血量，控制技能")
    print()
    print("AI 行为:")
    print("  1. 刺客会快速接近玩家")
    print("  2. 射手会保持距离风筝")
    print("  3. 守卫会吸引仇恨，阻挡玩家")
    print("  4. 敌人会使用特殊技能")
    print("  5. 低血量时会撤退")
    print()
    print("验收标准:")
    print("  ✓ 3 种敌人视觉清晰可辨")
    print("  ✓ AI 行为符合类型特点")
    print("  ✓ 敌人会主动追击玩家")
    print("  ✓ 技能系统与 AI 配合流畅")
    print("  ✓ 战斗有策略深度")
    print()
    print("按 Ctrl+C 停止测试")
    print("=" * 60)
    print()

    # 启动 Godot
    try:
        subprocess.run([
            godot_path,
            "--path", ".",
            "scenes/game/snow_island.tscn"
        ])
    except KeyboardInterrupt:
        print("\n测试中断")
        return 0

    return 0

if __name__ == "__main__":
    sys.exit(main())
