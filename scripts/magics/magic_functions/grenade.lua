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
        }
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
    
    -- 如果已爆炸，不再处理
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
    -- 在effect位置生成炸弹实体
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
    
    -- 如果已爆炸，不再处理
    if grenade_data.has_exploded then
        return
    end
    
    -- 使用动态房间边界检测
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        -- 飞出房间边界，直接爆炸
        local base_damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
        TBoN_MOD:Grenade_Explode(entity, base_damage)
        grenade_data.has_exploded = true
        return
    end
    
    -- 检测是否碰到障碍物（边界反弹会先触发，所以碰到的都是内部障碍物）
    local current_frame = Game():GetFrameCount()
    if current_frame - grenade_data.last_hit_frame < 5 then
        -- 避免连续碰撞检测
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
            -- 正面击中地形，触发爆炸
            local base_damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
            
            -- 对障碍物造成额外伤害
            grid_entity:Hurt(math.floor(base_damage * 0.8))
            
            -- 引爆
            TBoN_MOD:Grenade_Explode(entity, base_damage)
            
            -- 检查触发系统
            local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
            if trigger_data then
                TBoN_MOD:TriggerSystem_Grid_Collision_Check(entity, grid_entity)
            end
            
            grenade_data.has_exploded = true
        else
            -- 侧面或斜向碰撞，进行反弹
            if grenade_data.bounce_count < grenade_data.max_bounces then
                -- 计算反射方向
                local reflection = entity.Velocity - to_grid * (2 * dot * entity.Velocity:Length())
                
                -- 应用反射速度，保持较高的能量（0.8倍速度）
                entity.Velocity = reflection * 0.8
                
                grenade_data.bounce_count = grenade_data.bounce_count + 1
                grenade_data.last_hit_frame = current_frame
                
                -- 对障碍物造成轻微伤害
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
