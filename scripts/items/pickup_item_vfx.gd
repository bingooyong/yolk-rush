extends Area3D
class_name PickupItemVFX
## 可拾取道具粒子效果组件
## 为游戏中的拾取物添加视觉反馈

signal item_picked_up(item_id: String)

## 配置
@export var item_id: String = "coin"
@export var item_value: int = 1
@export var enable_idle_glow: bool = true
@export var enable_pickup_flash: bool = true
@export var rotate_speed: float = 1.0

## 引用
var vfx_emitter: Node3D
var idle_effect: GPUParticles3D = null

## 状态
var is_picked_up: bool = false

func _ready() -> void:
	# 设置碰撞检测
	body_entered.connect(_on_body_entered)

	# 创建VFXEmitter
	_setup_vfx_emitter()

	# 启动空闲发光效果
	if enable_idle_glow:
		_play_idle_glow()

	print("[PickupItemVFX] Ready: %s" % item_id)

func _setup_vfx_emitter() -> void:
	var vfx_script = load("res://scripts/vfx/vfx_emitter.gd")
	if not vfx_script:
		push_warning("[PickupItemVFX] VFXEmitter script not found")
		return

	vfx_emitter = Node3D.new()
	vfx_emitter.name = "VFXEmitter"
	vfx_emitter.set_script(vfx_script)
	add_child(vfx_emitter)

func _process(delta: float) -> void:
	if is_picked_up:
		return

	# 旋转道具
	if rotate_speed > 0:
		rotate_y(rotate_speed * delta)

func _play_idle_glow() -> void:
	if not vfx_emitter:
		return

	await get_tree().process_frame

	# 持续的光环效果
	idle_effect = vfx_emitter.start_continuous_effect("pickup_sparkle", Vector3.UP, 0.5)

	print("[PickupItemVFX] Idle glow started")

func _on_body_entered(body: Node3D) -> void:
	if is_picked_up:
		return

	# 检查是否是玩家
	if not body.is_in_group("player") and not body.name.contains("Player"):
		return

	_pickup()

func _pickup() -> void:
	if is_picked_up:
		return

	is_picked_up = true

	# 停止空闲效果
	if idle_effect and vfx_emitter:
		vfx_emitter.stop_continuous_effect(idle_effect)
		idle_effect = null

	# 播放拾取特效
	if enable_pickup_flash and vfx_emitter:
		vfx_emitter.play_pickup_effect()

	# 播放音效
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("item_pickup")

	# 发送信号
	item_picked_up.emit(item_id)

	print("[PickupItemVFX] Picked up: %s (value: %d)" % [item_id, item_value])

	# 延迟销毁，让粒子播放完
	await get_tree().create_timer(0.3).timeout
	queue_free()

func _exit_tree() -> void:
	# 清理持续效果
	if idle_effect and vfx_emitter:
		vfx_emitter.stop_continuous_effect(idle_effect)
