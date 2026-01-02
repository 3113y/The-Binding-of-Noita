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
            is_grounded = false, -- 是否已落地
            last_damage_frame = 0, -- 上次造成伤害的帧
            damaged_entities = {}, -- 已经直接命中的实体列表
        }
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, TBoN_MOD.Disc_Bullet_Big_Init, TBoN.Magic.Info.Variant.Disc_Bullet_Big)

-- 伤害逻辑 - 支持持续伤害和直接命中
function TBoN_MOD:Disc_Bullet_Big_Damage(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    TBoN_MOD:Disc_Bullet_Big_Init(entity)
    
    local disc_data = entity_data.disc_big_data
    -- 如果已落地，不造成伤害
    if disc_data.is_grounded then
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
                
                -- 直接击中后落地
                disc_data.is_grounded = true
                entity.Velocity = entity.Velocity * 0.3
                -- 播放落地动画（如果有的话）
                if entity:GetSprite():IsPlaying("RegularTear6") then
                    entity:GetSprite():Play("OnGround", true)
                end
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

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Disc_Bullet_Big_Damage, TBoN.Magic.Info.Variant.Disc_Bullet_Big)

-- 飞行和返回逻辑
function TBoN_MOD:Disc_Bullet_Big_Disappear(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    TBoN_MOD:Disc_Bullet_Big_Init(entity)
    
    local disc_data = entity_data.disc_big_data
    
    -- 如果已落地，继续减速直到停止
    if disc_data.is_grounded then
        entity.Velocity = entity.Velocity * 0.9
        if entity.Velocity:Length() < 0.5 then
            entity.Velocity = Vector(0, 0)
        end
        -- 落地后一段时间消失
        if entity.FrameCount > entity.Timeout + 60 then
            entity:Remove()
        end
        return
    end
    
    -- 检查房间墙壁碰撞并反弹
    local wall_collision = TBoN.Room.Function.Custom.Col_With_Room_Wall(entity.Position)
    if wall_collision then
        -- 碰到墙壁时触发返回
        disc_data.is_returning = true
        
        -- 根据墙壁位置计算正确的法线方向
        local shape_data = TBoN.Room.Variable.Current_Room_Shape
        local root_pos = shape_data.Root_Pos
        local size = shape_data.Shape.Size
        local pos = entity.Position
        local wall_normal = Vector(0, 0)
        
        -- 检测哪个边界被碰撞并设置对应的法线方向
        local dist_to_left = pos.X - root_pos.X
        local dist_to_right = (root_pos.X + size.X) - pos.X
        local dist_to_top = pos.Y - root_pos.Y
        local dist_to_bottom = (root_pos.Y + size.Y) - pos.Y
        
        local min_dist = math.min(dist_to_left, dist_to_right, dist_to_top, dist_to_bottom)
        
        if min_dist == dist_to_left then
            wall_normal = Vector(1, 0)  -- 左墙，法线向右
        elseif min_dist == dist_to_right then
            wall_normal = Vector(-1, 0)  -- 右墙，法线向左
        elseif min_dist == dist_to_top then
            wall_normal = Vector(0, 1)  -- 上墙，法线向下
        else
            wall_normal = Vector(0, -1)  -- 下墙，法线向上
        end
        
        -- 计算反射速度
        local velocity_normalized = entity.Velocity:Normalized()
        local dot = velocity_normalized:Dot(wall_normal)
        
        if dot < 0 then  -- 只在朝向墙壁时反弹
            local reflection = velocity_normalized - wall_normal * (2 * dot)
            entity.Velocity = reflection * entity.Velocity:Length() * 0.7
        end
    end
    
    -- 检查是否真的超出房间范围（墙外20px）
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
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
    
    -- 检测与障碍物的碰撞（边界反弹会先触发，所以碰到的都是内部障碍物）
    local grid_entity, grid_pos = TBoN.Room.Function.Custom.Check_Grid_Collision(entity.Position, 25)
    if grid_entity and grid_pos then
        -- 撞到内部坚固物体，随机方向弹跳
        local random_angle = math.random() * math.pi * 2
        local bounce_direction = Vector(math.cos(random_angle), math.sin(random_angle))
        entity.Velocity = bounce_direction * entity.Velocity:Length() * 0.7
        
        -- 对障碍物造成伤害
        grid_entity:Hurt(math.floor(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash) * 0.5))
        
        -- 触发返回模式
        disc_data.is_returning = true
        
        -- 检查触发系统
    end
    
    -- 回力镖返回逻辑
    if disc_data.is_returning then
        local to_spawn = (disc_data.spawn_position - entity.Position)
        local distance_to_spawn = to_spawn:Length()
        
        -- 已经返回到施放位置附近，落地
        if distance_to_spawn < 20 then
            disc_data.is_grounded = true
            entity.Velocity = entity.Velocity * 0.3
            -- 播放落地动画（如果有的话）
            if entity:GetSprite():IsPlaying("RegularTear6") then
                entity:GetSprite():Play("OnGround", true)
            end
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

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Disc_Bullet_Big_Disappear, TBoN.Magic.Info.Variant.Disc_Bullet_Big)
