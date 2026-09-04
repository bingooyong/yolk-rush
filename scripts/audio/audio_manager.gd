extends Node
## Audio Manager: 程序化音效生成器（无需外部音频文件）

@export var master_volume: float = 0.5

func _ready() -> void:
	print("[AudioManager] 程序化音效系统已就绪")

## 播放攻击音效
func play_attack_sound(position: Vector3 = Vector3.ZERO) -> void:
	_play_procedural_sound(position, {
		"frequency": 300.0,
		"duration": 0.15,
		"type": "pulse",
		"volume": 0.6
	})

## 播放受击音效
func play_hit_sound(position: Vector3 = Vector3.ZERO) -> void:
	_play_procedural_sound(position, {
		"frequency": 200.0,
		"duration": 0.2,
		"type": "noise",
		"volume": 0.5
	})

## 播放连击音效
func play_combo_sound(combo_count: int, position: Vector3 = Vector3.ZERO) -> void:
	var pitch := 1.0 + (combo_count * 0.1)  # 连击越高音调越高
	_play_procedural_sound(position, {
		"frequency": 400.0 * pitch,
		"duration": 0.1,
		"type": "sine",
		"volume": 0.4
	})

## 播放死亡音效
func play_death_sound(position: Vector3 = Vector3.ZERO) -> void:
	_play_procedural_sound(position, {
		"frequency": 150.0,
		"duration": 0.5,
		"type": "sweep_down",
		"volume": 0.6
	})

## 内部：播放程序化音效
func _play_procedural_sound(pos: Vector3, config: Dictionary) -> void:
	var player := AudioStreamPlayer3D.new()
	player.position = pos
	player.max_distance = 20.0
	player.volume_db = linear_to_db(config.get("volume", 0.5) * master_volume)

	# 生成音频流
	var stream := _generate_audio_stream(config)
	player.stream = stream

	# 添加到场景
	get_tree().root.add_child(player)
	player.play()

	# 播放完后自动删除
	await player.finished
	player.queue_free()

## 生成音频流
func _generate_audio_stream(config: Dictionary) -> AudioStream:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = config.get("duration", 0.2)

	# 注意：AudioStreamGenerator 需要实时填充数据
	# 这里我们使用 AudioStreamRandomPitch 包装一个简单的正弦波
	# 实际项目中可以用 AudioStreamPlayer 配合预生成的 PCM 数据

	# 简化方案：使用空的 AudioStreamWAV
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 44100
	wav.stereo = false

	var sample_count := int(44100 * config.get("duration", 0.2))
	var data := PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit = 2 bytes per sample

	var frequency := config.get("frequency", 440.0)
	var type := config.get("type", "sine")

	for i in sample_count:
		var t := float(i) / 44100.0
		var value := 0.0

		match type:
			"sine":
				value = sin(t * frequency * TAU)
			"pulse":
				value = 1.0 if sin(t * frequency * TAU) > 0 else -1.0
			"noise":
				value = randf_range(-1.0, 1.0)
			"sweep_down":
				var freq := frequency * (1.0 - t / config.get("duration", 0.5))
				value = sin(t * freq * TAU)

		# 应用包络（淡入淡出）
		var envelope := 1.0
		if t < 0.01:
			envelope = t / 0.01
		elif t > config.get("duration", 0.2) - 0.05:
			envelope = (config.get("duration", 0.2) - t) / 0.05

		value *= envelope * 0.3  # 降低音量避免削波

		# 转换为 16-bit PCM
		var sample := int(clamp(value * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample)

	wav.data = data
	return wav
