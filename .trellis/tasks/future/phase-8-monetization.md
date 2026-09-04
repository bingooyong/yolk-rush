# Phase 8: Monetization & Economy

**Status**: 📋 Planning  
**Priority**: P3  
**Dependencies**: Phase 7 完成  
**Estimated Effort**: 6-8 weeks  
**Target Date**: TBD

---

## 概述

实现游戏商业化系统，包括商城、IAP（内购）、虚拟货币、抽卡系统、战令系统。

## 前置条件

- ✅ Phase 1-7 已完成
- ✅ 玩家进度系统稳定（Phase 7）
- ⚠️ 需要法务审核（合规性）
- ⚠️ 需要支付接入（Apple/Google/支付宝/微信）
- ⚠️ 需要服务器端验证（防作弊）

---

## PRD (Product Requirements Document)

### 目标

为 Yolk Rush 建立健康的商业模式：
1. 虚拟货币系统（金币 + 钻石）
2. 商城系统（道具、皮肤、礼包）
3. IAP 内购（支持多平台）
4. 抽卡系统（公平透明）
5. 战令系统（Battle Pass）
6. 防沉迷与未成年保护

### 用户故事

**作为玩家**：
- 我希望能够购买喜欢的皮肤
- 我希望抽卡概率公开透明
- 我希望有免费途径获得付费内容
- 我希望战令物有所值

**作为运营**：
- 我希望商品配置灵活
- 我希望数据可追踪分析
- 我希望 ARPU 稳步增长
- 我希望符合各地法规

### 商业模式

**收入来源**：
1. **IAP 直购**（40%）- 礼包、钻石
2. **抽卡**（30%）- 角色、武器、皮肤
3. **战令**（20%）- 赛季通行证
4. **广告**（10%）- 可选激励视频

**定价策略**：
- 小额：￥6（首充）、￥18（月卡）
- 中额：￥68（礼包）、￥98（战令）
- 大额：￥328（大礼包）、￥648（顶级）

### 非目标（本 Phase 不做）

- ❌ NFT/区块链
- ❌ 赌博机制
- ❌ 强制付费（Pay-to-Win）
- ❌ 虚假宣传

---

## Design (设计方案)

### 架构设计

```
MonetizationSystem
    ├── CurrencyManager (货币管理)
    │   ├── GoldCurrency (金币 - 软货币)
    │   └── GemCurrency (钻石 - 硬货币)
    ├── ShopSystem (商城系统)
    │   ├── ShopCatalog (商品目录)
    │   ├── PurchaseValidator (购买验证)
    │   └── ReceiptVerifier (收据验证)
    ├── IAPManager (内购管理)
    │   ├── StoreKit (iOS)
    │   ├── GooglePlay (Android)
    │   └── ServerVerification (服务器验证)
    ├── GachaSystem (抽卡系统)
    │   ├── GachaPool (卡池)
    │   ├── PitySystem (保底机制)
    │   └── ProbabilityDisplay (概率公示)
    ├── BattlePassSystem (战令系统)
    │   ├── SeasonTracker (赛季追踪)
    │   ├── RewardTiers (奖励层级)
    │   └── ExperienceTracker (经验追踪)
    └── EconomyBalancer (经济平衡)
        ├── InflationController (通胀控制)
        └── SinkFaucet (水龙头/水池)
```

### 核心组件

#### 1. CurrencyManager.gd

```gdscript
class_name CurrencyManager extends Node

enum CurrencyType {
    GOLD,      # 软货币（游戏内获得）
    GEM,       # 硬货币（付费获得）
    TICKET,    # 抽卡券
}

var balances: Dictionary = {
    CurrencyType.GOLD: 0,
    CurrencyType.GEM: 0,
    CurrencyType.TICKET: 0,
}

signal currency_changed(type: CurrencyType, old_amount: int, new_amount: int)
signal currency_insufficient(type: CurrencyType, required: int, current: int)

func add_currency(type: CurrencyType, amount: int, source: String) -> void:
    if amount <= 0:
        return
    
    var old_amount = balances[type]
    balances[type] += amount
    currency_changed.emit(type, old_amount, balances[type])
    
    # 日志记录（用于经济分析）
    EconomyLogger.log_currency_gain(type, amount, source)

func spend_currency(type: CurrencyType, amount: int, reason: String) -> bool:
    if amount <= 0:
        return false
    
    if balances[type] < amount:
        currency_insufficient.emit(type, amount, balances[type])
        return false
    
    var old_amount = balances[type]
    balances[type] -= amount
    currency_changed.emit(type, old_amount, balances[type])
    
    # 日志记录
    EconomyLogger.log_currency_spend(type, amount, reason)
    return true

func can_afford(costs: Dictionary) -> bool:
    for currency_type in costs:
        if balances[currency_type] < costs[currency_type]:
            return false
    return true
```

#### 2. ShopSystem.gd

```gdscript
class_name ShopSystem extends Node

class ShopItem:
    var id: String
    var name: String
    var description: String
    var icon: Texture2D
    var price: Dictionary  # CurrencyType -> amount
    var iap_product_id: String  # 如果是 IAP 商品
    var contents: Array[Dictionary]  # 商品内容
    var available_from: int  # 起售时间戳
    var available_until: int  # 截止时间戳
    var purchase_limit: int = -1  # -1 = 无限制
    var purchased_count: int = 0
    var featured: bool = false
    var discount_percent: int = 0

var catalog: Dictionary = {}  # item_id -> ShopItem
var featured_items: Array[ShopItem] = []

signal item_purchased(item: ShopItem)
signal purchase_failed(item: ShopItem, reason: String)

func purchase_item(item_id: String) -> bool:
    var item: ShopItem = catalog[item_id]
    
    # 检查限购
    if item.purchase_limit > 0 and item.purchased_count >= item.purchase_limit:
        purchase_failed.emit(item, "purchase_limit_reached")
        return false
    
    # 检查时间
    var now = Time.get_unix_time_from_system()
    if item.available_from > now or item.available_until < now:
        purchase_failed.emit(item, "not_available")
        return false
    
    # IAP 商品
    if item.iap_product_id:
        IAPManager.purchase_product(item.iap_product_id, item)
        return true
    
    # 虚拟货币商品
    if not CurrencyManager.can_afford(item.price):
        purchase_failed.emit(item, "insufficient_funds")
        return false
    
    # 扣费
    for currency_type in item.price:
        CurrencyManager.spend_currency(currency_type, item.price[currency_type], "shop:" + item_id)
    
    # 发货
    deliver_item_contents(item)
    
    item.purchased_count += 1
    item_purchased.emit(item)
    return true

func deliver_item_contents(item: ShopItem) -> void:
    for content in item.contents:
        match content.type:
            "currency":
                CurrencyManager.add_currency(content.currency_type, content.amount, "shop")
            "item":
                InventoryManager.add_item(content.item_id, content.quantity)
            "character":
                CharacterUnlocker.unlock_character(content.character_id)
```

#### 3. IAPManager.gd

```gdscript
class_name IAPManager extends Node

signal purchase_started(product_id: String)
signal purchase_completed(product_id: String, receipt: String)
signal purchase_failed(product_id: String, error: String)
signal purchase_restored(products: Array[String])

var products: Dictionary = {}  # product_id -> ProductInfo
var pending_purchases: Dictionary = {}  # transaction_id -> purchase_data

func initialize() -> void:
    if OS.get_name() == "iOS":
        initialize_storekit()
    elif OS.get_name() == "Android":
        initialize_googleplay()

func purchase_product(product_id: String, context: Dictionary = {}) -> void:
    if not products.has(product_id):
        purchase_failed.emit(product_id, "product_not_found")
        return
    
    purchase_started.emit(product_id)
    
    # 调用平台 API
    if OS.get_name() == "iOS":
        # StoreKit 2
        var payment = {
            "product_id": product_id
        }
        # Native iOS bridge
    elif OS.get_name() == "Android":
        # Google Play Billing
        var purchase_params = {
            "product_id": product_id
        }
        # Native Android bridge

func verify_purchase_on_server(receipt: String, product_id: String) -> bool:
    var http = HTTPRequest.new()
    add_child(http)
    
    var response = await http.request_completed
    
    var result = JSON.parse_string(response[3].get_string_from_utf8())
    if result and result.valid:
        return true
    else:
        return false

func deliver_iap_product(product_id: String) -> void:
    var product_config = load_product_config(product_id)
    
    # 发放虚拟货币
    for currency_type in product_config.currencies:
        CurrencyManager.add_currency(
            currency_type,
            product_config.currencies[currency_type],
            "iap:" + product_id
        )
    
    # 发放物品
    for item_grant in product_config.items:
        InventoryManager.add_item(item_grant.item_id, item_grant.quantity)
```

#### 4. GachaSystem.gd

```gdscript
class_name GachaSystem extends Node

class GachaPool:
    var id: String
    var name: String
    var banner_image: Texture2D
    var cost: Dictionary  # CurrencyType -> amount
    var available_from: int
    var available_until: int
    var featured_items: Array[String]  # 提升概率的物品
    var guaranteed_items: Array[String]  # 保底物品
    var pity_threshold: int = 90  # 90 抽保底
    var rarity_rates: Dictionary = {
        "legendary": 0.006,  # 0.6%
        "epic": 0.051,       # 5.1%
        "rare": 0.133,       # 13.3%
        "uncommon": 0.255,   # 25.5%
        "common": 0.555,     # 55.5%
    }

var pools: Dictionary = {}  # pool_id -> GachaPool
var pity_counters: Dictionary = {}  # pool_id -> counter

signal gacha_started(pool: GachaPool, count: int)
signal gacha_result(pool: GachaPool, items: Array[Dictionary])

func perform_gacha(pool_id: String, count: int = 1) -> Array[Dictionary]:
    var pool: GachaPool = pools[pool_id]
    
    # 检查货币
    var total_cost = {}
    for currency_type in pool.cost:
        total_cost[currency_type] = pool.cost[currency_type] * count
    
    if not CurrencyManager.can_afford(total_cost):
        return []
    
    # 扣费
    for currency_type in total_cost:
        CurrencyManager.spend_currency(currency_type, total_cost[currency_type], "gacha:" + pool_id)
    
    gacha_started.emit(pool, count)
    
    # 抽取
    var results: Array[Dictionary] = []
    for i in range(count):
        var item = draw_single(pool)
        results.append(item)
    
    gacha_result.emit(pool, results)
    
    # 日志记录（用于概率验证）
    GachaLogger.log_gacha(pool_id, count, results)
    
    return results

func draw_single(pool: GachaPool) -> Dictionary:
    # 保底检查
    pity_counters[pool.id] = pity_counters.get(pool.id, 0) + 1
    
    var guaranteed_legendary = pity_counters[pool.id] >= pool.pity_threshold
    
    # 确定稀有度
    var rarity: String
    if guaranteed_legendary:
        rarity = "legendary"
        pity_counters[pool.id] = 0
    else:
        rarity = roll_rarity(pool.rarity_rates)
        if rarity == "legendary":
            pity_counters[pool.id] = 0
    
    # 从对应稀有度池中抽取
    var item = select_item_from_rarity(pool, rarity)
    
    return {
        "item_id": item.id,
        "rarity": rarity,
        "is_new": not InventoryManager.has_item(item.id)
    }

func roll_rarity(rates: Dictionary) -> String:
    var roll = randf()
    var cumulative = 0.0
    
    for rarity in ["legendary", "epic", "rare", "uncommon", "common"]:
        cumulative += rates[rarity]
        if roll < cumulative:
            return rarity
    
    return "common"

func get_probability_display(pool_id: String) -> Dictionary:
    var pool: GachaPool = pools[pool_id]
    
    # 法规要求：公示概率
    return {
        "base_rates": pool.rarity_rates,
        "pity_system": {
            "threshold": pool.pity_threshold,
            "current_pity": pity_counters.get(pool_id, 0)
        },
        "featured_boost": 0.5  # 提升概率 UP 角色 50%
    }
```

#### 5. BattlePassSystem.gd

```gdscript
class_name BattlePassSystem extends Node

class BattlePass:
    var season_id: String
    var season_name: String
    var start_date: int
    var end_date: int
    var max_level: int = 50
    var free_rewards: Dictionary  # level -> [rewards]
    var premium_rewards: Dictionary  # level -> [rewards]
    var premium_price: Dictionary  # 战令价格
    var exp_per_level: Array[int]  # 每级所需经验

var current_season: BattlePass
var premium_owned: bool = false
var current_level: int = 1
var current_exp: int = 0
var claimed_rewards: Dictionary = {}  # level -> claimed

signal level_up(new_level: int)
signal reward_claimed(level: int, reward: Dictionary, is_premium: bool)

func add_battlepass_exp(amount: int, source: String) -> void:
    current_exp += amount
    
    while current_exp >= get_exp_for_next_level():
        if current_level >= current_season.max_level:
            break
        
        current_exp -= get_exp_for_next_level()
        current_level += 1
        level_up.emit(current_level)

func claim_reward(level: int, is_premium: bool) -> bool:
    if level > current_level:
        return false
    
    if is_premium and not premium_owned:
        return false
    
    var key = str(level) + ("_premium" if is_premium else "_free")
    if claimed_rewards.has(key):
        return false
    
    var rewards = current_season.premium_rewards[level] if is_premium else current_season.free_rewards[level]
    
    # 发放奖励
    for reward in rewards:
        deliver_reward(reward)
    
    claimed_rewards[key] = true
    reward_claimed.emit(level, rewards, is_premium)
    return true

func purchase_premium() -> bool:
    if premium_owned:
        return false
    
    if not CurrencyManager.can_afford(current_season.premium_price):
        return false
    
    for currency_type in current_season.premium_price:
        CurrencyManager.spend_currency(
            currency_type,
            current_season.premium_price[currency_type],
            "battlepass_premium"
        )
    
    premium_owned = true
    return true
```

### 数据驱动配置

**data/monetization/shop_catalog.json**：

```json
{
  "$schema": "../schemas/shop_catalog_schema.json",
  "featured_rotation": {
    "interval_hours": 24,
    "items_count": 6
  },
  "items": [
    {
      "id": "starter_pack",
      "name": "新手礼包",
      "description": "超值首充！钻石 x600 + 金币 x10000",
      "icon": "res://assets/icons/shop/starter_pack.png",
      "price": {
        "real_money": {
          "USD": 0.99,
          "CNY": 6,
          "EUR": 0.89
        }
      },
      "iap_product_id": "com.yolkrush.starter_pack",
      "contents": [
        {"type": "currency", "currency_type": "GEM", "amount": 600},
        {"type": "currency", "currency_type": "GOLD", "amount": 10000},
        {"type": "item", "item_id": "rare_weapon_box", "quantity": 1}
      ],
      "purchase_limit": 1,
      "featured": true,
      "discount_percent": 80
    },
    {
      "id": "monthly_card",
      "name": "月卡",
      "description": "30 天每日领取钻石 x90，立即获得 300",
      "icon": "res://assets/icons/shop/monthly_card.png",
      "price": {
        "real_money": {
          "USD": 4.99,
          "CNY": 18,
          "EUR": 4.49
        }
      },
      "iap_product_id": "com.yolkrush.monthly_card",
      "contents": [
        {"type": "currency", "currency_type": "GEM", "amount": 300},
        {"type": "subscription", "subscription_type": "monthly_gem", "duration_days": 30}
      ],
      "featured": true
    },
    {
      "id": "gem_pack_large",
      "name": "钻石大礼包",
      "description": "钻石 x6480 + 额外赠送 20%",
      "icon": "res://assets/icons/shop/gem_pack_large.png",
      "price": {
        "real_money": {
          "USD": 99.99,
          "CNY": 648,
          "EUR": 89.99
        }
      },
      "iap_product_id": "com.yolkrush.gem_pack_large",
      "contents": [
        {"type": "currency", "currency_type": "GEM", "amount": 7776}
      ]
    },
    {
      "id": "skin_yolk_hero_knight",
      "name": "骑士皮肤",
      "description": "蛋黄英雄 - 骑士",
      "icon": "res://assets/icons/skins/yolk_hero_knight.png",
      "price": {
        "GEM": 1280
      },
      "contents": [
        {"type": "skin", "character_id": "yolk_hero", "skin_id": "knight"}
      ],
      "purchase_limit": 1
    }
  ]
}
```

**data/monetization/gacha_pools.json**：

```json
{
  "$schema": "../schemas/gacha_pool_schema.json",
  "pools": [
    {
      "id": "standard_banner",
      "name": "标准祈愿",
      "banner_image": "res://assets/banners/standard.png",
      "cost": {
        "TICKET": 1
      },
      "pity_threshold": 90,
      "rarity_rates": {
        "legendary": 0.006,
        "epic": 0.051,
        "rare": 0.133,
        "uncommon": 0.255,
        "common": 0.555
      },
      "pool_contents": {
        "legendary": ["char_aurora", "weapon_excalibur"],
        "epic": ["char_frost", "weapon_flame_sword", "armor_dragon_plate"],
        "rare": ["weapon_iron_blade", "armor_steel_helm"],
        "uncommon": ["weapon_bronze_sword", "armor_leather"],
        "common": ["material_wood", "material_iron_ore"]
      }
    },
    {
      "id": "limited_banner_summer",
      "name": "夏日限定",
      "banner_image": "res://assets/banners/summer_2027.png",
      "cost": {
        "TICKET": 1
      },
      "available_from": 1719792000,
      "available_until": 1722470400,
      "featured_items": ["char_summer_yolk", "weapon_beach_umbrella"],
      "pity_threshold": 90,
      "featured_rate_up": 0.5,
      "rarity_rates": {
        "legendary": 0.006,
        "epic": 0.051,
        "rare": 0.133,
        "uncommon": 0.255,
        "common": 0.555
      }
    }
  ]
}
```

**data/monetization/battlepass_season_1.json**：

```json
{
  "$schema": "../schemas/battlepass_schema.json",
  "season_id": "season_1_dawn",
  "season_name": "黎明序章",
  "start_date": 1717228800,
  "end_date": 1722470400,
  "max_level": 50,
  "premium_price": {
    "GEM": 980
  },
  "exp_per_level": [
    1000, 1000, 1000, 1000, 1000,
    1200, 1200, 1200, 1200, 1200,
    1500, 1500, 1500, 1500, 1500
  ],
  "free_rewards": {
    "1": [
      {"type": "currency", "currency_type": "GOLD", "amount": 1000}
    ],
    "5": [
      {"type": "item", "item_id": "uncommon_weapon_box", "quantity": 1}
    ],
    "10": [
      {"type": "currency", "currency_type": "TICKET", "amount": 5}
    ],
    "20": [
      {"type": "item", "item_id": "rare_weapon_box", "quantity": 1}
    ],
    "50": [
      {"type": "character", "character_id": "char_free_season_1"}
    ]
  },
  "premium_rewards": {
    "1": [
      {"type": "currency", "currency_type": "TICKET", "amount": 3}
    ],
    "5": [
      {"type": "item", "item_id": "rare_weapon_box", "quantity": 1}
    ],
    "10": [
      {"type": "skin", "character_id": "yolk_hero", "skin_id": "season_1_exclusive"}
    ],
    "25": [
      {"type": "item", "item_id": "epic_weapon_box", "quantity": 1}
    ],
    "50": [
      {"type": "character", "character_id": "char_premium_season_1"},
      {"type": "currency", "currency_type": "TICKET", "amount": 20}
    ]
  }
}
```

### 经济平衡

#### 水龙头（Faucet）- 货币产出

| 来源 | 金币/小时 | 钻石/天 | 备注 |
|------|-----------|---------|------|
| 战斗胜利 | 500 | 0 | 基础产出 |
| 每日任务 | 2000 | 50 | 完成 5 个任务 |
| 成就奖励 | - | 100-1000 | 一次性 |
| 月卡 | - | 90 | 付费 |
| 战令免费 | - | 100 | 赛季总计 |
| 战令付费 | - | 600 | 赛季总计 |

**免费玩家日均**：
- 金币：~5,000
- 钻石：~70（每日任务 + 战令免费）

**付费玩家日均**：
- 金币：~5,000
- 钻石：~200（月卡 + 每日任务 + 战令付费）

#### 水池（Sink）- 货币消耗

| 消耗项 | 金币 | 钻石 | 备注 |
|--------|------|------|------|
| 装备升级 | 1000-10000 | 0 | 按等级递增 |
| 技能升级 | 500-5000 | 0 | 按等级递增 |
| 商店物品 | 各异 | 各异 | 皮肤 ~1280 钻 |
| 抽卡单抽 | 0 | 160 | 或消耗抽卡券 |
| 抽卡十连 | 0 | 1600 | 保证 1 个稀有 |
| 战令购买 | 0 | 980 | 赛季一次 |

**核心循环设计**：
- 免费玩家：2-3 天攒够 1 次单抽，15 天攒够战令
- 付费玩家：立即满足抽卡需求，加速成长

---

## Implementation Plan

### Task 1: Currency System (3 days)

**文件**：
- `scripts/monetization/currency_manager.gd`
- `scripts/monetization/currency_display.gd`
- UI 显示（金币、钻石图标）

**验收**：
- [ ] 货币增减正确
- [ ] UI 实时更新
- [ ] 日志记录完整

### Task 2: Shop System Core (5 days)

**文件**：
- `scripts/monetization/shop_system.gd`
- `scenes/ui/shop_panel.tscn`
- `data/monetization/shop_catalog.json`

**验收**：
- [ ] 商品从 JSON 加载
- [ ] 虚拟货币购买正常
- [ ] 限购逻辑正确
- [ ] UI 显示完整

### Task 3: IAP Integration (7 days)

**文件**：
- `scripts/monetization/iap_manager.gd`
- iOS StoreKit 集成
- Android Google Play Billing 集成
- 服务器收据验证

**验收**：
- [ ] iOS 内购流程通畅
- [ ] Android 内购流程通畅
- [ ] 收据验证成功
- [ ] 沙盒环境测试通过

### Task 4: Server-Side Validation (5 days)

**后端**（Go/Node.js）：
- 收据验证 API
- 物品发放 API
- 防重放攻击
- 数据库记录

**验收**：
- [ ] Apple/Google 收据验证正确
- [ ] 重复收据被拒绝
- [ ] 发货记录可查询

### Task 5: Gacha System (6 days)

**文件**：
- `scripts/monetization/gacha_system.gd`
- `scenes/ui/gacha_panel.tscn`
- `data/monetization/gacha_pools.json`

**实现**：
1. 概率计算
2. 保底机制
3. 概率公示 UI
4. 抽卡动画
5. 日志记录

**验收**：
- [ ] 概率符合配置
- [ ] 保底正确触发
- [ ] 概率公示清晰
- [ ] 抽卡动画流畅

### Task 6: Battle Pass System (6 days)

**文件**：
- `scripts/monetization/battlepass_system.gd`
- `scenes/ui/battlepass_panel.tscn`
- `data/monetization/battlepass_season_1.json`

**验收**：
- [ ] 经验累积正确
- [ ] 奖励领取正常
- [ ] 免费/付费奖励区分清晰
- [ ] 赛季切换功能正常

### Task 7: Economy Balancing (5 days)

**工具**：
- 经济模拟器（Excel/Python）
- 数据分析看板

**数值调整**：
1. 产出/消耗平衡
2. 定价策略
3. 转化率预估

**验收**：
- [ ] 免费玩家可持续
- [ ] 付费玩家有优势但不 P2W
- [ ] 经济模型健康

### Task 8: Anti-Addiction & Minor Protection (4 days)

**功能**：
1. 实名认证接口
2. 防沉迷提示（未成年每日 1.5h）
3. 消费限额（未成年每月 ¥400）
4. 宵禁（22:00-8:00 禁止登录）

**验收**：
- [ ] 实名认证流程完整
- [ ] 防沉迷正确限制
- [ ] 消费限额生效
- [ ] 宵禁功能正常

### Task 9: Analytics & Dashboard (4 days)

**数据追踪**：
1. IAP 转化率
2. ARPU/ARPPU
3. 抽卡统计
4. 战令购买率

**看板**：
- 实时营收
- 玩家消费分布
- 经济健康度指标

**验收**：
- [ ] 数据埋点完整
- [ ] 看板实时更新
- [ ] 报表导出功能

### Task 10: Compliance & Testing (6 days)

**合规审查**：
1. 法务审核（抽卡概率、未成年保护）
2. 平台审核准备（Apple/Google）
3. 隐私政策更新

**测试**：
- IAP 沙盒测试
- 抽卡概率验证（10 万次模拟）
- 经济模型压测

**验收**：
- [ ] 法务审核通过
- [ ] 平台审核准备完成
- [ ] 所有测试通过

---

## Acceptance Criteria

### 功能验收

- [ ] 货币系统完整（金币 + 钻石）
- [ ] 商城系统可用（20+ 商品）
- [ ] IAP 内购流程通畅（iOS + Android）
- [ ] 抽卡系统完整（概率公示 + 保底）
- [ ] 战令系统完整（50 级奖励）
- [ ] 防沉迷系统生效

### 技术验收

- [ ] 服务器收据验证
- [ ] 数据加密传输
- [ ] 防刷防作弊
- [ ] 数据分析完备

### 合规验收

- [ ] 概率公示符合法规
- [ ] 未成年保护完整
- [ ] 隐私政策更新
- [ ] Apple/Google 审核通过

### 商业验收

- [ ] 转化率 ≥ 2%
- [ ] ARPU ≥ $0.50
- [ ] 付费深度合理（大 R / 小 R 平衡）

---

## Risks & Mitigations

### Risk 1: 平台审核不通过

**影响**: 高（无法上线）  
**缓解**:
- 提前研究审核指南
- 避免敏感机制（赌博、诱导）
- 法务提前审查

### Risk 2: 经济失衡（通货膨胀）

**影响**: 高（游戏经济崩溃）  
**缓解**:
- 经济模拟器预测
- 分阶段调整
- 监控数据及时干预

### Risk 3: 付费转化率低

**影响**: 中（营收不达标）  
**缓解**:
- A/B 测试定价
- 优化首充体验
- 战令物有所值

---

## Legal & Compliance

### 必须遵守的法规

**中国大陆**：
- 实名认证（网信办）
- 防沉迷（未成年保护）
- 概率公示（抽卡概率必须公开）
- 版号申请（游戏出版许可）

**欧盟（GDPR）**：
- 数据隐私保护
- Cookie 同意
- 用户数据删除权

**美国（COPPA）**：
- 13 岁以下儿童保护
- 家长同意机制

**Apple App Store**：
- 30% 分成
- 订阅自动续费透明化
- 禁止诱导评价

**Google Play**：
- 30% 分成（首年）
- 15% 分成（订阅 2 年后）
- 内购必须走 Google Play Billing

---

## Out of Scope (Phase 9+)

- ❌ NFT/区块链
- ❌ 实物周边商城
- ❌ 跨游戏虚拟货币
- ❌ 第三方支付（微信/支付宝直连）

---

## Estimated Timeline

```
Week 1-2: Currency + Shop + IAP (iOS/Android)
Week 3: Server Validation + Security
Week 4-5: Gacha + Battle Pass
Week 6: Economy Balance + Anti-Addiction
Week 7: Analytics + Compliance
Week 8: Testing + Polish
```

**Total**: 6-8 weeks

---

**文档版本**: 1.0  
**创建日期**: 2026-09-04  
**作者**: Claude Code (Opus 5)  
**状态**: 📋 Planning - 依赖 Phase 7 完成
**警告**: ⚠️ 本 Phase 涉及法律合规，必须咨询专业法务
