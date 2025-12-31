function TBoN_MOD:Decelerating_Shot(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_decelerating = false
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "DECELERATING_SHOT" then
                has_decelerating = true
                break
            end
        end
        if has_decelerating then
            -- 逐渐降低速度
            local deceleration_rate = 0.97  -- 每帧减速到原速度的97%（即每帧减少3%）
            entity.Velocity = entity.Velocity * deceleration_rate
            
            -- 防止速度过低导致投射物几乎停止
            local minSpeed = 1.0
            if entity.Velocity:Length() < minSpeed then
                entity.Velocity = entity.Velocity:Normalized() * minSpeed
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Decelerating_Shot)
