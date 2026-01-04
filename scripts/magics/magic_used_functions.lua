function TBoN.Magic.Function.Custom.Damage_Calculate(entity,table)
    local hash = GetPtrHash(entity)
    local tempdamage = table[hash].damages.damage + table[hash].damages.damage_projectile_add
    local finaldamage
    local rng = RNG()
    rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
    if table[hash].damages.damage_critical_chance > 100 then
    finaldamage = tempdamage * (5+ (table[hash].damages.damage_critical_chance - 100) / 2)
    elseif table[hash].damages.damage_critical_chance >= rng:RandomInt(100) then
        finaldamage = tempdamage * 5
    else
        finaldamage = tempdamage

    end
        return finaldamage
end
---@diagnostic disable: missing-return-value
---@param pos1 Vector,主目标
---@param pos2 Vector,待检测目标
---@param range number,检测范围
---@return boolean;在范围内返回true否则返回false
function TBoN.Magic.Function.Custom.Check_Pos(pos1, pos2, range)
    if math.sqrt((pos1.X - pos2.X) ^ 2 + (pos1.Y - pos2.Y) ^ 2) <= range then
        return true
    else
        return false
    end
end

function TBoN.Magic.Function.Custom.Get_Hole_Gravity(entity1, entity2) --获取引力数值
    local vec = (entity1.Mass * entity2.Mass) /
        (math.sqrt((entity1.Position.X - entity2.Position.X) ^ 2 + (entity1.Position.Y - entity2.Position.Y) ^ 2) ^ 2)
    if entity2.Mass >= 99 then
        return 0
    end
    if vec >= 2 then
        return 2
    else
        return vec
    end
end

function TBoN.Magic.Function.Custom.Hash_Table_Init(table) --初始化哈希表
    local hash = {}
    return hash
end

function TBoN.Magic.Function.Custom.Can_Col_With_Grid(grid_entity)
    -- 检查 Type 是否在不可碰撞列表中
    for _, type_value in ipairs(TBoN.Room.Table.Couldnt_Col.Types) do
        if grid_entity.Desc.Type == type_value then
            return false
        end
    end
    
    -- 检查 State
    if grid_entity.State == 2 or grid_entity.State == 1000 then
        return false
    end
    
    return true
end

