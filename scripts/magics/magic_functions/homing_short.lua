function TBoN_MOD:Homing_Short(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_homing = false
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "HOMING" then
                has_homing = true
                break
            end
        end
        if has_homing then
            -- 搜索附近的敌人
            local enemies = Isaac.FindInRadius(entity.Position, 70, EntityPartition.ENEMY)
            if #enemies > 0 and entity[1].Type ~= 33 then
                local target = enemies[1]
                local to_target = (target.Position - entity.Position):Normalized()
                local homing_strength = 1 -- 施加的力大小，可调整
                -- 直接给速度加上一个朝向目标的分量
                entity.Velocity = entity.Velocity + to_target * homing_strength
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Homing_Short)