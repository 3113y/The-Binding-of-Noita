function TBoN_MOD:Homing_Rotate(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_homing_rotate = false
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "HOMING_ROTATE" then
                has_homing_rotate = true
                break
            end
        end
        if has_homing_rotate then
            -- 搜索附近的敌人
            local enemies = Isaac.FindInRadius(entity.Position, 200, EntityPartition.ENEMY)
            if #enemies > 0 then
                local target = enemies[1] -- 选择第一个敌人作为目标
                local current_velocity = entity.Velocity
                
                -- 计算到目标的方向向量
                local to_target = target.Position - entity.Position
                to_target = to_target:Normalized()
                
                -- 计算当前速度的方向
                local current_direction = current_velocity:Normalized()
                local speed = current_velocity:Length()
                
                if speed > 0.1 then -- 避免除零错误
                    -- 计算垂直于当前速度方向的向量
                    local perpendicular = Vector(-current_direction.Y, current_direction.X)
                    
                    -- 计算从当前方向到目标方向的转向
                    -- 使用叉积来确定转向方向
                    local cross_product = current_direction.X * to_target.Y - current_direction.Y * to_target.X
                    
                    -- 根据叉积的符号决定转向方向
                    local turn_direction = cross_product > 0 and 1 or -1
                    
                    -- 应用垂直于速度的修正力
                    local correction_strength = 1  -- 修正力强度，可以调整
                    local correction_velocity = perpendicular * correction_strength * turn_direction
                    
                    -- 应用修正速度
                    entity.Velocity = entity.Velocity + correction_velocity
                    
                    -- 限制最大速度，保持原有的速度大小
                    local new_speed = entity.Velocity:Length()
                    if new_speed > speed * 1.2 then -- 允许速度略微增加
                        entity.Velocity = entity.Velocity:Normalized() * speed * 1.2
                    end
                end
            end
        end
    end
end
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Homing_Rotate)
