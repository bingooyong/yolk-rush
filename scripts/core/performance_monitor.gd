extends Node
class_name PerformanceMonitor
## 性能监控器
## 监控 FPS、内存、粒子和音效，自动优化性能

signal performance_warning(category: String, value: float)
signal performance_critical(category: String, value: float)

## 性能统计
var performance_stats: Dictionary = {
	"fps": 60.0,
	"frame_time": 0.0,
	"memory_used": 0.0,
	"active_particles": 0,
	"active_sounds": 0,
	"draw_calls": 0
}

## 性能阈值
var thresholds: Dictionary = {
	"fps_warning": 45.0,
	"fps_critical": 30.0,
	"memory_warning": 500.0,  # MB
	"memory_critical": 800.0,  # MB
	"particles_warning": 500,
	"particles_critical": 1000,
	"sounds_warning": 20,
	"sounds_critical": 30
}

## 监控设置
@export var enable_monitoring: bool = true
@export var update_interval: float = 1.0  # 秒
@export var auto_optimize: bool = true

## 内部状态
var time_since_update: float = 0.0
var frame_count: int = 0
var accumulated_frame_time: float = 0.0

## 优化状态
var optimization_level: int = 0  # 0=无, 1=轻度, 2=中度, 3=重度

## 管理器引用
var particle_manager: Node = null
var audio_manager: Node = null

func _ready() -> void:
	_find_managers()
	print("[PerformanceMonitor] Initialized")

func _process(delta: float) -> void:
	if not enable_monitoring:
		return

	# 累积帧时间
	frame_count += 1
	accumulated_frame_time += delta
	time_since_update += delta

	# 定期更新统计
	if time_since_update >= update_interval:
		_update_stats()
		_check_thresholds()

		if auto_optimize:
			_auto_optimize()

		time_since_update = 0.0
		frame_count = 0
		accumulated_frame_time = 0.0

## 查找管理器
func _find_managers() -> void:
	var tree = get_tree()
	if tree and tree.root:
		particle_manager = tree.root.find_child("ParticleEffectManager", true, false)

		if has_node("/root/AudioManager"):
			audio_manager = get_node("/root/AudioManager")

## 更新性能统计
func _update_stats() -> void:
	# FPS
	if accumulated_frame_time > 0:
		performance_stats.fps = frame_count / accumulated_frame_time
		performance_stats.frame_time = accumulated_frame_time / frame_count * 1000.0  # ms

	# 内存使用
	performance_stats.memory_used = OS.get_static_memory_usage() / 1048576.0  # 转换为 MB

	# 粒子数量
	if particle_manager:
		performance_stats.active_particles = particle_manager.get_active_count()

	# 音效数量
	if audio_manager and audio_manager.has_method("get_active_sound_count"):
		performance_stats.active_sounds = audio_manager.get_active_sound_count()

	# 渲染统计
	performance_stats.draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)

## 检查性能阈值
func _check_thresholds() -> void:
	# FPS 检查
	if performance_stats.fps < thresholds.fps_critical:
		performance_critical.emit("fps", performance_stats.fps)
	elif performance_stats.fps < thresholds.fps_warning:
		performance_warning.emit("fps", performance_stats.fps)

	# 内存检查
	if performance_stats.memory_used > thresholds.memory_critical:
		performance_critical.emit("memory", performance_stats.memory_used)
	elif performance_stats.memory_used > thresholds.memory_warning:
		performance_warning.emit("memory", performance_stats.memory_used)

	# 粒子检查
	if performance_stats.active_particles > thresholds.particles_critical:
		performance_critical.emit("particles", performance_stats.active_particles)
	elif performance_stats.active_particles > thresholds.particles_warning:
		performance_warning.emit("particles", performance_stats.active_particles)

	# 音效检查
	if performance_stats.active_sounds > thresholds.sounds_critical:
		performance_critical.emit("sounds", performance_stats.active_sounds)
	elif performance_stats.active_sounds > thresholds.sounds_warning:
		performance_warning.emit("sounds", performance_stats.active_sounds)

## 自动优化
func _auto_optimize() -> void:
	var current_fps = performance_stats.fps

	# 根据 FPS 决定优化等级
	if current_fps < thresholds.fps_critical:
		_apply_optimization(3)  # 重度优化
	elif current_fps < thresholds.fps_warning:
		_apply_optimization(2)  # 中度优化
	elif current_fps < 55.0:
		_apply_optimization(1)  # 轻度优化
	elif current_fps >= 58.0 and optimization_level > 0:
		_apply_optimization(0)  # 恢复正常

## 应用优化
func _apply_optimization(level: int) -> void:
	if level == optimization_level:
		return

	var old_level = optimization_level
	optimization_level = level

	match level:
		0:
			_restore_normal_quality()
		1:
			_apply_light_optimization()
		2:
			_apply_medium_optimization()
		3:
			_apply_heavy_optimization()

	print("[PerformanceMonitor] Optimization: %d -> %d (FPS: %.1f)" % [old_level, level, performance_stats.fps])

## 恢复正常质量
func _restore_normal_quality() -> void:
	# 粒子系统
	if particle_manager and particle_manager.has_method("set_quality_level"):
		particle_manager.set_quality_level(2)  # 高质量

	# 音效系统
	if audio_manager and audio_manager.has_method("set_max_sounds"):
		audio_manager.set_max_sounds(32)

## 轻度优化
func _apply_light_optimization() -> void:
	# 减少粒子质量
	if particle_manager and particle_manager.has_method("set_quality_level"):
		particle_manager.set_quality_level(1)  # 中质量

	# 限制音效数量
	if audio_manager and audio_manager.has_method("set_max_sounds"):
		audio_manager.set_max_sounds(24)

## 中度优化
func _apply_medium_optimization() -> void:
	# 进一步减少粒子
	if particle_manager and particle_manager.has_method("set_quality_level"):
		particle_manager.set_quality_level(0)  # 低质量

	# 进一步限制音效
	if audio_manager and audio_manager.has_method("set_max_sounds"):
		audio_manager.set_max_sounds(16)

	# 停止一些非必要粒子
	if particle_manager and particle_manager.has_method("stop_ambient_effects"):
		particle_manager.stop_ambient_effects()

## 重度优化
func _apply_heavy_optimization() -> void:
	# 最低粒子质量
	if particle_manager:
		if particle_manager.has_method("set_quality_level"):
			particle_manager.set_quality_level(0)
		if particle_manager.has_method("stop_all_effects"):
			particle_manager.stop_all_effects()

	# 最少音效
	if audio_manager and audio_manager.has_method("set_max_sounds"):
		audio_manager.set_max_sounds(8)

## 获取性能统计
func get_stats() -> Dictionary:
	return performance_stats.duplicate()

## 获取性能等级字符串
func get_performance_level() -> String:
	var fps = performance_stats.fps

	if fps >= 55.0:
		return "优秀"
	elif fps >= 45.0:
		return "良好"
	elif fps >= 30.0:
		return "一般"
	else:
		return "差"

## 获取优化等级字符串
func get_optimization_level_string() -> String:
	match optimization_level:
		0: return "无优化"
		1: return "轻度优化"
		2: return "中度优化"
		3: return "重度优化"
		_: return "未知"

## 强制垃圾回收
func force_garbage_collection() -> void:
	# Godot 4 不再有显式的 GC 控制
	# 但可以通过其他方式减少内存
	if particle_manager and particle_manager.has_method("cleanup_pool"):
		particle_manager.cleanup_pool()

	print("[PerformanceMonitor] Forced cleanup")

## 重置统计
func reset_stats() -> void:
	performance_stats = {
		"fps": 60.0,
		"frame_time": 0.0,
		"memory_used": 0.0,
		"active_particles": 0,
		"active_sounds": 0,
		"draw_calls": 0
	}

	time_since_update = 0.0
	frame_count = 0
	accumulated_frame_time = 0.0

## 生成性能报告
func generate_report() -> String:
	var report = "=== Performance Report ===\n"
	report += "FPS: %.1f (%.2fms)\n" % [performance_stats.fps, performance_stats.frame_time]
	report += "Memory: %.1f MB\n" % performance_stats.memory_used
	report += "Active Particles: %d\n" % performance_stats.active_particles
	report += "Active Sounds: %d\n" % performance_stats.active_sounds
	report += "Draw Calls: %d\n" % performance_stats.draw_calls
	report += "Performance Level: %s\n" % get_performance_level()
	report += "Optimization: %s\n" % get_optimization_level_string()
	report += "========================="

	return report
