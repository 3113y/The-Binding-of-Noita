function TBoN_MOD:Homing_Cursor(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_homing_cursor = false
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "HOMING_CURSOR" then
                has_homing_cursor = true
                break
            end
        end
        if has_homing_cursor then
            local aim_dir = TBoN.Gun.Function.Vector.Aim_direc:Normalized()
            local speed = entity.Velocity:Length()
            if speed > 0.1 then
                entity.Velocity = aim_dir * speed
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Homing_Cursor)