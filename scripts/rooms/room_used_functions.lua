function TBoN.Room.Function.Custom.Out_Of_Room(entity_pos)
    local shape_data = TBoN.Room.Variable.Current_Room_Shape or TBoN.Room.Table.Shape_Data[1]
    if not shape_data then
        TBoN_MOD:Room_Data_Refesh()
    end
    local root_pos = shape_data.Root_Pos
    local size = shape_data.Shape.Size
    -- 检查是否在主房间边界外
    if entity_pos.X + 20 < root_pos.X or entity_pos.X - 20 > root_pos.X + size.X or
       entity_pos.Y + 20 < root_pos.Y or entity_pos.Y - 20 > root_pos.Y + size.Y then
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

function TBoN.Room.Function.Custom.Col_With_Room_Wall(entity_pos)
    local shape_data = TBoN.Room.Variable.Current_Room_Shape
    if not shape_data then
        TBoN_MOD:Room_Data_Refesh()
    end
    local root_pos = shape_data.Root_Pos
    local size = shape_data.Shape.Size
    -- 检查是否在主房间边界外
    if entity_pos.X < root_pos.X or entity_pos.X > root_pos.X + size.X or
       entity_pos.Y < root_pos.Y or entity_pos.Y > root_pos.Y + size.Y then
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

-- 检查与障碍物的碰撞（不需要区分边界墙，因为边界反弹会先触发）
-- 返回：碰撞的 grid 实体，grid 位置
function TBoN.Room.Function.Custom.Check_Grid_Collision(entity_pos, radius)
    local room = Game():GetRoom()
    
    for idx = 0, room:GetGridSize() - 1 do
        local grid_entity = room:GetGridEntity(idx)
        if grid_entity and TBoN.Magic.Function.Custom.Can_Col_With_Grid(grid_entity) then
            local grid_pos = room:GetGridPosition(idx)
            
            -- 检查距离
            if TBoN.Magic.Function.Custom.Check_Pos(entity_pos, grid_pos, radius) then
                return grid_entity, grid_pos
            end
        end
    end
    
    return nil, nil
end