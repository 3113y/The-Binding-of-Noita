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
-- 保存法术信息到临时表
-- @param spell_subtype: 法术的SubType
-- @param magic_id: 法术ID
-- @param current_uses: 当前使用次数
-- @param max_uses: 最大使用次数
-- @param player_dropped: 是否为玩家丢弃（可选，默认false）
function TBoN.World.Function.Custom.Save_Spell_Info(spell_subtype, magic_id, current_uses, max_uses, player_dropped)
    if not TBoN.World.Table.dropped_spell_temp then
        TBoN.World.Table.dropped_spell_temp = {}
    end
    
    TBoN.World.Table.dropped_spell_temp[spell_subtype] = {
        magic_id = magic_id,
        current_uses = current_uses,
        max_uses = max_uses,
        timestamp = Game():GetFrameCount(),
        player_dropped = player_dropped or false
    }
end

-- 生成法术拾取物，可选保存信息
-- @param magic_id: 法术ID（如果提供则保存信息）
-- @param spell_subtype: 法术的SubType（如果magic_id提供则从它计算）
-- @param current_uses: 当前使用次数（可选）
-- @param max_uses: 最大使用次数（可选）
-- @param spawn_position: 生成位置（可选，默认为玩家位置）
-- @param velocity: 速度向量（可选，默认为零向量）
-- @param player_dropped: 是否为玩家丢弃（可选，默认true）
-- @return 生成的实体对象，如果spell_subtype无效则返回nil
function TBoN.Render.Function.Custom.Drop_Spell(magic_id, spell_subtype, current_uses, max_uses, spawn_position, velocity, player_dropped)
    -- 如果提供了magic_id，从它计算spell_subtype
    if magic_id then
        spell_subtype = TBoN.Render.Table.actions_map[magic_id]
    end
    
    if not spell_subtype then
        return nil
    end
    
    -- 如果提供了magic_id，保存法术信息
    if magic_id then
        TBoN.World.Function.Custom.Save_Spell_Info(
            spell_subtype,
            magic_id,
            current_uses,
            max_uses,
            player_dropped == nil and true or player_dropped
        )
    end
    
    -- 生成法术拾取物
    local spawn_pos = spawn_position or Isaac.GetPlayer().Position
    local spawn_vel = velocity or Vector(0, 0)
    return Isaac.Spawn(5, TBoN.Magic.Info.Variant.Pickup_Magic, spell_subtype, spawn_pos, spawn_vel, nil)
end

-- 保存法杖信息到临时表
-- @param wand_id: 法杖ID
-- @param wand_data: 法杖属性数据
-- @param spell_slots: 法术槽数据
-- @param player_dropped: 是否为玩家丢弃（可选，默认false）
function TBoN.World.Function.Custom.Save_Wand_Info(wand_id, wand_data, spell_slots, player_dropped)
    if not TBoN.World.Table.dropped_wand_temp then
        TBoN.World.Table.dropped_wand_temp = {}
    end
    
    TBoN.World.Table.dropped_wand_temp[wand_id] = {
        wand_data = wand_data,
        spell_slots = spell_slots,
        timestamp = Game():GetFrameCount(),
        player_dropped = player_dropped or false
    }
end

-- 丢弃法杖，保存信息并生成实体
-- @param gun_index: 法杖槽位索引
-- @return 生成的实体对象，如果槽位为空则返回nil
function TBoN.World.Function.Custom.Drop_Wand(gun_index)
    local wand_name = TBoN.Gun.Table.gun_info[gun_index].name
    if not wand_name or wand_name == false then
        return
    end
    
    -- 提取wand_id (wand_0000 -> 0)
    local wand_id = tonumber(string.match(wand_name, "wand_(%d+)")) or 0
    
    -- 保存法杖完整数据
    local wand_data = {
        name = TBoN.Gun.Table.gun_info[gun_index].name,
        shuffle = TBoN.Gun.Table.gun_info[gun_index].shuffle,
        capacity = TBoN.Gun.Table.gun_info[gun_index].capacity,
        cast_delay = TBoN.Gun.Table.gun_info[gun_index].cast_delay,
        recharge_time = TBoN.Gun.Table.gun_info[gun_index].recharge_time,
        mana_max = TBoN.Gun.Table.gun_info[gun_index].mana_max,
        mana_charge_speed = TBoN.Gun.Table.gun_info[gun_index].mana_charge_speed,
        spread_degrees = TBoN.Gun.Table.gun_info[gun_index].spread_degrees,
        always_cast = TBoN.Gun.Table.gun_info[gun_index].always_cast,
    }
    
    -- 保存法术槽数据（只遍历 capacity 范围）
    local spell_slots = {}
    if TBoN.Gun.Table.gun_magic_data[gun_index] then
        for slot_index = 1, wand_data.capacity do
            local magic_data = TBoN.Gun.Table.gun_magic_data[gun_index][slot_index]
            if magic_data then
                table.insert(spell_slots, {
                    magic_id = magic_data.magic_id,
                    current_uses = magic_data.current_uses,
                    max_uses = magic_data.max_uses,
                })
            end
        end
    end
    
    -- 保存法杖信息
    TBoN.World.Function.Custom.Save_Wand_Info(wand_id, wand_data, spell_slots, true)
    
    -- 生成法杖拾取物
    local entity = Isaac.Spawn(5, TBoN.Magic.Info.Variant.Pickup_Wand, wand_id, 
        Isaac.GetPlayer().Position + 70 * TBoN.Gun.Function.Vector.Aim_direc, Vector(0, 0), nil)
    
    -- 同时设置wand_hash以便立即访问
    local pickup_index = GetPtrHash(entity)
    TBoN.World.Table.wand_hash[pickup_index] = {
        wand_data = wand_data,
        spell_slots = spell_slots
    }
    
    local sprite = entity:GetSprite()
    sprite:Load("gfx/gun/" .. wand_data.name .. ".anm2", true)
    sprite:Play("Idle", true)
    
    -- 清空法杖槽位
    TBoN.Gun.Table.gun_info[gun_index] = TBoN.Data.Function.Custom.Deep_Copy(TBoN.Data.Table.gun_info_init[gun_index])
    TBoN.Gun.Table.gun_magic_data[gun_index] = TBoN.Data.Function.Custom.Deep_Copy(TBoN.Data.Table.gun_magic_data_init[gun_index])
    
    -- 重置法杖状态
    TBoN.Gun.Table.gun_states[gun_index] = {
        mana = 0,
        current_mana = 0,
        mana_max = 0,
        cast_delay_current = 0,
        recharge_time_current = 0,
        cast_cooldown = 0,
        recharge_cooldown = 0,
        deck_index = 1,
        deck = {},
        discard_pile = {},
        always_cast_hand = {},
        always_cast_index = 1,
        wrapped_around = false,
    }
    
    return entity
end