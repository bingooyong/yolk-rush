#!/usr/bin/env python3
"""测试 Phase 5 技能系统"""

import subprocess
import sys
import time
from pathlib import Path

def main():
    print("=" * 60)
    print("Phase 5: 技能系统测试")
    print("=" * 60)
    print()

    # 检查 Godot 是否可用
    godot_path = "/Applications/Godot.app/Contents/MacOS/Godot"
    if not Path(godot_path).exists():
        print("❌ Godot 未找到")
        return 1

    # 验证技能定义文件
    skill_def = Path("data/skills/skill_definitions.json")
    if not skill_def.exists():
        print("❌ 技能定义文件不存在")
        return 1

    print("✓ 技能定义文件存在")

    # 验证脚本文件
    required_files = [
        "scripts/game/skill_system.gd",
        "scenes/game/skill_ui.gd"
    ]

    for file_path in required_files:
        if not Path(file_path).exists():
            print(f"❌ 缺少文件: {file_path}")
            return 1
        print(f"✓ {file_path}")

    print()
    print("=" * 60)
    print("启动游戏测试技能系统")
    print("=" * 60)
    print()
    print("操作说明:")
    print("  WASD  - 移动")
    print("  空格  - 跳跃")
    print("  J/K   - 攻击")
    print("  Q     - 旋风斩 (AOE)")
    print("  E     - 冲刺 (位移)")
    print("  R     - 护盾 (防御)")
    print("  F     - 毁灭一击 (终结技)")
    print()
    print("验收标准:")
    print("  1. 按 Q/E/R/F 可以释放技能")
    print("  2. 技能有冷却时间限制")
    print("  3. UI 显示技能图标和冷却")
    print("  4. 技能对敌人造成伤害")
    print("  5. 技能有视觉反馈")
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
