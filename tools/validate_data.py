#!/usr/bin/env python3
"""Smoke mirror of CharacterDefinition / LevelDefinition validators (no Godot)."""
from __future__ import annotations
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HEIGHT_MIN, HEIGHT_MAX = 1.40, 1.70
REQUIRED_ANIMS = [
    "idle_animation", "run_animation", "jump_animation", "airborne_animation",
    "fall_animation", "land_animation", "roll_animation", "dash_animation",
    "pounce_animation", "hit_animation", "victory_animation", "fail_animation",
]
ALLOWED_ROLES = {
    "start_hall", "main_lane", "challenge", "shortcut", "recovery", "finish_hall",
}


def validate_character(path: Path) -> list[str]:
    data = json.loads(path.read_text())
    errs: list[str] = []
    if not data.get("id"):
        errs.append("missing id")
    vm = data.get("visual_model", "")
    if not vm.endswith((".glb", ".gltf")):
        errs.append(f"visual_model must be .glb/.gltf: {vm}")
    if not data.get("skeleton"):
        errs.append("missing skeleton")
    for k in REQUIRED_ANIMS:
        if not data.get(k):
            errs.append(f"missing animation field: {k}")
    mats = data.get("materials") or []
    if not mats:
        errs.append("materials must be non-empty")
    for i, m in enumerate(mats):
        if not isinstance(m, dict) or not m.get("slot") or not m.get("library"):
            errs.append(f"materials[{i}] needs slot + library")
    cp = data.get("collision_profile") or {}
    for k in ("height", "radius", "offset_y"):
        if k not in cp:
            errs.append(f"collision_profile missing {k}")
        elif k != "offset_y" and float(cp[k]) <= 0:
            errs.append(f"collision_profile.{k} must be > 0")
    contract = data.get("contract") or {}
    hm = float(contract.get("height_m", -1))
    if not (HEIGHT_MIN <= hm <= HEIGHT_MAX):
        errs.append(f"contract.height_m out of range: {hm}")
    if contract.get("facing") != "-Z":
        errs.append("contract.facing must be -Z")
    if contract.get("origin") != "feet":
        errs.append("contract.origin must be feet")
    return errs


def validate_level(path: Path, light_path: Path) -> list[str]:
    data = json.loads(path.read_text())
    light = json.loads(light_path.read_text())
    errs: list[str] = []
    if not data.get("id"):
        errs.append("missing id")
    if not data.get("lighting"):
        errs.append("missing lighting")
    spawn = data.get("spawn") or {}
    for k in ("x", "y", "z"):
        if k not in spawn:
            errs.append(f"spawn missing {k}")
    segs = data.get("segments") or []
    if not segs:
        errs.append("segments empty")
    roles = set()
    for i, seg in enumerate(segs):
        role = seg.get("role")
        if role not in ALLOWED_ROLES:
            errs.append(f"segments[{i}] bad role: {role}")
        else:
            roles.add(role)
        for k in ("id", "width", "length", "y"):
            if k not in seg:
                errs.append(f"segments[{i}] missing {k}")
        if float(seg.get("width", 0)) <= 0 or float(seg.get("length", 0)) <= 0:
            errs.append(f"segments[{i}] width/length must be > 0")
    for need in ("start_hall", "finish_hall"):
        if need not in roles:
            errs.append(f"missing role {need}")
    if data.get("lighting") != light.get("id"):
        errs.append(f"level.lighting {data.get('lighting')} != light id {light.get('id')}")
    return errs


def main() -> int:
    char = ROOT / "data/characters/yolk_hero.json"
    level = ROOT / "data/levels/snow_island_01.json"
    light = ROOT / "data/contracts/lighting_profile.json"
    ok = True
    ce = validate_character(char)
    if ce:
        ok = False
        print("FAIL character")
        for e in ce:
            print(" -", e)
    else:
        print("PASS character", char.name)
    le = validate_level(level, light)
    if le:
        ok = False
        print("FAIL level")
        for e in le:
            print(" -", e)
    else:
        print("PASS level", level.name)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
