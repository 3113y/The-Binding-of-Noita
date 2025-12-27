-- HORIZONTAL_ARC 修饰法术
-- 使任何投射物在一段时间内水平移动，但增加其伤害

function TBoN_MOD:Horizontal_Arc(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_horizontal_arc = false
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "HORIZONTAL_ARC" then
                has_horizontal_arc = true
                break
            end
        end
        if has_horizontal_arc then
            if not entity_data.horizontal_arc_data then
                entity_data.horizontal_arc_data = {
                    start_frame = Game():GetFrameCount(),
                    duration = 60, -- 水平移动持续60帧（1秒）
                    initial_velocity = entity.Velocity:Length()
                }
            end
            local arc_data = entity_data.horizontal_arc_data
            local current_frame = Game():GetFrameCount()
            local elapsed_frames = current_frame - arc_data.start_frame
            if elapsed_frames < arc_data.duration then
                local aim_direc = TBoN.Gun.Function.Vector.Aim_direc
                local horizontal_direction
                if aim_direc.X > 0 then
                    horizontal_direction = Vector(1, 0) -- 向右
                else
                    horizontal_direction = Vector(-1, 0) -- 向左
                end
                entity.Velocity = horizontal_direction * arc_data.initial_velocity
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Horizontal_Arc)
