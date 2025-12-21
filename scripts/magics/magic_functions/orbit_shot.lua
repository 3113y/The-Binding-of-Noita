-- ORBIT_SHOT 修饰法术
-- 使投射物环绕其施放/触发位置飞行
-- 投射物盘旋的半径与速度有关，通常大概与玩家的宽度相当
-- 投射物环绕的方向由玩家的朝向决定，且会在中途更新，因此可以实时控制投射物

function TBoN_MOD:Orbit_Shot(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_orbit = false
        
        -- 检查是否有 ORBIT_SHOT 修饰符
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "ORBIT_SHOT" then
                has_orbit = true
                break
            end
        end
        
        if has_orbit then
            -- 如果是第一次应用 ORBIT_SHOT，初始化轨道数据
            if not entity_data.orbit_data then
                entity_data.orbit_data = {
                    center = entity.Position:__add(Vector(0, 0)), -- 记录初始施放位置
                    initial_speed = entity.Velocity:Length(), -- 记录初始速度
                }
            end
            
            local orbit_data = entity_data.orbit_data
            
            -- 根据投射物速度计算轨道半径
            -- 半径大约与玩家宽度相当，基础半径约为 20-30 像素
            local base_radius = 25
            local speed_factor = orbit_data.initial_speed / 10 -- 速度影响系数
            local orbit_radius = base_radius + speed_factor * 5
            
            -- 获取投射物相对于环绕中心的位置
            local relative_pos = entity.Position - orbit_data.center
            local distance = relative_pos:Length()
            
            -- 如果距离太小，避免除以零
            if distance < 0.1 then
                distance = 0.1
                relative_pos = Vector(0.1, 0)
            end
            
            -- 计算径向方向（从中心指向投射物）
            local radial_direction = relative_pos:Normalized()
            
            -- 计算切向方向（垂直于径向方向）
            -- 根据玩家朝向决定旋转方向
            local aim_direc = TBoN.Gun.Function.Vector.Aim_direc
            local direction = 1 -- 默认顺时针
            if aim_direc.X < 0 then
                direction = -1 -- 逆时针
            end
            
            -- 切向量：将径向量旋转90度
            local tangent_direction = Vector(-radial_direction.Y * direction, radial_direction.X * direction)
            
            -- 计算向心力（使投射物保持在轨道上）
            local centripetal_force = -radial_direction * (distance - orbit_radius) * 0.5
            
            -- 计算切向速度（使投射物沿圆周运动）
            local tangent_speed = orbit_data.initial_speed
            local tangent_velocity = tangent_direction * tangent_speed
            
            -- 更新速度：切向速度 + 向心力
            entity.Velocity = tangent_velocity + centripetal_force
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Orbit_Shot)
