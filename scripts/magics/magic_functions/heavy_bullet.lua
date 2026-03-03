--伤害逻辑
function TBoN_MOD:Heavy_Bullet_Damage(entity)
    local entities = Isaac.FindInRadius(entity.Position, 10, EntityPartition.ENEMY)
    if #entities > 0 then
        entities[1]:TakeDamage(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash), 0,
            EntityRef(entity), 0)
        
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Heavy_Bullet_Damage, TBoN.Magic.Table.Info.Variant.Heavy_Bullet)
--消失逻辑
function TBoN_MOD:Heavy_Bullet_Disappear(entity)
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        entity:Kill()
    end
    
    -- 检测是否碰到障碍物
    local hit_grid = false
    for idx = 0, Game():GetRoom():GetGridSize() - 1 do
        local grid_entity = Game():GetRoom():GetGridEntity(idx)
        if grid_entity and TBoN.Magic.Function.Custom.Can_Col_With_Grid(grid_entity) and TBoN.Magic.Function.Custom.Check_Pos(entity.Position, Game():GetRoom():GetGridPosition(idx), 20) then
            hit_grid = true
            
            grid_entity:Hurt(math.floor(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)))
            Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
            entity:Remove()
            break
        end
    end
    if entity.Timeout <= 0 and not hit_grid then
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Heavy_Bullet_Disappear, TBoN.Magic.Table.Info.Variant.Heavy_Bullet)