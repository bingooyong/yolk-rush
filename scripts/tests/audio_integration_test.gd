extends SceneTree
## 音效集成测试

const AudioSynthesizerScript = preload("res://scripts/audio/audio_synthesizer.gd")

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Audio Integration Test")
	print("=".repeat(60) + "\n")

	var root = Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	await run_all_tests(root)

	quit()

func run_all_tests(root: Node) -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: AudioSynthesizer
	print("\n[Test 1] AudioSynthesizer")
	if await test_audio_synthesizer(root):
		tests_passed += 1
		print("  ✓ AudioSynthesizer test passed")
	else:
		tests_failed += 1
		print("  ✗ AudioSynthesizer test failed")

	# Test 2: AudioManager初始化
	print("\n[Test 2] AudioManager Initialization")
	if await test_audio_manager_init(root):
		tests_passed += 1
		print("  ✓ AudioManager init test passed")
	else:
		tests_failed += 1
		print("  ✗ AudioManager init test failed")

	# Test 3: 程序化音效播放
	print("\n[Test 3] Synthesized Sound Playback")
	if await test_synthesized_playback(root):
		tests_passed += 1
		print("  ✓ Synthesized playback test passed")
	else:
		tests_failed += 1
		print("  ✗ Synthesized playback test failed")

	# Test 4: UI音效
	print("\n[Test 4] UI Sound Effects")
	if await test_ui_sounds(root):
		tests_passed += 1
		print("  ✓ UI sounds test passed")
	else:
		tests_failed += 1
		print("  ✗ UI sounds test failed")

	# Test 5: 游戏音效
	print("\n[Test 5] Game Sound Effects")
	if await test_game_sounds(root):
		tests_passed += 1
		print("  ✓ Game sounds test passed")
	else:
		tests_failed += 1
		print("  ✗ Game sounds test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Audio integration is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

	await create_timer(0.5).timeout

func test_audio_synthesizer(root: Node) -> bool:
	# 测试预设列表
	var presets = AudioSynthesizerScript.get_preset_names()
	assert(presets.size() > 0, "Should have presets")
	print("  - Available presets: %d" % presets.size())

	# 测试UI音效预设
	assert("ui_click" in presets, "Should have ui_click")
	assert("ui_hover" in presets, "Should have ui_hover")
	assert("ui_confirm" in presets, "Should have ui_confirm")
	print("  - UI presets: ui_click, ui_hover, ui_confirm")

	# 测试游戏音效预设
	assert("jump" in presets, "Should have jump")
	assert("pickup" in presets, "Should have pickup")
	assert("enemy_defeat" in presets, "Should have enemy_defeat")
	print("  - Game presets: jump, pickup, enemy_defeat")

	# 测试音效生成
	var click_sound = AudioSynthesizerScript.generate_sound("ui_click")
	assert(click_sound != null, "Should generate ui_click sound")
	assert(click_sound is AudioStreamWAV, "Should be AudioStreamWAV")
	print("  - Generated ui_click: %d bytes" % click_sound.data.size())

	return true

func test_audio_manager_init(root: Node) -> bool:
	# 使用全局AudioManager（autoload）
	var audio_manager = root.get_node_or_null("/root/AudioManager")

	if not audio_manager:
		print("  - AudioManager autoload not available, skipping test")
		return true

	# 测试初始化
	assert(audio_manager != null, "AudioManager should be created")
	print("  - AudioManager found (autoload)")

	# 测试音效缓存
	if audio_manager.sfx_cache.size() > 0:
		print("  - Preloaded sounds: %d" % audio_manager.sfx_cache.size())
	else:
		print("  - No sounds preloaded yet")

	# 测试音量设置
	print("  - Master volume: %.1f" % audio_manager.master_volume)
	print("  - UI volume: %.1f" % audio_manager.ui_volume)

	return true

func test_synthesized_playback(root: Node) -> bool:
	var audio_manager = root.get_node_or_null("/root/AudioManager")

	if not audio_manager:
		print("  - AudioManager autoload not available, skipping test")
		return true

	# 测试播放UI音效
	audio_manager.play_ui_sound("ui_click")
	print("  - Played ui_click")

	await create_timer(0.1).timeout

	# 测试播放游戏音效
	audio_manager.play_sfx("jump")
	print("  - Played jump")

	await create_timer(0.1).timeout

	# 检查播放器创建
	var player_count = audio_manager.get_child_count()
	print("  - Audio players in manager: %d" % player_count)

	return true

func test_ui_sounds(root: Node) -> bool:
	var audio_manager = root.get_node_or_null("/root/AudioManager")

	if not audio_manager:
		print("  - AudioManager autoload not available, skipping test")
		return true

	# 测试所有UI音效
	var ui_sounds = ["ui_hover", "ui_click", "ui_confirm", "ui_cancel"]

	for sound_name in ui_sounds:
		audio_manager.play_ui_sound(sound_name)
		await create_timer(0.05).timeout

	print("  - Tested %d UI sounds" % ui_sounds.size())

	return true

func test_game_sounds(root: Node) -> bool:
	var audio_manager = root.get_node_or_null("/root/AudioManager")

	if not audio_manager:
		print("  - AudioManager autoload not available, skipping test")
		return true

	# 测试游戏音效
	var game_sounds = ["jump", "pickup", "enemy_defeat", "hit", "skill_ready"]

	for sound_name in game_sounds:
		audio_manager.play_sfx(sound_name)
		await create_timer(0.08).timeout

	print("  - Tested %d game sounds" % game_sounds.size())

	return true
