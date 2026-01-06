include("scripts.worlds.world_table")
-- 根据楼层和随机数选择法术
function TBoN.World.Function.Custom.Get_Random_Spell_By_Floor(floor, random_value)
    -- 将以撒的楼层映射到Noita的法术等级
    -- 1-10层映射到0-7级，11层及以上映射到10级
    local noita_level
    if floor <= 10 then
        -- 1层->0级, 2层->0级, 3层->1级, 4层->1级, 5层->2级, 6层->3级, 7层->4级, 8层->5级, 9层->6级, 10层->7级
        noita_level = math.floor((floor - 1) * 0.7)
        noita_level = math.max(0, math.min(7, noita_level))
    else
        noita_level = 10
    end

    local available_spells = {}
    local total_weight = 0
    
    for _, action in pairs(actions) do
        if action.id and TBoN.World.Table.UnlockedSpells[action.id] then
            if action.spawn_level and action.spawn_probability then

                local levels = {}
                local probabilities = {}
                
                for level_str in string.gmatch(action.spawn_level, "([^,]+)") do
                    table.insert(levels, tonumber(level_str))
                end
                
                for prob_str in string.gmatch(action.spawn_probability, "([^,]+)") do
                    table.insert(probabilities, tonumber(prob_str))
                end
                
                local weight = nil
                for i, level in ipairs(levels) do
                    if level == noita_level and probabilities[i] then
                        weight = probabilities[i]
                        break
                    end
                end
                
                if weight and weight > 0 then
                    table.insert(available_spells, {
                        id = action.id,
                        weight = weight
                    })
                    total_weight = total_weight + weight
                end
            end
        end
    end
    
    if total_weight == 0 or #available_spells == 0 then
        return nil
    end
    
    local target_weight = random_value * total_weight
    local accumulated_weight = 0
    
    for _, spell in ipairs(available_spells) do
        accumulated_weight = accumulated_weight + spell.weight
        if accumulated_weight >= target_weight then
            return spell.id
        end
    end
    
    -- 保险起见，返回最后一个法术
    return available_spells[#available_spells].id
end

-- 获取指定楼层所有可用法术列表（用于调试）
function TBoN.World.Function.Custom.Get_Available_Spells_By_Floor(floor)
    -- 将以撒的楼层映射到Noita的法术等级
    local noita_level
    if floor <= 10 then
        noita_level = math.floor((floor - 1) * 0.7)
        noita_level = math.max(0, math.min(7, noita_level))
    else
        noita_level = 10
    end
    
    local available_spells = {}
    
    for _, action in ipairs(actions) do
        -- 检查法术是否在已解锁列表中
        if action.id and TBoN.World.Table.UnlockedSpells[action.id] then
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
                            name = action.name,
                            weight = probabilities[i],
                            type = action.type
                        })
                        break
                    end
                end
            end
        end
    end
    
    return available_spells
end

-- 添加已解锁法术的辅助函数
-- @param spell_id: 法术ID或法术ID数组
function TBoN.World.Function.Custom.UnlockSpell(spell_id)
    if type(spell_id) == "table" then
        -- 如果传入的是数组，批量添加
        for _, id in ipairs(spell_id) do
            TBoN.World.Table.UnlockedSpells[id] = true
        end
    else
        -- 单个添加
        TBoN.World.Table.UnlockedSpells[spell_id] = true
    end
end
