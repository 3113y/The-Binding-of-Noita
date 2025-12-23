-- LINE_ARC 修饰法术
-- 使受影响的投射物沿十字线（竖直和水平）或对角线（45°角）方向运动，并增加其伤害

function TBoN_MOD:Line_Arc(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_line_arc = false
        
        -- 检查是否有 LINE_ARC 修饰符
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "LINE_ARC" then
                has_line_arc = true
                break
            end
        end
        
        if has_line_arc then
            -- 如果是第一次应用 LINE_ARC，初始化数据
            if not entity_data.line_arc_data then
                local initial_velocity = entity.Velocity
                local initial_speed = initial_velocity:Length()
                
                -- 归一化速度向量
                local vx = initial_velocity.X
                local vy = initial_velocity.Y
                
                -- 定义8个可能的方向向量（右、右下、下、左下、左、左上、上、右上）
                local direction_vectors = {
                    Vector(1, 0),     -- 右 (0°)
                    Vector(0.707, 0.707),   -- 右下 (45°)
                    Vector(0, 1),     -- 下 (90°)
                    Vector(-0.707, 0.707),  -- 左下 (135°)
                    Vector(-1, 0),    -- 左 (180°)
                    Vector(-0.707, -0.707), -- 左上 (225°)
                    Vector(0, -1),    -- 上 (270°)
                    Vector(0.707, -0.707)   -- 右上 (315°)
                }
                
                -- 找到与当前速度方向最接近的方向向量
                local best_direction = direction_vectors[1]
                local max_dot = vx * best_direction.X + vy * best_direction.Y
                
                for _, dir_vec in ipairs(direction_vectors) do
                    local dot_product = vx * dir_vec.X + vy * dir_vec.Y
                    if dot_product > max_dot then
                        max_dot = dot_product
                        best_direction = dir_vec
                    end
                end
                
                entity_data.line_arc_data = {
                    direction = best_direction,
                    speed = initial_speed
                }
            end
            
            local arc_data = entity_data.line_arc_data
            
            -- 强制投射物沿着固定方向移动
            entity.Velocity = arc_data.direction * arc_data.speed
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Line_Arc)
