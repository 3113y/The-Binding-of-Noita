-- BOUNCY_ORB 投射物逻辑

-- 伤害逻辑
function TBoN_MOD:Bouncy_Orb_Damage(entity)
    local entities = Isaac.FindInRadius(entity.Position, 10, EntityPartition.ENEMY)
    if #entities > 0 then
        local target = entities[1]
        local damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
        target:TakeDamage(damage, 0, EntityRef(entity), 0)
        entity:Remove()

    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Bouncy_Orb_Damage, TBoN.Magic.Info.Variant.Bouncy_Orb)

-- 反弹逻辑/更新
function TBoN_MOD:Bouncy_Orb_Bounce(entity)
    -- 速度衰减
    entity.Velocity = entity.Velocity * 0.98
    local current_speed = entity.Velocity:Length()
    
    -- 检查速度是否太慢
    if current_speed < 2 then
        entity.Velocity = Vector.Zero
        local entities = Isaac.FindInRadius(entity.Position, 20, EntityPartition.ENEMY)
        if #entities > 0 then
            local target = entities[1]
            local damage = TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)
            target:TakeDamage(damage * 0.5, 0, EntityRef(entity), 0)
        end
        entity:Remove()
        return
    end
    
    -- 检查房间墙壁碰撞并反弹
    local wall_collision = TBoN.Room.Function.Custom.Col_With_Room_Wall(entity.Position)
    if wall_collision then
        -- 根据墙壁位置计算反弹
        local room_center = Isaac.GetPlayer(0).Position
        local to_center = (room_center - entity.Position):Normalized()
        local velocity_normalized = entity.Velocity:Normalized()
        local dot = velocity_normalized:Dot(to_center)
        if dot < 0 then  -- 只在朝向墙壁时反弹
            local reflection = velocity_normalized - to_center * (2 * dot)
            entity.Velocity = reflection * current_speed * 0.95  -- 略微减速
        end
    end
    
    -- 检查网格碰撞并反弹
    local grid_entity, grid_pos = TBoN.Room.Function.Custom.Check_Grid_Collision(entity.Position, 15)
    if grid_entity and grid_pos then
        local to_grid = (grid_pos - entity.Position):Normalized()
        local velocity_normalized = entity.Velocity:Normalized()
        local dot = velocity_normalized:Dot(to_grid)
        local reflection = velocity_normalized - to_grid * (2 * dot)
        entity.Velocity = reflection * current_speed
    end
    
    -- 检查是否真的超出房间范围（墙外20px）
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        entity:Remove()
        return
    end
    
    -- 超时移除
    if entity.Timeout <= 0 then
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Bouncy_Orb_Bounce, TBoN.Magic.Info.Variant.Bouncy_Orb)