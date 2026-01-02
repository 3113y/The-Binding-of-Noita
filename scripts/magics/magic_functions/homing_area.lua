-- HOMING_AREA 修正法术
-- 投射物区域传送：如果在投射物附近出现有效目标，投射物会立即传送到目标的上方

function TBoN_MOD:Homing_Area(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_homing_area = false
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "HOMING_AREA" then
                has_homing_area = true
                break
            end
        end
        if has_homing_area then
            local detection_radius = 50  -- 检测半径
            local enemies = Isaac.FindInRadius(entity.Position, detection_radius, EntityPartition.ENEMY)   
            if #enemies > 0 and entity[1].Type ~= 33 then
                local target = enemies[1]
                entity.Position = target.Position + Vector(0, -10)
                local speed = entity.Velocity:Length()
                if speed > 0.1 then
                    local to_target = (target.Position - entity.Position):Normalized()
                    entity.Velocity = to_target * speed
                end
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Homing_Area)
