extends Node
## 游戏管理器 - Phase 6 集成
## 连接 HUD、Audio、Camera 和游戏逻辑

signal game_started
signal game_paused
signal game_resumed
signal game_over

## 引用
var hud: GameHUD
var audio: AudioManager
var camera_controller: CameraController
var player: CharacterBody3D

## 游戏状态
var is_paused: bool = false
var game_active: bool = false

func _ready() -> void:
	# 查找组件
	hud = get_node_or_null("/root/GameHUD")
	audio = get_node_or_null("/root/AudioManager")

	if not audio:
		audio = AudioManager.new()
		audio.name = "AudioManager"
		get_tree().root.add_child(audio)

## 开始游戏
func start_game() -> void:
	game_active = true
	game_started.emit()

	if audio:
		audio.play_music(AudioManager.MusicType.BATTLE)

## 暂停游戏
func pause_game() -> void:
	if not game_active:
		return

	is_paused = true
	get_tree().paused = true
	game_paused.emit()

	if audio:
		audio.set_music_volume(audio.music_volume * 0.3)

## 恢复游戏
func resume_game() -> void:
	if not is_paused:
		return

	is_paused = false
	get_tree().paused = false
	game_resumed.emit()

	if audio:
		audio.set_music_volume(audio.music_volume / 0.3)

## 游戏结束
func end_game(victory: bool) -> void:
	game_active = false
	game_over.emit()

	if audio:
		if victory:
			audio.play_music(AudioManager.MusicType.VICTORY)
		else:
			audio.play_music(AudioManager.MusicType.DEFEAT)

## 玩家受伤回调
func on_player_damaged(damage: float, current_health: float, max_health: float) -> void:
	if hud:
		hud.update_health(current_health, max_health, 0, 0)

	if audio:
		audio.play_sfx(AudioManager.SFXType.HIT_RECEIVED)

	if camera_controller:
		camera_controller.add_shake(0.3)

## 玩家攻击回调
func on_player_attack(combo_count: int) -> void:
	if audio:
		if combo_count >= 3:
			audio.play_sfx(AudioManager.SFXType.ATTACK_HEAVY)
		else:
			audio.play_sfx(AudioManager.SFXType.ATTACK_LIGHT)

	if camera_controller:
		camera_controller.add_shake(0.1)

	if hud:
		hud.add_combo()

## 玩家释放技能回调
func on_player_skill_cast(skill_id: String) -> void:
	if audio:
		audio.play_sfx(AudioManager.SFXType.SKILL_CAST)

	if camera_controller:
		camera_controller.add_shake(0.5)

## 玩家死亡回调
func on_player_death() -> void:
	if audio:
		audio.play_sfx(AudioManager.SFXType.DEATH)

	if camera_controller:
		camera_controller.death_effect()

	await get_tree().create_timer(2.0).timeout
	end_game(false)

## 敌人死亡回调
func on_enemy_killed() -> void:
	if audio:
		audio.play_sfx(AudioManager.SFXType.DEATH, 0.2)

## 技能冷却更新
func on_skill_cooldown_update(skill_key: String, remaining: float, total: float) -> void:
	if hud:
		hud.update_skill_cooldown(skill_key, remaining, total)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_paused:
			resume_game()
		else:
			pause_game()
