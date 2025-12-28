function TBoN.Room.Function.Custom.Out_Of_Room(entity_pos)
    local shape_data = TBoN.Room.Variable.Current_Room_Shape
    if not shape_data then
        print("No room shape data available.")
        return false
    end
    local root_pos = shape_data.Root_Pos
    local size = shape_data.Shape.Size
    -- 检查是否在主房间边界外
    if entity_pos.X < root_pos.X+40 or entity_pos.X > root_pos.X + size.X+40 or
       entity_pos.Y < root_pos.Y+40 or entity_pos.Y > root_pos.Y + size.Y+40 then
        return true
    end
    -- 如果房间有空洞，检查是否在空洞内（空洞内也算房间外）
    if shape_data.Shape.Hole then
        local hole_pos = shape_data.Shape.Hole.Pos
        local hole_size = shape_data.Shape.Hole.Size
        if entity_pos.X >= hole_pos.X and entity_pos.X <= hole_pos.X + hole_size.X and
           entity_pos.Y >= hole_pos.Y and entity_pos.Y <= hole_pos.Y + hole_size.Y then
            return true
        end
    end
    return false
end

-- 判断 grid 是否是房间边界墙
function TBoN.Room.Function.Custom.Is_Boundary_Wall(grid_pos)
    local shape_data = TBoN.Room.Variable.Current_Room_Shape
    
    if not shape_data then
        return false
    end
    
    local root_pos = shape_data.Root_Pos
    local size = shape_data.Shape.Size
    local margin = 50 -- 边界容差，grid 是 40x40 的，多留一点空间
    
    -- 检查是否靠近主房间边界
    if grid_pos.X <= root_pos.X + margin or grid_pos.X >= root_pos.X + size.X - margin or
       grid_pos.Y <= root_pos.Y + margin or grid_pos.Y >= root_pos.Y + size.Y - margin then
        return true
    end
    
    -- 检查是否是空洞边界
    if shape_data.Shape.Hole then
        local hole_pos = shape_data.Shape.Hole.Pos
        local hole_size = shape_data.Shape.Hole.Size
        
        -- 空洞边界的容差范围
        if grid_pos.X >= hole_pos.X - margin and grid_pos.X <= hole_pos.X + hole_size.X + margin and
           grid_pos.Y >= hole_pos.Y - margin and grid_pos.Y <= hole_pos.Y + hole_size.Y + margin then
            -- 进一步判断是否在空洞边界上
            if (grid_pos.X <= hole_pos.X + margin or grid_pos.X >= hole_pos.X + hole_size.X - margin) or
               (grid_pos.Y <= hole_pos.Y + margin or grid_pos.Y >= hole_pos.Y + hole_size.Y - margin) then
                return true
            end
        end
    end
    
    return false
end

-- 检查与房间内部障碍物的碰撞（排除边界墙）
-- 返回：碰撞的 grid 实体，grid 位置
function TBoN.Room.Function.Custom.Check_Interior_Grid_Collision(entity_pos, radius)
    local room = Game():GetRoom()
    
    for idx = 0, room:GetGridSize() - 1 do
        local grid_entity = room:GetGridEntity(idx)
        if grid_entity and TBoN.Magic.Function.Custom.Can_Col_With_Grid(grid_entity) then
            local grid_pos = room:GetGridPosition(idx)
            
            -- 排除边界墙
            if not TBoN.Room.Function.Custom.Is_Boundary_Wall(grid_pos) then
                -- 检查距离
                if TBoN.Magic.Function.Custom.Check_Pos(entity_pos, grid_pos, radius) then
                    return grid_entity, grid_pos
                end
            end
        end
    end
    
    return nil, nil
end