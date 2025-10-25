-- 已解锁/已制作的法术白名单
-- 只有在这个表中的法术才能被随机生成
TBoN.World.Table = TBoN.World.Table or {}
TBoN.World.Table.UnlockedSpells = {
    -- 示例：添加你已经实现和测试过的法术ID
    -- ["BOMB"] = true,
    -- ["LASER"] = true,
    -- 根据实际情况添加更多法术
}

-- 根据楼层和随机数选择法术
function TBoN.World.Function.Custom.GetRandomSpellByFloor(floor, random_value)
    -- 限制楼层范围
    if floor > 10 then
        floor = 10
    end
    
    -- 收集所有在当前楼层可生成的法术及其权重
    local available_spells = {}
    local total_weight = 0
    
    for _, action in pairs(actions) do
        -- 检查法术是否在已解锁列表中
        if action.id and TBoN.World.Table.UnlockedSpells[action.id] then
            if action.spawn_level and action.spawn_probability then
                -- 解析 spawn_level 和 spawn_probability
                local levels = {}
                local probabilities = {}
                
                -- 分割字符串
                for level_str in string.gmatch(action.spawn_level, "([^,]+)") do
                    table.insert(levels, tonumber(level_str))
                end
                
                for prob_str in string.gmatch(action.spawn_probability, "([^,]+)") do
                    table.insert(probabilities, tonumber(prob_str))
                end
                
                -- 查找当前楼层对应的权重
                local weight = nil
                for i, level in ipairs(levels) do
                    if level == floor and probabilities[i] then
                        weight = probabilities[i]
                        break
                    end
                end
                
                -- 如果该法术在当前楼层有权重且大于0，加入可用列表
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
    
    -- 如果没有可用法术，返回 nil
    if total_weight == 0 or #available_spells == 0 then
        return nil
    end
    
    -- 使用随机数选择法术
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
