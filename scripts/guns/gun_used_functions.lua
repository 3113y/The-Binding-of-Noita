-- 全局变量：当前施法的充能时间
current_reload_time = 0

function draw_actions(i, bool)
    TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act + i
end

-- ==================== SpellContext 施法上下文 ====================
-- 替代全局 c 和 proj_modifier，封装单个施法块的所有属性
-- 使用方式: local ctx = CreateSpellContext() 或 CreateSpellContext(parent_ctx)

--- 创建一个新的施法上下文
---@param parent_ctx table|nil 父上下文，用于触发法术继承属性
---@return table ctx 施法上下文对象
function CreateSpellContext(parent_ctx)
    local ctx = {
        -- 基础属性
        fire_rate_wait = 0,
        entity_type = nil,
        entity_variant = nil,
        entity_subtype = 0,
        speed = 1,
        speed_multiplier = 1,
        damage = parent_ctx and parent_ctx.damage or 1,
        screenshake = 0,
        lifetime = 0,
        lifetime_add = 0,
        spread_degrees = 0,
        recoil_knockback = 0,
        damage_critical_chance = parent_ctx and parent_ctx.damage_critical_chance or 0,
        damage_projectile_add = parent_ctx and parent_ctx.damage_projectile_add or 0,
        -- 触发相关
        trigger_type = nil,
        trigger_draw_count = nil,
        trigger_param = nil,
        -- 修饰符列表
        modifiers = {},
    }
    -- 继承父上下文的修饰符（深拷贝）
    if parent_ctx and parent_ctx.modifiers then
        for i, mod in ipairs(parent_ctx.modifiers) do
            ctx.modifiers[i] = mod
        end
    end
    return ctx
end

--- 添加修饰符到上下文
---@param ctx table 施法上下文
---@param modifier_name string 修饰符名称
function SpellContext_AddModifier(ctx, modifier_name)
    table.insert(ctx.modifiers, modifier_name)
end

--- 从上下文构建投射物配置表
---@param ctx table 施法上下文
---@param spell_name string 法术ID
---@param trigger_projectiles table|nil 触发投射物配置列表
---@return table projectile_config 投射物配置
function SpellContext_BuildProjectile(ctx, spell_name, trigger_projectiles)
    return {
        entity_type = ctx.entity_type,
        entity_variant = ctx.entity_variant,
        entity_subtype = ctx.entity_subtype or 0,
        spell_name = spell_name,
        speed = ctx.speed or 1,
        speed_multiplier = ctx.speed_multiplier or 1,
        damage = ctx.damage or 1,
        fire_rate_wait = ctx.fire_rate_wait or 0,
        lifetime = ctx.lifetime or 0,
        lifetime_add = ctx.lifetime_add or 0,
        spread_degrees = ctx.spread_degrees or 0,
        damage_critical_chance = ctx.damage_critical_chance or 0,
        damage_projectile_add = ctx.damage_projectile_add or 0,
        recoil_knockback = ctx.recoil_knockback or 0,
        modifiers = {table.unpack(ctx.modifiers)},
        trigger_type = ctx.trigger_type,
        trigger_param = ctx.trigger_param,
        trigger_projectiles = trigger_projectiles or {},
    }
end

-- ==================== 工具函数 ====================

-- 散射角度计算函数
---@param base_direction Vector 基础方向向量
---@param spread_degrees number 散射角度（度数）
---@param rng RNG RNG 对象
---@return Vector direction 计算后的方向向量
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

--- 生成投射物实体并注册到魔法系统
--- 包括：Isaac.Spawn、生命周期设置、magic_hash注册、触发注册、旋转/动画设置
---@param proj table 投射物配置（来自SpellContext_BuildProjectile）
---@param position Vector 生成位置
---@param velocity Vector 生成速度向量
---@param parent Entity 父实体
---@return Entity 生成的实体
function TBoN.Gun.Function.Custom.Spawn_Projectile_Entity(proj, position, velocity, parent)
    local entity = Isaac.Spawn(
        proj.entity_type,
        proj.entity_variant,
        proj.entity_subtype or 0,
        position,
        velocity,
        parent
    )

    if entity:ToEffect() then
        entity:ToEffect():SetTimeout((proj.lifetime or 0) + (proj.lifetime_add or 0))
    end
    entity.Parent = parent

    -- 注册到magic_hash
    local entity_hash = GetPtrHash(entity)
    TBoN.Magic.Table.magic_hash[entity_hash] = {
        damages = {
            damage = proj.damage or 1,
            damage_critical_chance = proj.damage_critical_chance or 0,
            damage_projectile_add = proj.damage_projectile_add or 0
        },
        modifiers = proj.modifiers or {},
        trigger_projectiles = proj.trigger_projectiles or {},
        applied = false
    }

    -- 触发法术注册
    if proj.trigger_type and proj.trigger_projectiles and #proj.trigger_projectiles > 0 then
        local trigger_type_map = {
            TIMER = TBoN.Magic.Table.Info.TriggerType.TIMER,
            COLLISION = TBoN.Magic.Table.Info.TriggerType.COLLISION,
            DEATH = TBoN.Magic.Table.Info.TriggerType.DEATH,
        }
        TBoN.Magic.Function.Custom.RegisterTrigger(
            entity,
            trigger_type_map[proj.trigger_type] or TBoN.Magic.Table.Info.TriggerType.COLLISION,
            proj.trigger_projectiles,
            proj.trigger_param
        )
    end

    -- 设置旋转和动画
    local degrees = math.deg(math.atan(velocity.Y, velocity.X))
    if entity:ToTear() then
        entity:ToTear().Rotation = degrees
    end
    entity.SpriteRotation = degrees
    local sprite = entity:GetSprite()
    if sprite then
        sprite:Play("RegularTear6", false)
    end

    return entity
end

-- 处理触发法术的施法块（递归支持嵌套触发）
-- 使用SpellContext，不再操作全局c/proj_modifier
-- @param gun_state: 当前魔杖状态
-- @param draw_count: 抽取数量
-- @param remaining_mana: 剩余法力
-- @param parent_ctx: 父投射物的SpellContext（用于继承）
-- @param used_spells_list: 已使用法术列表（引用，用于记录）
-- @return: { projectiles = {...}, remaining_mana = x, mana_cost = y }
function TBoN.Gun.Function.Custom.Process_Trigger_Spell_Block(gun_state, draw_count, remaining_mana, parent_ctx, used_spells_list)
    local trigger_projectiles = {}
    local total_mana_cost = 0
    local trigger_draw_act = draw_count
    
    -- 创建触发法术的上下文（自动继承父上下文的 damage/crit/modifier）
    local ctx = CreateSpellContext(parent_ctx)
    
    -- 处理触发法术块
    while trigger_draw_act > 0 do
        -- 检查牌库是否有牌
        if #gun_state.deck == 0 then
            break
        end
        
        local trigger_spell_name = gun_state.deck[1]
        if not trigger_spell_name then
            break
        end
        
        local trigger_spell_info = actions[TBoN.Render.Table.actions_map[trigger_spell_name]]
        if not trigger_spell_info then
            -- 法术未找到，移除并继续
            table.remove(gun_state.deck, 1)
            table.insert(gun_state.discard_pile, trigger_spell_name)
            trigger_draw_act = trigger_draw_act - 1
            goto continue_trigger
        end
        
        local trigger_mana = trigger_spell_info.mana or 0
        
        -- 检查法力是否足够
        if remaining_mana + 0.001 < trigger_mana then
            break
        end
        
        -- 消耗法力
        remaining_mana = remaining_mana - trigger_mana
        total_mana_cost = total_mana_cost + trigger_mana
        
        -- 从牌库移除，放入弃牌堆
        table.remove(gun_state.deck, 1)
        table.insert(gun_state.discard_pile, trigger_spell_name)
        
        -- 消耗draw_act
        trigger_draw_act = trigger_draw_act - 1
        TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act - 1
        
        -- 记录使用的法术
        table.insert(used_spells_list, trigger_spell_name)
        
        -- 执行法术action
        if trigger_spell_info.action then trigger_spell_info.action(ctx) end
        
        -- 根据法术类型处理
        if trigger_spell_info.type == "ACTION_TYPE_MODIFIER" or trigger_spell_info.type == "ACTION_TYPE_OTHER" or trigger_spell_info.type == "ACTION_TYPE_DRAW_MANY" then
            -- 修饰符法术，继续下一个法术
        elseif trigger_spell_info.type == "ACTION_TYPE_PROJECTILE" or trigger_spell_info.type == "ACTION_TYPE_STATIC_PROJECTILE" then
            if ctx.entity_type and ctx.entity_variant then
                -- 如果这个被触发的法术本身也是触发法术，递归处理
                local nested_trigger_projectiles = {}
                if ctx.trigger_type then
                    local nested_result = TBoN.Gun.Function.Custom.Process_Trigger_Spell_Block(
                        gun_state,
                        ctx.trigger_draw_count or 1,
                        remaining_mana,
                        ctx,  -- 直接传当前ctx作为父上下文
                        used_spells_list
                    )
                    
                    if nested_result then
                        remaining_mana = nested_result.remaining_mana
                        total_mana_cost = total_mana_cost + (nested_result.mana_cost or 0)
                        nested_trigger_projectiles = nested_result.projectiles or {}
                    end
                end
                
                -- 使用BuildProjectile构建投射物配置
                table.insert(trigger_projectiles, SpellContext_BuildProjectile(ctx, trigger_spell_name, nested_trigger_projectiles))
                
                -- 重置上下文以处理下一个法术（重新继承父上下文）
                ctx = CreateSpellContext(parent_ctx)
            end
        end
        
        ::continue_trigger::
    end
    
    return {
        projectiles = trigger_projectiles,
        remaining_mana = remaining_mana,
        mana_cost = total_mana_cost
    }
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
-- 使用SpellContext替代全局c/proj_modifier
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
    
    -- 创建施法上下文（替代全局c重置）
    local ctx = CreateSpellContext()
    local new_cast_block_needed = false  -- 首次已通过CreateSpellContext初始化
    
    -- 单个施法块的抽取循环（直到draw_act=0）
    while TBoN.Gun.Variable.Num.draw_act > 0 do
            if new_cast_block_needed then
                ctx = CreateSpellContext()
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
                if #gun_state.deck == 0 then
                    if not gun_state.wrapped_around and not gun_info.shuffle and #gun_state.discard_pile > 0 then
                        for _, spell in ipairs(gun_state.discard_pile) do
                            table.insert(gun_state.deck, spell)
                        end
                        gun_state.discard_pile = {}
                        gun_state.wrapped_around = true
                    else
                        break
                    end
                end
                
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
                            if uses == 0 then
                                table.remove(gun_state.deck, 1)
                                table.insert(gun_state.discard_pile, spell_name)
                                spell_name = nil
                                TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act - 1
                            end
                            break
                        end
                    end
                end
                
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
            
            -- 检查法力是否足够
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

            -- 处理弃牌
            if not is_from_always_cast then
                table.remove(gun_state.deck, 1)
                table.insert(gun_state.discard_pile, spell_name)
            end
            
            -- 执行法术action
            if spell_info.action then spell_info.action(ctx) end
            
            -- 根据法术类型处理
            if spell_info.type == "ACTION_TYPE_MODIFIER" or spell_info.type == "ACTION_TYPE_OTHER" or spell_info.type == "ACTION_TYPE_DRAW_MANY" then
                -- 修饰符法术，不创建投射物，继续下一个法术
            elseif spell_info.type == "ACTION_TYPE_PROJECTILE" or spell_info.type == "ACTION_TYPE_STATIC_PROJECTILE" then
                if ctx.entity_type and ctx.entity_variant then
                    -- 收集并完整处理触发法术
                    local trigger_projectiles = {}
                    if ctx.trigger_type then
                        -- 处理触发法术的施法块，直接传ctx作为父上下文
                        local trigger_result = TBoN.Gun.Function.Custom.Process_Trigger_Spell_Block(
                            gun_state,
                            ctx.trigger_draw_count or 1,
                            remaining_mana,
                            ctx,
                            used_spells_this_cast
                        )
                        
                        if trigger_result then
                            remaining_mana = trigger_result.remaining_mana
                            total_mana_cost = total_mana_cost + (trigger_result.mana_cost or 0)
                            trigger_projectiles = trigger_result.projectiles or {}
                        end
                    end
                    
                    -- 使用BuildProjectile构建投射物配置
                    table.insert(projectiles, SpellContext_BuildProjectile(ctx, spell_name, trigger_projectiles))
                end
                new_cast_block_needed = true
            elseif spell_info.type == "trigger" then
                new_cast_block_needed = true
            end
            
            TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act - 1
            ::continue::
    end
    -- draw_act = 0，本施法块结束
    
    local real_total_delay = base_cast_delay + (ctx.fire_rate_wait or 0)
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
