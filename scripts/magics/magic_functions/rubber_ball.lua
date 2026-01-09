-- RUBBER_BALL 投射物逻辑

-- 伤害逻辑
function TBoN_MOD:Rubber_Ball_Damage(entity)
    local entities = Isaac.FindInRadius(entity.Position, 10, EntityPartition.ENEMY)
    if #entities > 0 then
        local target = entities[1]
        local damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
        target:TakeDamage(damage, 0, EntityRef(entity), 0)
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Rubber_Ball_Damage, TBoN.Magic.Info.Variant.Rubber_Ball)

-- 反弹逻辑/更新
function TBoN_MOD:Rubber_Ball_Bounce(entity)
    -- 速度衰减
    entity.Velocity = entity.Velocity * 0.985
    local current_speed = entity.Velocity:Length()
    
    -- 速度过慢则停止
    if current_speed < 0.1 then
        entity.Velocity = Vector.Zero
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
        return
    end
    
    -- 检查房间墙壁碰撞并反弹
    local wall_collision = TBoN.Room.Function.Custom.Col_With_Room_Wall(entity.Position)
    if wall_collision then
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
            entity.Velocity = reflection * current_speed * 0.92
        end
    end
    
    -- 检测与墙壁/障碍物的碰撞并反弹
    local grid_entity, grid_pos = TBoN.Room.Function.Custom.Check_Grid_Collision(entity.Position, 15)
    if grid_entity and grid_pos then
        -- 反弹时对墙壁造成伤害
        if TBoN.Magic.Function.Custom.Can_Col_With_Grid(grid_entity) then
            grid_entity:Hurt(math.floor(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash) * 0.3))
        end
        local to_grid = (grid_pos - entity.Position):Normalized()
        local velocity_normalized = entity.Velocity:Normalized()
        local dot = velocity_normalized:Dot(to_grid)
        local reflection = velocity_normalized - to_grid * (2 * dot)
        entity.Velocity = reflection * current_speed * 0.92
    end
    
    -- 检查是否真的超出房间范围（墙外20px）
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
        return
    end
    
    if entity.Timeout <= 0 then
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Rubber_Ball_Bounce, TBoN.Magic.Info.Variant.Rubber_Ball)
