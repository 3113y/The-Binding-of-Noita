-- CHAOTIC_ARC 修饰法术
-- 混乱弧线
-- 使投射物以一种无法预测的路径飞行
-- 尽管描述中说投射物会飞向任何地方，但仍有一些逻辑
-- 投射物一般会以锥形散开，特别是在高速的法术中
function TBoN_MOD:Chaotic_Arc(entity)
    local entity_hash = GetPtrHash(entity)
    if TBoN.Magic.Table.magic_hash[entity_hash] then
        local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
        local has_chaotic_arc = false
        
        -- 检查是否有 CHAOTIC_ARC 修饰符
        for _, modifier in ipairs(entity_data.modifiers) do
            if modifier == "CHAOTIC_ARC" then
                has_chaotic_arc = true
                break
            end
        end
        
        if has_chaotic_arc then
            -- 初始化混乱弧线数据
            if not entity_data.chaotic_data then
                -- 使用游戏帧数和实体哈希值作为随机种子，确保每个投射物的路径不同
                local seed = Game():GetFrameCount() + entity_hash
                entity_data.chaotic_data = {
                    initial_velocity = entity.Velocity:__add(Vector(0, 0)), -- 记录初始速度
                    initial_speed = entity.Velocity:Length(), -- 记录初始速度大小
                    initial_direction = entity.Velocity:Normalized(), -- 记录初始方向
                    seed = seed, -- 随机种子
                    time = 0, -- 经过的时间（帧数）
                    phase_offset_x = (seed % 100) / 100.0 * math.pi * 2, -- X轴相位偏移
                    phase_offset_y = ((seed * 17) % 100) / 100.0 * math.pi * 2, -- Y轴相位偏移
                    frequency_x = 0.15 + ((seed * 23) % 50) / 500.0, -- X轴频率（增加随机性）
                    frequency_y = 0.12 + ((seed * 31) % 50) / 500.0, -- Y轴频率（增加随机性）
                    amplitude_multiplier = 1.0, -- 振幅倍增器
                }
            end
            
            local chaotic_data = entity_data.chaotic_data
            chaotic_data.time = chaotic_data.time + 1
            
            -- 根据速度调整振幅和频率
            -- 速度越快，振幅越大，形成更明显的锥形散开效果
            local speed_factor = chaotic_data.initial_speed / 10
            local base_amplitude = 8.0
            local amplitude = base_amplitude * (1.0 + speed_factor * 0.3)
            
            -- 随时间增加振幅，让投射物逐渐散开形成锥形
            local time_factor = math.min(chaotic_data.time / 60.0, 2.0) -- 限制最大倍增
            amplitude = amplitude * (1.0 + time_factor * 0.5)
            
            -- 使用多个正弦波叠加创建混乱效果
            -- 主波 - 基础运动
            local main_wave_x = math.sin(chaotic_data.time * chaotic_data.frequency_x + chaotic_data.phase_offset_x) * amplitude
            local main_wave_y = math.cos(chaotic_data.time * chaotic_data.frequency_y + chaotic_data.phase_offset_y) * amplitude
            
            -- 次波 - 增加复杂性（更高频率，更小振幅）
            local secondary_freq_x = chaotic_data.frequency_x * 2.3
            local secondary_freq_y = chaotic_data.frequency_y * 2.7
            local secondary_amplitude = amplitude * 0.4
            local secondary_wave_x = math.sin(chaotic_data.time * secondary_freq_x - chaotic_data.phase_offset_x * 0.7) * secondary_amplitude
            local secondary_wave_y = math.cos(chaotic_data.time * secondary_freq_y + chaotic_data.phase_offset_y * 1.3) * secondary_amplitude
            
            -- 微波 - 增加更多不规则性（最高频率，最小振幅）
            local micro_freq_x = chaotic_data.frequency_x * 4.1
            local micro_freq_y = chaotic_data.frequency_y * 3.9
            local micro_amplitude = amplitude * 0.15
            local micro_wave_x = math.sin(chaotic_data.time * micro_freq_x + chaotic_data.phase_offset_x * 1.5) * micro_amplitude
            local micro_wave_y = math.cos(chaotic_data.time * micro_freq_y - chaotic_data.phase_offset_y * 0.9) * micro_amplitude
            
            -- 叠加所有波形
            local total_offset_x = main_wave_x + secondary_wave_x + micro_wave_x
            local total_offset_y = main_wave_y + secondary_wave_y + micro_wave_y
            
            -- 计算垂直于初始方向的向量（用于横向偏移）
            local perpendicular = Vector(-chaotic_data.initial_direction.Y, chaotic_data.initial_direction.X)
            
            -- 计算新的速度方向
            -- 保持基本的前进方向，同时添加混乱的偏移
            local base_velocity = chaotic_data.initial_direction * chaotic_data.initial_speed
            
            -- 横向偏移（相对于初始方向）
            local lateral_offset = perpendicular * total_offset_x
            
            -- 纵向偏移（沿初始方向的垂直方向）
            local vertical_offset = Vector(0, total_offset_y)
            
            -- 组合所有分量
            local target_velocity = base_velocity + lateral_offset + vertical_offset
            
            -- 平滑过渡到新速度，避免突然的方向变化
            local transition_speed = 0.2
            entity.Velocity = entity.Velocity * (1 - transition_speed) + target_velocity * transition_speed
            
            -- 确保速度不会太低或太高
            local current_speed = entity.Velocity:Length()
            if current_speed < chaotic_data.initial_speed * 0.5 then
                entity.Velocity = entity.Velocity:Normalized() * (chaotic_data.initial_speed * 0.5)
            elseif current_speed > chaotic_data.initial_speed * 1.5 then
                entity.Velocity = entity.Velocity:Normalized() * (chaotic_data.initial_speed * 1.5)
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Chaotic_Arc)
