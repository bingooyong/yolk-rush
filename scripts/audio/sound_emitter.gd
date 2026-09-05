extends Node
class_name SoundEmitter
## 音效发射器 - 用于游戏对象的音效播放

## 音效类型
enum SoundType {
	PLAYER_JUMP,
	PLAYER_LAND,
	PLAYER_HURT,
	PLAYER_DIE,
	POWERUP_COLLECT,
	OBSTACLE_HIT,
	CHECKPOINT_REACH,
	BUTTON_CLICK,
	BUTTON_HOVER,
	LEVEL_START,
	LEVEL_COMPLETE,
	LEVEL_FAILED,
	COUNTDOWN,
	GO,
}

## 音效映射
const SOUND_MAP = {
	SoundType.PLAYER_JUMP: "player_jump",
	SoundType.PLAYER_LAND: "player_land",
	SoundType.PLAYER_HURT: "player_hurt",
	SoundType.PLAYER_DIE: "player_die",
	SoundType.POWERUP_COLLECT: "powerup_collect",
	SoundType.OBSTACLE_HIT: "obstacle_hit",
	SoundType.CHECKPOINT_REACH: "checkpoint_reach",
	SoundType.BUTTON_CLICK: "button_click",
	SoundType.BUTTON_HOVER: "button_hover",
	SoundType.LEVEL_START: "level_start",
	SoundType.LEVEL_COMPLETE: "level_complete",
	SoundType.LEVEL_FAILED: "level_failed",
	SoundType.COUNTDOWN: "countdown",
	SoundType.GO: "go",
}

## 音效管理器引用
var audio_manager: AudioManager = null

## 父节点（用于3D音效）
var parent_node: Node = null

## 是否使用3D音效
@export var use_3d_sound: bool = false

## 音量偏移
@export var volume_offset: float = 0.0

## 音高随机范围
@export var pitch_randomness: float = 0.1

func _ready() -> void:
	parent_node = get_parent()
	_find_audio_manager()

## 查找音效管理器
func _find_audio_manager() -> void:
	audio_manager = get_node_or_null("/root/AudioManager")
	if not audio_manager:
		push_warning("[SoundEmitter] AudioManager not found")

## 播放音效
func play(sound_type: SoundType) -> void:
	if not audio_manager:
		return

	var sfx_name = SOUND_MAP.get(sound_type, "")
	if sfx_name.is_empty():
		return

	var pitch = 1.0 + randf_range(-pitch_randomness, pitch_randomness)

	# 3D音效
	if use_3d_sound and parent_node is Node3D:
		audio_manager.play_sfx_3d(sfx_name, parent_node.global_position, volume_offset)
	# 2D音效
	else:
		audio_manager.play_sfx(sfx_name, volume_offset, pitch)

## 便捷方法

func play_jump() -> void:
	play(SoundType.PLAYER_JUMP)

func play_land() -> void:
	play(SoundType.PLAYER_LAND)

func play_hurt() -> void:
	play(SoundType.PLAYER_HURT)

func play_die() -> void:
	play(SoundType.PLAYER_DIE)

func play_powerup_collect() -> void:
	play(SoundType.POWERUP_COLLECT)

func play_obstacle_hit() -> void:
	play(SoundType.OBSTACLE_HIT)

func play_checkpoint_reach() -> void:
	play(SoundType.CHECKPOINT_REACH)
