#!/bin/bash

echo "=== Verifying Inventory System Files ==="
echo ""

GODOT="/Applications/Godot.app/Contents/MacOS/Godot"

files=(
  "scripts/inventory/inventory_item.gd"
  "scripts/inventory/item_stack.gd"
  "scripts/inventory/inventory_system.gd"
  "scripts/inventory/quick_bar_system.gd"
  "scripts/inventory/item_database.gd"
)

all_pass=true

for file in "${files[@]}"; do
  echo "Checking: $file"
  if $GODOT --headless --check-only --script "$file" 2>&1 | grep -q "ERROR"; then
    echo "  ✗ Syntax errors found"
    all_pass=false
  else
    echo "  ✓ Syntax OK"
  fi
done

echo ""
if $all_pass; then
  echo "✓ All inventory files have valid syntax"
  exit 0
else
  echo "✗ Some files have syntax errors"
  exit 1
fi
