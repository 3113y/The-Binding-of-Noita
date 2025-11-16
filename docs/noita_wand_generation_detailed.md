# Noita 法杖生成系统详细实现指南

## 一、核心数据结构

### 1.1 法杖属性结构
```lua
-- Noita 法杖完整属性
WandStats = {
    -- 基础属性
    capacity = 0,                    -- 法术容量 (3-26)
    actions_per_round = 1,          -- 每轮施法数 (1-26)
    reload_time = 0,                -- 装填时间(帧) (-10 ~ 120)
    shuffle_deck_when_empty = true, -- 空时洗牌
    
    -- 施法属性
    fire_rate_wait = 0,             -- 施法延迟(帧) (-20 ~ 60)
    spread_degrees = 0,             -- 扩散角度 (-10 ~ 30)
    speed_multiplier = 1.0,         -- 速度倍数 (0.5 ~ 3.0)
    
    -- 法力系统
    mana_max = 0,                   -- 最大法力 (0 ~ 2000)
    mana_charge_speed = 0,          -- 充能速度 (0 ~ 2000)
    
    -- 永久施法
    always_cast_spell = nil,        -- 永久法术ID
    
    -- 外观
    sprite_file = "",               -- 法杖图片路径
    ui_name = "",                   -- UI显示名称
}
```

### 1.2 法术属性结构
```lua
SpellData = {
    -- 标识信息
    id = "",                        -- 法术ID如 "LIGHT_BULLET"
    name = "",                      -- 显示名称
    description = "",               -- 描述
    sprite = "",                    -- 图标路径
    
    -- 类型分类
    type = ACTION_TYPE_PROJECTILE,  -- 类型常量
    spawn_level = "0,1,2,3,4,5,6",  -- 可刷新层级
    spawn_probability = "1,1,1,1,1,1,1", -- 各层概率
    
    -- 法力消耗
    mana = 10,                      -- 法力消耗
    max_uses = -1,                  -- 使用次数 (-1=无限)
    
    -- 修正属性(叠加到法杖施法状态)
    fire_rate_wait = 0,             -- 施法延迟修正
    speed_multiplier = 1.0,         -- 速度修正
    spread_degrees = 0,             -- 扩散修正
    reload_time = 0,                -- 装填时间修正
    
    -- 抛射物文件
    projectile_file = "",           -- 抛射物实体路径
    
    -- 特殊标志
    never_unlimited = false,        -- 不能无限使用
    ai_never_uses = false,          -- AI不使用
    is_dangerous = false,           -- 危险法术
}
```

## 二、法杖生成核心算法

### 2.1 主生成函数
```lua
-- 伪代码: 生成法杖的完整流程
function GenerateWand(level, x, y, is_better)
    -- 1. 初始化随机种子
    SetRandomSeed(x + y + GameFrame())
    
    -- 2. 创建法杖实体
    local wand = CreateWandEntity(x, y)
    
    -- 3. 生成基础属性
    local stats = GenerateWandStats(level, is_better)
    ApplyStatsToWand(wand, stats)
    
    -- 4. 选择法杖外观
    local sprite = SelectWandSprite(level)
    SetWandSprite(wand, sprite)
    
    -- 5. 添加法术
    local spell_count = Random(1, stats.capacity)
    AddRandomSpells(wand, level, spell_count)
    
    -- 6. 可能添加永久法术
    if RollAlwaysCast(level) then
        local always_spell = SelectAlwaysCast(level)
        SetAlwaysCast(wand, always_spell)
    end
    
    return wand
end
```

### 2.2 属性生成详细算法
```lua
-- 按等级生成法杖属性
function GenerateWandStats(level, is_better)
    local stats = {}
    
    -- 等级配置表 [最小, 最大, 平均值, 方差]
    local level_configs = {
        [1] = {
            capacity = {3, 6, 4, 1},
            actions_per_round = {1, 2, 1, 0.3},
            reload_time = {30, 70, 50, 15},
            fire_rate_wait = {5, 20, 12, 5},
            spread_degrees = {0, 5, 2, 2},
            speed_multiplier = {0.8, 1.2, 1.0, 0.2},
            mana_max = {100, 300, 200, 50},
            mana_charge_speed = {50, 150, 100, 30},
            shuffle = 0.7  -- 70%概率洗牌
        },
        [2] = {
            capacity = {4, 8, 6, 1.5},
            actions_per_round = {1, 3, 2, 0.5},
            reload_time = {25, 60, 40, 12},
            fire_rate_wait = {3, 18, 10, 5},
            spread_degrees = {-2, 8, 3, 3},
            speed_multiplier = {0.9, 1.5, 1.2, 0.3},
            mana_max = {200, 500, 350, 80},
            mana_charge_speed = {80, 200, 140, 40},
            shuffle = 0.6
        },
        [3] = {
            capacity = {5, 10, 7, 2},
            actions_per_round = {1, 4, 2, 0.7},
            reload_time = {20, 50, 35, 10},
            fire_rate_wait = {0, 15, 7, 5},
            spread_degrees = {-5, 10, 2, 4},
            speed_multiplier = {1.0, 2.0, 1.5, 0.4},
            mana_max = {300, 700, 500, 100},
            mana_charge_speed = {100, 300, 200, 60},
            shuffle = 0.5
        },
        [4] = {
            capacity = {6, 13, 9, 2},
            actions_per_round = {1, 5, 3, 1},
            reload_time = {10, 45, 25, 10},
            fire_rate_wait = {-5, 12, 5, 5},
            spread_degrees = {-8, 12, 1, 5},
            speed_multiplier = {1.2, 2.5, 1.8, 0.5},
            mana_max = {400, 1000, 700, 150},
            mana_charge_speed = {150, 400, 275, 80},
            shuffle = 0.4
        },
        [5] = {
            capacity = {7, 16, 11, 3},
            actions_per_round = {1, 6, 3, 1.2},
            reload_time = {0, 40, 20, 12},
            fire_rate_wait = {-10, 10, 2, 6},
            spread_degrees = {-10, 15, 0, 6},
            speed_multiplier = {1.5, 3.0, 2.2, 0.6},
            mana_max = {500, 1500, 1000, 250},
            mana_charge_speed = {200, 600, 400, 120},
            shuffle = 0.3
        },
        [6] = {
            capacity = {8, 20, 14, 4},
            actions_per_round = {1, 8, 4, 1.5},
            reload_time = {-10, 35, 15, 15},
            fire_rate_wait = {-15, 8, 0, 7},
            spread_degrees = {-12, 18, -2, 8},
            speed_multiplier = {2.0, 3.5, 2.8, 0.8},
            mana_max = {600, 2000, 1300, 350},
            mana_charge_speed = {300, 800, 550, 150},
            shuffle = 0.2
        }
    }
    
    local config = level_configs[Clamp(level, 1, 6)]
    
    -- 使用正态分布生成属性
    stats.capacity = RandomNormal(
        config.capacity[3], 
        config.capacity[4]
    )
    stats.capacity = Clamp(
        Round(stats.capacity), 
        config.capacity[1], 
        config.capacity[2]
    )
    
    -- 类似方式生成其他属性...
    stats.actions_per_round = ClampedNormal(
        config.actions_per_round[3],
        config.actions_per_round[4],
        config.actions_per_round[1],
        config.actions_per_round[2]
    )
    
    stats.reload_time = Round(ClampedNormal(
        config.reload_time[3],
        config.reload_time[4],
        config.reload_time[1],
        config.reload_time[2]
    ))
    
    stats.fire_rate_wait = Round(ClampedNormal(
        config.fire_rate_wait[3],
        config.fire_rate_wait[4],
        config.fire_rate_wait[1],
        config.fire_rate_wait[2]
    ))
    
    stats.spread_degrees = ClampedNormal(
        config.spread_degrees[3],
        config.spread_degrees[4],
        config.spread_degrees[1],
        config.spread_degrees[2]
    )
    
    stats.speed_multiplier = ClampedNormal(
        config.speed_multiplier[3],
        config.speed_multiplier[4],
        config.speed_multiplier[1],
        config.speed_multiplier[2]
    )
    
    stats.mana_max = Round(ClampedNormal(
        config.mana_max[3],
        config.mana_max[4],
        config.mana_max[1],
        config.mana_max[2]
    ))
    
    stats.mana_charge_speed = Round(ClampedNormal(
        config.mana_charge_speed[3],
        config.mana_charge_speed[4],
        config.mana_charge_speed[1],
        config.mana_charge_speed[2]
    ))
    
    -- 洗牌标志
    stats.shuffle_deck_when_empty = (Random(0, 1) < config.shuffle)
    
    -- Better版本: 提升所有属性10-30%
    if is_better then
        local boost = Random(1.1, 1.3)
        stats.capacity = Round(stats.capacity * boost)
        stats.mana_max = Round(stats.mana_max * boost)
        stats.mana_charge_speed = Round(stats.mana_charge_speed * boost)
        
        -- 降低惩罚属性
        stats.reload_time = Round(stats.reload_time * 0.8)
        stats.fire_rate_wait = Round(stats.fire_rate_wait * 0.8)
        stats.spread_degrees = stats.spread_degrees * 0.7
    end
    
    return stats
end

-- 辅助函数: 正态分布随机
function RandomNormal(mean, stddev)
    -- Box-Muller变换
    local u1 = Random(0, 1)
    local u2 = Random(0, 1)
    local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return mean + z * stddev
end

-- 辅助函数: 限制范围的正态分布
function ClampedNormal(mean, stddev, min, max)
    local value = RandomNormal(mean, stddev)
    return Clamp(value, min, max)
end
```

## 三、法术选择算法

### 3.1 法术池过滤
```lua
-- 获取可用法术池
function GetAvailableSpells(level)
    local all_spells = GetAllSpells()
    local available = {}
    
    for _, spell in pairs(all_spells) do
        -- 检查等级要求
        if CanSpawnAtLevel(spell, level) then
            -- 检查概率
            local prob = GetSpawnProbability(spell, level)
            if prob > 0 then
                table.insert(available, {
                    spell = spell,
                    probability = prob
                })
            end
        end
    end
    
    return available
end

-- 检查法术是否可在该层生成
function CanSpawnAtLevel(spell, level)
    -- spawn_level = "0,1,2,3" 字符串
    local levels = SplitString(spell.spawn_level, ",")
    
    for _, lv in pairs(levels) do
        if tonumber(lv) == level then
            return true
        end
    end
    
    return false
end

-- 获取法术在该层的生成概率
function GetSpawnProbability(spell, level)
    local levels = SplitString(spell.spawn_level, ",")
    local probs = SplitString(spell.spawn_probability, ",")
    
    for i, lv in pairs(levels) do
        if tonumber(lv) == level then
            return tonumber(probs[i])
        end
    end
    
    return 0
end
```

### 3.2 加权随机选择
```lua
-- 基于概率权重选择法术
function SelectSpellByWeight(spell_pool)
    -- 计算总权重
    local total_weight = 0
    for _, entry in pairs(spell_pool) do
        total_weight = total_weight + entry.probability
    end
    
    -- 随机选择
    local roll = Random(0, total_weight)
    local cumulative = 0
    
    for _, entry in pairs(spell_pool) do
        cumulative = cumulative + entry.probability
        if roll <= cumulative then
            return entry.spell
        end
    end
    
    -- 保底返回第一个
    return spell_pool[1].spell
end
```

### 3.3 法术添加逻辑
```lua
-- 为法杖添加随机法术
function AddRandomSpells(wand, level, count)
    -- 获取可用法术池
    local spell_pool = GetAvailableSpells(level)
    
    -- 类型平衡: 确保有抛射物
    local has_projectile = false
    local added_spells = {}
    
    for i = 1, count do
        local spell
        
        -- 第一个法术必须是抛射物
        if i == 1 or not has_projectile then
            spell = SelectSpellByType(spell_pool, ACTION_TYPE_PROJECTILE)
            has_projectile = true
        else
            -- 后续法术可以是任意类型,但增加修正器概率
            if Random(0, 1) < 0.3 then  -- 30%概率选修正器
                spell = SelectSpellByType(spell_pool, 
                    ACTION_TYPE_MODIFIER, 
                    ACTION_TYPE_UTILITY)
            else
                spell = SelectSpellByWeight(spell_pool)
            end
        end
        
        -- 避免重复(除非是常见法术)
        if not IsCommonSpell(spell) then
            if Contains(added_spells, spell) then
                -- 重新选择
                spell = SelectSpellByWeight(spell_pool)
            end
        end
        
        -- 添加到法杖
        AddSpellToWand(wand, spell.id)
        table.insert(added_spells, spell)
    end
end

-- 选择特定类型的法术
function SelectSpellByType(spell_pool, ...)
    local types = {...}
    local filtered = {}
    
    for _, entry in pairs(spell_pool) do
        for _, type in pairs(types) do
            if entry.spell.type == type then
                table.insert(filtered, entry)
                break
            end
        end
    end
    
    if #filtered == 0 then
        return SelectSpellByWeight(spell_pool)
    end
    
    return SelectSpellByWeight(filtered)
end

-- 常见法术可以重复
function IsCommonSpell(spell)
    local common_spells = {
        "LIGHT_BULLET",
        "LIGHT_BULLET_TRIGGER",
        "HEAVY_BULLET",
        "ENERGY_ORB",
        "BOMB",
    }
    
    return Contains(common_spells, spell.id)
end
```

## 四、Always Cast (永久法术) 系统

### 4.1 概率计算
```lua
-- 计算是否添加永久法术
function RollAlwaysCast(level)
    -- 等级越高,概率越大
    local probabilities = {
        [1] = 0.02,   -- 2%
        [2] = 0.05,   -- 5%
        [3] = 0.08,   -- 8%
        [4] = 0.12,   -- 12%
        [5] = 0.15,   -- 15%
        [6] = 0.20,   -- 20%
    }
    
    local prob = probabilities[Clamp(level, 1, 6)]
    return Random(0, 1) < prob
end
```

### 4.2 永久法术选择
```lua
-- 选择永久法术
function SelectAlwaysCast(level)
    -- 永久法术池(相对安全的法术)
    local always_cast_pool = {
        -- 等级1-2可用
        {id = "CHAINSAW", level = 1, weight = 10},
        {id = "LUMINOUS_DRILL", level = 1, weight = 8},
        {id = "LIGHT_BULLET", level = 1, weight = 5},
        
        -- 等级3-4可用
        {id = "HEAVY_SHOT", level = 3, weight = 6},
        {id = "CRITICAL_HIT", level = 3, weight = 7},
        {id = "DAMAGE", level = 3, weight = 8},
        
        -- 等级5-6可用
        {id = "HOMING", level = 5, weight = 9},
        {id = "ACCELERATING_SHOT", level = 5, weight = 7},
        {id = "EXPLOSIVE_PROJECTILE", level = 5, weight = 4},
        
        -- 稀有永久法术
        {id = "PLASMA_BEAM", level = 6, weight = 2},
        {id = "MIST_RADIOACTIVE", level = 6, weight = 1},
    }
    
    -- 过滤可用法术
    local available = {}
    for _, spell in pairs(always_cast_pool) do
        if level >= spell.level then
            table.insert(available, spell)
        end
    end
    
    -- 加权选择
    local total = 0
    for _, spell in pairs(available) do
        total = total + spell.weight
    end
    
    local roll = Random(0, total)
    local cumulative = 0
    for _, spell in pairs(available) do
        cumulative = cumulative + spell.weight
        if roll <= cumulative then
            return spell.id
        end
    end
    
    return available[1].id
end
```

## 五、特殊法杖类型实现

### 5.1 不洗牌法杖
```lua
-- 创建不洗牌法杖(无序施法)
function CreateUnshuffleWand(level, x, y)
    local wand = GenerateWand(level, x, y, false)
    
    -- 强制不洗牌
    SetWandStat(wand, "shuffle_deck_when_empty", false)
    
    -- 提升属性补偿
    local capacity = GetWandStat(wand, "capacity")
    SetWandStat(wand, "capacity", capacity + 2)
    
    -- 降低装填时间
    local reload = GetWandStat(wand, "reload_time")
    SetWandStat(wand, "reload_time", reload * 0.7)
    
    -- 添加更多法术
    AddRandomSpells(wand, level, capacity + 2)
    
    return wand
end
```

### 5.2 快速法杖
```lua
-- 创建快速施法法杖(机关枪型)
function CreateFastWand(level, x, y)
    local wand = GenerateWand(level, x, y, false)
    
    -- 设置快速施法属性
    SetWandStat(wand, "actions_per_round", 3)
    SetWandStat(wand, "fire_rate_wait", 2)  -- 非常低的延迟
    SetWandStat(wand, "reload_time", 15)    -- 快速装填
    
    -- 增加容量
    SetWandStat(wand, "capacity", 10)
    
    -- 法力消耗快,但恢复也快
    SetWandStat(wand, "mana_max", 500)
    SetWandStat(wand, "mana_charge_speed", 300)
    
    -- 添加轻型法术
    local light_spells = {
        "LIGHT_BULLET",
        "RUBBER_BALL",
        "ENERGY_ORB_TIER_1",
    }
    
    for i = 1, 8 do
        local spell = light_spells[Random(1, #light_spells)]
        AddSpellToWand(wand, spell)
    end
    
    return wand
end
```

### 5.3 爆炸法杖
```lua
-- 创建爆炸型法杖
function CreateExplosiveWand(level, x, y)
    local wand = GenerateWand(level, x, y, false)
    
    -- 设置慢速高伤属性
    SetWandStat(wand, "actions_per_round", 1)
    SetWandStat(wand, "fire_rate_wait", 40)
    SetWandStat(wand, "reload_time", 60)
    SetWandStat(wand, "capacity", 4)
    
    -- 高法力
    SetWandStat(wand, "mana_max", 1000)
    SetWandStat(wand, "mana_charge_speed", 200)
    
    -- 添加爆炸法术
    local explosive_spells = {
        "BOMB",
        "DYNAMITE",
        "GRENADE",
        "ROCKET",
        "NUKE",
    }
    
    -- 根据等级过滤
    local available = {}
    for _, spell_id in pairs(explosive_spells) do
        local spell = GetSpell(spell_id)
        if CanSpawnAtLevel(spell, level) then
            table.insert(available, spell_id)
        end
    end
    
    -- 添加2-3个爆炸法术
    for i = 1, Random(2, 3) do
        local spell = available[Random(1, #available)]
        AddSpellToWand(wand, spell)
    end
    
    -- 可能添加爆炸修正器作为永久法术
    if Random(0, 1) < 0.3 then
        SetAlwaysCast(wand, "EXPLOSIVE_PROJECTILE")
    end
    
    return wand
end
```

## 六、以撒模组实现建议

### 6.1 数据结构映射
```lua
-- 以撒物品 -> Noita法杖
Isaac.WandItem = {
    -- 基础属性
    Charges = 0,           -- 对应 mana_max
    ChargeRate = 0,        -- 对应 mana_charge_speed
    
    -- 法杖属性 (存储在item的data table中)
    Data = {
        Capacity = 4,
        ActionsPerRound = 1,
        ReloadTime = 30,
        ShuffleDeck = true,
        FireRateWait = 10,
        SpreadDegrees = 0,
        SpeedMultiplier = 1.0,
        
        -- 法术列表
        Spells = {},
        AlwaysCast = nil,
    }
}
```

### 6.2 施法循环实现
```lua
-- 以撒主动道具使用回调
function OnWandUse(item, player)
    local wand_data = item:GetData()
    
    -- 检查法力
    if item.Charge < GetNextSpellManaCost(wand_data) then
        return false  -- 法力不足
    end
    
    -- 施法循环
    for i = 1, wand_data.ActionsPerRound do
        -- 抽取法术
        local spell = DrawSpell(wand_data)
        if not spell then
            -- 牌组空了,装填
            Reload(wand_data)
            break
        end
        
        -- 消耗法力
        item.Charge = item.Charge - spell.mana
        
        -- 执行法术
        CastSpell(spell, player, wand_data)
        
        -- 施法延迟
        player:AddCacheFlags(CacheFlag.FIRE_DELAY)
        player:EvaluateItems()
    end
    
    return true
end

-- 抽牌逻辑
function DrawSpell(wand_data)
    -- 从hand抽取
    if #wand_data.Hand > 0 then
        local spell = table.remove(wand_data.Hand, 1)
        table.insert(wand_data.Discarded, spell)
        return spell
    end
    
    -- hand空了,检查是否需要装填
    if #wand_data.Deck == 0 then
        if wand_data.ShuffleDeck then
            -- 洗牌
            wand_data.Deck = ShuffleArray(wand_data.Discarded)
            wand_data.Discarded = {}
        else
            -- 不洗牌,按顺序
            wand_data.Deck = wand_data.Discarded
            wand_data.Discarded = {}
        end
    end
    
    -- 从deck抽取
    if #wand_data.Deck > 0 then
        return table.remove(wand_data.Deck, 1)
    end
    
    return nil
end

-- 施法实现
function CastSpell(spell, player, wand_data)
    -- 应用永久法术修正
    local stats = {
        speed = wand_data.SpeedMultiplier,
        spread = wand_data.SpreadDegrees,
    }
    
    if wand_data.AlwaysCast then
        ApplySpellModifiers(stats, wand_data.AlwaysCast)
    end
    
    -- 应用法术自身修正
    ApplySpellModifiers(stats, spell)
    
    -- 发射抛射物
    if spell.projectile_file then
        SpawnProjectile(player, spell.projectile_file, stats)
    end
    
    -- 执行特殊效果
    if spell.special_effect then
        spell.special_effect(player, stats)
    end
end
```

### 6.3 法杖生成集成
```lua
-- 在房间生成时创建法杖
function OnRoomClear()
    local level = Game():GetLevel()
    local stage = level:GetStage()
    
    -- 10%概率生成法杖
    if Random(0, 1) < 0.1 then
        local room = Game():GetRoom()
        local pos = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true)
        
        -- 生成对应层级的法杖
        local wand = GenerateIsaacWand(stage, pos.X, pos.Y)
        Isaac.Spawn(EntityType.PICKUP, PickupVariant.COLLECTIBLE, wand.ID, pos, Vector.Zero, nil)
    end
end

-- 创建以撒法杖物品
function GenerateIsaacWand(stage, x, y)
    -- 使用Noita算法生成属性
    local stats = GenerateWandStats(stage, false)
    
    -- 创建以撒物品
    local wand = RegisterActiveItem("WAND_" .. stage .. "_" .. Random(1, 9999))
    
    -- 映射属性
    wand.MaxCharges = math.floor(stats.mana_max / 100)
    wand.ChargeType = ItemConfig.CHARGE_TIMED
    
    -- 存储法杖数据
    wand.Data = {
        Capacity = stats.capacity,
        ActionsPerRound = stats.actions_per_round,
        ReloadTime = stats.reload_time,
        ShuffleDeck = stats.shuffle_deck_when_empty,
        FireRateWait = stats.fire_rate_wait,
        SpreadDegrees = stats.spread_degrees,
        SpeedMultiplier = stats.speed_multiplier,
        
        Spells = {},
        Deck = {},
        Hand = {},
        Discarded = {},
        AlwaysCast = nil,
    }
    
    -- 添加法术
    AddRandomSpells(wand, stage, Random(2, stats.capacity))
    
    -- 初始化deck
    for _, spell in pairs(wand.Data.Spells) do
        table.insert(wand.Data.Deck, spell)
    end
    
    if stats.shuffle_deck_when_empty then
        wand.Data.Deck = ShuffleArray(wand.Data.Deck)
    end
    
    -- 永久法术
    if RollAlwaysCast(stage) then
        wand.Data.AlwaysCast = SelectAlwaysCast(stage)
    end
    
    return wand
end
```

## 七、关键实现要点

### 7.1 属性平衡
- **容量 vs 施法数**: 高容量通常配低施法数
- **装填时间 vs 施法延迟**: 两者成反比
- **法力 vs 消耗**: 快速施法需要高法力恢复
- **扩散 vs 伤害**: 低扩散通常配低伤害

### 7.2 法术组合原则
1. **必须有抛射物**: 至少一个能造成伤害的法术
2. **修正器比例**: 30-40%修正器,60-70%抛射物/特殊
3. **避免纯修正器**: 确保有输出能力
4. **稀有度平衡**: 不要全是高级法术或全是低级法术

### 7.3 随机性控制
```lua
-- 使用种子确保可重现
function SetDeterministicSeed(x, y, game_time)
    math.randomseed(x * 1000 + y * 100 + game_time)
end

-- 每日种子
function SetDailySeed(day_number)
    math.randomseed(20250116 + day_number)
end
```

### 7.4 性能优化
- 法术池预计算并缓存
- 避免每次施法重新过滤
- 使用对象池复用抛射物

## 八、完整示例: 第3层法杖生成

```lua
function GenerateLevel3Wand()
    -- 1. 设置种子
    SetRandomSeed(os.time())
    
    -- 2. 生成属性
    local wand = {
        capacity = 7,              -- 正态分布(7, 2) -> [5, 10]
        actions_per_round = 2,     -- 正态分布(2, 0.7) -> [1, 4]
        reload_time = 35,          -- 正态分布(35, 10) -> [20, 50]
        fire_rate_wait = 7,        -- 正态分布(7, 5) -> [0, 15]
        spread_degrees = 2,        -- 正态分布(2, 4) -> [-5, 10]
        speed_multiplier = 1.5,    -- 正态分布(1.5, 0.4) -> [1.0, 2.0]
        mana_max = 500,            -- 正态分布(500, 100) -> [300, 700]
        mana_charge_speed = 200,   -- 正态分布(200, 60) -> [100, 300]
        shuffle_deck_when_empty = true,  -- 50%概率
        
        spells = {},
        always_cast = nil,
    }
    
    -- 3. 添加法术 (5个)
    -- 法术池过滤
    local spell_pool = {
        {id = "LIGHT_BULLET", prob = 1.0, type = "projectile"},
        {id = "HEAVY_BULLET", prob = 0.8, type = "projectile"},
        {id = "ENERGY_ORB", prob = 0.6, type = "projectile"},
        {id = "BOMB", prob = 0.5, type = "projectile"},
        {id = "DAMAGE", prob = 0.7, type = "modifier"},
        {id = "SPEED", prob = 0.6, type = "modifier"},
        {id = "HOMING", prob = 0.3, type = "modifier"},
    }
    
    -- 第一个: 必定是抛射物
    table.insert(wand.spells, SelectByWeight(
        FilterByType(spell_pool, "projectile")
    ))
    
    -- 后续4个: 混合
    for i = 2, 5 do
        if Random() < 0.3 then
            -- 30%修正器
            local spell = SelectByWeight(
                FilterByType(spell_pool, "modifier")
            )
            table.insert(wand.spells, spell)
        else
            -- 70%抛射物
            local spell = SelectByWeight(
                FilterByType(spell_pool, "projectile")
            )
            table.insert(wand.spells, spell)
        end
    end
    
    -- 4. 8%概率永久法术
    if Random() < 0.08 then
        local always_pool = {"CHAINSAW", "CRITICAL_HIT", "DAMAGE"}
        wand.always_cast = always_pool[Random(1, 3)]
    end
    
    -- 5. 初始化施法状态
    wand.deck = CopyArray(wand.spells)
    if wand.shuffle_deck_when_empty then
        wand.deck = ShuffleArray(wand.deck)
    end
    wand.hand = {}
    wand.discarded = {}
    
    return wand
end
```

这个详细的实现指南应该能帮助你将Noita的法杖系统移植到以撒模组中!