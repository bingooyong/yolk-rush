extends Node
class_name AudioManager
## 音效管理器
## Phase 6: 音效系统

## 音效类型
enum SFXType {
	FOOTSTEP,
	JUMP,
	LAND,
	ATTACK_LIGHT,
	ATTACK_HEAVY,
	SKILL_CAST,
	HIT_RECEIVED,
	DEATH,
	UI_CLICK,
	UI_HOVER,
}

## 音乐类型
enum MusicType {
	MENU,
	BATTLE,
	VICTORY,
	DEFEAT,
}

## 音效音量
@export var sfx_volume: float = 0.8
@export var music_volume: float = 0.6

## 音频总线
const BUS_MASTER := "Master"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"

## 当前播放的音乐
var current_music: AudioStreamPlayer = null

## 音效池（避免重复创建）
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players := 32

func _ready() -> void:
	# 预创建音效播放器池
	for i in range(max_sfx_players):
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		sfx_players.append(player)

	# 应用音量设置
	_apply_volume_settings()

## 播放音效
func play_sfx(type: SFXType, pitch_variation: float = 0.1) -> void:
	var stream := _get_sfx_stream(type)
	if not stream:
		return

	# 从池中获取空闲播放器
	var player := _get_free_player()
	if not player:
		return

	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume)
	player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	player.play()

## 播放音效（3D空间）
func play_sfx_3d(type: SFXType, position: Vector3, parent: Node3D) -> void:
	var stream := _get_sfx_stream(type)
	if not stream:
		return

	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = BUS_SFX
	player.volume_db = linear_to_db(sfx_volume)
	player.position = position
	player.max_distance = 20.0
	player.attenuation_filter_cutoff_hz = 5000.0

	parent.add_child(player)
	player.play()

	# 播放完毕后删除
	await player.finished
	player.queue_free()

## 播放音乐
func play_music(type: MusicType, fade_duration: float = 1.0) -> void:
	var stream := _get_music_stream(type)
	if not stream:
		return

	# 如果已经在播放相同音乐，不重复播放
	if current_music and current_music.stream == stream:
		return

	# 淡出当前音乐
	if current_music:
		var fade_out := create_tween()
		fade_out.tween_property(current_music, "volume_db", -80.0, fade_duration)
		await fade_out.finished
		current_music.stop()
		current_music.queue_free()

	# 创建新音乐播放器
	current_music = AudioStreamPlayer.new()
	current_music.stream = stream
	current_music.bus = BUS_MUSIC
	current_music.volume_db = -80.0  # 从静音开始
	add_child(current_music)
	current_music.play()

	# 淡入新音乐
	var fade_in := create_tween()
	fade_in.tween_property(current_music, "volume_db", linear_to_db(music_volume), fade_duration)

## 停止音乐
func stop_music(fade_duration: float = 1.0) -> void:
	if not current_music:
		return

	var fade_out := create_tween()
	fade_out.tween_property(current_music, "volume_db", -80.0, fade_duration)
	await fade_out.finished

	current_music.stop()
	current_music.queue_free()
	current_music = null

## 设置音效音量
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(BUS_SFX),
		linear_to_db(sfx_volume)
	)

## 设置音乐音量
func set_music_volume(volume: float) -> void:
	music_volume = clampf(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(BUS_MUSIC),
		linear_to_db(music_volume)
	)
	if current_music:
		current_music.volume_db = linear_to_db(music_volume)

## 获取空闲播放器
func _get_free_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	# 如果都在播放，返回第一个（会被打断）
	return sfx_players[0]

## 应用音量设置
func _apply_volume_settings() -> void:
	set_sfx_volume(sfx_volume)
	set_music_volume(music_volume)

## 获取音效资源（占位符，等待真实音频文件）
func _get_sfx_stream(type: SFXType) -> AudioStream:
	# TODO: 加载真实音频文件
	# 目前返回 null，Phase 6 会补充音频资源
	match type:
		SFXType.FOOTSTEP:
			return _load_audio("res://audio/sfx/footstep.ogg")
		SFXType.JUMP:
			return _load_audio("res://audio/sfx/jump.ogg")
		SFXType.LAND:
			return _load_audio("res://audio/sfx/land.ogg")
		SFXType.ATTACK_LIGHT:
			return _load_audio("res://audio/sfx/attack_light.ogg")
		SFXType.ATTACK_HEAVY:
			return _load_audio("res://audio/sfx/attack_heavy.ogg")
		SFXType.SKILL_CAST:
			return _load_audio("res://audio/sfx/skill_cast.ogg")
		SFXType.HIT_RECEIVED:
			return _load_audio("res://audio/sfx/hit_received.ogg")
		SFXType.DEATH:
			return _load_audio("res://audio/sfx/death.ogg")
		SFXType.UI_CLICK:
			return _load_audio("res://audio/sfx/ui_click.ogg")
		SFXType.UI_HOVER:
			return _load_audio("res://audio/sfx/ui_hover.ogg")
	return null

## 获取音乐资源（占位符）
func _get_music_stream(type: MusicType) -> AudioStream:
	# TODO: 加载真实音乐文件
	match type:
		MusicType.MENU:
			return _load_audio("res://audio/music/menu.ogg")
		MusicType.BATTLE:
			return _load_audio("res://audio/music/battle.ogg")
		MusicType.VICTORY:
			return _load_audio("res://audio/music/victory.ogg")
		MusicType.DEFEAT:
			return _load_audio("res://audio/music/defeat.ogg")
	return null

## 加载音频文件（带错误处理）
func _load_audio(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		push_warning("[AudioManager] Audio file not found: %s" % path)
		return null
	return load(path) as AudioStream
