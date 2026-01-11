-- LUMINOUS_DRILL 光明穿凿 投射物逻辑
-- 发射一道短射程，强穿透力的绿色光束，能够挖掘任何材料

-- 对敌人造成伤害逻辑（强大的穿透伤害）
function TBoN_MOD:Luminous_Drill_Damage_Enemy(entity)
    local damage_radius = 20  -- 伤害半径，比链锯稍大
    -- 获取房间内所有敌人
    local entities = Isaac.GetRoomEntities()
    for _, target in ipairs(entities) do
        if target:IsVulnerableEnemy() and target:IsActiveEnemy(false) then
            -- 检查是否在伤害范围内
            if TBoN.Magic.Function.Custom.Check_Pos(entity.Position, target.Position, damage_radius) then
                local damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
                -- 短距离内伤害更强
                target:TakeDamage(damage * 1.5, 0, EntityRef(entity), 0)
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Luminous_Drill_Damage_Enemy, TBoN.Magic.Info.Variant.Luminous_Drill)

-- 破坏障碍物逻辑（和黑洞一样，能挖掘任何材料）
function TBoN_MOD:Luminous_Drill_Destroy_Material(entity)
    local destroy_radius = 20  -- 破坏半径
    for idx = 0, Game():GetRoom():GetGridSize() - 1 do
        local grid_entity = Game():GetRoom():GetGridEntity(idx)
        if grid_entity then
            local grid_pos = Game():GetRoom():GetGridPosition(idx)
            if TBoN.Magic.Function.Custom.Check_Pos(entity.Position, grid_pos, destroy_radius) then
                grid_entity:Destroy()
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Luminous_Drill_Destroy_Material, TBoN.Magic.Info.Variant.Luminous_Drill)

-- 消失逻辑（短射程）
function TBoN_MOD:Luminous_Drill_Disappear(entity)
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
        return
    end
    
    if entity.Timeout <= 0 then
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Luminous_Drill_Disappear, TBoN.Magic.Info.Variant.Luminous_Drill)
