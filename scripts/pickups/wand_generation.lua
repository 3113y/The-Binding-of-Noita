include("scripts.pickups.wands_data")

local function clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end
    return math.max(lower, math.min(upper, val))
end

local function Round(num)
    return math.floor(num + 0.5)
end
local function RandomDistribution(min, max, mean, sharpness, rng)
    if min >= max then return min end
    if sharpness <= 0 then
        return min + rng:RandomFloat() * (max - min)
    end
    local best = min + rng:RandomFloat() * (max - min)
    local best_dist = math.abs(best - mean)
    local samples = math.min(sharpness + 1, 10)
    for i = 2, samples do
        local val = min + rng:RandomFloat() * (max - min)
        local dist = math.abs(val - mean)
        if dist < best_dist then
            best = val
            best_dist = dist
        end
    end
    return best
end

-- 浮点版本 (不做四舍五入)
local function RandomDistributionf(min, max, mean, sharpness, rng)
    return RandomDistribution(min, max, mean, sharpness, rng)
end

-- 整数随机 [min, max] (含两端)
local function RandomInt(min, max, rng)
    if min >= max then return min end
    return min + rng:RandomInt(max - min + 1)
end

-- 百分比随机 [0, 100)
local function Random100(rng)
    return rng:RandomInt(101) -- 0-100
end

local function ShuffleTable(t, rng)
    for i = #t, 2, -1 do
        local j = rng:RandomInt(i) + 1
        t[i], t[j] = t[j], t[i]
    end
end

local function RandomFromArray(varray, rng)
    local r = rng:RandomInt(#varray) + 1
    return varray[r]
end

-- ============================================================================
-- gun_probs 概率分布表 (完全还原原版)
-- ============================================================================

-- 普通法杖的概率分布 (来自 gun_procedural.lua)
local gun_probs_normal = {}

gun_probs_normal["deck_capacity"] = {
    name = "deck_capacity", total_prob = 0,
    { prob = 1,    min = 3,  max = 10, mean = 6, sharpness = 2 },
    { prob = 0.1,  min = 2,  max = 7,  mean = 4, sharpness = 4,
      extra = function(gun) gun["prob_unshuffle"] = gun["prob_unshuffle"] + 0.8 end },
    { prob = 0.05, min = 1,  max = 5,  mean = 3, sharpness = 4,
      extra = function(gun) gun["prob_unshuffle"] = gun["prob_unshuffle"] + 0.8 end },
    { prob = 0.15, min = 5,  max = 11, mean = 8, sharpness = 2 },
    { prob = 0.12, min = 2,  max = 20, mean = 8, sharpness = 4 },
    { prob = 0.15, min = 3,  max = 12, mean = 6, sharpness = 6,
      extra = function(gun) gun["prob_draw_many"] = gun["prob_draw_many"] + 0.8 end },
    { prob = 1,    min = 1,  max = 20, mean = 6, sharpness = 0 },
}

gun_probs_normal["reload_time"] = {
    name = "reload_time", total_prob = 0,
    { prob = 1,    min = 5,   max = 60,  mean = 30, sharpness = 2 },
    { prob = 0.5,  min = 1,   max = 100, mean = 40, sharpness = 2 },
    { prob = 0.02, min = 1,   max = 100, mean = 40, sharpness = 0 },
    { prob = 0.35, min = 1,   max = 240, mean = 40, sharpness = 0,
      extra = function(gun) gun["prob_unshuffle"] = gun["prob_unshuffle"] + 0.5 end },
}

gun_probs_normal["fire_rate_wait"] = {
    name = "fire_rate_wait", total_prob = 0,
    { prob = 1,    min = 1,   max = 30, mean = 5,  sharpness = 2 },
    { prob = 0.1,  min = 1,   max = 50, mean = 15, sharpness = 3 },
    { prob = 0.1,  min = -15, max = 15, mean = 0,  sharpness = 3 },
    { prob = 0.45, min = 0,   max = 35, mean = 12, sharpness = 0 },
}

gun_probs_normal["spread_degrees"] = {
    name = "spread_degrees", total_prob = 0,
    { prob = 1,   min = -5,  max = 10, mean = 0, sharpness = 3 },
    { prob = 0.1, min = -35, max = 35, mean = 0, sharpness = 0 },
}

gun_probs_normal["speed_multiplier"] = {
    name = "speed_multiplier", total_prob = 0,
    { prob = 1,     min = 0.8, max = 1.2, mean = 1,   sharpness = 6 },
    { prob = 0.05,  min = 1,   max = 2,   mean = 1.1, sharpness = 3 },
    { prob = 0.05,  min = 0.5, max = 1,   mean = 0.9, sharpness = 3 },
    { prob = 1,     min = 0.8, max = 1.2, mean = 1,   sharpness = 0 },
    { prob = 0.001, min = 1,   max = 10,  mean = 5,   sharpness = 2 },
}

gun_probs_normal["actions_per_round"] = {
    name = "actions_per_round", total_prob = 0,
    { prob = 1,    min = 1, max = 3, mean = 1, sharpness = 3 },
    { prob = 0.2,  min = 2, max = 4, mean = 2, sharpness = 8 },
    { prob = 0.05, min = 1, max = 5, mean = 2, sharpness = 2 },
    { prob = 1,    min = 1, max = 5, mean = 2, sharpness = 0 },
}

-- Better法杖的概率分布 (来自 gun_procedural_better.lua) - 更窄更好的分布
local gun_probs_better = {}

gun_probs_better["deck_capacity"] = {
    name = "deck_capacity", total_prob = 0,
    { prob = 1, min = 5, max = 13, mean = 8, sharpness = 2 },
}

gun_probs_better["reload_time"] = {
    name = "reload_time", total_prob = 0,
    { prob = 1, min = 5, max = 40, mean = 20, sharpness = 2 },
}

gun_probs_better["fire_rate_wait"] = {
    name = "fire_rate_wait", total_prob = 0,
    { prob = 1, min = 1, max = 35, mean = 5, sharpness = 2 },
}

gun_probs_better["spread_degrees"] = {
    name = "spread_degrees", total_prob = 0,
    { prob = 1, min = -1, max = 2, mean = 0, sharpness = 3 },
}

gun_probs_better["speed_multiplier"] = {
    name = "speed_multiplier", total_prob = 0,
    { prob = 1, min = 0.8, max = 1.2, mean = 1, sharpness = 6 },
}

gun_probs_better["actions_per_round"] = {
    name = "actions_per_round", total_prob = 0,
    { prob = 1, min = 1, max = 3, mean = 1, sharpness = 3 },
}

-- ============================================================================
-- 概率系统函数
-- ============================================================================

local function init_total_prob(value)
    value.total_prob = 0
    for i, v in ipairs(value) do
        if v.prob ~= nil then
            value.total_prob = value.total_prob + v.prob
        end
    end
end

local function init_gun_probs(probs)
    for k, v in pairs(probs) do
        init_total_prob(probs[k])
    end
end

local function get_gun_probs(probs, what, rng)
    if probs[what] == nil then return nil end
    if probs[what].total_prob == 0 then
        init_total_prob(probs[what])
    end

    local r = rng:RandomFloat() * probs[what].total_prob
    local last_entry = nil
    for i, v in ipairs(probs[what]) do
        if type(v) == "number" then
            return { prob = v, min = v, max = v, mean = v, sharpness = 0 }
        end
        if v.prob ~= nil then
            last_entry = v
            if r <= v.prob then
                return v
            end
            r = r - v.prob
        end
    end
    -- 浮点精度兜底: 返回最后一个有效条目
    return last_entry
end

-- ============================================================================
-- 属性生成函数 (完全还原原版 apply_random_variable)
-- ============================================================================

local function apply_random_variable(t_gun, variable, probs, rng)
    local cost = t_gun["cost"]
    local prob_entry = get_gun_probs(probs, variable, rng)

    if not prob_entry then
        -- 安全兜底: 使用中间值
        prob_entry = { prob = 1, min = 0, max = 1, mean = 0.5, sharpness = 0 }
    end

    -- 调用 extra 回调 (用于修改 prob_unshuffle 等)
    if prob_entry.extra then
        prob_entry.extra(t_gun)
    end

    -- reload_time: [1-240], cost = (60-reload_time)/5
    if variable == "reload_time" then
        local min = clamp(60 - (cost * 5), 1, 240)
        local max = 1024
        t_gun[variable] = clamp(
            RandomDistribution(prob_entry.min, prob_entry.max, prob_entry.mean, prob_entry.sharpness, rng),
            min, max)
        t_gun[variable] = Round(t_gun[variable])
        t_gun["cost"] = t_gun["cost"] - ((60 - t_gun[variable]) / 5)
        return
    end

    -- fire_rate_wait: [-50, 50], cost = 16-fire_rate_wait
    if variable == "fire_rate_wait" then
        local min = clamp(16 - cost, -50, 50)
        local max = 50
        t_gun[variable] = clamp(
            RandomDistribution(prob_entry.min, prob_entry.max, prob_entry.mean, prob_entry.sharpness, rng),
            min, max)
        t_gun[variable] = Round(t_gun[variable])
        t_gun["cost"] = t_gun["cost"] - (16 - t_gun[variable])
        return
    end

    -- spread_degrees: [-35, 35], cost = -1.5 * spread
    if variable == "spread_degrees" then
        local min = clamp(cost / -1.5, -35, 35)
        local max = 35
        t_gun[variable] = clamp(
            RandomDistribution(prob_entry.min, prob_entry.max, prob_entry.mean, prob_entry.sharpness, rng),
            min, max)
        t_gun[variable] = Round(t_gun[variable])
        t_gun["cost"] = t_gun["cost"] - (16 - t_gun[variable])
        return
    end

    -- speed_multiplier: [0.5, 10], cost = 0 (不消耗)
    if variable == "speed_multiplier" then
        t_gun[variable] = RandomDistributionf(prob_entry.min, prob_entry.max, prob_entry.mean, prob_entry.sharpness, rng)
        t_gun["cost"] = t_gun["cost"] - 0
        return
    end

    -- deck_capacity: [1, 20], cost = (capacity-6)*5
    if variable == "deck_capacity" then
        local min = 1
        local max = clamp((cost / 5) + 6, 1, 20)

        if t_gun["force_unshuffle"] == 1 then
            min = 1
            max = ((cost - 15) / 5)
            if max > 6 then
                max = 6 + ((cost - (15 + 6 * 5)) / 10)
            end
        end

        max = clamp(max, 1, 20)
        t_gun[variable] = clamp(
            RandomDistribution(prob_entry.min, prob_entry.max, prob_entry.mean, prob_entry.sharpness, rng),
            min, max)
        t_gun[variable] = Round(t_gun[variable])
        t_gun["cost"] = t_gun["cost"] - ((t_gun[variable] - 6) * 5)
        return
    end

    local deck_capacity = t_gun["deck_capacity"]

    -- shuffle_deck_when_empty: [0,1], cost = 15+capacity*5 (不洗牌消耗)
    if variable == "shuffle_deck_when_empty" then
        local random = RandomInt(0, 1, rng)
        if t_gun["force_unshuffle"] == 1 then
            random = 1
        end
        -- 限制不洗牌到容量<=9
        if random == 1 and cost >= (15 + deck_capacity * 5) and deck_capacity <= 9 then
            t_gun[variable] = 0 -- 0 = 不洗牌
            t_gun["cost"] = t_gun["cost"] - (15 + deck_capacity * 5)
        end
        return
    end

    -- actions_per_round: [1, 5], cost = 阶梯式
    if variable == "actions_per_round" then
        local action_costs = {
            0,
            5 + (deck_capacity * 2),
            15 + (deck_capacity * 3.5),
            35 + (deck_capacity * 5),
            45 + (deck_capacity * deck_capacity)
        }

        local min = 1
        local max = 1
        for i, acost in ipairs(action_costs) do
            if acost <= cost then
                max = i
            end
        end
        max = clamp(max, 1, deck_capacity)

        t_gun[variable] = math.floor(clamp(
            RandomDistribution(prob_entry.min, prob_entry.max, prob_entry.mean, prob_entry.sharpness, rng),
            min, max))
        local temp_cost = action_costs[clamp(t_gun[variable], 1, #action_costs)]
        t_gun["cost"] = t_gun["cost"] - temp_cost
        return
    end
end

-- ============================================================================
-- 法杖名称 (原版形容词表)
-- ============================================================================

local gun_names = {
    'Deadly', 'Rusty', 'Old', 'New', 'Shiny', 'Lethal', 'Dangerous', 'Large',
    'Enormous', 'Tiny', 'Small', 'Big', 'Pretty', 'Terrifying', 'Confusing',
    'Mystery', 'Superior', 'Inferior', 'Destructive', 'Chaotic', 'Lawful',
    'Good', 'Bad', 'Neutral', 'Worn', 'Polished', 'Waxen', 'Strong', 'Weak',
    'Complex', 'Tactical', 'Horrifying', 'Scary', 'Scratched', 'Untested',
    'Prototype', 'Type a', 'Type b', 'Type x', 'Secret', 'Special', 'Unique',
    'Mega', 'Super', 'Giga', 'Turbo', 'Hyper', 'Alpha', 'Omega', 'Extreme',
    'Vanilla', 'Flavourful', 'Sturdy', 'Solid', 'Used', 'Unused', 'Grey',
    'Gray', 'Sepia', 'Secretly', 'Actual', 'Genuine', 'Powerful', 'Double',
    'Triple', 'Stereo', 'Ancient', 'Antique', 'Rustic', 'Artisan', 'Slick',
    'Slim', 'Bulky', 'Heavy', 'Efficient', 'Fast', 'Quick', 'Rapid', 'Slow',
    'Veteran', 'Agile', 'Bitcoin', 'Online',
}

-- ============================================================================
-- 法杖模板匹配 (完全还原原版 GetWand / WandDiff)
-- ============================================================================

-- 计算属性差异分数
local function WandDiff(gun_ws, wand)
    local score = 0
    score = score + (math.abs(gun_ws.fire_rate_wait - wand.fire_rate_wait) * 2)
    score = score + (math.abs(gun_ws.actions_per_round - wand.actions_per_round) * 20)
    score = score + (math.abs(gun_ws.shuffle_deck_when_empty - wand.shuffle_deck_when_empty) * 30)
    score = score + (math.abs(gun_ws.deck_capacity - wand.deck_capacity) * 5)
    score = score + math.abs(gun_ws.spread_degrees - wand.spread_degrees)
    score = score + math.abs(gun_ws.reload_time - wand.reload_time)
    return score
end

-- 将生成的属性转换到法杖模板空间, 然后匹配最接近的模板
local function GetWand(gun, rng)
    local gun_ws = {}
    gun_ws.fire_rate_wait = clamp(((gun["fire_rate_wait"] + 5) / 7) - 1, 0, 4)
    gun_ws.actions_per_round = clamp(gun["actions_per_round"] - 1, 0, 2)
    gun_ws.shuffle_deck_when_empty = clamp(gun["shuffle_deck_when_empty"], 0, 1)
    gun_ws.deck_capacity = clamp((gun["deck_capacity"] - 3) / 3, 0, 7)
    gun_ws.spread_degrees = clamp(((gun["spread_degrees"] + 5) / 5) - 1, 0, 2)
    gun_ws.reload_time = clamp(((gun["reload_time"] + 5) / 25) - 1, 0, 2)

    local best_wand = nil
    local best_score = 1000
    local best_index = 1

    for k, wand in pairs(wands) do
        local score = WandDiff(gun_ws, wand)
        if score <= best_score then
            best_wand = wand
            best_score = score
            best_index = k
            -- 随机返回同分的某一个
            if score == 0 and RandomInt(0, 100, rng) < 33 then
                return best_wand, best_index
            end
        end
    end
    return best_wand, best_index
end

-- ============================================================================
-- 楼层 → cost/level 映射
-- ============================================================================

local FLOOR_CONFIG = {
    [1] = { cost = 30,  level = 1 },
    [2] = { cost = 40,  level = 2 },
    [3] = { cost = 60,  level = 3 },
    [4] = { cost = 80,  level = 4 },
    [5] = { cost = 100, level = 5 },
    [6] = { cost = 120, level = 6 },
}

-- ============================================================================
-- 根据楼层和类型获取随机法术 (适配原版 GetRandomActionWithType)
-- ============================================================================

local function GetRandomActionWithType(floor, action_type_str, rng)
    -- 楼层→Noita法术等级
    local noita_level
    if floor <= 10 then
        noita_level = math.max(0, math.min(7, floor - 1))
    else
        noita_level = 10
    end

    local available_spells = {}
    local total_weight = 0

    for _, action in pairs(actions) do
        if action.id and TBoN.Pickup.Table.UnlockedSpells[action.id] then
            -- 类型筛选
            if action.type == action_type_str then
                if action.spawn_level and action.spawn_probability then
                    local levels = {}
                    local probabilities = {}
                    for level_str in string.gmatch(action.spawn_level, "([^,]+)") do
                        table.insert(levels, tonumber(level_str))
                    end
                    for prob_str in string.gmatch(action.spawn_probability, "([^,]+)") do
                        table.insert(probabilities, tonumber(prob_str))
                    end
                    for i, level in ipairs(levels) do
                        if level == noita_level and probabilities[i] and probabilities[i] > 0 then
                            table.insert(available_spells, {
                                id = action.id,
                                weight = probabilities[i]
                            })
                            total_weight = total_weight + probabilities[i]
                            break
                        end
                    end
                end
            end
        end
    end

    if total_weight == 0 or #available_spells == 0 then
        -- 回退: 返回默认法术
        if action_type_str == "ACTION_TYPE_PROJECTILE" then return "LIGHT_BULLET" end
        if action_type_str == "ACTION_TYPE_MODIFIER" then return "SPEED" end
        if action_type_str == "ACTION_TYPE_DRAW_MANY" then return "BURST_2" end
        if action_type_str == "ACTION_TYPE_STATIC_PROJECTILE" then return "DISC_BULLET" end
        return "LIGHT_BULLET"
    end

    -- 加权随机
    local target = rng:RandomFloat() * total_weight
    local acc = 0
    for _, spell in ipairs(available_spells) do
        acc = acc + spell.weight
        if acc >= target then
            return spell.id
        end
    end
    return available_spells[#available_spells].id
end

-- ============================================================================
-- 核心生成函数 (完全还原 generate_gun)
-- ============================================================================

function TBoN.Pickup.Function.Custom.GenerateWand(floor, is_better, rng)
    is_better = is_better or false

    if not rng then
        rng = RNG()
        local seeds = Game():GetSeeds()
        rng:SetSeed(seeds:GetStartSeed(), 35)
    end

    -- 确定 cost 和 level
    local floor_clamped = clamp(floor, 1, 6)
    local config = FLOOR_CONFIG[floor_clamped]
    local cost = config.cost
    local level = config.level

    -- 选择概率分布表
    local probs = is_better and gun_probs_better or gun_probs_normal
    init_gun_probs(probs)

    -- Level 1 时 50% 概率 +5 cost
    if level == 1 then
        if Random100(rng) < 50 then
            cost = cost + 5
        end
    end
    cost = cost + RandomInt(-3, 3, rng)

    -- 构建法杖属性表
    local gun = {}
    gun["cost"] = cost
    gun["deck_capacity"] = 0
    gun["actions_per_round"] = 0
    gun["reload_time"] = 0
    gun["shuffle_deck_when_empty"] = 1  -- 默认洗牌
    gun["fire_rate_wait"] = 0
    gun["spread_degrees"] = 0
    gun["speed_multiplier"] = 0
    gun["prob_unshuffle"] = 0.1
    gun["prob_draw_many"] = 0.15
    gun["mana_charge_speed"] = 50 * level + RandomInt(-5, 5 * level, rng)
    gun["mana_max"] = 50 + (150 * level) + (RandomInt(-5, 5, rng) * 10)
    gun["force_unshuffle"] = 0

    -- 20% 概率: 慢充能大法力池
    local p = Random100(rng)
    if p < 20 then
        gun["mana_charge_speed"] = (50 * level + RandomInt(-5, 5 * level, rng)) / 5
        gun["mana_max"] = (50 + (150 * level) + (RandomInt(-5, 5, rng) * 10)) * 3
        if gun["mana_charge_speed"] < 10 then
            gun["mana_charge_speed"] = 10
        end
    end

    -- 强制不洗牌概率 (15% + level*6%)
    p = Random100(rng)
    if p < 15 + level * 6 then
        gun["force_unshuffle"] = 1
    end

    -- 5% 概率: 稀有法杖 (+65 cost)
    local is_rare = false
    p = Random100(rng)
    if p < 5 then
        is_rare = true
        gun["cost"] = gun["cost"] + 65
    end

    -- ===================== 属性生成 (随机顺序) =====================
    local variables_01 = { "reload_time", "fire_rate_wait", "spread_degrees", "speed_multiplier" }
    local variables_02 = { "deck_capacity" }
    local variables_03 = { "shuffle_deck_when_empty", "actions_per_round" }

    ShuffleTable(variables_01, rng)
    if gun["force_unshuffle"] ~= 1 then
        ShuffleTable(variables_03, rng)
    end

    for _, v in pairs(variables_01) do
        apply_random_variable(gun, v, probs, rng)
    end
    for _, v in pairs(variables_02) do
        apply_random_variable(gun, v, probs, rng)
    end
    for _, v in pairs(variables_03) do
        apply_random_variable(gun, v, probs, rng)
    end

    -- 99.5% 概率将剩余cost转为容量
    if gun["cost"] > 5 and RandomInt(0, 1000, rng) < 995 then
        if gun["shuffle_deck_when_empty"] == 1 then
            gun["deck_capacity"] = gun["deck_capacity"] + (gun["cost"] / 5)
            gun["cost"] = 0
        else
            gun["deck_capacity"] = gun["deck_capacity"] + (gun["cost"] / 10)
            gun["cost"] = 0
        end
    end

    -- 应用 force_unshuffle 参数
    -- (原版也检查 PERK_NO_MORE_SHUFFLE_WANDS, 此处跳过)
    if gun["force_unshuffle"] == 1 then
        gun["shuffle_deck_when_empty"] = 0
    end

    -- 容量限制
    if RandomInt(0, 10000, rng) <= 9999 then
        gun["deck_capacity"] = clamp(gun["deck_capacity"], 2, 26)
    end
    if gun["deck_capacity"] <= 1 then
        gun["deck_capacity"] = 2
    end
    gun["deck_capacity"] = Round(gun["deck_capacity"])

    -- 高充能时间补偿: 大幅增加 actions_per_round
    if gun["reload_time"] >= 60 then
        local function random_add_apr()
            gun["actions_per_round"] = gun["actions_per_round"] + 1
            if Random100(rng) < 70 then
                random_add_apr()
            end
        end
        random_add_apr()

        if Random100(rng) < 50 then
            local new_apr = gun["deck_capacity"]
            for i = 1, 6 do
                local temp = RandomInt(gun["actions_per_round"], gun["deck_capacity"], rng)
                if temp < new_apr then
                    new_apr = temp
                end
            end
            gun["actions_per_round"] = new_apr
        end
    end

    gun["actions_per_round"] = clamp(gun["actions_per_round"], 1, gun["deck_capacity"])

    -- 确保 mana 最小值
    gun["mana_max"] = math.max(50, Round(gun["mana_max"]))
    gun["mana_charge_speed"] = math.max(10, Round(gun["mana_charge_speed"]))

    -- ===================== 法杖外观匹配 (原版 GetWand) =====================
    local wand_template, wand_index = GetWand(gun, rng)
    local wand_sprite_name = string.format("wand_%04d", wand_index - 1) -- Lua 1-based → 0-based

    -- ===================== 名称生成 =====================
    local adjective = gun_names[RandomInt(1, #gun_names, rng)]
    local template_name = wand_template and wand_template.name or "Wand"
    local ui_name = adjective .. " " .. template_name

    -- ===================== 法术填充 (还原原版算法) =====================
    local spell_slots = {}
    local spell_level = level - 1 -- 原版使用 level-1 查找法术

    local deck_capacity = gun["deck_capacity"]
    local card_count = RandomInt(1, 3, rng)
    local bullet_card = GetRandomActionWithType(spell_level, "ACTION_TYPE_PROJECTILE", rng)
    local card = ""
    local random_bullets = 0

    if Random100(rng) < 50 and card_count < 3 then
        card_count = card_count + 1
    end
    if Random100(rng) < 10 or is_rare then
        card_count = card_count + RandomInt(1, 2, rng)
    end

    card_count = RandomInt(Round(0.51 * deck_capacity), deck_capacity, rng)
    card_count = clamp(card_count, 1, deck_capacity - 1)

    if Random100(rng) < (level * 10) - 5 then
        random_bullets = 1
    end

    -- Always Cast (4% 概率, 稀有法杖必定触发)
    local always_cast = nil
    if Random100(rng) < 4 or is_rare then
        p = Random100(rng)
        if p < 77 then
            always_cast = GetRandomActionWithType(spell_level + 1, "ACTION_TYPE_MODIFIER", rng)
        elseif p < 85 then
            always_cast = GetRandomActionWithType(spell_level + 1, "ACTION_TYPE_MODIFIER", rng)
        elseif p < 93 then
            always_cast = GetRandomActionWithType(spell_level + 1, "ACTION_TYPE_STATIC_PROJECTILE", rng)
        else
            always_cast = GetRandomActionWithType(spell_level + 1, "ACTION_TYPE_PROJECTILE", rng)
        end
    end

    -- 法术填充 (还原原版逻辑)
    local cards_to_add = {}

    if card_count < 3 then
        -- 少量法术模式
        if card_count > 1 and Random100(rng) < 20 then
            card = GetRandomActionWithType(spell_level, "ACTION_TYPE_MODIFIER", rng)
            table.insert(cards_to_add, card)
            card_count = card_count - 1
        end
        for i = 1, card_count do
            if random_bullets == 1 then
                table.insert(cards_to_add, GetRandomActionWithType(spell_level, "ACTION_TYPE_PROJECTILE", rng))
            else
                table.insert(cards_to_add, bullet_card)
            end
        end
    else
        -- 大量法术模式
        if Random100(rng) < 40 then
            card = GetRandomActionWithType(spell_level, "ACTION_TYPE_DRAW_MANY", rng)
            table.insert(cards_to_add, card)
            card_count = card_count - 1
        end
        if card_count > 3 and Random100(rng) < 40 then
            card = GetRandomActionWithType(spell_level, "ACTION_TYPE_DRAW_MANY", rng)
            table.insert(cards_to_add, card)
            card_count = card_count - 1
        end
        if Random100(rng) < 80 then
            card = GetRandomActionWithType(spell_level, "ACTION_TYPE_MODIFIER", rng)
            table.insert(cards_to_add, card)
            card_count = card_count - 1
        end
        for i = 1, card_count do
            if random_bullets == 1 then
                table.insert(cards_to_add, GetRandomActionWithType(spell_level, "ACTION_TYPE_PROJECTILE", rng))
            else
                table.insert(cards_to_add, bullet_card)
            end
        end
    end

    -- 转换为 spell_slots 格式
    for _, spell_id in ipairs(cards_to_add) do
        if spell_id and spell_id ~= "" then
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
        end
    end

    -- 填充剩余空槽 (始终填满24格, 与 gun_magic_data_init 结构一致)
    for i = #spell_slots + 1, 24 do
        table.insert(spell_slots, {
            magic_id = false,
            current_uses = 0,
            max_uses = 0
        })
    end

    -- ===================== 构建返回数据 =====================
    local wand_data = {
        name = wand_sprite_name,          -- 贴图标识符 "wand_XXXX" (用于sprite加载)
        ui_name = ui_name,                -- 显示名称 "Deadly Spread staff" (用于UI)
        shuffle = (gun["shuffle_deck_when_empty"] == 1),
        capacity = deck_capacity,
        cast_delay = gun["fire_rate_wait"],
        recharge_time = gun["reload_time"],
        mana_max = gun["mana_max"],
        mana_charge_speed = gun["mana_charge_speed"],
        spread_degrees = gun["spread_degrees"],
        speed_multiplier = gun["speed_multiplier"],
        actions_per_round = gun["actions_per_round"],
        always_cast = always_cast,
        is_rare = is_rare,
    }

    return wand_data, spell_slots
end

-- ============================================================================
-- 初始法杖生成 (起始火花弹杖)
-- ============================================================================

function TBoN.Pickup.Function.Custom.GenerateStarterWand(rng)
    if not rng then
        rng = RNG()
        rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
    end

    -- 还原原版 starting_wand.lua 的属性范围
    local cast_delay = RandomInt(9, 15, rng)
    local recharge_time = RandomInt(20, 28, rng)
    local mana_max = RandomInt(80, 130, rng)
    local mana_charge_speed = RandomInt(25, 40, rng)
    local capacity = RandomInt(2, 3, rng)

    local wand_name = "wand_b_0000"

    local wand = {
        name = wand_name,
        ui_name = "Bolt staff",
        shuffle = false,
        capacity = capacity,
        cast_delay = cast_delay,
        recharge_time = recharge_time,
        mana_max = mana_max,
        mana_charge_speed = mana_charge_speed,
        spread_degrees = 0,
        speed_multiplier = 1,
        actions_per_round = 1,
        always_cast = nil,
        is_rare = false,
    }

    -- 法术: LIGHT_BULLET 或随机初始法术
    local spell_slots = {}
    local spell_id = "LIGHT_BULLET"

    -- 还原原版: 死亡次数>=1时50%概率使用随机初始法术
    local starter_actions = { "SPITTER", "RUBBER_BALL", "BOUNCY_ORB" }
    local n_of_deaths = TBoN.Pickup.Variable.Num and TBoN.Pickup.Variable.Num.death_count or 0
    if n_of_deaths >= 1 then
        if Random100(rng) < 50 then
            spell_id = RandomFromArray(starter_actions, rng)
        end
    end

    local action = actions[TBoN.Render.Table.actions_map[spell_id]]
    local max_uses = -1
    if action and action.max_uses then
        max_uses = action.max_uses
    end

    local action_count = math.min(RandomInt(1, 3, rng), capacity)
    for i = 1, action_count do
        table.insert(spell_slots, {
            magic_id = spell_id,
            current_uses = max_uses,
            max_uses = max_uses
        })
    end

    -- 填满24格与 gun_magic_data_init 结构一致
    for i = #spell_slots + 1, 24 do
        table.insert(spell_slots, {
            magic_id = false,
            current_uses = 0,
            max_uses = 0
        })
    end

    return wand, spell_slots
end

-- ============================================================================
-- 初始炸弹杖生成
-- ============================================================================

function TBoN.Pickup.Function.Custom.GenerateStarterBombWand(rng)
    if not rng then
        rng = RNG()
        rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
    end

    local cast_delay = RandomInt(3, 8, rng)
    local recharge_time = RandomInt(1, 10, rng)
    local mana_max = RandomInt(80, 110, rng)
    local mana_charge_speed = RandomInt(5, 20, rng)

    local wand_name = "wand_b_0001"

    local wand = {
        name = wand_name,
        ui_name = "Bomb wand",
        shuffle = true,
        capacity = 1,
        cast_delay = cast_delay,
        recharge_time = recharge_time,
        mana_max = mana_max,
        mana_charge_speed = mana_charge_speed,
        spread_degrees = 0,
        speed_multiplier = 1,
        actions_per_round = 1,
        always_cast = nil,
        is_rare = false,
    }

    local spell_slots = {}
    local spell_id = "BOMB"

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

    -- 填满24格与 gun_magic_data_init 结构一致
    for i = #spell_slots + 1, 24 do
        table.insert(spell_slots, {
            magic_id = false,
            current_uses = 0,
            max_uses = 0
        })
    end

    return wand, spell_slots
end

-- ============================================================================
-- 向后兼容: GenerateWandStats (部分外部代码可能引用)
-- ============================================================================

function TBoN.Pickup.Function.Custom.GenerateWandStats(floor, is_better, rng)
    local wand_data, _ = TBoN.Pickup.Function.Custom.GenerateWand(floor, is_better, rng)
    return wand_data
end

-- ============================================================================
-- 公开接口: 根据法杖属性自动匹配贴图和名称
-- 输入: gun_info 格式的表 (需包含 cast_delay/actions_per_round/shuffle/capacity/spread_degrees/recharge_time)
-- 返回: sprite_name ("wand_XXXX"), ui_name ("Deadly Spread staff")
-- ============================================================================

function TBoN.Pickup.Function.Custom.ResolveWandAppearance(gun_info, rng)
    if not rng then
        rng = RNG()
        rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
    end

    -- 构建 GetWand 所需的 gun 表
    local gun = {
        ["fire_rate_wait"]           = gun_info.cast_delay or 0,
        ["actions_per_round"]        = gun_info.actions_per_round or 1,
        ["shuffle_deck_when_empty"]  = gun_info.shuffle and 1 or 0,
        ["deck_capacity"]            = gun_info.capacity or 2,
        ["spread_degrees"]           = gun_info.spread_degrees or 0,
        ["reload_time"]              = gun_info.recharge_time or 0,
    }

    local wand_template, wand_index = GetWand(gun, rng)
    local sprite_name = string.format("wand_%04d", wand_index - 1)

    -- 生成显示名称
    local adjective = gun_names[RandomInt(1, #gun_names, rng)]
    local template_name = wand_template and wand_template.name or "Wand"
    local ui_name = adjective .. " " .. template_name

    return sprite_name, ui_name
end

return TBoN.Pickup.Function.Custom
