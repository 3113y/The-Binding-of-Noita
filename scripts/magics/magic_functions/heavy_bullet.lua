--伤害逻辑
function TBoN_MOD:Heavy_Bullet_Damage(entity)
    local entities = Isaac.FindInRadius(entity.Position, 10, EntityPartition.ENEMY)
    if #entities > 0 then
        entities[1]:TakeDamage(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash), 0,
            EntityRef(entity), 0)
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Heavy_Bullet_Damage, 801)
--消失逻辑
function TBoN_MOD:Heavy_Bullet_Disappear(entity)
    if entity.Position.X < -80 or entity.Position.X > 800 or entity.Position.Y < 0 or entity.Position.Y > 600 then
        entity:Kill()
    end
    if entity.Timeout <= 0 then
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Heavy_Bullet_Disappear, 801)
