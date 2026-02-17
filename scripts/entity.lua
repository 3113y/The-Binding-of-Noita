include("scripts.entities.entity_table")
include("scripts.entities.entity_used_functions")

function TBoN_MOD:EntityNPC_Attack_With_Wand(npc)
    local npc_hash = GetPtrHash(npc)
    local wand_info = TBoN.Entity.Table.NPC_Wand_Hash[npc_hash]
    if not wand_info then return end

    local wand_data = wand_info.wand_data
    local gun_state = TBoN.Entity.Function.Custom.Get_Or_Init_NPC_Wand_State(npc, wand_info)

    -- 初次检测到法杖时创建Effect
    if not TBoN.Entity.Table.NPC_Wand_Effects[npc_hash] then
        TBoN.Entity.Function.Custom.Create_NPC_Wand_Effect(npc, wand_data)
    end

    -- 更新冷却
    if gun_state.cast_cooldown > 0 then
        gun_state.cast_cooldown = gun_state.cast_cooldown - 1
        return
    end
    if gun_state.recharge_cooldown > 0 then
        gun_state.recharge_cooldown = gun_state.recharge_cooldown - 1
        return
    end

    -- 回蓝
    gun_state.current_mana = math.min(
        gun_state.current_mana + (wand_data.mana_charge_speed / 60),
        gun_state.mana_max
    )

    -- 获取目标并检查距离
    local target = npc:GetPlayerTarget()
    if not target then return end
    local offset = target.Position - npc.Position
    if offset:Length() > 400 then return end
    local direction = offset:Normalized()

    -- 施法（wand_data字段与gun_info一致，可直接传递）
    local result = TBoN.Entity.Function.Custom.Cast_Spell_Isolated(gun_state, wand_data)
    if not result or not result.projectiles or #result.projectiles == 0 then return end

    -- 更新法杖状态
    gun_state.current_mana = result.remaining_mana
    gun_state.cast_cooldown = result.total_cast_delay
    gun_state.recharge_cooldown = result.recharge_time

    -- 生成投射物
    local scatter_rng = RNG()
    scatter_rng:SetSeed(Game():GetFrameCount() + npc_hash, 35)

    for _, proj in ipairs(result.projectiles) do
        local scatter_direction = TBoN.Gun.Function.Custom.Calculate_Spread_Direction(
            direction, proj.spread_degrees or 0, scatter_rng
        )
        local position = npc.Position + scatter_direction * 30
        local velocity = scatter_direction * (proj.speed) * (proj.speed_multiplier or 1)
        TBoN.Gun.Function.Custom.Spawn_Projectile_Entity(proj, position, velocity, npc)
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_NPC_UPDATE,TBoN_MOD.EntityNPC_Attack_With_Wand)

function TBoN_MOD:Wand_Drop_After_Death(npc)
    local npc_hash = GetPtrHash(npc)
    local wand_info = TBoN.Entity.Table.NPC_Wand_Hash[npc_hash]
    if not wand_info then return end
    local wand_data = wand_info.wand_data
    local spell_slots = wand_info.spell_slots
    local wand_id = tonumber(string.match(wand_data.name, "wand_(%d+)")) or 0
    local entity = Isaac.Spawn(5, TBoN.Magic.Info.Variant.Pickup_Wand, wand_id,
        npc.Position, Vector(0, 0), nil)
    local pickup_index = entity.InitSeed
    TBoN.Pickup.Function.Custom.Save_Wand_Info(pickup_index, wand_data, spell_slots, false)
    TBoN.Pickup.Table.Wand_Hash[pickup_index] = {
        wand_data = wand_data,
        spell_slots = spell_slots
    }
    -- 设置法杖精灵图
    local sprite = entity:GetSprite()
    sprite:Load("gfx/gun/" .. wand_data.name .. ".anm2", true)
    sprite:Play("Idle", true)
    sprite.Offset = Vector(-9, 0)

    -- 移除法杖渲染Effect
    TBoN.Entity.Function.Custom.Remove_NPC_Wand_Effect(npc)

    -- 清理NPC法杖数据
    TBoN.Entity.Table.NPC_Wand_Hash[npc_hash] = nil
    TBoN.Entity.Table.NPC_Wand_States[npc_hash] = nil
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL,TBoN_MOD.Wand_Drop_After_Death)

function TBoN_MOD:Wand_Render_With_EntityNPC(effect)
    local npc = effect.Parent
    if not npc or not npc:Exists() then
        effect:Remove()
        return
    end
    
    if not npc:ToNPC() then
        return
    end
    
    local npc_hash = GetPtrHash(npc)
    local wand_info = TBoN.Entity.Table.NPC_Wand_Hash[npc_hash]
    if not wand_info then
        effect:Remove()
        TBoN.Entity.Table.NPC_Wand_Effects[npc_hash] = nil
        return
    end
    
    local target = npc:ToNPC():GetPlayerTarget()
    if target then
        local direction = (target.Position - npc.Position):Normalized()
        local degrees = direction:GetAngleDegrees()
        effect.SpriteRotation = degrees
    end
    
    effect.Position = npc.Position + Vector(0, -5)
    effect.SpriteScale = Vector(1.2, 1.2)
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE,TBoN_MOD.Wand_Render_With_EntityNPC)