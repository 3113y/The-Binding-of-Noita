function TBoN.Entity.Function.Custom.EntityNPC_Col_With_Pickup(entitypickup, entitynpc)
    local pickup_index = entitypickup.InitSeed
    local wand_info = TBoN.Pickup.Table.Wand_Hash[pickup_index]
    if not wand_info then
        if TBoN.Pickup.Table.dropped_wand_temp and TBoN.Pickup.Table.dropped_wand_temp[pickup_index] then
            local temp_data = TBoN.Pickup.Table.dropped_wand_temp[pickup_index]
            if Game():GetFrameCount() - temp_data.timestamp <= 36000 then
                wand_info = {
                    wand_data = temp_data.wand_data,
                    spell_slots = temp_data.spell_slots
                }
            end
        end
    end
    if not wand_info then
        return
    end
    local npc_hash = GetPtrHash(entitynpc)
    TBoN.Entity.Table.NPC_Wand_Hash[npc_hash] = {
        wand_data = wand_info.wand_data,
        spell_slots = wand_info.spell_slots
    }
    TBoN.Pickup.Table.Wand_Hash[pickup_index] = nil
    if TBoN.Pickup.Table.dropped_wand_temp and TBoN.Pickup.Table.dropped_wand_temp[pickup_index] then
        TBoN.Pickup.Table.dropped_wand_temp[pickup_index] = nil
    end
    entitypickup:Remove()
end

--- 初始化或获取NPC法杖状态
---@param npc Entity NPC实体
---@param wand_info table 法杖信息 {wand_data, spell_slots}
---@return table gun_state NPC法杖状态
function TBoN.Entity.Function.Custom.Get_Or_Init_NPC_Wand_State(npc, wand_info)
    local npc_hash = GetPtrHash(npc)

    if not TBoN.Entity.Table.NPC_Wand_States[npc_hash] then
        -- 构建初始牌库
        local initial_deck = {}
        for _, spell_data in ipairs(wand_info.spell_slots) do
            if spell_data.magic_id and spell_data.magic_id ~= false then
                table.insert(initial_deck, spell_data.magic_id)
            end
        end

        -- 如果需要洗牌
        if wand_info.wand_data.shuffle then
            local rng = RNG()
            rng:SetSeed(npc.InitSeed, 35)
            for j = #initial_deck, 2, -1 do
                local k = rng:RandomInt(j - 1) + 1
                initial_deck[j], initial_deck[k] = initial_deck[k], initial_deck[j]
            end
        end

        TBoN.Entity.Table.NPC_Wand_States[npc_hash] = {
            deck = initial_deck,
            discard_pile = {},
            always_cast_hand = {},
            current_mana = wand_info.wand_data.mana_max,
            mana_max = wand_info.wand_data.mana_max,
            cast_cooldown = 0,
            recharge_cooldown = 0,
            always_cast_index = 1,
            wrapped_around = false,
        }
    end

    return TBoN.Entity.Table.NPC_Wand_States[npc_hash]
end

-- 封装函数：在隔离的环境中执行施法，避免全局变量冲突
-- 施法核心已使用SpellContext，仅需保存/恢复 draw_act 和 current_reload_time
---@param gun_state table: 法杖状态
---@param gun_info table: 法杖信息
---@return table|nil: 施法结果 {projectiles, remaining_mana, total_cast_delay, recharge_time}
function TBoN.Entity.Function.Custom.Cast_Spell_Isolated(gun_state, gun_info)
    -- 保存仍为全局的变量
    local saved_draw_act = TBoN.Gun.Variable.Num.draw_act
    local saved_reload_time = current_reload_time
    
    TBoN.Gun.Variable.Num.draw_act = 1
    
    -- 执行施法（内部使用SpellContext，不再操作全局c/proj_modifier）
    local result = TBoN.Gun.Function.Custom.Get_Next_Shutted_Magic_Info(gun_state, gun_info)
    
    -- 恢复全局变量
    TBoN.Gun.Variable.Num.draw_act = saved_draw_act
    current_reload_time = saved_reload_time
    
    return result
end

--- 为NPC创建法杖渲染Effect
---@param npc Entity NPC实体
---@param wand_data table 法杖数据
function TBoN.Entity.Function.Custom.Create_NPC_Wand_Effect(npc, wand_data)
    local npc_hash = GetPtrHash(npc)
    
    -- 如果已存在，先移除旧的
    if TBoN.Entity.Table.NPC_Wand_Effects[npc_hash] then
        TBoN.Entity.Table.NPC_Wand_Effects[npc_hash]:Remove()
    end
    
    -- 创建新Effect
    local effect = Isaac.Spawn(1000, TBoN.Render.Variable.Num.Hand_Item_Variant, 0,
        npc.Position, Vector(0, 0), nil):ToEffect()
    
    if not effect then return end
    
    effect.Parent = npc
    effect.SpriteOffset = Vector(0, -8)
    
    -- 加载法杖sprite
    local sprite = effect:GetSprite()
    sprite:Load("gfx/gun/" .. wand_data.name .. ".anm2", true)
    sprite:Play("Idle", true)
    
    -- 保存到表中
    TBoN.Entity.Table.NPC_Wand_Effects[npc_hash] = effect
end

--- 移除NPC的法杖渲染Effect
---@param npc Entity NPC实体
function TBoN.Entity.Function.Custom.Remove_NPC_Wand_Effect(npc)
    local npc_hash = GetPtrHash(npc)
    
    if TBoN.Entity.Table.NPC_Wand_Effects[npc_hash] then
        TBoN.Entity.Table.NPC_Wand_Effects[npc_hash]:Remove()
        TBoN.Entity.Table.NPC_Wand_Effects[npc_hash] = nil
    end
end