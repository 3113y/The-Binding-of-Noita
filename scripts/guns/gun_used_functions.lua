function draw_actions(i, bool)
    draw_act = draw_act + i
end

-- 简化版本的施法块处理函数
-- @param cast_blocks: 施法块数组
-- @return: 执行的法术序列
function Execute_Cast_Blocks(cast_blocks)
    local executed_spells = {}
    
    for block_index, block in ipairs(cast_blocks) do
        local block_spells = {}
        local projectile_entities = {} -- 存储该施法块中所有投射物实体信息

        
        -- 先执行所有modifier法术
        for _, spell_info in ipairs(block) do
            local spell_name = spell_info.name
            local action_info = actions[actions_map[spell_name]]
            if action_info and (action_info.type == "ACTION_TYPE_MODIFIER" or action_info.type == "ACTION_TYPE_OTHER" or action_info.type == "ACTION_TYPE_DRAW_MANY") then
                if action_info.action then
                    action_info.action()
                end
            end
            table.insert(block_spells, spell_name)
        end

        -- 再执行所有投射物法术并收集
        for _, spell_info in ipairs(block) do
            local spell_name = spell_info.name
            local action_info = actions[actions_map[spell_name]]
            if action_info and (action_info.type == "ACTION_TYPE_PROJECTILE" or action_info.type == "ACTION_TYPE_STATIC_PROJECTILE") then
                if action_info.action then
                    action_info.action()
                end
                if c.entity_type and c.entity_variant then
                    table.insert(projectile_entities, {
                        entity_type = c.entity_type,
                        entity_variant = c.entity_variant,
                        spell_name = spell_name,
                        speed_multiplier = c.speed_multiplier or 1,
                        damage = c.damage or 1,
                        fire_rate_wait = c.fire_rate_wait or 0,
                        -- 可以添加更多属性
                    })
                    print("收集投射物: " .. spell_name .. " (Type: " .. c.entity_type .. ", Variant: " .. c.entity_variant .. ", 延迟: " .. (c.fire_rate_wait or 0) .. "帧)")
                end
            end
        end
        
        -- 将投射物信息和施法块延迟存储到执行结果中
        table.insert(executed_spells, {
            spells = block_spells,
            projectiles = projectile_entities,
            total_fire_rate_wait = c.fire_rate_wait or 0  -- 整个施法块的总延迟
        })
    end
    
    return executed_spells
end

function Get_Magic_Table_Of_Current_Gun(magic_table, gun_info_table, gun_index)
    if gun_index > 4 then
        return {}
    end
    local result = {}
    if gun_info_table[gun_index].shuffle then
        local temp = {}
        for i, magic in pairs(magic_table[gun_index]) do
            if magic then
                table.insert(temp, magic)
            end
        end
        local rng = Isaac.GetPlayer():GetCollectibleRNG(1)
        for i = #temp, 2, -1 do
            local j = rng:RandomInt(i) + 1
            temp[i], temp[j] = temp[j], temp[i]
        end
        local t = 1
        for _, magic in ipairs(temp) do
            result[t] = magic
            t = t + 1
        end
    else
        local t = 1
        for _, magic in pairs(magic_table[gun_index]) do
            if magic then
                result[t] = magic
                t = t + 1
            end
        end
    end
    return result
end

-- 简化的 Noita 施法函数，自动处理回绕，考虑法杖属性
-- @param new_magic_table: 法术列表
-- @param current_deck_index: 当前牌库指针位置
-- @param gun_info: 法杖信息（包含延迟、充能等属性）
-- @param current_mana: 当前法力值（可选）
-- @return: {cast_blocks, next_deck_index, total_cast_delay, recharge_time, mana_cost}
function Get_Next_Shutted_Magic_Info(new_magic_table, current_deck_index, gun_info, current_mana)
    current_deck_index = current_deck_index or 1
    current_mana = current_mana or (gun_info and gun_info.mana_max or 100)
    
    local cast_blocks = {}  -- 施法块数组
    local current_block = {} -- 当前施法块
    local deck_size = #new_magic_table
    local used_spells = {}  -- 本轮已使用的法术索引
    local has_cast_this_round = false -- 本轮是否已有施法
    draw_act = 1 -- 初始化抽取次数
    
    -- 法杖属性
    local base_cast_delay = gun_info and gun_info.cast_delay or 0
    local recharge_time = gun_info and gun_info.recharge_time or 0
    local mana_max = gun_info and gun_info.mana_max or 100
    
    -- 施法统计
    local total_mana_cost = 0 -- 总法力消耗
    local remaining_mana = current_mana
    
    print("=== 开始施法 ===")
    print("法杖基础延迟: " .. base_cast_delay .. "帧")
    print("法杖充能时间: " .. recharge_time .. "帧")
    print("当前法力: " .. remaining_mana .. "/" .. mana_max)

    -- 在整个施法循环前重置c表
    c.fire_rate_wait = 0
    c.entity_type = nil
    c.entity_variant = nil
    c.speed_multiplier = 1
    c.damage = 1
    c.screenshake = 0

    -- 开始施法循环
    while draw_act > 0 do
        -- 检查是否需要回绕（牌库用完）
        if current_deck_index > deck_size then
            if has_cast_this_round then
                -- 已经施放过法术，回绕后结束本轮施法
                print("回绕触发，结束本轮施法")
                current_deck_index = 1
                break
            else
                -- 还没施放过法术，重置到开头继续
                current_deck_index = 1
                print("牌库为空，重置到开头")
            end
        end
        
        -- 检查当前法术是否已在本轮使用过（防止无限循环）
        if used_spells[current_deck_index] then
            print("所有法术都已尝试，结束施法")
            break
        end
        
        local spell_name = new_magic_table[current_deck_index]
        if spell_name and actions and actions_map and actions[actions_map[spell_name]] then
            local spell_info = actions[actions_map[spell_name]]
            -- 检查法力消耗
            local spell_mana_cost = spell_info.mana or 0
            local can_cast_mana = remaining_mana >= spell_mana_cost
            local can_cast_uses = true
            if can_cast_mana and can_cast_uses then
                -- 成功抽取，消耗法力
                remaining_mana = remaining_mana - spell_mana_cost
                total_mana_cost = total_mana_cost + spell_mana_cost
                used_spells[current_deck_index] = true
                has_cast_this_round = true
                table.insert(current_block, {
                    name = spell_name,
                    index = current_deck_index,
                    mana_cost = spell_mana_cost
                })
                print("成功施放: " .. spell_name .. " (法力: -" .. spell_mana_cost .. ")")
                -- 执行法术action（draw_actions会动态增加draw_act）
                if spell_info.action then
                    spell_info.action()
                end
                -- 检查是否为触发类法术
                if spell_info.type and spell_info.type == "trigger" then
                    if #current_block > 0 then
                        table.insert(cast_blocks, current_block)
                        current_block = {}
                        print("  创建新施法块（触发类法术）")
                    end
                end
                current_deck_index = current_deck_index + 1
                draw_act = draw_act - 1
            else
                print("跳过法术: " .. spell_name .. " (法力不足: " .. remaining_mana .. "/" .. spell_mana_cost .. ")")
                used_spells[current_deck_index] = true
                current_deck_index = current_deck_index + 1
                -- 不减少抽取次数
            end
        else
            used_spells[current_deck_index] = true
            current_deck_index = current_deck_index + 1
        end
    end
    
    -- 添加最后的施法块
    if #current_block > 0 then
        table.insert(cast_blocks, current_block)
    end
    
    -- 处理回绕后的指针位置
    if current_deck_index > deck_size then
        current_deck_index = 1
    end
    
    -- 执行施法块并获取真实的延迟
    local executed_results = Execute_Cast_Blocks(cast_blocks)
    
    -- 计算真实的总延迟
    local real_total_delay = base_cast_delay
    for _, result in ipairs(executed_results) do
        if result.total_fire_rate_wait then
            real_total_delay = real_total_delay + result.total_fire_rate_wait
        end
    end
    
    -- 如果施法了任何法术，需要进入充能时间
    local needs_recharge = has_cast_this_round and (#new_magic_table > 0)
    
    print("=== 施法结束 ===")
    print("基础延迟: " .. base_cast_delay .. "帧")
    print("法术延迟: " .. (real_total_delay - base_cast_delay) .. "帧")
    print("总延迟: " .. real_total_delay .. "帧")
    print("总法力消耗: " .. total_mana_cost)
    print("剩余法力: " .. remaining_mana .. "/" .. mana_max)
    print("需要充能: " .. tostring(needs_recharge) .. " (" .. recharge_time .. "帧)")
    
    return {
        cast_blocks = cast_blocks,
        next_deck_index = current_deck_index,
        total_cast_delay = real_total_delay,
        recharge_time = needs_recharge and recharge_time or 0,
        mana_cost = total_mana_cost,
        remaining_mana = remaining_mana,
        needs_recharge = needs_recharge,
        executed_results = executed_results
    }
end