-- GRENADE 投射物逻辑
-- 手榴弹 - 能够反弹的爆炸性火球，正面击中敌人或地形时立即引爆
-- 比起需要延时引爆的炸弹，更接近Noita中的手榴弹

-- 初始化手榴弹数据
function TBoN_MOD:Grenade_Init(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    if not entity_data.grenade_data then
        entity_data.grenade_data = {
            bounce_count = 0, -- 弹跳次数
            max_bounces = 3, -- 最大弹跳次数
            last_hit_frame = 0, -- 上次碰撞的帧数
            has_exploded = false, -- 是否已爆炸
            snake_phase = 0, -- 蛇行运动相位（用于GRENADE_ANTI）
            initial_speed = 0, -- 初始速度（用于GRENADE_ANTI）
        }
        -- 记录初始速度
        entity_data.grenade_data.initial_speed = entity.Velocity:Length()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, TBoN_MOD.Grenade_Init, TBoN.Magic.Info.Variant.Grenade)

-- 碰撞伤害和爆炸逻辑
function TBoN_MOD:Grenade_Damage(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    TBoN_MOD:Grenade_Init(entity)
    if entity_data.grenade_data.has_exploded then
        return
    end
    -- 搜索附近的敌人
    local entities = Isaac.FindInRadius(entity.Position, 10, EntityPartition.ENEMY)
    if #entities > 0 then
        -- 正面击中敌人，触发爆炸
        local base_damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
        -- 引爆：对周围区域造成爆炸伤害
        TBoN_MOD:Grenade_Explode(entity, base_damage)
        -- 检查是否是触发法术
        local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
        if trigger_data then
            TBoN_MOD:TriggerSystem_Entity_Collision_Check(entity, entities[1])
        end
        entity_data.grenade_data.has_exploded = true
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Grenade_Damage, TBoN.Magic.Info.Variant.Grenade)

-- 爆炸函数 - 生成炸弹并立即引爆
function TBoN_MOD:Grenade_Explode(entity, base_damage)
    local bomb = Isaac.Spawn(TBoN.Magic.Info.Type.Grenade_b, TBoN.Magic.Info.Variant.Grenade_b, entity.SubType, entity.Position, Vector.Zero, entity):ToBomb()
    if bomb then
        bomb.ExplosionDamage = base_damage * 1.5
        bomb.RadiusMultiplier = 0.6*entity.SubType +0.8
        bomb:SetExplosionCountdown(0)
    end
    entity:Remove()
end

-- 反弹和消失逻辑
function TBoN_MOD:Grenade_Disappear(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    TBoN_MOD:Grenade_Init(entity)
    local grenade_data = entity_data.grenade_data
    if grenade_data.has_exploded then
        return
    end
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        local base_damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
        TBoN_MOD:Grenade_Explode(entity, base_damage)
        grenade_data.has_exploded = true
        return
    end
    local current_frame = Game():GetFrameCount()
    if current_frame - grenade_data.last_hit_frame < 5 then
        return
    end
    local grid_entity, grid_pos = TBoN.Room.Function.Custom.Check_Grid_Collision(entity.Position, 20)
    if grid_entity and grid_pos then
        -- 检查是否是正面碰撞（朝向障碍物方向移动）
        local to_grid = (grid_pos - entity.Position):Normalized()
        local velocity_normalized = entity.Velocity:Normalized()
        local dot = velocity_normalized:Dot(to_grid)
        -- 正面碰撞（dot > 0.3表示较为直接的碰撞）
        if dot > 0.3 then
            local base_damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
            grid_entity:Hurt(math.floor(base_damage * 0.8))
            TBoN_MOD:Grenade_Explode(entity, base_damage)
            local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
            if trigger_data then
                TBoN_MOD:TriggerSystem_Grid_Collision_Check(entity, grid_entity)
            end
            grenade_data.has_exploded = true
        else
            -- 侧面或斜向碰撞，进行反弹
            if grenade_data.bounce_count < grenade_data.max_bounces then
                local reflection = entity.Velocity - to_grid * (2 * dot * entity.Velocity:Length())
                entity.Velocity = reflection * 0.8
                grenade_data.bounce_count = grenade_data.bounce_count + 1
                grenade_data.last_hit_frame = current_frame
                grid_entity:Hurt(math.floor(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash) * 0.3))
            else
                -- 达到最大弹跳次数，触发爆炸
                local base_damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
                TBoN_MOD:Grenade_Explode(entity, base_damage)
                grenade_data.has_exploded = true
            end
        end
    end
    -- 超时检测 - 超时后爆炸
    if entity.Timeout <= 0 then
        local base_damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
        TBoN_MOD:Grenade_Explode(entity, base_damage)
        grenade_data.has_exploded = true
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Grenade_Disappear, TBoN.Magic.Info.Variant.Grenade)

-- GRENADE_ANTI特殊运动逻辑 (subtype 3)
function TBoN_MOD:Grenade_Anti_Movement(entity)
    -- 只处理subtype 3的怪异火焰弹
    if entity.SubType ~= 3 then
        return
    end
    
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    TBoN_MOD:Grenade_Init(entity)
    local grenade_data = entity_data.grenade_data
    
    -- 如果已爆炸，不再处理
    if grenade_data.has_exploded then
        return
    end
    
    local current_speed = entity.Velocity:Length()
    
    -- 只在减速时才应用蛇行运动（速度低于初始速度的70%）
    if current_speed < grenade_data.initial_speed * 0.7 and current_speed > 1 then
        -- 增加蛇行相位
        grenade_data.snake_phase = grenade_data.snake_phase + 0.15
        
        -- 获取玩家位置
        local player = Isaac.GetPlayer(0)
        if player then
            local to_player = player.Position - entity.Position
            
            -- 计算垂直于当前速度方向的向量（用于蛇行）
            local velocity_normalized = entity.Velocity:Normalized()
            local perpendicular = Vector(-velocity_normalized.Y, velocity_normalized.X)
            
            -- 蛇行运动：正弦波摆动
            local snake_amplitude = 3.0 -- 蛇行幅度
            local snake_offset = perpendicular * (math.sin(grenade_data.snake_phase) * snake_amplitude)
            
            -- 尝试向玩家的水平位置靠拢
            local horizontal_correction = Vector(0, 0)
            local y_diff = to_player.Y
            
            if math.abs(y_diff) > 20 then -- 只在Y轴距离较大时才修正
                -- 根据Y轴差值计算修正力度
                local correction_strength = 0.5
                horizontal_correction = Vector(0, y_diff > 0 and correction_strength or -correction_strength)
            end
            
            -- 应用蛇行运动和水平修正
            entity.Velocity = entity.Velocity + snake_offset + horizontal_correction
            
            -- 保持速度在合理范围内
            local new_speed = entity.Velocity:Length()
            if new_speed > current_speed * 1.2 then
                entity.Velocity = entity.Velocity:Normalized() * (current_speed * 1.1)
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Grenade_Anti_Movement, TBoN.Magic.Info.Variant.Grenade)
