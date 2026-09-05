extends Node
class_name AudioSynthesizer
## 程序化音效合成器
## 生成简单的游戏音效，无需外部音频文件

## 音效预设配置
const PRESETS = {
	# UI音效
	"ui_hover": {
		"frequency": 800.0,
		"duration": 0.05,
		"wave": "sine",
		"volume": -10.0
	},
	"ui_click": {
		"frequency": 600.0,
		"duration": 0.08,
		"wave": "sine",
		"volume": -8.0
	},
	"ui_confirm": {
		"frequency": 1000.0,
		"duration": 0.12,
		"wave": "sine",
		"volume": -6.0
	},
	"ui_cancel": {
		"frequency": 400.0,
		"duration": 0.1,
		"wave": "sine",
		"volume": -8.0
	},

	# 游戏音效
	"jump": {
		"frequency": 600.0,
		"duration": 0.15,
		"wave": "square",
		"volume": -8.0,
		"pitch_sweep": 1.3  # 音调上升
	},
	"pickup": {
		"frequency": 1200.0,
		"duration": 0.1,
		"wave": "sine",
		"volume": -6.0,
		"pitch_sweep": 1.5
	},
	"enemy_defeat": {
		"frequency": 300.0,
		"duration": 0.2,
		"wave": "square",
		"volume": -5.0,
		"pitch_sweep": 0.5  # 音调下降
	},
	"hit": {
		"frequency": 200.0,
		"duration": 0.15,
		"wave": "noise",
		"volume": -4.0
	},
	"skill_ready": {
		"frequency": 1500.0,
		"duration": 0.2,
		"wave": "sine",
		"volume": -6.0,
		"pitch_sweep": 1.2
	},
	"star_appear": {
		"frequency": 2000.0,
		"duration": 0.15,
		"wave": "sine",
		"volume": -8.0
	},
	"rank_reveal": {
		"frequency": 800.0,
		"duration": 0.3,
		"wave": "sine",
		"volume": -4.0,
		"pitch_sweep": 1.4
	}
}

## 采样率
const SAMPLE_RATE = 44100.0

## 生成音效
static func generate_sound(preset_name: String) -> AudioStreamWAV:
	if not PRESETS.has(preset_name):
		push_warning("[AudioSynthesizer] Unknown preset: %s" % preset_name)
		return null

	var config = PRESETS[preset_name]
	return _generate_from_config(config)

## 从配置生成音效
static func _generate_from_config(config: Dictionary) -> AudioStreamWAV:
	var frequency: float = config.get("frequency", 440.0)
	var duration: float = config.get("duration", 0.1)
	var wave_type: String = config.get("wave", "sine")
	var volume_db: float = config.get("volume", -10.0)
	var pitch_sweep: float = config.get("pitch_sweep", 1.0)

	# 计算样本数
	var sample_count = int(SAMPLE_RATE * duration)
	var samples = PackedByteArray()

	# 生成波形数据
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / float(sample_count)

		# 音调扫描
		var current_freq = frequency * lerp(1.0, pitch_sweep, progress)

		# 生成样本
		var sample_value: float
		match wave_type:
			"sine":
				sample_value = sin(2.0 * PI * current_freq * t)
			"square":
				sample_value = 1.0 if sin(2.0 * PI * current_freq * t) > 0.0 else -1.0
			"triangle":
				var phase = fmod(current_freq * t, 1.0)
				sample_value = abs(phase - 0.5) * 4.0 - 1.0
			"noise":
				sample_value = randf() * 2.0 - 1.0
			_:
				sample_value = sin(2.0 * PI * current_freq * t)

		# 应用包络（淡入淡出）
		var envelope = _calculate_envelope(progress)
		sample_value *= envelope

		# 应用音量
		var volume_linear = db_to_linear(volume_db)
		sample_value *= volume_linear

		# 转换为16位整数
		var sample_int = int(clamp(sample_value * 32767.0, -32768.0, 32767.0))

		# 添加到样本数组（16位立体声）
		samples.append(sample_int & 0xFF)
		samples.append((sample_int >> 8) & 0xFF)
		samples.append(sample_int & 0xFF)  # 左声道
		samples.append((sample_int >> 8) & 0xFF)

	# 创建AudioStreamWAV
	var stream = AudioStreamWAV.new()
	stream.data = samples
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = true
	stream.mix_rate = int(SAMPLE_RATE)

	return stream

## 计算包络（ADSR简化版）
static func _calculate_envelope(progress: float) -> float:
	var attack = 0.05  # 5%淡入
	var release = 0.2  # 20%淡出

	if progress < attack:
		return progress / attack
	elif progress > (1.0 - release):
		return (1.0 - progress) / release
	else:
		return 1.0

## 生成所有预设音效
static func generate_all_presets() -> Dictionary:
	var sounds = {}
	for preset_name in PRESETS.keys():
		sounds[preset_name] = generate_sound(preset_name)
	return sounds

## 获取可用的预设列表
static func get_preset_names() -> Array:
	return PRESETS.keys()
