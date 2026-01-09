-- DISC_BULLET 投射物逻辑
-- 圆锯片 - 旋转的锯片状投射物，击中固体材料时弹跳，能量耗尽后落地
-- 能够伤害施法者自身（任意entity）

-- 初始化圆锯片数据
function TBoN_MOD:Disc_Bullet_Init(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    if not entity_data.disc_data then
        entity_data.disc_data = {
            energy = 100, -- 初始能量
            is_grounded = false, -- 是否已落地
            bounce_count = 0, -- 弹跳次数
            last_hit_frame = 0, -- 上次碰撞的帧数
        }
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, TBoN_MOD.Disc_Bullet_Init, TBoN.Magic.Info.Variant.Disc_Bullet)

-- 伤害逻辑 - 能够伤害任意实体（包括玩家）
function TBoN_MOD:Disc_Bullet_Damage(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    TBoN_MOD:Disc_Bullet_Init(entity)
    
    -- 如果已落地，不造成伤害
    if entity_data.disc_data.is_grounded then
        return
    end
    
    -- 搜索附近的所有实体（包括玩家、敌人等）
    local all_entities = {}
    -- 添加敌人
    local enemies = Isaac.FindInRadius(entity.Position, 10, EntityPartition.ENEMY)
    for _, enemy in ipairs(enemies) do
        table.insert(all_entities, enemy)
    end
    -- 添加玩家
    local players = Isaac.FindInRadius(entity.Position, 10, EntityPartition.PLAYER)
    for _, player in ipairs(players) do
        table.insert(all_entities, player)
    end
    -- 添加友方实体
    local familiars = Isaac.FindInRadius(entity.Position, 10, EntityPartition.FAMILIAR)
    for _, familiar in ipairs(familiars) do
        table.insert(all_entities, familiar)
    end
    
    if #all_entities > 0 then
        local target = all_entities[1]
        local damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
        target:TakeDamage(damage, 0, EntityRef(entity), 0)
        
        -- 能量大幅衰减
        entity_data.disc_data.energy = entity_data.disc_data.energy - 30
        
        -- 击中实体后停止移动
        entity.Velocity = entity.Velocity * 0.1
        
        -- 检查是否是触发法术

    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Disc_Bullet_Damage, TBoN.Magic.Info.Variant.Disc_Bullet)

-- 弹跳和消失逻辑
function TBoN_MOD:Disc_Bullet_Disappear(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    TBoN_MOD:Disc_Bullet_Init(entity)
    local disc_data = entity_data.disc_data
    
    -- 检查房间墙壁碰撞并反弹
    local wall_collision = TBoN.Room.Function.Custom.Col_With_Room_Wall(entity.Position)
    if wall_collision then
        -- 能量衰减
        disc_data.energy = disc_data.energy - 20
        
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
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
        return
    end
    
    -- 能量随时间自然衰减
    disc_data.energy = disc_data.energy - 0.5
    
    -- 能量耗尽，落地变为无害
    if disc_data.energy <= 0 and not disc_data.is_grounded then
        disc_data.is_grounded = true
        entity.Velocity = entity.Velocity * 0.3 -- 减速
        -- 播放落地动画（如果有的话）
        if entity:GetSprite():IsPlaying("RegularTear6") then
            entity:GetSprite():Play("OnGround", true)
        end
    end
    
    -- 如果已落地，继续减速直到停止
    if disc_data.is_grounded then
        entity.Velocity = entity.Velocity * 0.9
        if entity.Velocity:Length() < 0.5 then
            entity.Velocity = Vector(0, 0)
        end
        -- 落地后一段时间消失
        if entity.FrameCount > entity.Timeout + 60 then
            Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
            entity:Remove()
        end
        return
    end
    
    -- 检测与障碍物的碰撞（边界反弹会先触发，所以碰到的都是内部障碍物）
    local current_frame = Game():GetFrameCount()
    if current_frame - disc_data.last_hit_frame < 5 then
        -- 避免连续碰撞检测
        return
    end
    
    local grid_entity, grid_pos = TBoN.Room.Function.Custom.Check_Grid_Collision(entity.Position, 20)
    if grid_entity and grid_pos then
        -- 击中内部障碍物，弹跳！
        local to_grid = (grid_pos - entity.Position)
        -- 如果距离太近，强制推开
        if to_grid:Length() < 5 then
            to_grid = to_grid:Normalized() * 5
        end
        to_grid = to_grid:Normalized()
        
        -- 计算反射方向（改进的反弹逻辑）
        local velocity_normalized = entity.Velocity:Normalized()
        local dot = velocity_normalized:Dot(to_grid)
        
        -- 只在朝向障碍物时才反弹
        if dot > 0 then
            local reflection = entity.Velocity - to_grid * (2 * dot * entity.Velocity:Length())
            -- 应用反射速度，并保持一定的能量损失
            entity.Velocity = reflection * 0.7
        else
            -- 如果已经在远离障碍物，只减少速度
            entity.Velocity = entity.Velocity * 0.8
        end
        
        -- 能量衰减
        disc_data.energy = disc_data.energy - 15
        disc_data.bounce_count = disc_data.bounce_count + 1
        disc_data.last_hit_frame = current_frame
        
        -- 对障碍物造成伤害
        grid_entity:Hurt(math.floor(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash) * 0.5))
        
        -- 检查触发系统
    end
    
    -- 超时检测
    if entity.Timeout <= 0 then
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Disc_Bullet_Disappear, TBoN.Magic.Info.Variant.Disc_Bullet)
