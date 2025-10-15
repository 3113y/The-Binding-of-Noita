function TBoN_MOD:Homing_Accelerating(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_homing_accelerating = false
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "HOMING_ACCELERATING" then
                has_homing_accelerating = true
                break
            end
        end
        if has_homing_accelerating then
            -- 搜索附近的敌人
            local enemies = Isaac.FindInRadius(entity.Position, 200, EntityPartition.ENEMY)
            if #enemies > 0 then
                local target = enemies[1]
                local to_target = (target.Position - entity.Position):Normalized()
                local homing_strength = 1 -- 追踪力大小
                local accel_strength = 0.07 -- 加速系数
                -- 追踪分量
                entity.Velocity = entity.Velocity + to_target * homing_strength
                -- 加速分量
                entity.Velocity = entity.Velocity * (1 + accel_strength)
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Homing_Accelerating)