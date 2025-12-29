-- SPITTER 投射物逻辑
-- 分裂弹 - 发射中等散布的飞弹，随时间推移快速缩小直到消失
-- 三种等级：基础、绿色(Tier 2)、紫色(Tier 3)
-- 每种都有带定时触发的变种（不支持碰撞触发，仅定时触发）

-- 初始化分裂弹数据
function TBoN_MOD:Spitter_Init(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    if not entity_data.spitter_data then
        -- 根据子类型确定等级
        local subtype = entity.SubType
        local tier = 1
        
        if subtype == TBoN.Magic.Info.SubType.Spitter_Tier_2 then
            tier = 2
        elseif subtype == TBoN.Magic.Info.SubType.Spitter_Tier_3 then
            tier = 3
        end
        
        entity_data.spitter_data = {
            tier = tier,
            spawn_frame = Game():GetFrameCount(),
            max_lifetime = 20,
            initial_radius = 7,
            final_radius = 1.5,
        }
    end
end

-- 伤害逻辑
function TBoN_MOD:Spitter_Damage(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    -- 初始化数据
    TBoN_MOD:Spitter_Init(entity)
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    local spitter_data = entity_data.spitter_data
    
    -- 计算当前碰撞半径
    local elapsed_frames = Game():GetFrameCount() - spitter_data.spawn_frame
    local lifetime_ratio = math.min(elapsed_frames / spitter_data.max_lifetime, 1.0)
    local current_radius = spitter_data.initial_radius - (spitter_data.initial_radius - spitter_data.final_radius) * lifetime_ratio
    
    -- 检测敌人碰撞
    local entities = Isaac.FindInRadius(entity.Position, current_radius, EntityPartition.ENEMY)
    if #entities > 0 then
        entities[1]:TakeDamage(
            TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash),
            0,
            EntityRef(entity),
            0
        )
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
    
    -- 初始化数据
    TBoN_MOD:Spitter_Init(entity)
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    local spitter_data = entity_data.spitter_data
    
    -- 检测是否出界
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        entity:Kill()
        return
    end
    
    -- 计算当前碰撞半径用于障碍物检测
    local elapsed_frames = Game():GetFrameCount() - spitter_data.spawn_frame
    local lifetime_ratio = math.min(elapsed_frames / spitter_data.max_lifetime, 1.0)
    local current_radius = spitter_data.initial_radius - (spitter_data.initial_radius - spitter_data.final_radius) * lifetime_ratio
    
    -- 当生命周期结束时移除（sprite 已经缩小到看不见）
    if elapsed_frames >= spitter_data.max_lifetime then
        entity:Remove()
        return
    end
    
    -- 应用阻尼效果（模拟减速）
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
            entity:Remove()
            break
        end
    end
    
    -- 超时消失
    if entity.Timeout <= 0 then
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Spitter_Disappear, TBoN.Magic.Info.Variant.Spitter)
