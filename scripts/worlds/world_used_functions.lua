include("scripts.worlds.world_table")
-- 根据楼层和随机数选择法术
function TBoN.World.Function.Custom.GetRandomSpellByFloor(floor, random_value)
    if floor > 10 then
        floor = 10
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
                    if level == floor and probabilities[i] then
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
function TBoN.World.Function.Custom.GetAvailableSpellsByFloor(floor)
    if floor > 10 then
        floor = 10
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
                    if level == floor and probabilities[i] and probabilities[i] > 0 then
                        table.insert(available_spells, {
                            id = action.id,
                            name = action.name,
                            weight = probabilities[i],
                            type = action.type
                        })
                        print("Available Spell: " .. action.id .. " | Name: " .. action.name .. " | Weight: " .. probabilities[i] .. " | Type: " .. action.type)
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

-- 移除已解锁法术
-- @param spell_id: 法术ID
function TBoN.World.Function.Custom.LockSpell(spell_id)
    TBoN.World.Table.UnlockedSpells[spell_id] = nil
end

-- 检查法术是否已解锁
-- @param spell_id: 法术ID
-- @return: true/false
function TBoN.World.Function.Custom.IsSpellUnlocked(spell_id)
    return TBoN.World.Table.UnlockedSpells[spell_id] == true
end
