-- CHAINSAW 投射物逻辑

-- 对敌人造成伤害逻辑
function TBoN_MOD:Chainsaw_Damage_Enemy(entity)
    local damage_radius = 15  -- 伤害半径
    
    -- 获取房间内所有敌人
    local entities = Isaac.GetRoomEntities()
    for _, target in ipairs(entities) do
        if target:IsVulnerableEnemy() and target:IsActiveEnemy(false) then
            -- 检查是否在伤害范围内
            if TBoN.Magic.Function.Custom.Check_Pos(entity.Position, target.Position, damage_radius) then
                local damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity)
                target:TakeDamage(damage, 0, EntityRef(entity), 0)
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Chainsaw_Damage_Enemy, TBoN.Magic.Info.Variant.Chainsaw)

-- 破坏障碍物逻辑
function TBoN_MOD:Chainsaw_Destroy_Material(entity)
    local destroy_radius = 15  -- 破坏半径
    for idx = 0, Game():GetRoom():GetGridSize() - 1 do
        local grid_entity = Game():GetRoom():GetGridEntity(idx)
        if grid_entity then
            local grid_pos = Game():GetRoom():GetGridPosition(idx)
            -- 检查是否在破坏范围内
            if TBoN.Magic.Function.Custom.Check_Pos(entity.Position, grid_pos, destroy_radius) then
                grid_entity:Hurt(math.floor(TBoN.Magic.Function.Custom.Damage_Calculate(entity)))
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Chainsaw_Destroy_Material, TBoN.Magic.Info.Variant.Chainsaw)

-- 消失逻辑
function TBoN_MOD:Chainsaw_Disappear(entity)
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        entity:Kill()
    end
    
    if entity.Timeout <= 0 then
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Chainsaw_Disappear, TBoN.Magic.Info.Variant.Chainsaw)
