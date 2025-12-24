-- PINGPONG_PATH 修饰法术
-- 乒乓回弹（又名乒乓路径、乒乓轨迹）
-- 使投射物在空中一定范围内折返运动，像乒乓球一样来回弹跳
-- 折返的次数取决于投射物的速度和持续时间
function TBoN_MOD:PingPong_Path(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_pingpong = false
        
        -- 检查是否有 PINGPONG_PATH 修饰符
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "PINGPONG_PATH" then
                has_pingpong = true
                break
            end
        end
        
        if has_pingpong then
            -- 初始化乒乓数据
            if not entity_data.pingpong_data then
                entity_data.pingpong_data = {
                    center = entity.Position:__add(Vector(0, 0)), -- 记录初始施放位置（折返中心点）
                    initial_velocity = entity.Velocity:__add(Vector(0, 0)), -- 记录初始速度
                    initial_speed = entity.Velocity:Length(), -- 记录初始速度大小
                    direction = 1, -- 当前方向：1为正向，-1为反向
                    travel_distance = 0, -- 累计移动距离
                    base_range = 150, -- 基础折返范围
                }
            end
            
            local pingpong_data = entity_data.pingpong_data
            
            -- 根据速度动态调整折返范围
            -- 速度越快，折返范围越大
            local speed_factor = pingpong_data.initial_speed / 10
            local pingpong_range = pingpong_data.base_range + speed_factor * 10
            
            -- 计算相对于中心点的位置
            local relative_pos = entity.Position - pingpong_data.center
            local distance_from_center = relative_pos:Length()
            
            -- 计算投射物的移动方向（基于初始速度方向）
            local move_direction = pingpong_data.initial_velocity:Normalized()
            
            -- 检查是否需要折返
            -- 当投射物距离中心点超过折返范围时，反转方向
            if distance_from_center >= pingpong_range then
                -- 反转方向
                pingpong_data.direction = -pingpong_data.direction
                
                -- 重新设置中心点为当前位置，实现连续折返
                pingpong_data.center = entity.Position:__add(Vector(0, 0))
            end
            
            -- 应用乒乓运动
            -- 投射物沿着初始方向来回移动
            local current_velocity = move_direction * pingpong_data.initial_speed * pingpong_data.direction
            
            -- 平滑过渡：使用插值使方向改变更自然
            local transition_speed = 0.15 -- 过渡速度，值越小越平滑
            entity.Velocity = entity.Velocity * (1 - transition_speed) + current_velocity * transition_speed
            
            -- 记录移动距离（用于调试或其他逻辑）
            pingpong_data.travel_distance = pingpong_data.travel_distance + entity.Velocity:Length()
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.PingPong_Path)
