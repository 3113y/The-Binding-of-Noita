-- 触发系统 - 用于处理定时触发、碰撞触发、死亡触发等
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
-- @param spell_queue: 待触发的法术队列 (法术ID数组)
-- @param trigger_param: 触发参数 (对于TIMER是帧数,对于COLLISION是nil)
function TBoN.Magic.Function.Custom.RegisterTrigger(entity, trigger_type, spell_queue, trigger_param)
    local entity_hash = GetPtrHash(entity)
    
    print("[TRIGGER_SYS] RegisterTrigger 被调用")
    print("[TRIGGER_SYS] Entity Hash: " .. entity_hash)
    print("[TRIGGER_SYS] Trigger Type: " .. (trigger_type or "nil"))
    print("[TRIGGER_SYS] Spell Queue 长度: " .. #spell_queue)
    if #spell_queue > 0 then
        print("[TRIGGER_SYS] Spell Queue: " .. table.concat(spell_queue, ", "))
    end
    
    TBoN.Magic.Table.trigger_data[entity_hash] = {
        entity = entity,
        trigger_type = trigger_type,
        spell_queue = spell_queue or {},  -- 待触发的法术队列
        trigger_param = trigger_param,     -- 触发参数
        triggered = false,                 -- 是否已触发
        init_frame = Game():GetFrameCount(), -- 初始化帧
    }
end

-- 执行触发的法术队列
-- @param entity: 触发源实体
-- @param trigger_data: 触发数据
function TBoN.Magic.Function.Custom.ExecuteTriggerSpells(entity, trigger_data)
    print("[TRIGGER_SYS] ExecuteTriggerSpells 开始执行")
    if not trigger_data then
        print("[TRIGGER_SYS] 错误：trigger_data 为 nil")
        return
    end
    if #trigger_data.spell_queue == 0 then
        print("[TRIGGER_SYS] 错误：spell_queue 为空")
        return
    end
    print("[TRIGGER_SYS] Spell Queue: " .. table.concat(trigger_data.spell_queue, ", "))
    
    -- 保存当前的c和proj_modifier状态
    local old_c = {
        fire_rate_wait = c.fire_rate_wait,
        entity_type = c.entity_type,
        entity_variant = c.entity_variant,
        speed = c.speed,
        speed_multiplier = c.speed_multiplier,
        damage = c.damage,
        screenshake = c.screenshake,
        lifetime_add = c.lifetime_add,
        spread_degrees = c.spread_degrees,
        recoil_knockback = c.recoil_knockback,
        damage_critical_chance = c.damage_critical_chance,
        damage_projectile_add = c.damage_projectile_add,
    }
    local old_proj_modifier = {}
    for i, v in ipairs(proj_modifier) do
        table.insert(old_proj_modifier, v)
    end
    
    -- 重置c状态
    c.fire_rate_wait = 0
    c.entity_type = nil
    c.entity_variant = nil
    c.speed = 1
    c.speed_multiplier = 1
    c.damage = 1
    c.screenshake = 0
    c.lifetime_add = 0
    c.spread_degrees = 0
    c.recoil_knockback = 0
    c.damage_critical_chance = 0
    c.damage_projectile_add = 0
    proj_modifier = {}
    
    -- 执行法术队列中的每个法术
    for _, spell_id in ipairs(trigger_data.spell_queue) do
        print("[TRIGGER_SYS] 处理法术: " .. spell_id)
        local spell_idx = TBoN.Render.Table.actions_map[spell_id]
        if spell_idx and actions[spell_idx] then
            local spell = actions[spell_idx]
            print("[TRIGGER_SYS] 找到法术配置，类型: " .. (spell.type or "nil"))
            
            -- 执行法术action
            if spell.action then
                print("[TRIGGER_SYS] 执行法术 action")
                spell.action()
                print("[TRIGGER_SYS] action 执行后 c.entity_type: " .. tostring(c.entity_type))
                print("[TRIGGER_SYS] action 执行后 c.entity_variant: " .. tostring(c.entity_variant))
            end
            
            -- 如果是投射物类型，在触发位置生成
            if (spell.type == "ACTION_TYPE_PROJECTILE" or spell.type == "ACTION_TYPE_STATIC_PROJECTILE") 
               and c.entity_type and c.entity_variant then
                print("[TRIGGER_SYS] 准备生成投射物 Type:" .. c.entity_type .. " Variant:" .. c.entity_variant)
                
                -- 计算发射方向（继承原投射物的速度方向）
                local spawn_velocity = entity.Velocity:Length() > 0 and entity.Velocity:Normalized() or Vector(1, 0)
                local scatter_direction = TBoN.Gun.Function.Custom.Calculate_Spread_Direction(
                    spawn_velocity,
                    c.spread_degrees or 0
                )
                
                -- 在触发点生成新投射物
                print("[TRIGGER_SYS] 在位置 " .. tostring(entity.Position) .. " 生成实体")
                local new_entity = Isaac.Spawn(
                    c.entity_type,
                    c.entity_variant,
                    0,
                    entity.Position,
                    scatter_direction * (c.speed or 1) * (c.speed_multiplier or 1),
                    entity.Parent or entity
                )
                print("[TRIGGER_SYS] 实体生成成功！Hash: " .. GetPtrHash(new_entity))
                
                -- 设置生命周期
                if new_entity:ToEffect() then
                    new_entity:ToEffect():SetTimeout(c.lifetime_add or 0)
                end
                
                -- 设置旋转
                local degrees
                if scatter_direction.X > 0 then
                    degrees = 90 + math.deg(math.atan(scatter_direction.Y / scatter_direction.X))
                else
                    degrees = math.deg(math.atan(scatter_direction.Y / scatter_direction.X)) - 90
                end
                new_entity.SpriteRotation = degrees
                if new_entity:ToTear() then
                    new_entity:ToTear().Rotation = degrees
                end
                
                -- 播放动画
                local sprite = new_entity:GetSprite()
                if sprite then
                    sprite:Play("Idle", false)
                end
                
                -- 存储伤害数据到magic_hash
                local new_hash = GetPtrHash(new_entity)
                TBoN.Magic.Table.magic_hash[new_hash] = {
                    damages = {
                        damage = c.damage or 1,
                        damage_critical_chance = c.damage_critical_chance or 0,
                        damage_projectile_add = c.damage_projectile_add or 0
                    },
                    modifiers = {},
                    applied = false
                }
                
                -- 复制修饰符
                for i, mod in ipairs(proj_modifier) do
                    table.insert(TBoN.Magic.Table.magic_hash[new_hash].modifiers, mod)
                end
                
                -- 重置c状态以处理下一个法术
                c.entity_type = nil
                c.entity_variant = nil
            end
        end
    end
    
    -- 恢复c状态
    c.fire_rate_wait = old_c.fire_rate_wait
    c.entity_type = old_c.entity_type
    c.entity_variant = old_c.entity_variant
    c.speed = old_c.speed
    c.speed_multiplier = old_c.speed_multiplier
    c.damage = old_c.damage
    c.screenshake = old_c.screenshake
    c.lifetime_add = old_c.lifetime_add
    c.spread_degrees = old_c.spread_degrees
    c.recoil_knockback = old_c.recoil_knockback
    c.damage_critical_chance = old_c.damage_critical_chance
    c.damage_projectile_add = old_c.damage_projectile_add
    proj_modifier = old_proj_modifier
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
                
                -- 移除原投射物
                entity:Remove()
            end
        end
    end
end

-- 碰撞触发检测
function TBoN_MOD:TriggerSystem_Collision_Check(entity, collider)
    local entity_hash = GetPtrHash(entity)
    local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
    
    print("[TRIGGER_SYS] Collision_Check 被调用，Hash: " .. entity_hash)
    print("[TRIGGER_SYS] trigger_data 存在: " .. tostring(trigger_data ~= nil))
    if trigger_data then
        print("[TRIGGER_SYS] trigger_type: " .. (trigger_data.trigger_type or "nil"))
        print("[TRIGGER_SYS] triggered: " .. tostring(trigger_data.triggered))
    end
    
    if trigger_data and not trigger_data.triggered then
        if trigger_data.trigger_type == TBoN.Magic.Info.TriggerType.COLLISION then
            print("[TRIGGER_SYS] 触发类型匹配：COLLISION")
            -- 检查碰撞对象是否为敌人或障碍物
            local is_enemy = collider and collider:IsEnemy() or false
            local is_grid = collider and collider.GridCollisionClass ~= nil or false
            print("[TRIGGER_SYS] collider.IsEnemy: " .. tostring(is_enemy))
            print("[TRIGGER_SYS] collider.GridCollisionClass: " .. tostring(is_grid))
            
            if is_enemy or is_grid then
                print("[TRIGGER_SYS] ===== 开始执行触发 =====")
                TBoN.Magic.Function.Custom.ExecuteTriggerSpells(entity, trigger_data)
                trigger_data.triggered = true
                print("[TRIGGER_SYS] ===== 触发执行完成 =====")
                
                -- 移除原投射物
                entity:Remove()
            else
                print("[TRIGGER_SYS] 碰撞对象不是敌人或障碍物，不触发")
            end
        end
    end
end

-- 死亡触发检测
function TBoN_MOD:TriggerSystem_Death_Check(entity)
    local entity_hash = GetPtrHash(entity)
    local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
    
    if trigger_data and not trigger_data.triggered then
        if trigger_data.trigger_type == TBoN.Magic.Info.TriggerType.DEATH then
            -- 在实体即将被移除时触发
            TBoN.Magic.Function.Custom.ExecuteTriggerSpells(entity, trigger_data)
            trigger_data.triggered = true
        end
    end
    
    -- 清理触发数据
    TBoN.Magic.Table.trigger_data[entity_hash] = nil
end

-- 注册回调
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.TriggerSystem_Timer_Update)
-- 注意: 碰撞检测需要在具体投射物的碰撞回调中调用 TriggerSystem_Collision_Check
-- 死亡触发需要在投射物消失时调用 TriggerSystem_Death_Check

-- 清理无效的触发数据(可选,定期清理)
function TBoN_MOD:TriggerSystem_Cleanup()
    for hash, data in pairs(TBoN.Magic.Table.trigger_data) do
        if not data.entity or not data.entity:Exists() then
            TBoN.Magic.Table.trigger_data[hash] = nil
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_UPDATE, TBoN_MOD.TriggerSystem_Cleanup)
