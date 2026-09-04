extends Node
## GameManager - 游戏全局管理器
## Phase 6: 完整系统集成 + 伤害飘字

var game_hud: CanvasLayer
var camera_controller: Node3D
var damage_number_scene: PackedScene

func _ready() -> void:
	# 预加载伤害飘字场景
	damage_number_scene = preload("res://scenes/ui/damage_number_3d.tscn")
	print("[GameManager] Initialized")

func initialize() -> void:
	print("[GameManager] System initialization complete")

func set_hud(hud: CanvasLayer) -> void:
	game_hud = hud
	print("[GameManager] HUD connected")

func set_camera(camera: Node3D) -> void:
	camera_controller = camera
	print("[GameManager] Camera connected")

## 玩家事件回调
func on_player_attack(combo_stage: int) -> void:
	print("[GameManager] Player attack - Combo stage: %d" % combo_stage)

	# 更新 HUD Combo
	if game_hud and game_hud.has_method("update_combo"):
		game_hud.update_combo(combo_stage)

	# 播放攻击音效
	if combo_stage == 1:
		AudioManager.play_sfx("attack_light")
	elif combo_stage == 2:
		AudioManager.play_sfx("attack_medium")
	else:
		AudioManager.play_sfx("attack_heavy")

	# 相机轻微震动
	if camera_controller and camera_controller.has_method("add_shake"):
		var shake_strength := 0.1 + (combo_stage - 1) * 0.05
		camera_controller.add_shake(shake_strength)

func on_player_damaged(amount: float, current_hp: float, max_hp: float) -> void:
	print("[GameManager] Player damaged: %.1f (%.1f/%.1f)" % [amount, current_hp, max_hp])

	# 更新 HUD 血条
	if game_hud and game_hud.has_method("update_health"):
		game_hud.update_health(current_hp, max_hp)

	# 播放受击音效
	AudioManager.play_sfx("player_hit")

	# 相机震动
	if camera_controller and camera_controller.has_method("add_shake"):
		camera_controller.add_shake(0.3)

func on_player_died() -> void:
	print("[GameManager] Player died")
	AudioManager.play_sfx("player_death")

	# 相机剧烈震动
	if camera_controller and camera_controller.has_method("add_shake"):
		camera_controller.add_shake(1.0)

	# TODO: 显示死亡界面

func on_player_shield_changed(current: float, max_shield: float) -> void:
	if game_hud and game_hud.has_method("update_shield"):
		game_hud.update_shield(current, max_shield)

## 技能事件回调
func on_skill_cast(skill_id: String) -> void:
	print("[GameManager] Skill cast: %s" % skill_id)

	# 播放技能音效
	match skill_id:
		"whirlwind_slash":
			AudioManager.play_sfx("skill_whirlwind")
		"dash":
			AudioManager.play_sfx("skill_dash")
		"shield":
			AudioManager.play_sfx("skill_shield")
		"devastate":
			AudioManager.play_sfx("skill_devastate")

	# 技能特殊相机效果
	if camera_controller:
		match skill_id:
			"dash":
				# 冲刺时 FOV 扩大
				if camera_controller.has_method("set_fov_boost"):
					camera_controller.set_fov_boost(1.2, 0.3)
			"devastate":
				# 大招慢动作
				if camera_controller.has_method("set_time_scale"):
					camera_controller.set_time_scale(0.3, 0.5)
				if camera_controller.has_method("add_shake"):
					camera_controller.add_shake(0.8)

func on_skill_cooldown(skill_id: String, duration: float) -> void:
	print("[GameManager] Skill cooldown: %s (%.1fs)" % [skill_id, duration])
	# HUD 冷却由 SkillSystem 直接更新

## 敌人事件回调
func on_enemy_damaged(amount: float, position: Vector3) -> void:
	print("[GameManager] Enemy damaged: %.1f at %s" % [amount, position])

	# 生成伤害飘字
	spawn_damage_number(amount, position, false)

	# 播放打击音效
	AudioManager.play_sfx("enemy_hit")

	# 轻微相机震动
	if camera_controller and camera_controller.has_method("add_shake"):
		camera_controller.add_shake(0.15)

func on_enemy_died(position: Vector3) -> void:
	print("[GameManager] Enemy died at %s" % position)

	# 播放死亡音效
	AudioManager.play_sfx("enemy_death")

	# 生成特殊飘字
	spawn_damage_number(0, position, false, "KILL")

	# 相机震动
	if camera_controller and camera_controller.has_method("add_shake"):
		camera_controller.add_shake(0.4)

## 伤害飘字生成
func spawn_damage_number(amount: float, world_position: Vector3, is_critical: bool, custom_text: String = "") -> void:
	if not damage_number_scene:
		return

	var damage_number: Node3D = damage_number_scene.instantiate()
	damage_number.global_position = world_position + Vector3(0, 1.5, 0)  # 偏移到头顶

	# 设置文本
	if custom_text != "":
		damage_number.set_text(custom_text)
	else:
		damage_number.set_damage(amount, is_critical)

	# 添加到场景树
	get_tree().root.add_child(damage_number)

	print("[GameManager] Spawned damage number: %.1f at %s" % [amount, world_position])
