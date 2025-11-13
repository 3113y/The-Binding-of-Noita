--伤害逻辑
function TBoN_MOD:Light_Bullet_Damage(entity)
    local entities = Isaac.FindInRadius(entity.Position, 10, EntityPartition.ENEMY)
    if #entities > 0 then
        print("[LIGHT_BULLET] 碰到敌人，造成伤害")
        entities[1]:TakeDamage(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash), 0, EntityRef(entity), 0)
        
        -- 检查是否是触发法术
        local entity_hash = GetPtrHash(entity)
        local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
        if trigger_data then
            print("[LIGHT_BULLET] 检测到触发数据，调用碰撞检测")
            TBoN_MOD:TriggerSystem_Collision_Check(entity, entities[1])
        else
            print("[LIGHT_BULLET] 无触发数据，直接移除")
            entity:Remove()
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Light_Bullet_Damage, 800)
--消失逻辑
function TBoN_MOD:Light_Bullet_Disappear(entity)
    if entity.Position.X < -80 or entity.Position.X > 800 or entity.Position.Y < 0 or entity.Position.Y > 600 then
        entity:Kill()
    end
    if entity.Timeout <= 0 then
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Light_Bullet_Disappear, 800)
