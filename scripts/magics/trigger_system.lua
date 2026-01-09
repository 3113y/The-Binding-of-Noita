-- 触发系统 - 用于处理定时触发、碰撞触发、死亡触发等
-- 核心设计：触发法术在施法阶段就已经完全计算好，触发时只需生成预设的投射物
TBoN.Magic.Table.trigger_data = TBoN.Magic.Table.trigger_data or {}

-- 触发类型枚举
TBoN.Magic.Info.TriggerType = {
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
    for _, proj in ipairs(trigger_data.trigger_projectiles) do
        if proj.entity_type and proj.entity_variant then
            -- 计算发射方向（继承原投射物的速度方向）
            local spawn_velocity = entity.Velocity:Length() > 0 and entity.Velocity:Normalized() or Vector(1, 0)
            local scatter_direction = TBoN.Gun.Function.Custom.Calculate_Spread_Direction(
                spawn_velocity,
                proj.spread_degrees or 0,
                trigger_rng
            )
            
            -- 在触发点生成新投射物
            local new_entity = Isaac.Spawn(
                proj.entity_type,
                proj.entity_variant,
                proj.entity_subtype or 0,
                entity.Position,
                scatter_direction * (proj.speed or 1) * (proj.speed_multiplier or 1),
                entity.Parent or entity
            )
            
            -- 设置生命周期
            if new_entity:ToEffect() then
                new_entity:ToEffect():SetTimeout((proj.lifetime or 0) + (proj.lifetime_add or 0))
            end
            new_entity.Parent = entity.Parent
            
            -- 设置旋转
            local degrees = math.deg(math.atan(scatter_direction.Y, scatter_direction.X))
            new_entity.SpriteRotation = degrees
            if new_entity:ToTear() then
                new_entity:ToTear().Rotation = degrees
            end
            
            -- 播放动画
            local sprite = new_entity:GetSprite()
            if sprite then
                sprite:Play("RegularTear6", false)
            end
            
            -- 存储伤害数据到magic_hash（直接使用预计算的数据）
            local new_hash = GetPtrHash(new_entity)
            TBoN.Magic.Table.magic_hash[new_hash] = {
                damages = {
                    damage = proj.damage or 1,
                    damage_critical_chance = proj.damage_critical_chance or 0,
                    damage_projectile_add = proj.damage_projectile_add or 0
                },
                modifiers = {},
                trigger_spells = proj.trigger_spells or {},
                applied = false
            }
            
            -- 复制修饰符
            if proj.modifiers then
                for _, mod in ipairs(proj.modifiers) do
                    table.insert(TBoN.Magic.Table.magic_hash[new_hash].modifiers, mod)
                end
            end
            
            -- 如果这个被触发的投射物本身也是触发法术，递归注册
            if proj.is_trigger and proj.trigger_projectiles and #proj.trigger_projectiles > 0 then
                local trigger_type_map = {
                    TIMER = TBoN.Magic.Info.TriggerType.TIMER,
                    COLLISION = TBoN.Magic.Info.TriggerType.COLLISION,
                    DEATH = TBoN.Magic.Info.TriggerType.DEATH,
                }
                TBoN.Magic.Function.Custom.RegisterTrigger(
                    new_entity,
                    trigger_type_map[proj.trigger_type] or TBoN.Magic.Info.TriggerType.COLLISION,
                    proj.trigger_projectiles,
                    proj.trigger_param
                )
            end
        end
    end
end

-- 定时触发更新
function TBoN_MOD:TriggerSystem_Timer_Update(entity)
    local entity_hash = GetPtrHash(entity)
    local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
    
    if trigger_data and not trigger_data.triggered then
        if trigger_data.trigger_type == TBoN.Magic.Info.TriggerType.TIMER then
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
