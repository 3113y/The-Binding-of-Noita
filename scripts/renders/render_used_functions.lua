function TBoN.UI.Function.Custom.Mouse_Pos_But_Check(Mouse_Pos, Aim_pos) --检测鼠标位置（即在某小格）
    mous_pos = Isaac.WorldToScreen(Mouse_Pos)
    if mous_pos.X >= Aim_pos.X and mous_pos.X <= Aim_pos.X + 20 then
        if mous_pos.Y >= Aim_pos.Y and mous_pos.Y <= Aim_pos.Y + 20 then
            return true
        else
            return false
        end
    end
end

function TBoN.UI.Function.Custom.Mouse_Pos_Pos_Check(Mouse_Pos, table, i) --检测鼠标位置（即在某区域）
    mous_pos = Isaac.WorldToScreen(Mouse_Pos)
    local temp = 0
    for _, p in pairs(table) do
        if mous_pos.X >= p.pos.X and mous_pos.X <= p.pos.X + 20 then
            if mous_pos.Y >= p.pos.Y and mous_pos.Y <= p.pos.Y + 20 then
                temp = temp + 1
            else
                temp = temp
            end
        end
    end
    if temp > 0 then
        return i
    else
        return false
    end
end

function TBoN.UI.Function.Custom.swapGunGroups(gunTable, i, j)
    -- 边界检查
    local gunI = gunTable[i]
    local gunJ = gunTable[j]
    
    -- 交换gun_info中的所有信息
    TBoN.Gun.Table.gun_info[i], TBoN.Gun.Table.gun_info[j] = TBoN.Gun.Table.gun_info[j], TBoN.Gun.Table.gun_info[i]

    -- 交换magic数据
    TBoN.Gun.Table.gun_magic_data[i], TBoN.Gun.Table.gun_magic_data[j] = TBoN.Gun.Table.gun_magic_data[j], TBoN.Gun.Table.gun_magic_data[i]
end

function TBoN.UI.Function.Custom.mergeMagicAndGunMagic(magicTable, gunTable)
    local merged = {}

    -- 合并magic表中的所有法术槽
    for _, magicSlot in pairs(magicTable) do
        -- 仅保留核心属性
        table.insert(merged, {
            pos = magicSlot.pos,
            sprite = magicSlot.sprite,
            magic = magicSlot.magic,
            source = "magic"
        })
    end

    -- 合并每个gun的有效法术槽
    for gunIndex, gunItem in pairs(gunTable) do
        local capacity = TBoN.Gun.Table.gun_info[gunIndex].capacity or 0
        local gunMagicSlots = TBoN.UI.Table.gun_magic_render_table[gunIndex] or {}

        -- 只合并前capacity个法术槽
        for i = 1, capacity do
            local magicSlot = gunMagicSlots[i]
            if magicSlot then
                table.insert(merged, {
                    pos = magicSlot.pos,
                    sprite = magicSlot.sprite,
                    magic = TBoN.Gun.Table.gun_magic_data[gunIndex][i],
                    source = "gun",
                    gunIndex = gunIndex
                })
            end
        end
    end

    return merged
end

function TBoN.UI.Function.Custom.splitMergedToOriginal(mergedTable, originalMagic, originalGun)
    -- 处理magic表部分
    local magicPos = 1
    for _, mergedItem in ipairs(mergedTable) do
        if mergedItem.source == "magic" then
            if originalMagic[magicPos] then
                -- 仅更新法术标识
                originalMagic[magicPos].magic = mergedItem.magic
                magicPos = magicPos + 1
            else
                break
            end
        else
            break
        end
    end

    -- 处理gun表部分
    local gunPos = magicPos
    for gunIndex, gunItem in ipairs(originalGun) do
        local capacity = TBoN.Gun.Table.gun_info[gunIndex].capacity or 0
        for i = 1, capacity do
            local mergedItem = mergedTable[gunPos]
            if mergedItem and mergedItem.source == "gun" and mergedItem.gunIndex == gunIndex then
                TBoN.Gun.Table.gun_magic_data[gunIndex][i] = mergedItem.magic
                gunPos = gunPos + 1
            else
                TBoN.Gun.Table.gun_magic_data[gunIndex][i] = false
            end
        end
    end
end

function TBoN.UI.Function.Custom.deepCopy(orig) -- 深拷贝表的工具函数
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[TBoN.UI.Function.Custom.deepCopy(orig_key)] = TBoN.UI.Function.Custom.deepCopy(orig_value)
        end
        setmetatable(copy, TBoN.UI.Function.Custom.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- 获取法术详细信息
function TBoN.UI.Function.Custom.GetSpellInfo(spell_name)
    if not spell_name or not TBoN.UI.Table.actions_map[spell_name] then
        return nil
    end
    
    local spell_info = actions[TBoN.UI.Table.actions_map[spell_name]]
    if not spell_info then
        return nil
    end
    
    -- 保存当前c表和proj_modifier状态
    local old_c = TBoN.UI.Function.Custom.deepCopy(c)
    local old_proj_modifier = TBoN.UI.Function.Custom.deepCopy(proj_modifier)
    
    -- 重置c表到初始状态
    c = {
        fire_rate_wait = 0,
        entity_type = nil,
        entity_variant = nil,
        speed_multiplier = 1,
        damage = 1,
        screenshake = 0,
        lifetime_add = 0,
        spread_degrees = 0,
        recoil_knockback = 0,
        damage_critical_chance = 0,
        damage_projectile_add = 0,
    }
    proj_modifier = {}
    
    -- 执行法术action来获取效果
    if spell_info.action then
        spell_info.action()
    end
    
    -- 构建返回结果
    local result = {
        name = spell_name,
        type = spell_info.type,
        mana_cost = spell_info.mana or 0,
        description = spell_info.description or "",
        
        -- 基础属性（所有法术都有）
        fire_rate_wait = c.fire_rate_wait,
        cast_delay = c.fire_rate_wait,
        recharge_time = spell_info.recharge_time or 0,
        
        -- 投射物属性（仅投射物法术有效）
        damage = nil,
        speed_multiplier = c.speed_multiplier,
        lifetime_add = c.lifetime_add,
        spread_degrees = c.spread_degrees,
        recoil_knockback = c.recoil_knockback,
        damage_critical_chance = c.damage_critical_chance,
        damage_projectile_add = c.damage_projectile_add,
        
        -- 修饰符信息
        modifiers = TBoN.UI.Function.Custom.deepCopy(proj_modifier),
        
        -- 实体信息
        entity_type = c.entity_type,
        entity_variant = c.entity_variant,
    }
    
    -- 只有投射物法术才包含投射物相关属性
    if spell_info.type == "ACTION_TYPE_PROJECTILE" or spell_info.type == "ACTION_TYPE_STATIC_PROJECTILE" then
        result.damage = c.damage
        result.speed_multiplier = c.speed_multiplier
        result.lifetime_add = c.lifetime_add
        result.spread_degrees = c.spread_degrees
        result.recoil_knockback = c.recoil_knockback
        result.damage_critical_chance = c.damage_critical_chance
        result.damage_projectile_add = c.damage_projectile_add
    end
    
    -- 修饰符法术的特殊处理
    if spell_info.type == "ACTION_TYPE_MODIFIER" then
        result.modifier_effects = {
            damage_mult = c.damage ~= 1 and c.damage or nil,
            speed_mult = c.speed_multiplier ~= 1 and c.speed_multiplier or nil,
            spread_add = c.spread_degrees ~= 0 and c.spread_degrees or nil,
            recoil_add = c.recoil_knockback ~= 0 and c.recoil_knockback or nil,
            crit_chance_add = c.damage_critical_chance ~= 0 and c.damage_critical_chance or nil,
            damage_add = c.damage_projectile_add ~= 0 and c.damage_projectile_add or nil,
            lifetime_add = c.lifetime_add ~= 0 and c.lifetime_add or nil,
        }
    end
    
    -- 恢复原始状态
    c = old_c
    proj_modifier = old_proj_modifier
    
    return result
end
