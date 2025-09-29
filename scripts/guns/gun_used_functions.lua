function draw_actions(i, bool)
    draw_act = draw_act + i
end

-- 核心施法函数，现在直接操作 gun_state 并返回所有结果
-- 按照Noita机制：每个施法块独立，modifier只影响同一施法块内后续的投射物
-- @param gun_state: 当前法杖的状态表 (deck, discard_pile, current_mana, etc.)
-- @param gun_info: 法杖的静态信息 (cast_delay, recharge_time, etc.)
-- @param gun_index: 法杖索引，用于从gun_magic_data获取法术数据
-- @return: {cast_blocks, total_cast_delay, recharge_time, mana_cost, remaining_mana, used_spells_this_cast, projectiles}
function Get_Next_Shutted_Magic_Info(gun_state, gun_info, gun_index)
    local cast_blocks = {}
    local used_spells_this_cast = {} -- 本次施法消耗的法术
    local projectiles = {} -- 本次施法生成的所有投射物
    local has_cast_this_round = false
    draw_act = 1 -- 正常的draw_act值

    local base_cast_delay = gun_info.cast_delay or 0
    local recharge_time = gun_info.recharge_time or 0
    local mana_max = gun_info.mana_max or 100
    
    local total_mana_cost = 0
    local remaining_mana = gun_state.current_mana

    -- 使用当前的牌库状态，不重新构建
    local deck_copy = {}
    for _, spell in ipairs(gun_state.deck) do
        table.insert(deck_copy, spell)
    end
    
    print("使用当前牌库状态，大小: " .. #deck_copy .. " (弃牌堆: " .. #gun_state.discard_pile .. ")")

    local current_deck_index = 1
    local new_cast_block_needed = true -- 标记是否需要新的施法块
    local wrapped_around = false -- 标记是否发生了回绕

    while draw_act > 0 do
        -- 检查是否需要新的施法块
        if new_cast_block_needed then
            -- 重置c表，开始新的施法块
            c.fire_rate_wait = 0
            c.entity_type = nil
            c.entity_variant = nil
            c.speed_multiplier = 1
            c.damage = 1
            c.screenshake = 0
            c.lifetime_add = 0
            print("开始新施法块 (c表已重置)")
            new_cast_block_needed = false
        end

        if current_deck_index > #deck_copy then
            -- 牌库耗尽
            if not gun_info.shuffle and #gun_state.discard_pile > 0 then
                -- 非乱序法杖，回绕，从弃牌堆抽取
                print("回绕触发 - 从弃牌堆抽取，继续当前施法块")
                -- 将弃牌堆添加到牌库副本进行回绕
                for _, spell in ipairs(gun_state.discard_pile) do
                    table.insert(deck_copy, spell)
                end
                current_deck_index = #deck_copy - #gun_state.discard_pile + 1 -- 指向弃牌堆的第一个法术
                wrapped_around = true -- 标记发生了回绕
                print("回绕后可抽取法术，弃牌堆大小: " .. #gun_state.discard_pile)
                -- 回绕不结束施法块，继续在当前施法块内抽取
            else
                -- 乱序法杖或无弃牌堆，结束施法
                print("无法回绕，结束施法")
                break
            end
        else
            if #deck_copy == 0 then
                print("牌库已空，无法施法")
                break
            end

            local spell_name = deck_copy[current_deck_index]
            if not spell_name then
                 print("无效的法术索引，结束施法")
                 break
            end

            local spell_info = actions[actions_map[spell_name]]
            local spell_mana_cost = spell_info.mana or 0

            if remaining_mana >= spell_mana_cost then
                -- 成功施法
                remaining_mana = remaining_mana - spell_mana_cost
                total_mana_cost = total_mana_cost + spell_mana_cost
                has_cast_this_round = true

                table.insert(used_spells_this_cast, spell_name)
                print("成功施放: " .. spell_name .. " (法力: -" .. spell_mana_cost .. ")")

                -- 检查是从牌库还是弃牌堆抽取的法术
                local original_deck_size = #gun_state.deck
                local is_from_deck = current_deck_index <= original_deck_size
                
                if is_from_deck then
                    -- 从牌库抽取，移入弃牌堆并从原始牌库移除
                    table.insert(gun_state.discard_pile, spell_name)
                    for i = #gun_state.deck, 1, -1 do
                        if gun_state.deck[i] == spell_name then
                            table.remove(gun_state.deck, i)
                            break
                        end
                    end
                    print("  从牌库移动到弃牌堆")
                else
                    -- 从弃牌堆抽取（回绕），从弃牌堆移除但不再加入弃牌堆
                    local discard_index = current_deck_index - original_deck_size
                    if discard_index >= 1 and discard_index <= #gun_state.discard_pile then
                        table.remove(gun_state.discard_pile, discard_index)
                        print("  从弃牌堆移除（回绕）")
                    end
                end
                
                -- 从牌库副本中移除已施放的法术
                table.remove(deck_copy, current_deck_index)

                if spell_info.action then
                    spell_info.action()
                end

                -- 处理不同类型的法术
                if spell_info.type == "ACTION_TYPE_MODIFIER" or spell_info.type == "ACTION_TYPE_OTHER" or spell_info.type == "ACTION_TYPE_DRAW_MANY" then
                    -- modifier法术，只修改c表，不结束施法块
                    print("  modifier法术，继续当前施法块")
                    
                elseif spell_info.type == "ACTION_TYPE_PROJECTILE" or spell_info.type == "ACTION_TYPE_STATIC_PROJECTILE" then
                    -- 投射物法术，收集投射物并结束当前施法块
                    if c.entity_type and c.entity_variant then
                        table.insert(projectiles, {
                            entity_type = c.entity_type,
                            entity_variant = c.entity_variant,
                            spell_name = spell_name,
                            speed_multiplier = c.speed_multiplier or 1,
                            damage = c.damage or 1,
                            fire_rate_wait = c.fire_rate_wait or 0,
                            lifetime_add = c.lifetime_add or 0, 
                        })
                        print("收集投射物: " .. spell_name .. " (速度倍率: " .. (c.speed_multiplier or 1) .. ") - 施法块结束")
                    end
                    -- 投射物法术结束当前施法块
                    new_cast_block_needed = true
                    
                elseif spell_info.type == "trigger" then
                    -- 触发法术结束当前施法块
                    print("  触发法术 - 施法块结束")
                    new_cast_block_needed = true
                end
                
                draw_act = draw_act - 1
                -- 注意：因为我们删除了元素，所以索引不需要增加
            else
                -- 法力不足，跳过
                print("跳过法术: " .. spell_name .. " (法力不足: " .. remaining_mana .. "/" .. spell_mana_cost .. ")")
                current_deck_index = current_deck_index + 1
            end
        end
    end

    local real_total_delay = base_cast_delay + (c.fire_rate_wait or 0)
    
    -- 如果发生了回绕，清空弃牌堆并强制进入充能
    if wrapped_around and has_cast_this_round then
        print("回绕结束，清空弃牌堆，强制进入充能")
        gun_state.discard_pile = {}
    end
    
    -- 如果牌库为空，则需要充能（无论是否有弃牌堆）
    local needs_recharge = has_cast_this_round and (#gun_state.deck == 0 or wrapped_around)
    
    return {
        cast_blocks = cast_blocks,
        total_cast_delay = real_total_delay,
        recharge_time = needs_recharge and recharge_time or 0,
        mana_cost = total_mana_cost,
        remaining_mana = remaining_mana,
        used_spells_this_cast = used_spells_this_cast,
        projectiles = projectiles
    }
end