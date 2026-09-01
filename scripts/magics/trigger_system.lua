-- 触发系统 - 用于处理定时触发、碰撞触发、死亡触发等
-- 核心设计：触发法术在施法阶段就已经完全计算好，触发时只需生成预设的投射物
TBoN.Magic.Table.trigger_data = TBoN.Magic.Table.trigger_data or {}

-- 触发类型枚举
TBoN.Magic.Table.Info.TriggerType = {
    TIMER = 1,      -- 定时触发
    COLLISION = 2,  -- 碰撞触发
    DEATH = 3,      -- 死亡触发
}

-- 为投射物注册触发信息
-- @param entity: 投射物实体
-- @param trigger_type: 触发类型 (TIMER, COLLISION, DEATH)
-- @param trigger_projectiles: 待触发的投射物数据数组（已完全计算好的投射物配置）
-- @param trigger_param: 触发参数 (对于TIMER是帧数,对于COLLISION是nil)
function TBoN.Magic.Function.Custom.RegisterTrigger(entity, trigger_type, trigger_projectiles, trigger_param)
    local entity_hash = GetPtrHash(entity)
    
    TBoN.Magic.Table.trigger_data[entity_hash] = {
        entity = entity,
        trigger_type = trigger_type,
        trigger_projectiles = trigger_projectiles or {},  -- 待触发的投射物配置（已包含所有属性和修饰符）
        trigger_param = trigger_param,     -- 触发参数
        triggered = false,                 -- 是否已触发
        init_frame = Game():GetFrameCount(), -- 初始化帧
    }
end

-- 执行触发的法术
-- @param entity: 触发源实体
-- @param trigger_data: 触发数据
function TBoN.Magic.Function.Custom.ExecuteTriggerSpells(entity, trigger_data)
    if not trigger_data then
        return
    end
    if not trigger_data.trigger_projectiles or #trigger_data.trigger_projectiles == 0 then
        return
    end
    
    -- 创建基于实体哈希的RNG用于散射
    local trigger_rng = RNG()
    local base_hash = GetPtrHash(entity)
    trigger_rng:SetSeed(base_hash + Game():GetFrameCount(), 35)
    
    -- 遍历所有预计算好的触发投射物
    local spawn_dir = entity.Velocity:Length() > 0 and entity.Velocity:Normalized() or Vector(1, 0)
    local parent = entity.Parent or entity

    for _, proj in ipairs(trigger_data.trigger_projectiles) do
        if proj.entity_type and proj.entity_variant then
            local scatter_direction = TBoN.Gun.Function.Custom.Calculate_Spread_Direction(
                spawn_dir, proj.spread_degrees or 0, trigger_rng
            )
            local velocity = scatter_direction * (proj.speed or 1) * (proj.speed_multiplier or 1)
            local new_entity = TBoN.Gun.Function.Custom.Spawn_Projectile_Entity(
                proj, entity.Position, velocity, parent
            )
            new_entity.Parent = parent
        end
    end
end

-- 定时触发更新
function TBoN_MOD:TriggerSystem_Timer_Update(entity)
    local entity_hash = GetPtrHash(entity)
    local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
    
    if trigger_data and not trigger_data.triggered then
        if trigger_data.trigger_type == TBoN.Magic.Table.Info.TriggerType.TIMER then
            local elapsed_frames = Game():GetFrameCount() - trigger_data.init_frame
            
            -- 达到定时时间,触发
            if elapsed_frames >= trigger_data.trigger_param then
                TBoN.Magic.Function.Custom.ExecuteTriggerSpells(entity, trigger_data)
                trigger_data.triggered = true
            end
        end
    end
end

-- 注册回调
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.TriggerSystem_Timer_Update)

-- 清理无效的触发数据(可选,定期清理)
function TBoN_MOD:TriggerSystem_Cleanup()
    for hash, data in pairs(TBoN.Magic.Table.trigger_data) do
        if not data.entity or not data.entity:Exists() then
            TBoN.Magic.Table.trigger_data[hash] = nil
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_UPDATE, TBoN_MOD.TriggerSystem_Cleanup)

--- @function 法术移除前的统一触发检测
--- @param entity Entity 即将被移除的法术实体
function TBoN_MOD:TriggerSystem_Pre_Magic_Remove(entity)
    local entity_hash = GetPtrHash(entity)
    local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
    if trigger_data and not trigger_data.triggered then
        TBoN.Magic.Function.Custom.ExecuteTriggerSpells(entity, trigger_data)
        trigger_data.triggered = true
    end
end

TBoN_MOD:AddCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, TBoN_MOD.TriggerSystem_Pre_Magic_Remove)
