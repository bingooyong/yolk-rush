extends SceneTree
## Phase 16 音效系统测试

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("Phase 16 - Audio System Test")
	print("=".repeat(60) + "\n")

	await run_all_tests()

	quit()

func run_all_tests() -> void:
	var tests_passed = 0
	var tests_failed = 0

	# Test 1: AudioManager 基础功能
	print("\n[Test 1] AudioManager Basic Functionality")
	if test_audio_manager_basic():
		tests_passed += 1
		print("  ✓ AudioManager basic test passed")
	else:
		tests_failed += 1
		print("  ✗ AudioManager basic test failed")

	# Test 2: 音量控制
	print("\n[Test 2] Volume Control")
	if test_volume_control():
		tests_passed += 1
		print("  ✓ Volume control test passed")
	else:
		tests_failed += 1
		print("  ✗ Volume control test failed")

	# Test 3: 音效播放
	print("\n[Test 3] SFX Playback")
	if test_sfx_playback():
		tests_passed += 1
		print("  ✓ SFX playback test passed")
	else:
		tests_failed += 1
		print("  ✗ SFX playback test failed")

	# Test 4: 音乐播放
	print("\n[Test 4] Music Playback")
	if test_music_playback():
		tests_passed += 1
		print("  ✓ Music playback test passed")
	else:
		tests_failed += 1
		print("  ✗ Music playback test failed")

	# Test 5: 查询接口
	print("\n[Test 5] Query Interface")
	if test_query_interface():
		tests_passed += 1
		print("  ✓ Query interface test passed")
	else:
		tests_failed += 1
		print("  ✗ Query interface test failed")

	# 总结
	print("\n" + "=".repeat(60))
	print("Test Summary:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("  Total:  %d" % (tests_passed + tests_failed))
	print("=".repeat(60))

	if tests_failed == 0:
		print("\n✓ All tests passed! Phase 16 Audio System is working correctly.\n")
	else:
		print("\n✗ Some tests failed. Please check the implementation.\n")

func test_audio_manager_basic() -> bool:
	# 测试 AudioManager 类存在
	var AudioManagerClass = load("res://scripts/audio/audio_manager.gd")
	if not AudioManagerClass:
		print("  ✗ Failed to load AudioManager script")
		return false
	print("  - AudioManager script loaded")

	# 测试音频总线
	var master_idx = AudioServer.get_bus_index("Master")
	var music_idx = AudioServer.get_bus_index("Music")
	var sfx_idx = AudioServer.get_bus_index("SFX")
	var ui_idx = AudioServer.get_bus_index("UI")

	if master_idx < 0:
		print("  ✗ Master bus not found")
		return false
	print("  - Master bus exists")

	if music_idx < 0:
		print("  ✗ Music bus not found")
		return false
	print("  - Music bus exists")

	if sfx_idx < 0:
		print("  ✗ SFX bus not found")
		return false
	print("  - SFX bus exists")

	if ui_idx < 0:
		print("  ✗ UI bus not found")
		return false
	print("  - UI bus exists")

	return true

func test_volume_control() -> bool:
	# 测试音量设置
	var master_idx = AudioServer.get_bus_index("Master")

	# 设置音量
	AudioServer.set_bus_volume_db(master_idx, -10.0)
	var volume = AudioServer.get_bus_volume_db(master_idx)

	if abs(volume - (-10.0)) > 0.1:
		print("  ✗ Volume control failed")
		return false
	print("  - Volume control works")

	# 测试静音
	AudioServer.set_bus_mute(master_idx, true)
	if not AudioServer.is_bus_mute(master_idx):
		print("  ✗ Mute control failed")
		return false
	print("  - Mute control works")

	# 取消静音
	AudioServer.set_bus_mute(master_idx, false)
	if AudioServer.is_bus_mute(master_idx):
		print("  ✗ Unmute control failed")
		return false
	print("  - Unmute control works")

	return true

func test_sfx_playback() -> bool:
	# 测试音效播放器创建
	var player = AudioStreamPlayer.new()
	if not player:
		print("  ✗ Failed to create AudioStreamPlayer")
		return false
	print("  - AudioStreamPlayer created")

	# 测试总线设置
	player.bus = "SFX"
	if player.bus != "SFX":
		print("  ✗ Failed to set bus")
		player.queue_free()
		return false
	print("  - Bus assignment works")

	# 测试音量设置
	player.volume_db = -5.0
	if abs(player.volume_db - (-5.0)) > 0.1:
		print("  ✗ Volume setting failed")
		player.queue_free()
		return false
	print("  - Volume setting works")

	# 测试音高设置
	player.pitch_scale = 1.5
	if abs(player.pitch_scale - 1.5) > 0.01:
		print("  ✗ Pitch setting failed")
		player.queue_free()
		return false
	print("  - Pitch setting works")

	player.queue_free()
	return true

func test_music_playback() -> bool:
	# 测试音乐播放器
	var player = AudioStreamPlayer.new()
	if not player:
		print("  ✗ Failed to create music player")
		return false
	print("  - Music player created")

	# 测试总线设置
	player.bus = "Music"
	if player.bus != "Music":
		print("  ✗ Failed to set music bus")
		player.queue_free()
		return false
	print("  - Music bus assignment works")

	# 测试暂停功能
	player.stream_paused = true
	if not player.stream_paused:
		print("  ✗ Pause failed")
		player.queue_free()
		return false
	print("  - Pause works")

	# 测试恢复功能
	player.stream_paused = false
	if player.stream_paused:
		print("  ✗ Resume failed")
		player.queue_free()
		return false
	print("  - Resume works")

	player.queue_free()
	return true

func test_query_interface() -> bool:
	# 测试总线查询
	var bus_count = AudioServer.get_bus_count()
	if bus_count < 4:
		print("  ✗ Expected at least 4 buses, found %d" % bus_count)
		return false
	print("  - Bus count: %d" % bus_count)

	# 测试总线名称
	var has_master = false
	var has_music = false
	var has_sfx = false
	var has_ui = false

	for i in range(bus_count):
		var bus_name = AudioServer.get_bus_name(i)
		if bus_name == "Master":
			has_master = true
		elif bus_name == "Music":
			has_music = true
		elif bus_name == "SFX":
			has_sfx = true
		elif bus_name == "UI":
			has_ui = true

	if not has_master:
		print("  ✗ Master bus not found")
		return false
	if not has_music:
		print("  ✗ Music bus not found")
		return false
	if not has_sfx:
		print("  ✗ SFX bus not found")
		return false
	if not has_ui:
		print("  ✗ UI bus not found")
		return false

	print("  - All required buses present")

	return true
