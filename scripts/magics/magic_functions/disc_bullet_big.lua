-- DISC_BULLET_BIG 投射物逻辑
-- 巨型锯片 - 回力镖式的巨大旋转锯，会飞回施法位置
-- 靠近敌人持续造成伤害，直接击中会失效

-- 初始化巨型锯片数据
function TBoN_MOD:Disc_Bullet_Big_Init(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    if not entity_data.disc_big_data then
        entity_data.disc_big_data = {
            spawn_position = entity.Position:__add(Vector(0, 0)), -- 记录施放位置
            is_returning = false, -- 是否正在返回
            max_distance = 250, -- 最大飞行距离
            travel_distance = 0, -- 已飞行距离
            is_dead = false, -- 是否失效
            last_damage_frame = 0, -- 上次造成伤害的帧
            damaged_entities = {}, -- 已经直接命中的实体列表
        }
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, TBoN_MOD.Disc_Bullet_Big_Init, 805)

-- 伤害逻辑 - 支持持续伤害和直接命中
function TBoN_MOD:Disc_Bullet_Big_Damage(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    TBoN_MOD:Disc_Bullet_Big_Init(entity)
    
    local disc_data = entity_data.disc_big_data
    if disc_data.is_dead then
        return
    end
    
    -- 搜索附近的所有实体（包括玩家、敌人等）
    local all_entities = {}
    local enemies = Isaac.FindInRadius(entity.Position, 30, EntityPartition.ENEMY)
    for _, enemy in ipairs(enemies) do
        table.insert(all_entities, enemy)
    end
    local players = Isaac.FindInRadius(entity.Position, 30, EntityPartition.PLAYER)
    for _, player in ipairs(players) do
        table.insert(all_entities, player)
    end
    local familiars = Isaac.FindInRadius(entity.Position, 30, EntityPartition.FAMILIAR)
    for _, familiar in ipairs(familiars) do
        table.insert(all_entities, familiar)
    end
    
    local current_frame = Game():GetFrameCount()
    local damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
    
    for _, target in ipairs(all_entities) do
        local distance = (target.Position - entity.Position):Length()
        
        -- 直接命中（15像素内）
        if distance <= 15 then
            local target_hash = GetPtrHash(target)
            if not disc_data.damaged_entities[target_hash] then
                -- 造成完整伤害并标记为已命中
                target:TakeDamage(damage, 0, EntityRef(entity), 0)
                disc_data.damaged_entities[target_hash] = true
                
                -- 检查触发系统
                local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
                if trigger_data then
                    TBoN_MOD:TriggerSystem_Entity_Collision_Check(entity, target)
                end
                
                -- 直接击中后失效
                disc_data.is_dead = true
                entity.Velocity = entity.Velocity * 0.1
                entity:Remove()
                return
            end
        -- 靠近但未直接命中（15-30像素内）- 持续伤害
        elseif distance <= 30 then
            -- 每隔几帧造成一次持续伤害（移动越慢伤害频率越高）
            local speed = entity.Velocity:Length()
            local damage_interval = math.max(3, math.floor(speed / 2)) -- 速度慢时伤害间隔短
            
            if current_frame - disc_data.last_damage_frame >= damage_interval then
                -- 造成持续伤害（较低）
                target:TakeDamage(damage * 0.3, 0, EntityRef(entity), 0)
                disc_data.last_damage_frame = current_frame
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Disc_Bullet_Big_Damage, 805)

-- 飞行和返回逻辑
function TBoN_MOD:Disc_Bullet_Big_Disappear(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    TBoN_MOD:Disc_Bullet_Big_Init(entity)
    
    local disc_data = entity_data.disc_big_data
    
    -- 如果已失效，快速移除
    if disc_data.is_dead then
        entity:Remove()
        return
    end
    
    -- 边界检测和墙壁限制
    local wall_left = 40
    local wall_right = 600
    local wall_top = 120
    local wall_bottom = 440
    
    -- 强制限制在墙壁范围内
    if entity.Position.X < wall_left then
        entity.Position = Vector(wall_left + 5, entity.Position.Y)
        entity.Velocity = Vector(math.abs(entity.Velocity.X) * 0.7, entity.Velocity.Y)
        disc_data.is_returning = true
    elseif entity.Position.X > wall_right then
        entity.Position = Vector(wall_right - 5, entity.Position.Y)
        entity.Velocity = Vector(-math.abs(entity.Velocity.X) * 0.7, entity.Velocity.Y)
        disc_data.is_returning = true
    end
    
    if entity.Position.Y < wall_top then
        entity.Position = Vector(entity.Position.X, wall_top + 5)
        entity.Velocity = Vector(entity.Velocity.X, math.abs(entity.Velocity.Y) * 0.7)
        disc_data.is_returning = true
    elseif entity.Position.Y > wall_bottom then
        entity.Position = Vector(entity.Position.X, wall_bottom - 5)
        entity.Velocity = Vector(entity.Velocity.X, -math.abs(entity.Velocity.Y) * 0.7)
        disc_data.is_returning = true
    end
    
    -- 超出大边界直接移除
    if entity.Position.X < -80 or entity.Position.X > 800 or entity.Position.Y < 0 or entity.Position.Y > 600 then
        entity:Remove()
        return
    end
    
    -- 计算已飞行距离
    local current_distance = (entity.Position - disc_data.spawn_position):Length()
    disc_data.travel_distance = current_distance
    
    -- 达到最大距离或超时，开始返回
    if current_distance >= disc_data.max_distance or entity.Timeout <= 30 then
        disc_data.is_returning = true
    end
    
    -- 检测障碍物碰撞
    for idx = 0, Game():GetRoom():GetGridSize() - 1 do
        local grid_entity = Game():GetRoom():GetGridEntity(idx)
        if grid_entity and TBoN.Magic.Function.Custom.Can_Col_With_Grid(grid_entity) and TBoN.Magic.Function.Custom.Check_Pos(entity.Position, Game():GetRoom():GetGridPosition(idx), 25) then
            -- 撞到坚固物体，随机方向弹跳
            local random_angle = math.random() * math.pi * 2
            local bounce_direction = Vector(math.cos(random_angle), math.sin(random_angle))
            entity.Velocity = bounce_direction * entity.Velocity:Length() * 0.7
            
            -- 对障碍物造成伤害
            grid_entity:Hurt(math.floor(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash) * 0.5))
            
            -- 触发返回模式
            disc_data.is_returning = true
            
            -- 检查触发系统
            break
        end
    end
    
    -- 回力镖返回逻辑
    if disc_data.is_returning then
        local to_spawn = (disc_data.spawn_position - entity.Position)
        local distance_to_spawn = to_spawn:Length()
        
        -- 已经返回到施放位置附近，失效
        if distance_to_spawn < 20 then
            entity:Remove()
            return
        end
        
        -- 向施放位置飞去
        local return_direction = to_spawn:Normalized()
        local return_speed = math.min(entity.Velocity:Length() + 0.5, 15) -- 逐渐加速返回
        
        -- 使用插值平滑转向
        local current_direction = entity.Velocity:Normalized()
        local blend_factor = 0.1
        local new_direction = (current_direction * (1 - blend_factor) + return_direction * blend_factor):Normalized()
        
        entity.Velocity = new_direction * return_speed
    end
    
    -- 超时失效
    if entity.Timeout <= 0 then
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Disc_Bullet_Big_Disappear, 805)
