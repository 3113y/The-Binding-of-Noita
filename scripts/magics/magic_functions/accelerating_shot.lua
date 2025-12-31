function TBoN_MOD:Accelerating_Shot(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_accelerating = false
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "ACCELERATING_SHOT" then
                has_accelerating = true
                break
            end
        end
        if has_accelerating then
            -- 逐渐提升速度
            local acceleration_rate = 1.03  -- 每帧加速到原速度的103%（即每帧增加3%）
            entity.Velocity = entity.Velocity * acceleration_rate
            
            -- 防止速度过高导致投射物过快
            local maxSpeed = 30.0
            if entity.Velocity:Length() > maxSpeed then
                entity.Velocity = entity.Velocity:Normalized() * maxSpeed
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Accelerating_Shot)
