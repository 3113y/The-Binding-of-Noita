--伤害逻辑
function TBoN_MOD:Light_Bullet_Damage(entity)
    local entities = Isaac.FindInRadius(entity.Position, 10, EntityPartition.ENEMY)
    if #entities > 0 then
        entities[1]:TakeDamage(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash), 0, EntityRef(entity), 0)
        local entity_hash = GetPtrHash(entity)
        local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
        if trigger_data then
            -- 实体碰撞检测
            TBoN_MOD:TriggerSystem_Entity_Collision_Check(entity, entities[1])
        else
            entity:Remove()
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Light_Bullet_Damage, 800)
--消失逻辑
function TBoN_MOD:Light_Bullet_Disappear(entity)
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        entity:Kill()
    end
    
    -- 检测是否碰到障碍物
    local hit_grid = false
    for idx = 0, Game():GetRoom():GetGridSize() - 1 do
        local grid_entity = Game():GetRoom():GetGridEntity(idx)
        if grid_entity and TBoN.Magic.Function.Custom.Can_Col_With_Grid(grid_entity) and TBoN.Magic.Function.Custom.Check_Pos(entity.Position, Game():GetRoom():GetGridPosition(idx), 20) then
            hit_grid = true
            
            -- 检查是否是触发法术
            local entity_hash = GetPtrHash(entity)
            local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
            if trigger_data then
                -- 障碍物碰撞检测
                grid_entity:Hurt(math.floor(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)))
                TBoN_MOD:TriggerSystem_Grid_Collision_Check(entity, grid_entity)
            else
                grid_entity:Hurt(math.floor(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)))
                entity:Remove()
            end
            break
        end
    end
    
    if entity.Timeout <= 0 and not hit_grid then
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Light_Bullet_Disappear, 800)
