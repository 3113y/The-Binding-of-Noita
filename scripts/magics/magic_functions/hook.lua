-- Hook 投射物逻辑
function TBoN_MOD:Hook(entity)
    -- 检测房间边界
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        entity:Kill()
        return
    end
    
    -- 投射物失效时的处理
    if entity.Timeout <= 0 then
        -- 尝试对范围内的敌人造成伤害
        local entities = Isaac.FindInRadius(entity.Position, 20, EntityPartition.ENEMY)
        if #entities > 0 then
            entities[1]:TakeDamage(
                TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash), 
                0, 
                EntityRef(entity), 
                0
            )
        end
        
        -- 拉动玩家
        if entity.Parent then
            local player = entity.Parent:ToPlayer()
            if player then
                -- 计算投射物相对玩家的方向
                local direction = (entity.Position - player.Position):Normalized()
                
                -- 给予玩家固定速度，将玩家拉向投射物方向
                -- 拉动强度固定为 8，不受任何速度修正影响
                local pull_strength = 8.0
                player.Velocity = player.Velocity + direction * pull_strength
            end
        end
        
        -- 移除投射物
        Isaac.RunCallback(TBoN.Callback.MC_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Hook, TBoN.Magic.Info.Variant.Hook)