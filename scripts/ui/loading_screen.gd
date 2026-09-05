extends Control
class_name LoadingScreen
## 加载界面

signal loading_complete()

## 节点引用
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var loading_label: Label = $CenterContainer/VBoxContainer/LoadingLabel
@onready var tip_label: Label = $CenterContainer/VBoxContainer/TipLabel
@onready var spinner: TextureRect = $CenterContainer/VBoxContainer/Spinner

## 加载进度
var loading_progress: float = 0.0
var loading_speed: float = 0.5  # 模拟加载速度

## 提示文本列表
var loading_tips: Array[String] = [
	"提示: 使用冲刺可以快速躲避障碍",
	"提示: 收集金币可以获得额外分数",
	"提示: 技能可以对多个敌人造成伤害",
	"提示: 护盾可以抵挡一次伤害",
	"提示: 合理使用道具可以更容易通关",
	"提示: 注意观察敌人的移动规律",
	"提示: 跳跃时可以改变方向",
	"提示: 完成时间越短，分数越高"
]

func _ready() -> void:
	print("[LoadingScreen] Initializing...")

	# 如果节点不存在，创建它们
	if not has_node("CenterContainer"):
		_create_ui()

	# 随机选择提示
	if tip_label:
		tip_label.text = loading_tips[randi() % loading_tips.size()]

	print("[LoadingScreen] Initialized")

func _process(delta: float) -> void:
	if loading_progress < 1.0:
		# 模拟加载进度
		loading_progress += delta * loading_speed
		loading_progress = min(loading_progress, 1.0)

		# 更新进度条
		if progress_bar:
			progress_bar.value = loading_progress * 100

		# 更新文本
		if loading_label:
			loading_label.text = "加载中... %.0f%%" % (loading_progress * 100)

		# 旋转加载图标
		if spinner:
			spinner.rotation += delta * 3.0

		# 加载完成
		if loading_progress >= 1.0:
			_on_loading_complete()

## 创建UI
func _create_ui() -> void:
	# 背景
	var background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.15)
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	add_child(background)

	# 中心容器
	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	# 垂直容器
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.custom_minimum_size = Vector2(400, 0)
	center.add_child(vbox)

	# 加载标签
	loading_label = Label.new()
	loading_label.name = "LoadingLabel"
	loading_label.text = "加载中... 0%"
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 32)
	loading_label.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(loading_label)

	# 间距
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)

	# 加载图标（旋转的圆圈）
	spinner = TextureRect.new()
	spinner.name = "Spinner"
	spinner.custom_minimum_size = Vector2(64, 64)
	spinner.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	spinner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# TODO: 设置实际的旋转图标纹理
	vbox.add_child(spinner)

	# 间距
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)

	# 进度条
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(400, 30)
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.show_percentage = false
	vbox.add_child(progress_bar)

	# 间距
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer3)

	# 提示标签
	tip_label = Label.new()
	tip_label.name = "TipLabel"
	tip_label.text = "提示: 加载中..."
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 18)
	tip_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(tip_label)

## 加载完成
func _on_loading_complete() -> void:
	print("[LoadingScreen] Loading complete")

	# 淡出动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		loading_complete.emit()
		queue_free()
	)

## 开始加载
func start_loading(duration: float = 2.0) -> void:
	loading_progress = 0.0
	loading_speed = 1.0 / duration

	if progress_bar:
		progress_bar.value = 0

	if loading_label:
		loading_label.text = "加载中... 0%"

	# 随机选择新的提示
	if tip_label:
		tip_label.text = loading_tips[randi() % loading_tips.size()]

## 立即完成加载
func finish_loading() -> void:
	loading_progress = 1.0

	if progress_bar:
		progress_bar.value = 100

	if loading_label:
		loading_label.text = "加载完成!"
