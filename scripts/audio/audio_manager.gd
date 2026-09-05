extends Node
## 音效管理器 - 统一管理游戏音效和音乐

const AudioSynthesizer = preload("res://scripts/audio/audio_synthesizer.gd")

signal music_changed(track_name: String)
signal sfx_played(sfx_name: String)
signal volume_changed(bus: String, volume: float)

## 音频总线名称
const BUS_MASTER = "Master"
const BUS_MUSIC = "Music"
const BUS_SFX = "SFX"
const BUS_UI = "UI"

## 音效池
var sfx_players: Dictionary = {}  # sfx_name -> Array[AudioStreamPlayer]
var sfx_pool_size: int = 5  # 每种音效的播放器数量

## 音乐播放器
var music_player: AudioStreamPlayer = null
var current_music_track: String = ""
var music_fade_duration: float = 1.0

## 音量设置（0.0 - 1.0）
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var ui_volume: float = 1.0

## 音效资源缓存
var sfx_cache: Dictionary = {}  # sfx_name -> AudioStream
var music_cache: Dictionary = {}  # track_name -> AudioStream

## 3D音效支持
var audio_listener: AudioListener3D = null

func _ready() -> void:
	_setup_music_player()
	_load_audio_settings()
	_apply_volume_settings()
	_preload_synthesized_sounds()

	print("[AudioManager] Initialized")

## 预加载程序化音效
func _preload_synthesized_sounds() -> void:
	var preset_names = AudioSynthesizer.get_preset_names()
	for preset_name in preset_names:
		var stream = AudioSynthesizer.generate_sound(preset_name)
		if stream:
			sfx_cache[preset_name] = stream

	print("[AudioManager] Preloaded %d synthesized sounds" % preset_names.size())

## 设置音乐播放器
func _setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = BUS_MUSIC
	add_child(music_player)

## 加载音频设置
func _load_audio_settings() -> void:
	# 从存档系统加载设置
	var save_system = _get_save_system()
	if save_system:
		master_volume = save_system.get_setting("master_volume", 1.0)
		music_volume = save_system.get_setting("music_volume", 0.8)
		sfx_volume = save_system.get_setting("sfx_volume", 1.0)
		ui_volume = save_system.get_setting("ui_volume", 1.0)

## 获取存档系统
func _get_save_system():
	var flow_manager = get_node_or_null("/root/GameFlowManager")
	if flow_manager and flow_manager.save_system:
		return flow_manager.save_system
	return null

## === 音乐控制 ===

## 播放音乐
func play_music(track_name: String, fade_in: bool = true) -> void:
	if track_name == current_music_track and music_player.playing:
		return

	# 加载音乐资源
	var stream = _load_music(track_name)
	if not stream:
		push_warning("[AudioManager] Music not found: %s" % track_name)
		return

	# 淡出当前音乐
	if music_player.playing and fade_in:
		await _fade_out_music()

	# 播放新音乐
	music_player.stream = stream
	music_player.play()
	current_music_track = track_name

	# 淡入
	if fade_in:
		_fade_in_music()

	music_changed.emit(track_name)
	print("[AudioManager] Playing music: %s" % track_name)

## 停止音乐
func stop_music(fade_out: bool = true) -> void:
	if not music_player.playing:
		return

	if fade_out:
		await _fade_out_music()
	else:
		music_player.stop()

	current_music_track = ""

## 暂停音乐
func pause_music() -> void:
	music_player.stream_paused = true

## 恢复音乐
func resume_music() -> void:
	music_player.stream_paused = false

## 淡入音乐
func _fade_in_music() -> void:
	music_player.volume_db = -80.0

	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", 0.0, music_fade_duration)

## 淡出音乐
func _fade_out_music() -> void:
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, music_fade_duration)
	await tween.finished

	music_player.stop()

## === 音效控制 ===

## 播放音效
func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream = _load_sfx(sfx_name)
	if not stream:
		push_warning("[AudioManager] SFX not found: %s" % sfx_name)
		return

	var player = _get_available_player(sfx_name)
	if not player:
		return

	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

	sfx_played.emit(sfx_name)

## 播放 UI 音效
func play_ui_sound(sfx_name: String) -> void:
	play_ui_sfx(sfx_name)

## 播放 UI 音效
func play_ui_sfx(sfx_name: String) -> void:
	var stream = _load_sfx(sfx_name)
	if not stream:
		return

	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = BUS_UI
	add_child(player)

	player.finished.connect(func(): player.queue_free())
	player.play()

	sfx_played.emit(sfx_name)

## 播放 3D 音效
func play_sfx_3d(sfx_name: String, world_position: Vector3, volume_db: float = 0.0) -> void:
	var stream = _load_sfx(sfx_name)
	if not stream:
		return

	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = BUS_SFX
	player.volume_db = volume_db
	player.global_position = world_position

	# 添加到场景
	get_tree().root.add_child(player)

	player.finished.connect(func(): player.queue_free())
	player.play()

	sfx_played.emit(sfx_name)

## 获取可用的音效播放器
func _get_available_player(sfx_name: String) -> AudioStreamPlayer:
	# 检查是否已有播放器池
	if not sfx_players.has(sfx_name):
		sfx_players[sfx_name] = []

	var players = sfx_players[sfx_name]

	# 查找空闲的播放器
	for player in players:
		if not player.playing:
			return player

	# 如果池未满，创建新播放器
	if players.size() < sfx_pool_size:
		var player = AudioStreamPlayer.new()
		player.name = "SFX_%s_%d" % [sfx_name, players.size()]
		player.bus = BUS_SFX
		add_child(player)
		players.append(player)
		return player

	# 池已满，使用最旧的播放器
	return players[0]

## === 音量控制 ===

## 设置主音量
func set_master_volume(volume: float) -> void:
	master_volume = clampf(volume, 0.0, 1.0)
	_apply_bus_volume(BUS_MASTER, master_volume)
	_save_volume_setting("master_volume", master_volume)
	volume_changed.emit(BUS_MASTER, master_volume)

## 设置音乐音量
func set_music_volume(volume: float) -> void:
	music_volume = clampf(volume, 0.0, 1.0)
	_apply_bus_volume(BUS_MUSIC, music_volume)
	_save_volume_setting("music_volume", music_volume)
	volume_changed.emit(BUS_MUSIC, music_volume)

## 设置音效音量
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)
	_apply_bus_volume(BUS_SFX, sfx_volume)
	_save_volume_setting("sfx_volume", sfx_volume)
	volume_changed.emit(BUS_SFX, sfx_volume)

## 设置UI音量
func set_ui_volume(volume: float) -> void:
	ui_volume = clampf(volume, 0.0, 1.0)
	_apply_bus_volume(BUS_UI, ui_volume)
	_save_volume_setting("ui_volume", ui_volume)
	volume_changed.emit(BUS_UI, ui_volume)

## 应用所有音量设置
func _apply_volume_settings() -> void:
	_apply_bus_volume(BUS_MASTER, master_volume)
	_apply_bus_volume(BUS_MUSIC, music_volume)
	_apply_bus_volume(BUS_SFX, sfx_volume)
	_apply_bus_volume(BUS_UI, ui_volume)

## 应用总线音量
func _apply_bus_volume(bus_name: String, volume: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		# 线性音量转换为分贝
		var db = linear_to_db(volume) if volume > 0 else -80.0
		AudioServer.set_bus_volume_db(bus_index, db)

## 保存音量设置
func _save_volume_setting(key: String, value: float) -> void:
	var save_system = _get_save_system()
	if save_system:
		save_system.save_setting(key, value)

## === 资源加载 ===

## 加载音乐
func _load_music(track_name: String) -> AudioStream:
	# 检查缓存
	if music_cache.has(track_name):
		return music_cache[track_name]

	# 加载资源
	var path = "res://audio/music/%s.ogg" % track_name
	if not ResourceLoader.exists(path):
		# 尝试 mp3
		path = "res://audio/music/%s.mp3" % track_name

	if ResourceLoader.exists(path):
		var stream = load(path)
		music_cache[track_name] = stream
		return stream

	return null

## 加载音效
func _load_sfx(sfx_name: String) -> AudioStream:
	# 检查缓存（包括程序化音效）
	if sfx_cache.has(sfx_name):
		return sfx_cache[sfx_name]

	# 尝试从文件系统加载
	var path = "res://audio/sfx/%s.wav" % sfx_name
	if not ResourceLoader.exists(path):
		# 尝试 ogg
		path = "res://audio/sfx/%s.ogg" % sfx_name

	if ResourceLoader.exists(path):
		var stream = load(path)
		sfx_cache[sfx_name] = stream
		return stream

	# 如果文件不存在，尝试生成程序化音效
	if AudioSynthesizer.PRESETS.has(sfx_name):
		var stream = AudioSynthesizer.generate_sound(sfx_name)
		if stream:
			sfx_cache[sfx_name] = stream
			return stream

	return null

## 预加载音效
func preload_sfx(sfx_names: Array) -> void:
	for sfx_name in sfx_names:
		_load_sfx(sfx_name)

	print("[AudioManager] Preloaded %d SFX" % sfx_names.size())

## 预加载音乐
func preload_music(track_names: Array) -> void:
	for track_name in track_names:
		_load_music(track_name)

	print("[AudioManager] Preloaded %d music tracks" % track_names.size())

## 清理缓存
func clear_cache() -> void:
	sfx_cache.clear()
	music_cache.clear()
	print("[AudioManager] Cache cleared")

## === 便捷方法 ===

## 播放常见游戏音效
func play_powerup_collect() -> void:
	play_sfx("powerup_collect", 0.0, randf_range(0.9, 1.1))

func play_obstacle_hit() -> void:
	play_sfx("obstacle_hit", 0.0, randf_range(0.95, 1.05))

func play_button_click() -> void:
	play_ui_sfx("button_click")

func play_button_hover() -> void:
	play_ui_sfx("button_hover")

func play_level_complete() -> void:
	play_sfx("level_complete")

func play_level_failed() -> void:
	play_sfx("level_failed")

func play_countdown() -> void:
	play_sfx("countdown")

func play_go() -> void:
	play_sfx("go")

## === 查询接口 ===

## 音乐是否正在播放
func is_music_playing() -> bool:
	return music_player.playing

## 获取当前音乐
func get_current_music() -> String:
	return current_music_track

## 获取主音量
func get_master_volume() -> float:
	return master_volume

## 获取音乐音量
func get_music_volume() -> float:
	return music_volume

## 获取音效音量
func get_sfx_volume() -> float:
	return sfx_volume

## 获取UI音量
func get_ui_volume() -> float:
	return ui_volume
