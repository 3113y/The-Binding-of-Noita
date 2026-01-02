-- Noita法杖自然生成系统
-- 基于Noita原版生成算法实现

TBoN.World.Function = TBoN.World.Function or {}
TBoN.World.Function.Custom = TBoN.World.Function.Custom or {}

-- ==================== 辅助函数 ====================

-- Box-Muller变换: 生成正态分布随机数
local function RandomNormal(mean, stddev, rng)
    local u1 = rng:RandomFloat()
    local u2 = rng:RandomFloat()
    local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return mean + z * stddev
end

-- 限制范围的正态分布
local function ClampedNormal(mean, stddev, min_val, max_val, rng)
    local value = RandomNormal(mean, stddev, rng)
    return math.max(min_val, math.min(max_val, value))
end

-- 四舍五入
local function Round(num)
    return math.floor(num + 0.5)
end

-- 限制数值范围
local function Clamp(value, min_val, max_val)
    return math.max(min_val, math.min(max_val, value))
end

-- ==================== 核心生成配置 ====================

-- 各楼层法杖属性生成配置
-- 格式: {最小值, 最大值, 平均值, 标准差}
local WAND_GENERATION_CONFIG = {
    [1] = {  -- 地下室 (Basement)
        capacity = {3, 6, 4, 1},
        cast_delay = {5, 20, 12, 5},
        recharge_time = {30, 70, 50, 15},
        mana_max = {100, 300, 200, 50},
        mana_charge_speed = {50, 150, 100, 30},
        spread_degrees = {0, 5, 2, 2},
        shuffle_probability = 0.7,  -- 70%概率洗牌
        always_cast_probability = 0.02,  -- 2%概率永久法术
        spell_count_min = 2,
        spell_count_max = 4,
    },
    [2] = {  -- 地窖 (Cellar/Caves)
        capacity = {4, 8, 6, 1.5},
        cast_delay = {3, 18, 10, 5},
        recharge_time = {25, 60, 40, 12},
        mana_max = {200, 500, 350, 80},
        mana_charge_speed = {80, 200, 140, 40},
        spread_degrees = {-2, 8, 3, 3},
        shuffle_probability = 0.6,
        always_cast_probability = 0.05,
        spell_count_min = 3,
        spell_count_max = 6,
    },
    [3] = {  -- 洞穴 (Depths)
        capacity = {5, 10, 7, 2},
        cast_delay = {0, 15, 7, 5},
        recharge_time = {20, 50, 35, 10},
        mana_max = {300, 700, 500, 100},
        mana_charge_speed = {100, 300, 200, 60},
        spread_degrees = {-5, 10, 2, 4},
        shuffle_probability = 0.5,
        always_cast_probability = 0.08,
        spell_count_min = 4,
        spell_count_max = 7,
    },
    [4] = {  -- 子宫 (Womb)
        capacity = {6, 13, 9, 2},
        cast_delay = {-5, 12, 5, 5},
        recharge_time = {10, 45, 25, 10},
        mana_max = {400, 1000, 700, 150},
        mana_charge_speed = {150, 400, 275, 80},
        spread_degrees = {-8, 12, 1, 5},
        shuffle_probability = 0.4,
        always_cast_probability = 0.12,
        spell_count_min = 5,
        spell_count_max = 9,
    },
    [5] = {  -- 大教堂 (Cathedral/Sheol)
        capacity = {7, 16, 11, 3},
        cast_delay = {-10, 10, 2, 6},
        recharge_time = {0, 40, 20, 12},
        mana_max = {500, 1500, 1000, 250},
        mana_charge_speed = {200, 600, 400, 120},
        spread_degrees = {-10, 15, 0, 6},
        shuffle_probability = 0.3,
        always_cast_probability = 0.15,
        spell_count_min = 6,
        spell_count_max = 11,
    },
    [6] = {  -- 宝箱 (Chest/Dark Room)
        capacity = {8, 20, 14, 4},
        cast_delay = {-15, 8, 0, 7},
        recharge_time = {-10, 35, 15, 15},
        mana_max = {600, 2000, 1300, 350},
        mana_charge_speed = {300, 800, 550, 150},
        spread_degrees = {-12, 18, -2, 8},
        shuffle_probability = 0.2,
        always_cast_probability = 0.20,
        spell_count_min = 7,
        spell_count_max = 14,
    }
}

-- 永久法术池配置 (按楼层分级)
local ALWAYS_CAST_POOL = {
    -- 1-2层可用
    {id = "LIGHT_BULLET", min_floor = 1, weight = 5},
    {id = "BULLET", min_floor = 1, weight = 6},
    
    -- 3-4层可用
    {id = "HEAVY_BULLET", min_floor = 3, weight = 7},
    {id = "BOMB", min_floor = 3, weight = 4},
    
    -- 5-6层可用
    {id = "BLACK_HOLE", min_floor = 5, weight = 3},
    {id = "TELEPORT_PROJECTILE", min_floor = 5, weight = 5},
}

-- ==================== 法杖属性生成 ====================

-- 洗牌表
local function ShuffleTable(t, rng)
    for i = #t, 2, -1 do
        local j = rng:RandomInt(i) + 1
        t[i], t[j] = t[j], t[i]
    end
end

-- 生成法杖基础属性（参考Noita原版cost系统）
function TBoN.World.Function.Custom.GenerateWandStats(floor, is_better, rng)
    -- 限制楼层范围
    floor = Clamp(floor, 1, 6)
    local config = WAND_GENERATION_CONFIG[floor]
    
    -- 初始化cost系统（楼层越高cost越高）
    local cost = 20 + floor * 10 + rng:RandomInt(7) - 3
    if is_better then
        cost = cost + 65  -- 稀有法杖增加cost
    end
    
    local stats = {
        cost = cost,
        prob_unshuffle = 0.1,  -- 不洗牌概率累积
        prob_draw_many = 0.15, -- 多抽取概率
    }
    
    -- Mana系统变化
    stats.mana_max = 50 + (150 * floor) + (rng:RandomInt(11) - 5) * 10
    stats.mana_charge_speed = 50 * floor + rng:RandomInt(11) - 5
    
    -- 20%概率：慢充能大容量
    if rng:RandomFloat() < 0.2 then
        stats.mana_charge_speed = stats.mana_charge_speed / 5
        stats.mana_max = stats.mana_max * 3
    end
    
    -- 15%概率：快充能小容量
    if rng:RandomFloat() < 0.15 then
        stats.mana_charge_speed = stats.mana_charge_speed * 5
        stats.mana_max = stats.mana_max / 3
    end
    
    -- 确保最小值
    stats.mana_max = math.max(50, Round(stats.mana_max))
    stats.mana_charge_speed = math.max(10, Round(stats.mana_charge_speed))
    
    -- 强制不洗牌概率（随楼层增加）
    local force_unshuffle = (rng:RandomFloat() < (0.15 + floor * 0.06))
    if force_unshuffle then
        stats.prob_unshuffle = stats.prob_unshuffle + 1.0
    end
    
    -- 按随机顺序生成属性（模拟原版算法）
    local attr_order = {"spread", "cast_delay", "recharge_time", "speed"}
    ShuffleTable(attr_order, rng)
    
    -- 1. 生成基础属性（消耗cost）
    for _, attr in ipairs(attr_order) do
        if attr == "spread" then
            -- spread: cost影响范围，负spread增加cost
            local min_spread = Clamp(cost / -1.5, -35, 35)
            local max_spread = 35
            local raw_spread = ClampedNormal(
                config.spread_degrees[3],
                config.spread_degrees[4],
                min_spread,
                max_spread,
                rng
            )
            stats.spread_degrees = math.floor(raw_spread * 10 + 0.5) / 10
            stats.cost = stats.cost + stats.spread_degrees * 1.5
            
        elseif attr == "cast_delay" then
            -- cast_delay: cost: 16-delay
            local min_delay = Clamp(16 - cost, -50, 50)
            local max_delay = 50
            stats.cast_delay = Round(ClampedNormal(
                config.cast_delay[3],
                config.cast_delay[4],
                min_delay,
                max_delay,
                rng
            ))
            stats.cost = stats.cost - (16 - stats.cast_delay)
            
        elseif attr == "recharge_time" then
            -- recharge_time: cost: (60-time)/5
            local min_reload = Clamp(60 - (cost * 5), 1, 240)
            local max_reload = 240
            stats.recharge_time = Round(ClampedNormal(
                config.recharge_time[3],
                config.recharge_time[4],
                min_reload,
                max_reload,
                rng
            ))
            stats.cost = stats.cost - ((60 - stats.recharge_time) / 5)
            
        elseif attr == "speed" then
            -- speed_multiplier: 不影响cost
            stats.speed_multiplier = ClampedNormal(1.0, 0.1, 0.8, 1.2, rng)
        end
    end
    
    -- 2. 生成容量（基于剩余cost）
    local min_capacity = 1
    local max_capacity = Clamp((stats.cost / 5) + 6, 1, 20)
    
    -- 大容量增加不洗牌倾向
    if max_capacity > 9 then
        stats.prob_unshuffle = stats.prob_unshuffle + 0.8
    end
    
    stats.capacity = Round(ClampedNormal(
        config.capacity[3],
        config.capacity[4],
        min_capacity,
        max_capacity,
        rng
    ))
    stats.capacity = Clamp(stats.capacity, 2, 26)  -- UI限制
    stats.cost = stats.cost - ((stats.capacity - 6) * 5)
    
    -- 3. 决定洗牌
    local shuffle_roll = rng:RandomFloat()
    if force_unshuffle or shuffle_roll > config.shuffle_probability or 
       (shuffle_roll < stats.prob_unshuffle and stats.capacity <= 9) then
        stats.shuffle = false
        stats.cost = stats.cost - (15 + stats.capacity * 5)
    else
        stats.shuffle = true
    end
    
    -- 4. 每轮抽取数（基于cost）
    local action_costs = {20, 40, 60, 80, 100}
    local max_actions = 1
    for i, acost in ipairs(action_costs) do
        if stats.cost >= acost then
            max_actions = i
        end
    end
    max_actions = math.min(max_actions, stats.capacity)
    
    stats.actions_per_round = Round(ClampedNormal(1.5, 0.8, 1, max_actions, rng))
    stats.actions_per_round = Clamp(stats.actions_per_round, 1, stats.capacity)
    
    local action_cost = action_costs[Clamp(stats.actions_per_round, 1, #action_costs)] or 0
    stats.cost = stats.cost - action_cost
    
    -- Better法杖额外提升
    if is_better then
        stats.capacity = Round(stats.capacity * 1.2)
        stats.mana_max = Round(stats.mana_max * 1.3)
        stats.mana_charge_speed = Round(stats.mana_charge_speed * 1.2)
        stats.cast_delay = Round(stats.cast_delay * 0.7)
        stats.recharge_time = Round(stats.recharge_time * 0.7)
        stats.spread_degrees = math.floor(stats.spread_degrees * 0.6 * 10 + 0.5) / 10
    end
    
    return stats
end

-- ==================== 法术选择算法 ====================

-- 选择永久法术 (Always Cast)
local function SelectAlwaysCast(floor, rng)
    -- 过滤可用法术
    local available = {}
    local total_weight = 0
    
    for _, spell_data in ipairs(ALWAYS_CAST_POOL) do
        if floor >= spell_data.min_floor then
            table.insert(available, spell_data)
            total_weight = total_weight + spell_data.weight
        end
    end
    
    if #available == 0 then
        return nil
    end
    
    -- 加权随机选择
    local roll = rng:RandomFloat() * total_weight
    local cumulative = 0
    
    for _, spell_data in ipairs(available) do
        cumulative = cumulative + spell_data.weight
        if roll <= cumulative then
            return spell_data.id
        end
    end
    
    return available[1].id
end

-- 为法杖添加随机法术
local function AddRandomSpells(wand_spells, floor, count, capacity, rng)
    -- 获取该层可用法术池
    local available_spells = TBoN.World.Function.Custom.GetAvailableSpellsByFloor(floor)
    
    if #available_spells == 0 then
        return
    end
    
    -- 确保至少有一个投射物法术
    local has_projectile = false
    local added_count = 0
    
    for i = 1, math.min(count, capacity) do
        local spell_id = nil
        
        -- 第一个法术必须是投射物
        if i == 1 or not has_projectile then
            -- 过滤投射物类型
            local projectile_spells = {}
            for _, spell_data in ipairs(available_spells) do
                local action = actions[TBoN.Render.Table.actions_map[spell_data.id]]
                if action and action.type == ACTION_TYPE_PROJECTILE then
                    table.insert(projectile_spells, spell_data)
                end
            end
            
            if #projectile_spells > 0 then
                local selected = projectile_spells[rng:RandomInt(#projectile_spells) + 1]
                spell_id = selected.id
                has_projectile = true
            end
        end
        
        -- 如果没有选到法术,从全池随机选择
        if not spell_id then
            local selected = available_spells[rng:RandomInt(#available_spells) + 1]
            spell_id = selected.id
        end
        
        -- 添加到法杖
        if spell_id then
            -- 从 gun_actions 获取法术的 max_uses
            local action = actions[TBoN.Render.Table.actions_map[spell_id]]
            local max_uses = -1  -- 默认无限使用
            if action and action.max_uses then
                max_uses = action.max_uses
            end
            
            table.insert(wand_spells, {
                magic_id = spell_id,
                current_uses = max_uses,  -- 当前使用次数等于最大使用次数
                max_uses = max_uses
            })
            added_count = added_count + 1
        end
    end
end

-- ==================== 法杖完整生成 ====================

-- 生成完整法杖数据
function TBoN.World.Function.Custom.GenerateWand(floor, is_better, rng)
    is_better = is_better or false
    
    -- 如果没有提供RNG，创建一个基于当前游戏种子的RNG
    if not rng then
        rng = RNG()
        local seeds = Game():GetSeeds()
        local start_seed = seeds:GetStartSeed()
        rng:SetSeed(start_seed, 35)
    end
    
    -- 1. 生成基础属性
    local stats = TBoN.World.Function.Custom.GenerateWandStats(floor, is_better, rng)
    
    -- 2. 选择法杖外观 (随机选择一个wand sprite)
    local wand_sprite_count = 100  -- 假设有100个法杖外观
    local wand_name = string.format("wand_%04d", rng:RandomInt(wand_sprite_count))
    
    -- 3. 创建法杖数据结构
    local wand = {
        name = wand_name,
        shuffle = stats.shuffle,
        capacity = stats.capacity,
        cast_delay = stats.cast_delay,
        recharge_time = stats.recharge_time,
        mana_max = stats.mana_max,
        mana_charge_speed = stats.mana_charge_speed,
        spread_degrees = stats.spread_degrees,
        actions_per_round = stats.actions_per_round or 1,
        speed_multiplier = stats.speed_multiplier or 1.0,
    }
    
    -- 4. 添加法术
    local spell_slots = {}
    local config = WAND_GENERATION_CONFIG[Clamp(floor, 1, 6)]
    local spell_count = rng:RandomInt(config.spell_count_max - config.spell_count_min + 1) + config.spell_count_min
    spell_count = math.min(spell_count, stats.capacity)  -- 不超过容量
    
    AddRandomSpells(spell_slots, floor, spell_count, stats.capacity, rng)
    
    -- 填充剩余空槽
    for i = #spell_slots + 1, stats.capacity do
        table.insert(spell_slots, {
            magic_id = false,
            current_uses = 0,
            max_uses = 0
        })
    end
    
    -- 5. 永久法术 (Always Cast)
    if rng:RandomFloat() < config.always_cast_probability then
        wand.always_cast = SelectAlwaysCast(floor, rng)
    else
        wand.always_cast = nil
    end
    return wand, spell_slots
end

-- ==================== 初始法杖生成 ====================

-- 生成初始魔杖（火花弹为主）
function TBoN.World.Function.Custom.GenerateStarterWand(rng)
    if not rng then
        rng = RNG()
        rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
    end
    
    -- 随机属性范围
    local cast_delay = rng:RandomInt(7) + 9  -- 9-15帧 (0.15-0.25s)
    local recharge_time = rng:RandomInt(9) + 20  -- 20-28帧 (0.33-0.47s)
    local mana_max = rng:RandomInt(51) + 80  -- 80-130
    local mana_charge_speed = rng:RandomFloat() * 1.5 + 2.5  -- 2.5-4.0
    mana_charge_speed = math.floor(mana_charge_speed * 10 + 0.5) / 10  -- 保留一位小数
    local capacity = rng:RandomInt(2) + 2  -- 2-3
    
    -- 选择法杖外观
    local wand_sprite_count = 100
    local wand_name = "wand_b_0000"
    
    -- 创建法杖数据
    local wand = {
        name = wand_name,
        shuffle = false,
        capacity = capacity,
        cast_delay = cast_delay,
        recharge_time = recharge_time,
        mana_max = mana_max,
        mana_charge_speed = mana_charge_speed,
        spread_degrees = 0.0,
        always_cast = nil,
    }
    
    -- 选择初始法术：50%火花弹，50%普通子弹
    local spell_slots = {}
    local spell_id = "LIGHT_BULLET"
    
    -- 获取法术的max_uses
    local action = actions[TBoN.Render.Table.actions_map[spell_id]]
    local max_uses = -1
    if action and action.max_uses then
        max_uses = action.max_uses
    end
    
    table.insert(spell_slots, {
        magic_id = spell_id,
        current_uses = max_uses,
        max_uses = max_uses
    })
    
    -- 填充剩余空槽
    for i = 2, capacity do
        table.insert(spell_slots, {
            magic_id = false,
            current_uses = 0,
            max_uses = 0
        })
    end
    return wand, spell_slots
end

-- 生成初始炸弹杖
function TBoN.World.Function.Custom.GenerateStarterBombWand(rng)
    if not rng then
        rng = RNG()
        rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
    end
    
    -- 随机属性范围
    local cast_delay = rng:RandomInt(6) + 3  -- 3-8帧 (0.05-0.13s)
    local recharge_time = rng:RandomInt(10) + 1  -- 1-10帧 (0.02-0.17s)
    local mana_max = rng:RandomInt(31) + 80  -- 80-110
    local mana_charge_speed = rng:RandomFloat() * 15 + 5  -- 5-20
    mana_charge_speed = math.floor(mana_charge_speed * 10 + 0.5) / 10  -- 保留一位小数
    
    -- 选择法杖外观
    local wand_sprite_count = 100
    local wand_name = "wand_b_0001"
    
    -- 创建法杖数据
    local wand = {
        name = wand_name,
        shuffle = true,
        capacity = 1,
        cast_delay = cast_delay,
        recharge_time = recharge_time,
        mana_max = mana_max,
        mana_charge_speed = mana_charge_speed,
        spread_degrees = 0.0,
        always_cast = nil,
    }
    
    -- 选择初始法术：60%炸弹，40%火花弹
    local spell_slots = {}
    local spell_id = "BOMB"
    
    -- 获取法术的max_uses
    local action = actions[TBoN.Render.Table.actions_map[spell_id]]
    local max_uses = -1
    if action and action.max_uses then
        max_uses = action.max_uses
    end
    
    table.insert(spell_slots, {
        magic_id = spell_id,
        current_uses = max_uses,
        max_uses = max_uses
    })
    return wand, spell_slots
end

-- ==================== 房间生成钩子 ====================

-- 在清房后生成法杖
function TBoN_MOD:OnRoomClearWandSpawn()
    local level = Game():GetLevel()
    local room = level:GetCurrentRoom()
    local stage = level:GetStage()
    
    -- 跳过特殊房间
    if room:GetType() == RoomType.ROOM_BOSS or
       room:GetType() == RoomType.ROOM_TREASURE or
       room:GetType() == RoomType.ROOM_SHOP then
        return
    end
    
    -- 创建基于房间的确定性RNG
    local rng = RNG()
    local seeds = Game():GetSeeds()
    local room_seed = room:GetDecorationSeed()  -- 使用房间装饰种子确保每个房间独立
    rng:SetSeed(room_seed, 35)
    
    -- 10%概率生成法杖
    if rng:RandomFloat() < 0.1 then
        local pos = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true)
        
        -- 5%概率生成Better法杖
        local is_better = (rng:RandomFloat() < 0.05)
        
        -- 生成法杖数据
        local wand_data, spell_slots = TBoN.World.Function.Custom.GenerateWand(stage, is_better, rng)
        
        -- TODO: 创建实际的法杖拾取物
        -- 这里需要实现将wand_data和spell_slots保存并生成对应的实体
        print("[WAND_GEN] 在位置 " .. tostring(pos) .. " 生成法杖")
        
        -- 示例: 生成一个占位符实体
        -- Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.COLLECTIBLE, wand_item_id, pos, Vector.Zero, nil)
    end
end

-- 注册清房回调
-- TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, TBoN_MOD.OnRoomClearWandSpawn)

return TBoN.World.Function.Custom
