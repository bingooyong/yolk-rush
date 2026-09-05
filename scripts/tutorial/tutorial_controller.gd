extends Node
class_name TutorialController
## 教学控制器
## 管理教学流程和提示显示

## 信号
signal tutorial_step_completed(step_id: String)
signal tutorial_completed()
signal tutorial_message_shown(message: String)

## 教学步骤状态
enum StepState {
	WAITING,      ## 等待触发
	ACTIVE,       ## 进行中
	COMPLETED     ## 已完成
}

## 当前教学配置
var tutorial_config: Dictionary = {}

## 当前步骤
var current_step_index: int = 0

## 步骤状态
var step_states: Dictionary = {}

## 已完成的步骤
var completed_steps: Array[String] = []

## 是否启用教学
var tutorial_enabled: bool = true

## UI引用
var tutorial_ui: Control = null

## 玩家引用
var player: Node = null

func _ready() -> void:
	print("[TutorialController] Initializing...")

	# 查找UI
	tutorial_ui = _find_tutorial_ui()

	if not tutorial_ui:
		push_warning("[TutorialController] Tutorial UI not found")

## 加载教学配置
func load_tutorial(config: Dictionary) -> void:
	tutorial_config = config

	if not config.has("tutorial_steps"):
		push_warning("[TutorialController] No tutorial steps in config")
		return

	# 初始化步骤状态
	for step in config.tutorial_steps:
		step_states[step.id] = StepState.WAITING

	current_step_index = 0
	completed_steps.clear()

	print("[TutorialController] Loaded %d tutorial steps" % config.tutorial_steps.size())

## 开始教学
func start_tutorial() -> void:
	if not tutorial_enabled:
		return

	if tutorial_config.is_empty():
		push_warning("[TutorialController] Tutorial config not loaded")
		return

	print("[TutorialController] Starting tutorial")

	# 触发第一个步骤
	_check_and_trigger_steps("start")

## 设置玩家引用
func set_player(player_node: Node) -> void:
	player = player_node

	if player:
		# 连接玩家事件
		_connect_player_events()

## 连接玩家事件
func _connect_player_events() -> void:
	if not player:
		return

	# 连接移动事件
	if player.has_signal("moved"):
		player.moved.connect(_on_player_moved)

	# 连接跳跃事件
	if player.has_signal("jumped"):
		player.jumped.connect(_on_player_jumped)

	# 连接冲刺事件
	if player.has_signal("dashed"):
		player.dashed.connect(_on_player_dashed)

	# 连接攻击事件
	if player.has_signal("attacked"):
		player.attacked.connect(_on_player_attacked)

	# 连接技能事件
	if player.has_signal("skill_used"):
		player.skill_used.connect(_on_player_skill_used)

## 检查点触发
func trigger_checkpoint(checkpoint_id: String) -> void:
	if not tutorial_enabled:
		return

	print("[TutorialController] Checkpoint triggered: %s" % checkpoint_id)
	_check_and_trigger_steps("checkpoint:" + checkpoint_id)

## 检查并触发步骤
func _check_and_trigger_steps(trigger: String) -> void:
	if tutorial_config.is_empty():
		return

	for step in tutorial_config.tutorial_steps:
		# 跳过已完成的步骤
		if step.id in completed_steps:
			continue

		# 检查触发条件
		if step.trigger == trigger:
			_activate_step(step)

## 激活教学步骤
func _activate_step(step: Dictionary) -> void:
	print("[TutorialController] Activating step: %s" % step.id)

	step_states[step.id] = StepState.ACTIVE

	# 显示提示消息
	if step.has("message"):
		show_message(step.message)

	# 如果有持续时间，自动完成
	if step.has("duration") and step.duration > 0:
		await get_tree().create_timer(step.duration).timeout
		complete_step(step.id)

	# 如果需要等待玩家动作，保持激活状态
	# 由玩家事件回调来完成

## 显示教学消息
func show_message(message: String) -> void:
	print("[TutorialController] Message: %s" % message)

	if tutorial_ui and tutorial_ui.has_method("show_tutorial_message"):
		tutorial_ui.show_tutorial_message(message)

	tutorial_message_shown.emit(message)

## 完成教学步骤
func complete_step(step_id: String) -> void:
	if step_id in completed_steps:
		return

	print("[TutorialController] Completed step: %s" % step_id)

	step_states[step_id] = StepState.COMPLETED
	completed_steps.append(step_id)

	tutorial_step_completed.emit(step_id)

	# 检查是否所有步骤都完成
	if completed_steps.size() == tutorial_config.tutorial_steps.size():
		_complete_tutorial()

## 完成整个教学
func _complete_tutorial() -> void:
	print("[TutorialController] Tutorial completed!")
	tutorial_completed.emit()

	if tutorial_ui and tutorial_ui.has_method("hide_tutorial_ui"):
		tutorial_ui.hide_tutorial_ui()

## 查找当前激活的步骤
func get_active_step() -> Dictionary:
	if tutorial_config.is_empty():
		return {}

	for step in tutorial_config.tutorial_steps:
		if step_states.get(step.id, StepState.WAITING) == StepState.ACTIVE:
			return step

	return {}

## 跳过教学
func skip_tutorial() -> void:
	print("[TutorialController] Tutorial skipped")
	tutorial_enabled = false

	if tutorial_ui and tutorial_ui.has_method("hide_tutorial_ui"):
		tutorial_ui.hide_tutorial_ui()

	tutorial_completed.emit()

## 查找教学UI
func _find_tutorial_ui() -> Control:
	# 尝试从场景树查找
	var tree = get_tree()
	if tree and tree.root:
		var ui = tree.root.find_child("TutorialUI", true, false)
		if ui:
			return ui

	return null

## 玩家事件回调
func _on_player_moved() -> void:
	_check_action_completion("player_moved")

func _on_player_jumped() -> void:
	_check_action_completion("player_jumped")

func _on_player_dashed() -> void:
	_check_action_completion("player_dashed")

func _on_player_attacked() -> void:
	_check_action_completion("player_attacked")

func _on_player_skill_used(_skill_id: String) -> void:
	_check_action_completion("player_used_skill")

## 检查动作完成
func _check_action_completion(action: String) -> void:
	var active_step = get_active_step()

	if active_step.is_empty():
		return

	# 检查是否等待这个动作
	if active_step.has("wait_for") and active_step.wait_for == action:
		complete_step(active_step.id)

		# 检查下一个步骤
		_check_next_step(action)

## 检查并触发下一个步骤
func _check_next_step(last_action: String) -> void:
	if tutorial_config.is_empty():
		return

	# 查找以这个动作为触发条件的步骤
	for step in tutorial_config.tutorial_steps:
		if step.id in completed_steps:
			continue

		if step.has("trigger") and step.trigger == last_action:
			_activate_step(step)
			break

## 获取教学进度
func get_progress() -> float:
	if tutorial_config.is_empty():
		return 0.0

	var total_steps = tutorial_config.tutorial_steps.size()
	if total_steps == 0:
		return 0.0

	return float(completed_steps.size()) / float(total_steps)

## 获取教学统计
func get_statistics() -> Dictionary:
	return {
		"total_steps": tutorial_config.tutorial_steps.size() if not tutorial_config.is_empty() else 0,
		"completed_steps": completed_steps.size(),
		"progress": get_progress() * 100.0,
		"enabled": tutorial_enabled
	}

## 是否完成教学
func is_completed() -> bool:
	if tutorial_config.is_empty():
		return true

	return completed_steps.size() == tutorial_config.tutorial_steps.size()
