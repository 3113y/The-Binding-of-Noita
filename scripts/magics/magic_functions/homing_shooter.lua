function TBoN_MOD:Homing_Shooter(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_homing_shooter = false
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "HOMING_SHOOTER" then
                has_homing_shooter = true
                break
            end
        end
        if has_homing_shooter then
            -- 获取玩家实体
            local player = Isaac.GetPlayer(0) -- 默认主玩家
            if player then
                local to_player = (player.Position - entity.Position):Normalized()
                local shooter_strength = 1 -- 施加的力大小，可调整
                -- 施加恒定力
                entity.Velocity = entity.Velocity + to_player * shooter_strength
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Homing_Shooter)