---@diagnostic disable: missing-return-value
---@param pos1 Vector,主目标
---@param pos2 Vector,待检测目标
---@param range number,检测范围
---@return boolean,在范围内返回true否则返回false
function Check_Pos(pos1,pos2,range)
    if math.sqrt((pos1.X - pos2.X) ^ 2 + (pos1.Y - pos2.Y) ^ 2) <= range then
        return true
    else
        return false
    end
end
---@param entity1 Entity,白洞/黑洞实体
---@param entity2 Entity,被吸引实体
---@return number,引力数值
function Get_Hole_Gravity(entity1,entity2)--获取引力数值
    local vec = (entity1.Mass*entity2.Mass)/(math.sqrt((entity1.Position.X - entity2.Position.X) ^ 2 + (entity1.Position.Y - entity2.Position.Y) ^ 2)^2)
    if entity2.Mass >= 99 then
        return 0
    end
    if vec >= 2 then
        return 2
    else
        return vec
    end
end
function Get_Hole_Velocity_Vector(entity1,entity2)--获取引力方向单位向量
    return Vector(
        (entity1.Position.X - entity2.Position.X) /
        math.sqrt((entity1.Position.X - entity2.Position.X) ^ 2 +
            (entity1.Position.Y - entity2.Position.Y) ^ 2),
        (entity1.Position.Y - entity2.Position.Y) /
        math.sqrt((entity1.Position.X - entity2.Position.X) ^ 2 +
            (entity1.Position.Y - entity2.Position.Y) ^ 2))
end