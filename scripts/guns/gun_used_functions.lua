function draw_actions(i, bool)
    TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act + i
end

-- 散射角度计算函数
---@param base_direction: 基础方向向量 (Vector)
---@param spread_degrees: 散射角度 (度数)
---@return Vector: 计算后的方向向量 (Vector)
function TBoN.Gun.Function.Custom.Calculate_Spread_Direction(base_direction, spread_degrees)
    if not spread_degrees or spread_degrees <= 0 then
        return base_direction:Normalized()
    end
    
    local base_angle_rad = math.atan(base_direction.Y, base_direction.X)
    local final_angle_rad = base_angle_rad
    
    if spread_degrees >= 360 then
        final_angle_rad = math.random() * 2 * math.pi
    else
        local spread_rad = math.rad(spread_degrees)
        local random_offset = (math.random() - 0.5) * 2 * spread_rad
        final_angle_rad = base_angle_rad + random_offset
    end
    
    return Vector(math.cos(final_angle_rad), math.sin(final_angle_rad))
end
function TBoN.Gun.Function.Custom.Initialize_All_Gun_States()
    for i = 1, 4 do
        TBoN.Gun.Table.gun_states[i] = {
            deck = {},
            discard_pile = {},
            current_mana = 0,
            cast_cooldown = 0,
            recharge_cooldown = 0,
        }
        
        local current_gun_info = TBoN.Gun.Table.gun_info and TBoN.Gun.Table.gun_info[i]
        if current_gun_info and current_gun_info.name then
            TBoN.Gun.Table.gun_states[i].current_mana = current_gun_info.mana_max or 0
            
            local initial_deck = {}
            local magic_data = TBoN.Gun.Table.gun_magic_data and TBoN.Gun.Table.gun_magic_data[i]
            if magic_data then
                for _, spell_name in ipairs(magic_data) do
                    if spell_name then
                        table.insert(initial_deck, spell_name)
                    end
                end
            end
            
            if current_gun_info.shuffle then
                local rng = RNG()
                rng:SetSeed(Game():GetSeeds():GetPlayerInitSeed())
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
function TBoN.Gun.Function.Custom.Get_Next_Shutted_Magic_Info(gun_state, gun_info)
    local cast_blocks = {}
    local used_spells_this_cast = {}
    local projectiles = {}
    local has_cast_this_round = false
    TBoN.Gun.Variable.Num.draw_act = 1
    local base_cast_delay = gun_info.cast_delay or 0
    local recharge_time = gun_info.recharge_time or 0
    local total_mana_cost = 0
    local remaining_mana = gun_state.current_mana
    local deck_copy = {}
    for _, spell in ipairs(gun_state.deck) do
        table.insert(deck_copy, spell)
    end
    local current_deck_index = 1
    local new_cast_block_needed = true
    local wrapped_around = false
    while TBoN.Gun.Variable.Num.draw_act > 0 do
        if new_cast_block_needed then
            c.fire_rate_wait = 0
            c.entity_type = nil
            c.entity_variant = nil
            c.speed_multiplier = 1
            c.damage = 1
            c.screenshake = 0
            c.lifetime_add = 0
            c.damage_critical_chance = 0
            c.damage_projectile_add = 0
            c.spread_degrees = 0
            c.recoil_knockback = 0
            proj_modifier = {}
            new_cast_block_needed = false
        end
        if current_deck_index > #deck_copy then
            if not gun_info.shuffle and #gun_state.discard_pile > 0 then
                for _, spell in ipairs(gun_state.discard_pile) do
                    table.insert(deck_copy, spell)
                end
                current_deck_index = #deck_copy - #gun_state.discard_pile + 1
                wrapped_around = true
            else
                break
            end
        else
            if #deck_copy == 0 then
                break
            end
            local spell_name = deck_copy[current_deck_index]
            if not spell_name then
                 break
            end
            local spell_info = actions[TBoN.UI.Table.actions_map[spell_name]]
            local spell_mana_cost = spell_info.mana or 0
            if remaining_mana >= spell_mana_cost then
                remaining_mana = remaining_mana - spell_mana_cost
                total_mana_cost = total_mana_cost + spell_mana_cost
                has_cast_this_round = true

                table.insert(used_spells_this_cast, spell_name)

                local original_deck_size = #gun_state.deck
                local is_from_deck = current_deck_index <= original_deck_size
                
                if is_from_deck then
                    table.insert(gun_state.discard_pile, spell_name)
                    for i = #gun_state.deck, 1, -1 do
                        if gun_state.deck[i] == spell_name then
                            table.remove(gun_state.deck, i)
                            break
                        end
                    end
                else
                    local discard_index = current_deck_index - original_deck_size
                    if discard_index >= 1 and discard_index <= #gun_state.discard_pile then
                        table.remove(gun_state.discard_pile, discard_index)
                    end
                end
                
                table.remove(deck_copy, current_deck_index)

                if spell_info.action then
                    spell_info.action()
                end

                if spell_info.type == "ACTION_TYPE_MODIFIER" or spell_info.type == "ACTION_TYPE_OTHER" or spell_info.type == "ACTION_TYPE_DRAW_MANY" then                   
                elseif spell_info.type == "ACTION_TYPE_PROJECTILE" or spell_info.type == "ACTION_TYPE_STATIC_PROJECTILE" then
                    if c.entity_type and c.entity_variant then
                        local modifiers_copy = {}
                        for _, modifier in ipairs(proj_modifier) do
                            table.insert(modifiers_copy, modifier)
                        end                        
                        table.insert(projectiles, {
                            entity_type = c.entity_type,
                            entity_variant = c.entity_variant,
                            spell_name = spell_name,
                            speed_multiplier = c.speed_multiplier or 1,
                            damage = c.damage or 1,
                            fire_rate_wait = c.fire_rate_wait or 0,
                            lifetime_add = c.lifetime_add or 0,
                            spread_degrees = c.spread_degrees or 0,
                            damage_critical_chance = c.damage_critical_chance or 0,
                            damage_projectile_add = c.damage_projectile_add or 0,
                            recoil_knockback = c.recoil_knockback or 0,
                            modifiers = modifiers_copy,
                        })
                    end
                    new_cast_block_needed = true               
                elseif spell_info.type == "trigger" then
                    new_cast_block_needed = true
                end
                TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act - 1
            else
                current_deck_index = current_deck_index + 1
            end
        end
    end
    local real_total_delay = base_cast_delay + (c.fire_rate_wait or 0)
    if wrapped_around and has_cast_this_round then
        gun_state.discard_pile = {}
    end
    local needs_recharge = has_cast_this_round and (#gun_state.deck == 0 or wrapped_around)
    return {
        cast_blocks = cast_blocks,
        total_cast_delay = real_total_delay,
        recharge_time = needs_recharge and recharge_time or 0,
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
                rng:SetSeed(Game():GetSeeds():GetPlayerInitSeed())
                for j = #state.deck, 2, -1 do
                    local k = rng:RandomInt(j-1) + 1
                    state.deck[j], state.deck[k] = state.deck[k], state.deck[j]
                end
            end

            state.cast_cooldown = 0
            state.recharge_cooldown = 0
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
                if state.recharge_cooldown == 0 then
                    state.deck = {}
                    state.discard_pile = {}
                    
                    local magic_data = TBoN.Gun.Table.gun_magic_data and TBoN.Gun.Table.gun_magic_data[i]
                    if magic_data then
                        for _, spell_name in ipairs(magic_data) do
                            if spell_name then
                                table.insert(state.deck, spell_name)
                            end
                        end
                    end

                    if info.shuffle then
                        local rng = RNG()
                        rng:SetSeed(Game():GetSeeds():GetPlayerInitSeed())
                        for j = #state.deck, 2, -1 do
                            local k = rng:RandomInt(j-1) + 1
                            state.deck[j], state.deck[k] = state.deck[k], state.deck[j]
                        end
                    end
                end
            end
            
            local mana_charge_per_frame = info.mana_charge_speed / 60
            state.current_mana = math.min(
                state.current_mana + mana_charge_per_frame, 
                info.mana_max
            )
        end
    end
end
