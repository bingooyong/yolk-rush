extends Node
class_name DropSystem
## 掉落系统 - 管理敌人掉落和战利品生成

signal item_dropped(item_id, quantity, position)
signal loot_generated(loot_table_id, items)

var drop_database = null
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	print("[DropSystem] Initialized")

## 设置掉落数据库
func set_database(db) -> void:
	drop_database = db
	print("[DropSystem] Database set")

## 从掉落表生成掉落
func generate_drops(loot_table_id: String, luck_bonus: float = 0.0) -> Array:
	if not drop_database:
		return []

	var loot_table = drop_database.get_loot_table(loot_table_id)
	if not loot_table:
		return []

	var drops = []

	for entry in loot_table.entries:
		var adjusted_chance = entry.chance * (1.0 + luck_bonus)
		adjusted_chance = clamp(adjusted_chance, 0.0, 1.0)

		if rng.randf() <= adjusted_chance:
			var quantity = rng.randi_range(entry.min_quantity, entry.max_quantity)
			drops.append({
				"item_id": entry.item_id,
				"quantity": quantity
			})

	print("[DropSystem] Generated %d drops from table '%s'" % [drops.size(), loot_table_id])
	loot_generated.emit(loot_table_id, drops)

	return drops

## 从敌人生成掉落（按敌人类型和等级）
func generate_enemy_drops(enemy_type: String, enemy_level: int, luck_bonus: float = 0.0) -> Array:
	var loot_table_id = "%s_lv%d" % [enemy_type, enemy_level]

	# 尝试精确匹配
	var drops = generate_drops(loot_table_id, luck_bonus)

	# 如果没有，尝试基础表
	if drops.is_empty():
		loot_table_id = enemy_type
		drops = generate_drops(loot_table_id, luck_bonus)

	return drops

## 按稀有度生成随机掉落
func generate_random_drop_by_rarity(rarity_weights: Dictionary = {}) -> Dictionary:
	if not drop_database:
		return {}

	# 默认稀有度权重
	var default_weights = {
		"common": 60.0,
		"uncommon": 25.0,
		"rare": 10.0,
		"epic": 4.0,
		"legendary": 1.0
	}

	# 合并自定义权重
	for key in rarity_weights.keys():
		default_weights[key] = rarity_weights[key]

	# 计算总权重
	var total_weight = 0.0
	for weight in default_weights.values():
		total_weight += weight

	# 随机选择稀有度
	var roll = rng.randf() * total_weight
	var accumulated = 0.0

	for rarity in default_weights.keys():
		accumulated += default_weights[rarity]
		if roll <= accumulated:
			var items = drop_database.get_items_by_rarity(rarity)
			if not items.is_empty():
				var item = items[rng.randi() % items.size()]
				var quantity = rng.randi_range(1, 3)
				return {
					"item_id": item,
					"quantity": quantity,
					"rarity": rarity
				}

	return {}

## 生成金币掉落
func generate_gold_drop(base_amount: int, level_multiplier: float = 1.0, luck_bonus: float = 0.0) -> int:
	var min_gold = int(base_amount * level_multiplier * 0.8)
	var max_gold = int(base_amount * level_multiplier * 1.2)

	var gold = rng.randi_range(min_gold, max_gold)
	gold = int(gold * (1.0 + luck_bonus))

	return gold

## 生成经验值掉落
func generate_exp_drop(base_exp: int, level_multiplier: float = 1.0) -> int:
	var min_exp = int(base_exp * level_multiplier * 0.9)
	var max_exp = int(base_exp * level_multiplier * 1.1)

	return rng.randi_range(min_exp, max_exp)

## 批量掉落（用于宝箱、BOSS等）
func generate_batch_drops(loot_tables: Array, luck_bonus: float = 0.0) -> Array:
	var all_drops = []

	for table_id in loot_tables:
		var drops = generate_drops(table_id, luck_bonus)
		all_drops.append_array(drops)

	return all_drops

## 获取掉落预览（不实际生成）
func preview_drops(loot_table_id: String) -> Array:
	if not drop_database:
		return []

	var loot_table = drop_database.get_loot_table(loot_table_id)
	if not loot_table:
		return []

	var preview = []
	for entry in loot_table.entries:
		preview.append({
			"item_id": entry.item_id,
			"chance": entry.chance * 100.0,
			"min_quantity": entry.min_quantity,
			"max_quantity": entry.max_quantity
		})

	return preview
