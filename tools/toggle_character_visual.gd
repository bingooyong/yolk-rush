@tool
extends EditorScript
## Yolk Rush - Toggle Character Visual Mode
## 在占位符和 GLB 模型之间快速切换，用于开发测试

const CHARACTER_IDS := ["yolk_hero"]

func _run() -> void:
	print("🥚 Yolk Rush - Character Visual Toggle")
	print("=" * 60)

	var editor_interface := get_editor_interface()
	var selected_nodes := editor_interface.get_selection().get_selected_nodes()

	if selected_nodes.is_empty():
		print("❌ No nodes selected")
		print("Please select a CharacterVisual node in the scene tree")
		return

	for node in selected_nodes:
		if node.has_method("load_visual_model") and node.has_method("_spawn_placeholder"):
			_toggle_visual_mode(node)
		else:
			print("⚠️  Selected node is not a CharacterVisual: %s" % node.name)

func _toggle_visual_mode(visual_node: Node) -> void:
	var has_placeholder := _has_placeholder_children(visual_node)
	var has_glb_model := _has_glb_children(visual_node)

	print("\nNode: %s" % visual_node.name)
	print("Character ID: %s" % visual_node.character_id)
	print("Current mode: %s" % ("Placeholder" if has_placeholder else "GLB Model" if has_glb_model else "Empty"))

	if has_placeholder:
		# 切换到 GLB 模型
		print("→ Switching to GLB model...")
		_clear_children(visual_node)
		visual_node.load_visual_model()
	elif has_glb_model:
		# 切换到占位符
		print("→ Switching to placeholder...")
		_clear_children(visual_node)
		visual_node._spawn_placeholder()
	else:
		# 首次加载
		print("→ Loading visual...")
		visual_node._load_character_visual(visual_node.character_id)

	print("✅ Visual mode toggled")

func _has_placeholder_children(node: Node) -> bool:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh := child.mesh
			if mesh is CapsuleMesh or mesh is SphereMesh:
				return true
	return false

func _has_glb_children(node: Node) -> bool:
	for child in node.get_children():
		# GLB 导入的节点通常不是简单的 MeshInstance3D
		if child.get_child_count() > 0 or (child is Node3D and not child is MeshInstance3D):
			return true
	return false

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
