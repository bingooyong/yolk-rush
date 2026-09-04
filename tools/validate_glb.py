#!/usr/bin/env python3
"""
Yolk Rush - GLB 模型验证工具
验证 GLB 模型是否符合项目规范
"""

import sys
import json
import struct
from pathlib import Path

def read_glb_header(glb_path: Path) -> dict:
    """读取 GLB 文件头信息"""
    try:
        with open(glb_path, 'rb') as f:
            # GLB 格式: magic(4) + version(4) + length(4)
            magic = f.read(4)
            if magic != b'glTF':
                return {"error": "Not a valid GLB file (magic mismatch)"}

            version = struct.unpack('<I', f.read(4))[0]
            length = struct.unpack('<I', f.read(4))[0]

            return {
                "version": version,
                "length": length,
                "valid": True
            }
    except Exception as e:
        return {"error": str(e)}

def validate_glb_model(glb_path: str) -> dict:
    """验证 GLB 模型"""
    path = Path(glb_path)

    result = {
        "path": str(path),
        "exists": path.exists(),
        "checks": {}
    }

    if not path.exists():
        result["status"] = "FAIL"
        result["message"] = "File not found"
        return result

    # 检查文件扩展名
    result["checks"]["extension"] = {
        "valid": path.suffix.lower() == ".glb",
        "message": f"Extension: {path.suffix}"
    }

    # 检查文件大小
    file_size = path.stat().st_size
    result["checks"]["size"] = {
        "valid": file_size > 0,
        "message": f"Size: {file_size / 1024:.2f} KB"
    }

    # 建议大小限制
    size_warning = ""
    if file_size > 10 * 1024 * 1024:  # 10MB
        size_warning = " (⚠️  Large file, consider optimization)"
    elif file_size > 50 * 1024 * 1024:  # 50MB
        size_warning = " (❌ File too large for mobile)"

    result["checks"]["size"]["message"] += size_warning

    # 读取 GLB 头信息
    header = read_glb_header(path)
    if "error" in header:
        result["checks"]["format"] = {
            "valid": False,
            "message": header["error"]
        }
        result["status"] = "FAIL"
        return result

    result["checks"]["format"] = {
        "valid": header.get("valid", False),
        "message": f"GLB version {header.get('version', 'unknown')}, length: {header.get('length', 0)} bytes"
    }

    # 检查文件命名规范
    name_valid = path.stem.replace('_', '').replace('-', '').isalnum()
    result["checks"]["naming"] = {
        "valid": name_valid,
        "message": f"Name: {path.stem} ({'valid' if name_valid else 'invalid - use alphanumeric, _ or -'})"
    }

    # 汇总状态
    all_valid = all(check.get("valid", False) for check in result["checks"].values())
    result["status"] = "PASS" if all_valid else "FAIL"

    return result

def validate_character_glb(character_json_path: str) -> dict:
    """验证角色 JSON 中引用的 GLB 模型"""
    path = Path(character_json_path)

    result = {
        "character_json": str(path),
        "status": "UNKNOWN"
    }

    if not path.exists():
        result["status"] = "FAIL"
        result["message"] = "Character JSON not found"
        return result

    try:
        with open(path, 'r') as f:
            data = json.load(f)

        character_id = data.get("character_id", "unknown")
        visual_model = data.get("visual_model", "")

        result["character_id"] = character_id
        result["visual_model"] = visual_model

        if not visual_model:
            result["status"] = "WARN"
            result["message"] = "No visual_model specified (will use placeholder)"
            return result

        # 转换 Godot 资源路径到文件系统路径
        if visual_model.startswith("res://"):
            # 假设脚本在 tools/ 目录，项目根在 ../
            project_root = Path(__file__).parent.parent
            fs_path = project_root / visual_model.replace("res://", "")
        else:
            fs_path = Path(visual_model)

        # 验证 GLB 文件
        glb_result = validate_glb_model(str(fs_path))
        result["glb_validation"] = glb_result
        result["status"] = glb_result["status"]

    except json.JSONDecodeError as e:
        result["status"] = "FAIL"
        result["message"] = f"Invalid JSON: {e}"
    except Exception as e:
        result["status"] = "FAIL"
        result["message"] = str(e)

    return result

def print_result(result: dict):
    """打印验证结果"""
    status_icon = {
        "PASS": "✅",
        "FAIL": "❌",
        "WARN": "⚠️",
        "UNKNOWN": "❓"
    }

    status = result.get("status", "UNKNOWN")
    icon = status_icon.get(status, "❓")

    print(f"\n{icon} Status: {status}")
    print(f"Path: {result.get('path', result.get('character_json', 'N/A'))}")

    if "message" in result:
        print(f"Message: {result['message']}")

    if "checks" in result:
        print("\nChecks:")
        for check_name, check_data in result["checks"].items():
            check_icon = "✅" if check_data.get("valid") else "❌"
            print(f"  {check_icon} {check_name}: {check_data.get('message', 'N/A')}")

    if "glb_validation" in result:
        print("\nGLB Model Validation:")
        glb = result["glb_validation"]
        for check_name, check_data in glb.get("checks", {}).items():
            check_icon = "✅" if check_data.get("valid") else "❌"
            print(f"  {check_icon} {check_name}: {check_data.get('message', 'N/A')}")

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python3 tools/validate_glb.py <path/to/model.glb>")
        print("  python3 tools/validate_glb.py <path/to/character.json>")
        sys.exit(1)

    input_path = sys.argv[1]
    path = Path(input_path)

    print("🥚 Yolk Rush - GLB Model Validator")
    print("=" * 60)

    if path.suffix.lower() == ".glb":
        result = validate_glb_model(input_path)
    elif path.suffix.lower() == ".json":
        result = validate_character_glb(input_path)
    else:
        print(f"❌ Unsupported file type: {path.suffix}")
        print("Supported: .glb, .json")
        sys.exit(1)

    print_result(result)

    # 退出码
    exit_code = 0 if result["status"] == "PASS" else 1
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
