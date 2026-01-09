-- SPITTER 投射物逻辑
-- 分裂弹 - 发射中等散布的飞弹，随时间推移快速缩小直到消失
-- 三种等级：基础、绿色(Tier 2)、紫色(Tier 3)
-- 每种都有带定时触发的变种（不支持碰撞触发，仅定时触发）

-- 伤害逻辑
function TBoN_MOD:Spitter_Damage(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end

    -- 计算当前碰撞半径
    local initial_radius = 7
    local final_radius = 1.5
    local max_lifetime = 20
    local elapsed_frames = max_lifetime - entity.Timeout
    local lifetime_ratio = math.min(elapsed_frames / max_lifetime, 1.0)
    local current_radius = initial_radius - (initial_radius - final_radius) * lifetime_ratio

    -- 检测敌人碰撞
    local entities = Isaac.FindInRadius(entity.Position, current_radius, EntityPartition.ENEMY)
    if #entities > 0 then
        entities[1]:TakeDamage(
            TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash),
            0,
            EntityRef(entity),
            0
        )
        
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Spitter_Damage, TBoN.Magic.Info.Variant.Spitter)

-- 消失逻辑
function TBoN_MOD:Spitter_Disappear(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end

    -- 检测是否出界
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        entity:Kill()
        return
    end

    -- 超时消失
    if entity.Timeout <= 0 then
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
        return
    end

    -- 计算当前碰撞半径用于障碍物检测
    local initial_radius = 7
    local final_radius = 1.5
    local max_lifetime = 20
    local elapsed_frames = max_lifetime - entity.Timeout
    local lifetime_ratio = math.min(elapsed_frames / max_lifetime, 1.0)
    local current_radius = initial_radius - (initial_radius - final_radius) * lifetime_ratio

    -- 应用阻尼效果（模拟减速）
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    local dampening = entity_data.dampening or 1.0
    if dampening < 1.0 then
        entity.Velocity = entity.Velocity * (1.0 - (1.0 - dampening) * 0.1)
    end

    -- 检测障碍物碰撞
    for idx = 0, Game():GetRoom():GetGridSize() - 1 do
        local grid_entity = Game():GetRoom():GetGridEntity(idx)
        if grid_entity and
            TBoN.Magic.Function.Custom.Can_Col_With_Grid(grid_entity) and
            TBoN.Magic.Function.Custom.Check_Pos(entity.Position, Game():GetRoom():GetGridPosition(idx), current_radius + 10) then
            grid_entity:Hurt(math.floor(TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash)))
            
            Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
            entity:Remove()
            break
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Spitter_Disappear, TBoN.Magic.Info.Variant.Spitter)
