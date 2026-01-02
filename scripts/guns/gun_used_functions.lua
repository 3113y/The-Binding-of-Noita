-- 全局变量：当前施法的充能时间
current_reload_time = 0

function draw_actions(i, bool)
    TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act + i
end

-- 散射角度计算函数
---@param base_direction: 基础方向向量 (Vector)
---@param spread_degrees: 散射角度 (度数)
---@param rng: RNG对象
---@return Vector: 计算后的方向向量 (Vector)
function TBoN.Gun.Function.Custom.Calculate_Spread_Direction(base_direction, spread_degrees, rng)
    if not spread_degrees or spread_degrees <= 0 then
        return base_direction:Normalized()
    end
    
    -- 如果没有提供RNG，创建一个基于游戏帧数的RNG
    if not rng then
        rng = RNG()
        local frame = Game():GetFrameCount()
        rng:SetSeed(frame, 35)
    end
    
    local base_angle_rad = math.atan(base_direction.Y, base_direction.X)
    local final_angle_rad = base_angle_rad
    
    if spread_degrees >= 360 then
        final_angle_rad = rng:RandomFloat() * 2 * math.pi
    else
        local spread_rad = math.rad(spread_degrees)
        local random_offset = (rng:RandomFloat() - 0.5) * 2 * spread_rad
        final_angle_rad = base_angle_rad + random_offset
    end
    
    return Vector(math.cos(final_angle_rad), math.sin(final_angle_rad))
end

-- 初始化所有魔杖的状态
function TBoN.Gun.Function.Custom.Initialize_All_Gun_States()
    for i = 1, 4 do
        TBoN.Gun.Table.gun_states[i] = {
            deck = {},
            discard_pile = {},
            always_cast_hand = {},  -- 始终施放法术的手牌（每次施法前预载）
            mana_max = 0,
            current_mana = 0,
            cast_cooldown = 0,
            recharge_cooldown = 0,
            always_cast_index = 1,   -- 记住始终施放的抽取位置
            wrapped_around = false,  -- 记住是否已经回绕
        }
        
        local current_gun_info = TBoN.Gun.Table.gun_info and TBoN.Gun.Table.gun_info[i]
        if current_gun_info and current_gun_info.name then
            TBoN.Gun.Table.gun_states[i].current_mana = current_gun_info.mana_max or 0
            TBoN.Gun.Table.gun_states[i].mana_max = current_gun_info.mana_max or 0
            local initial_deck = {}
            local magic_data = TBoN.Gun.Table.gun_magic_data and TBoN.Gun.Table.gun_magic_data[i]
            if magic_data then
                for _, spell_entry in ipairs(magic_data) do
                    if spell_entry and spell_entry.magic_id and spell_entry.magic_id ~= false then
                        table.insert(initial_deck, spell_entry.magic_id)
                    end
                end
            end
            
            if current_gun_info.shuffle then
                local rng = RNG()
                rng:SetSeed(Game():GetSeeds():GetNextSeed(), 35)
                for j = #initial_deck, 2, -1 do
                    local k = rng:RandomInt(j-1) + 1
                    initial_deck[j], initial_deck[k] = initial_deck[k], initial_deck[j]
                end
            end
            TBoN.Gun.Table.gun_states[i].deck = initial_deck
        end
    end
end

-- 核心施法函数，按照Noita机制施法
-- 每次调用返回一个施法块的信息
function TBoN.Gun.Function.Custom.Get_Next_Shutted_Magic_Info(gun_state, gun_info)
    local cast_blocks = {}
    local used_spells_this_cast = {}
    local projectiles = {}
    local has_cast_this_round = false
    TBoN.Gun.Variable.Num.draw_act = 1  -- 每个施法块开始时draw_act=1
    local base_cast_delay = gun_info.cast_delay or 0
    current_reload_time = gun_info.recharge_time or 0
    local total_mana_cost = 0
    local remaining_mana = gun_state.current_mana
    
    -- ==================== 始终施放预载（仅第一次） ====================
    -- 只在第一个施法块时预载始终施放法术
    if gun_state.always_cast_index == 1 then
        gun_state.always_cast_hand = {}
        if gun_info.always_cast then
            local always_cast_spell = gun_info.always_cast
            if type(always_cast_spell) == "string" then
                table.insert(gun_state.always_cast_hand, always_cast_spell)
            elseif type(always_cast_spell) == "table" then
                for _, spell_id in ipairs(always_cast_spell) do
                    table.insert(gun_state.always_cast_hand, spell_id)
                end
            end
        end
    end
    -- ================================================
    
    local new_cast_block_needed = true
    
    -- 单个施法块的抽取循环（直到draw_act=0）
    while TBoN.Gun.Variable.Num.draw_act > 0 do
            if new_cast_block_needed then
                c.fire_rate_wait = 0
                c.entity_type = nil
                c.entity_variant = nil
                c.entity_subtype = 0
                c.speed = 1
                c.speed_multiplier = 1
                c.damage = 1
                c.screenshake = 0
                c.lifetime = 0
                c.lifetime_add = 0
                c.damage_critical_chance = 0
                c.damage_projectile_add = 0
                c.spread_degrees = 0
                c.recoil_knockback = 0
                c.is_trigger = false
                c.trigger_type = nil
                c.trigger_draw_count = nil
                c.trigger_param = nil
                proj_modifier = {}
                new_cast_block_needed = false
            end
            
            -- ==================== 抽取法术 ====================
            local spell_name = nil
            local is_from_always_cast = false
            
            -- 优先从始终施放手牌抽取
            if gun_state.always_cast_index <= #gun_state.always_cast_hand then
                spell_name = gun_state.always_cast_hand[gun_state.always_cast_index]
                is_from_always_cast = true
                gun_state.always_cast_index = gun_state.always_cast_index + 1
            else
                -- 始终施放手牌已空，从普通牌库抽取
                -- 检查手牌是否已空
                if #gun_state.deck == 0 then
                    -- 手牌已空且draw_act非零，检查是否需要回绕
                    if not gun_state.wrapped_around and not gun_info.shuffle and #gun_state.discard_pile > 0 then
                        -- 发生回绕：从弃牌堆恢复到牌库
                        for _, spell in ipairs(gun_state.discard_pile) do
                            table.insert(gun_state.deck, spell)
                        end
                        gun_state.discard_pile = {}
                        gun_state.wrapped_around = true
                        -- 回绕后继续抽取直到draw_act=0或弃牌堆抽光
                    else
                        -- 已经回绕过或无法回绕，结束本施法块
                        break
                    end
                end
                
                -- 再次检查（回绕后可能仍然为空）
                if #gun_state.deck == 0 then
                    break
                end
                
                -- 从牌库第一张抽取
                spell_name = gun_state.deck[1]
                
                -- 检查该法术的使用次数
                local current_gun_index = TBoN.Render.Variable.Num.item_groove or 1
                local magic_data = TBoN.Gun.Table.gun_magic_data and TBoN.Gun.Table.gun_magic_data[current_gun_index]
                if magic_data then
                    for _, spell_entry in ipairs(magic_data) do
                        if spell_entry and spell_entry.magic_id == spell_name then
                            local uses = spell_entry.current_uses or -1
                            -- 如果使用次数为0，跳过该法术（但保留在牌库中）
                            if uses == 0 then
                                -- 从牌库移除并放入弃牌堆
                                table.remove(gun_state.deck, 1)
                                table.insert(gun_state.discard_pile, spell_name)
                                spell_name = nil
                                TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act - 1
                            end
                            -- 注意：有限使用次数的减少将在蓝量检查通过后进行
                            -- uses == -1 时无限使用，不做处理
                            break
                        end
                    end
                end
                
                -- 如果该法术使用次数为0，继续下一轮循环
                if not spell_name then
                    goto continue
                end
            end
            
            if not spell_name then
                break
            end
            
            local spell_info = actions[TBoN.Render.Table.actions_map[spell_name]]
            if not spell_info then
                if not is_from_always_cast then
                    -- 法术未找到，从牌库移除并放入弃牌堆
                    table.remove(gun_state.deck, 1)
                    table.insert(gun_state.discard_pile, spell_name)
                end
                TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act - 1
                goto continue
            end
            local spell_mana_cost = 0
            if is_from_always_cast then
                local raw_mana = spell_info.mana or 0
                if raw_mana < 0 then
                    spell_mana_cost = raw_mana
                else
                    spell_mana_cost = 0
                end
            else
                spell_mana_cost = spell_info.mana or 0
            end
            
            -- 检查法力是否足够 - 不足则立即结束本施法块
            if remaining_mana + 0.001 < spell_mana_cost then
                break
            end
            
            -- 蓝量检查通过后，减少法术使用次数
            if not is_from_always_cast then
                local current_gun_index = TBoN.Render.Variable.Num.item_groove or 1
                local magic_data = TBoN.Gun.Table.gun_magic_data and TBoN.Gun.Table.gun_magic_data[current_gun_index]
                if magic_data then
                    for _, spell_entry in ipairs(magic_data) do
                        if spell_entry and spell_entry.magic_id == spell_name then
                            local uses = spell_entry.current_uses or -1
                            if uses > 0 then
                                -- 有限使用次数，减1
                                spell_entry.current_uses = uses - 1
                            end
                            break
                        end
                    end
                end
            end
            
            -- 消耗法力并执行法术
            remaining_mana = remaining_mana - spell_mana_cost
            total_mana_cost = total_mana_cost + spell_mana_cost
            has_cast_this_round = true
            table.insert(used_spells_this_cast, spell_name)

            -- 处理弃牌（从牌库移除，放入弃牌堆）
            if not is_from_always_cast then
                table.remove(gun_state.deck, 1)
                table.insert(gun_state.discard_pile, spell_name)
            end
            
            -- 执行法术action
            if spell_info.action then
                spell_info.action()
            end
            
            -- 根据法术类型处理
            if spell_info.type == "ACTION_TYPE_MODIFIER" or spell_info.type == "ACTION_TYPE_OTHER" or spell_info.type == "ACTION_TYPE_DRAW_MANY" then
                -- 修饰符法术，不创建投射物，继续下一个法术
            elseif spell_info.type == "ACTION_TYPE_PROJECTILE" or spell_info.type == "ACTION_TYPE_STATIC_PROJECTILE" then
                if c.entity_type and c.entity_variant then
                    local modifiers_copy = {}
                    for _, modifier in ipairs(proj_modifier) do
                        table.insert(modifiers_copy, modifier)
                    end
                    
                    -- 收集触发法术队列
                    local trigger_spells = {}
                    if c.is_trigger then
                        local trigger_draw_count = c.trigger_draw_count or 1
                        
                        for i = 1, trigger_draw_count do
                            if TBoN.Gun.Variable.Num.draw_act <= 0 then
                                break  -- draw_act已耗尽，停止收集
                            end
                            
                            if #gun_state.deck > 0 then
                                local trigger_spell_name = gun_state.deck[1]
                                if trigger_spell_name then
                                    local trigger_spell_info = actions[TBoN.Render.Table.actions_map[trigger_spell_name]]
                                    if trigger_spell_info then
                                        local trigger_mana = trigger_spell_info.mana or 0
                                        if remaining_mana >= trigger_mana then
                                            remaining_mana = remaining_mana - trigger_mana
                                            total_mana_cost = total_mana_cost + trigger_mana
                                            table.insert(trigger_spells, trigger_spell_name)
                                            table.insert(used_spells_this_cast, trigger_spell_name)
                                            
                                            -- 从牌库移除，放入弃牌堆
                                            table.remove(gun_state.deck, 1)
                                            table.insert(gun_state.discard_pile, trigger_spell_name)
                                            
                                            -- 抽取法术消耗draw_act
                                            TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act - 1
                                        else
                                            break
                                        end
                                    end
                                end
                            else
                                break
                            end
                        end
                    end
                    
                    table.insert(projectiles, {
                        entity_type = c.entity_type,
                        entity_variant = c.entity_variant,
                        entity_subtype = c.entity_subtype or 0,
                        spell_name = spell_name,
                        speed = c.speed or 1,
                        speed_multiplier = c.speed_multiplier or 1,
                        damage = c.damage or 1,
                        fire_rate_wait = c.fire_rate_wait or 0,
                        lifetime = c.lifetime or 0,
                        lifetime_add = c.lifetime_add or 0,
                        spread_degrees = c.spread_degrees or 0,
                        damage_critical_chance = c.damage_critical_chance or 0,
                        damage_projectile_add = c.damage_projectile_add or 0,
                        recoil_knockback = c.recoil_knockback or 0,
                        modifiers = modifiers_copy,
                        is_trigger = c.is_trigger or false,
                        trigger_type = c.trigger_type,
                        trigger_param = c.trigger_param,
                        trigger_spells = trigger_spells,
                    })
                end
                new_cast_block_needed = true
            elseif spell_info.type == "trigger" then
                new_cast_block_needed = true
            end
            
            TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act - 1
            ::continue::
    end
    -- draw_act = 0，本施法块结束
    
    local real_total_delay = base_cast_delay + (c.fire_rate_wait or 0)
    if gun_state.wrapped_around and has_cast_this_round then
        gun_state.discard_pile = {}
    end
    local needs_recharge = has_cast_this_round and (#gun_state.deck == 0 or gun_state.wrapped_around)
    
    return {
        cast_blocks = cast_blocks,
        total_cast_delay = real_total_delay,
        recharge_time = needs_recharge and math.max(0, current_reload_time) or 0,
        mana_cost = total_mana_cost,
        remaining_mana = remaining_mana,
        used_spells_this_cast = used_spells_this_cast,
        projectiles = projectiles,
    }
end

-- 重置指定魔杖的施法状态
function TBoN.Gun.Function.Custom.Reset_Gun_Cast_State(gun_index)
    if gun_index and gun_index >= 1 and gun_index <= 4 then
        local state = TBoN.Gun.Table.gun_states[gun_index]
        if state then
            for _, spell in ipairs(state.discard_pile) do
                table.insert(state.deck, spell)
            end
            state.discard_pile = {}

            if TBoN.Gun.Table.gun_info[gun_index] and TBoN.Gun.Table.gun_info[gun_index].shuffle then
                local rng = RNG()
                rng:SetSeed(Game():GetSeeds():GetNextSeed(), 35)
                for j = #state.deck, 2, -1 do
                    local k = rng:RandomInt(j-1) + 1
                    state.deck[j], state.deck[k] = state.deck[k], state.deck[j]
                end
            end

            state.cast_cooldown = 0
            state.recharge_cooldown = 0
            state.always_cast_index = 1
            state.wrapped_around = false
            if TBoN.Gun.Table.gun_info[gun_index] then
                state.current_mana = TBoN.Gun.Table.gun_info[gun_index].mana_max
            end
        end
    end
end

-- 重置所有魔杖的施法状态
function TBoN.Gun.Function.Custom.Reset_All_Gun_Cast_States()
    TBoN.Gun.Function.Custom.Initialize_All_Gun_States()
end

-- 更新魔杖状态
function TBoN.Gun.Function.Custom.Update_Gun_States()
    for i = 1, 4 do
        local state = TBoN.Gun.Table.gun_states[i]
        local info = TBoN.Gun.Table.gun_info[i]
        if state and info and info.name then
            if state.cast_cooldown > 0 then
                state.cast_cooldown = state.cast_cooldown - 1
            end
            
            if state.recharge_cooldown > 0 then
                state.recharge_cooldown = state.recharge_cooldown - 1
            end
            
            -- 当 recharge_cooldown 为0或负数时，检查是否需要重置牌库
            if state.recharge_cooldown <= 0 and (#state.deck == 0 or state.wrapped_around) then
                state.deck = {}
                state.discard_pile = {}
                
                local magic_data = TBoN.Gun.Table.gun_magic_data and TBoN.Gun.Table.gun_magic_data[i]
                if magic_data then
                    for _, spell_entry in ipairs(magic_data) do
                        if spell_entry and spell_entry.magic_id and spell_entry.magic_id ~= false then
                            table.insert(state.deck, spell_entry.magic_id)
                        end
                    end
                end

                if info.shuffle then
                    local rng = RNG()
                    rng:SetSeed(Game():GetSeeds():GetNextSeed(), 35)
                    for j = #state.deck, 2, -1 do
                        local k = rng:RandomInt(j-1) + 1
                        state.deck[j], state.deck[k] = state.deck[k], state.deck[j]
                    end
                end
                
                -- 充能完成后重置索引
                state.always_cast_index = 1
                state.wrapped_around = false
            end
            
            local mana_charge_per_frame = info.mana_charge_speed / 60
            state.current_mana = math.min(
                state.current_mana + mana_charge_per_frame, 
                info.mana_max
            )
        end
    end
end