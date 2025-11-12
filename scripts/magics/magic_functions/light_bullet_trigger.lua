-- 带有碰撞触发的光弹示例
-- 这个法术在碰撞时会触发下一个施法块

-- 初始化时注册触发
function TBoN_MOD:Light_Bullet_Trigger_Init(entity)
    local entity_hash = GetPtrHash(entity)
    local magic_data = TBoN.Magic.Table.magic_hash[entity_hash]
    
    if magic_data then
        -- 检查是否有触发队列数据
        -- trigger_spells 应该在生成时就设置好
        local trigger_spells = magic_data.trigger_spells or {}
        
        if #trigger_spells > 0 then
            -- 注册碰撞触发
            TBoN.Magic.Function.Custom.RegisterTrigger(
                entity,
                TBoN.Magic.Info.TriggerType.COLLISION,
                trigger_spells,
                nil
            )
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, TBoN_MOD.Light_Bullet_Trigger_Init, 800)

-- 伤害逻辑 - 当碰到敌人时触发
function TBoN_MOD:Light_Bullet_Trigger_Damage(entity)
    local entities = Isaac.FindInRadius(entity.Position, 10, EntityPartition.ENEMY)
    if #entities > 0 then
        -- 造成伤害
        entities[1]:TakeDamage(
            TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash),
            0,
            EntityRef(entity),
            0
        )
        
        -- 触发碰撞事件
        TBoN_MOD:TriggerSystem_Collision_Check(entity, entities[1])
        
        -- 移除原弹(如果还没被触发系统移除)
        if entity:Exists() then
            entity:Remove()
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Light_Bullet_Trigger_Damage, 800)

-- 消失逻辑
function TBoN_MOD:Light_Bullet_Trigger_Disappear(entity)
    if entity.Position.X < -80 or entity.Position.X > 800 or entity.Position.Y < 0 or entity.Position.Y > 600 then
        entity:Kill()
    end
    if entity.Timeout <= 0 then
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Light_Bullet_Trigger_Disappear, 800)
