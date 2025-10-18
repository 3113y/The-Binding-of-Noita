function TBoN.UI.Function.Custom.Mouse_Pos_But_Check(Mouse_Pos, Aim_pos)
    mous_pos = Isaac.WorldToScreen(Mouse_Pos)
    if mous_pos.X >= Aim_pos.X and mous_pos.X <= Aim_pos.X + 20 then
        if mous_pos.Y >= Aim_pos.Y and mous_pos.Y <= Aim_pos.Y + 20 then
            return true
        else
            return false
        end
    end
end

function TBoN.UI.Function.Custom.Mouse_Pos_Pos_Check(Mouse_Pos, table, i)
    local mous_pos = Isaac.WorldToScreen(Mouse_Pos)
    for idx, p in pairs(table) do
        if p.pos then
            if mous_pos.X >= p.pos.X and mous_pos.X <= p.pos.X + 20 then
                if mous_pos.Y >= p.pos.Y and mous_pos.Y <= p.pos.Y + 20 then
                    return true
                end
            end
        end
    end
    return false
end

function TBoN.UI.Function.Custom.swapGunGroups(gunTable, i, j)
    TBoN.Gun.Table.gun_info[i], TBoN.Gun.Table.gun_info[j] = TBoN.Gun.Table.gun_info[j], TBoN.Gun.Table.gun_info[i]
    TBoN.Gun.Table.gun_magic_data[i], TBoN.Gun.Table.gun_magic_data[j] = TBoN.Gun.Table.gun_magic_data[j], TBoN.Gun.Table.gun_magic_data[i]
end

function TBoN.UI.Function.Custom.mergeMagicAndGunMagic(magicTable, gunTable)
    local merged = {}

    for i, magicSlot in pairs(magicTable) do
        local magic_id = TBoN.Magic.Table.bag_magic_data[i].magic_id
        table.insert(merged, {
            pos = magicSlot.pos,
            sprite = magicSlot.sprite,
            magic = magic_id == false and false or magic_id,
            source = "magic",
            bag_index = i
        })
    end

    for gunIndex, gunItem in pairs(gunTable) do
        local capacity = TBoN.Gun.Table.gun_info[gunIndex].capacity or 0
        local gunMagicSlots = TBoN.UI.Table.gun_magic_render_table[gunIndex] or {}

        for i = 1, capacity do
            local magicSlot = gunMagicSlots[i]
            if magicSlot then
                local magic_id = TBoN.Gun.Table.gun_magic_data[gunIndex][i].magic_id
                table.insert(merged, {
                    pos = magicSlot.pos,
                    sprite = magicSlot.sprite,
                    magic = magic_id == false and false or magic_id,
                    source = "gun",
                    gunIndex = gunIndex,
                    slotIndex = i
                })
            end
        end
    end

    return merged
end

function TBoN.UI.Function.Custom.splitMergedToOriginal(mergedTable)
    for i, mergedItem in ipairs(mergedTable) do
        if mergedItem.source == "magic" and mergedItem.bag_index then
            local bag_index = mergedItem.bag_index
            if mergedItem.magic and mergedItem.magic ~= false then
                if TBoN.Magic.Table.bag_magic_data[bag_index].magic_id ~= mergedItem.magic then
                    TBoN.Magic.Table.bag_magic_data[bag_index].magic_id = mergedItem.magic
                    TBoN.Magic.Table.bag_magic_data[bag_index].current_uses = -1
                    TBoN.Magic.Table.bag_magic_data[bag_index].max_uses = -1
                end
            else
                TBoN.Magic.Table.bag_magic_data[bag_index].magic_id = false
                TBoN.Magic.Table.bag_magic_data[bag_index].current_uses = 0
                TBoN.Magic.Table.bag_magic_data[bag_index].max_uses = 0
            end
        elseif mergedItem.source == "gun" and mergedItem.gunIndex and mergedItem.slotIndex then
            local gunIndex = mergedItem.gunIndex
            local slotIndex = mergedItem.slotIndex
            if mergedItem.magic and mergedItem.magic ~= false then
                if TBoN.Gun.Table.gun_magic_data[gunIndex][slotIndex].magic_id ~= mergedItem.magic then
                    TBoN.Gun.Table.gun_magic_data[gunIndex][slotIndex].magic_id = mergedItem.magic
                    TBoN.Gun.Table.gun_magic_data[gunIndex][slotIndex].current_uses = -1
                    TBoN.Gun.Table.gun_magic_data[gunIndex][slotIndex].max_uses = -1
                end
            else
                TBoN.Gun.Table.gun_magic_data[gunIndex][slotIndex].magic_id = false
                TBoN.Gun.Table.gun_magic_data[gunIndex][slotIndex].current_uses = 0
                TBoN.Gun.Table.gun_magic_data[gunIndex][slotIndex].max_uses = 0
            end
        end
    end
end

function TBoN.UI.Function.Custom.deepCopy(orig)
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

function TBoN.UI.Function.Custom.GetMousePosItemInfo(mouse_pos)
    local result = {
        type = 0,
        item_name = nil,
        item_index = nil,
        gun_index = nil,
        spell_slot_index = nil,
        spell_info = nil
    }
    
    for i, gun in pairs(TBoN.UI.Table.gun_render_table) do
        if TBoN.UI.Function.Custom.Mouse_Pos_But_Check(mouse_pos, gun.pos) then
            result.type = 1
            result.gun_index = i
            if TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name then
                result.item_name = TBoN.Gun.Table.gun_info[i].name
            end
            return result
        end
    end
    
    for i, item in pairs(TBoN.UI.Table.item) do
        if TBoN.UI.Function.Custom.Mouse_Pos_But_Check(mouse_pos, item.pos) then
            result.type = 2
            result.item_index = i
            if item.item then
                result.item_name = item.item
            end
            return result
        end
    end
    
    for i, magic in pairs(TBoN.UI.Table.bag_magic_render_table) do
        if TBoN.UI.Function.Custom.Mouse_Pos_But_Check(mouse_pos, magic.pos) then
            result.type = 3
            result.spell_slot_index = i
            local magic_data = TBoN.Magic.Table.bag_magic_data[i]
            if magic_data and magic_data.magic_id and magic_data.magic_id ~= false then
                result.item_name = magic_data.magic_id
                result.spell_info = TBoN.UI.Function.Custom.GetSpellInfo(magic_data.magic_id)
            end
            return result
        end
    end
    
    for gunIndex, gun in pairs(TBoN.UI.Table.gun_render_table) do
        if TBoN.Gun.Table.gun_info[gunIndex] and TBoN.Gun.Table.gun_info[gunIndex].name then
            local capacity = TBoN.Gun.Table.gun_info[gunIndex].capacity or 0
            for k = 1, capacity do
                local magicSlot = TBoN.UI.Table.gun_magic_render_table[gunIndex] and TBoN.UI.Table.gun_magic_render_table[gunIndex][k]
                if magicSlot and TBoN.UI.Function.Custom.Mouse_Pos_But_Check(mouse_pos, magicSlot.pos) then
                    result.type = 3
                    result.gun_index = gunIndex
                    result.spell_slot_index = k
                    local spell_data = TBoN.Gun.Table.gun_magic_data[gunIndex] and TBoN.Gun.Table.gun_magic_data[gunIndex][k]
                    if spell_data and spell_data.magic_id and spell_data.magic_id ~= false then
                        result.item_name = spell_data.magic_id
                        result.spell_info = TBoN.UI.Function.Custom.GetSpellInfo(spell_data.magic_id)
                    end
                    return result
                end
            end
        end
    end
    
    return result
end

function TBoN.UI.Function.Custom.GetSpellInfo(spell_name)
    if not spell_name or not TBoN.UI.Table.actions_map[spell_name] then
        return nil
    end
    
    local spell_info = actions[TBoN.UI.Table.actions_map[spell_name]]
    if not spell_info then
        return nil
    end
    
    local old_c = TBoN.UI.Function.Custom.deepCopy(c)
    local old_proj_modifier = TBoN.UI.Function.Custom.deepCopy(proj_modifier)
    
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
    
    if spell_info.action then
        spell_info.action()
    end
    
    local result = {
        name = spell_name,
        type = spell_info.type,
        mana_cost = spell_info.mana or 0,
        fire_rate_wait = c.fire_rate_wait,
        cast_delay = c.fire_rate_wait,
        recharge_time = spell_info.recharge_time or 0,
        speed_multiplier = c.speed_multiplier,
        damage = c.damage,
        speed = c.speed,
        lifetime_add = c.lifetime_add,
        spread_degrees = c.spread_degrees,
        recoil_knockback = c.recoil_knockback,
        damage_critical_chance = c.damage_critical_chance,
        damage_projectile_add = c.damage_projectile_add,
        modifiers = TBoN.UI.Function.Custom.deepCopy(proj_modifier),
    }
    
    if spell_info.type == "ACTION_TYPE_PROJECTILE" or spell_info.type == "ACTION_TYPE_STATIC_PROJECTILE" then
        result.damage = c.damage
        c.speed = c.speed
        result.speed_multiplier = c.speed_multiplier
        result.spread_degrees = c.spread_degrees
        result.recoil_knockback = c.recoil_knockback
        result.damage_critical_chance = c.damage_critical_chance
    end
    
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
    
    c = old_c
    proj_modifier = old_proj_modifier
    
    return result
end

function TBoN.UI.Function.Custom.Load_Anm2(sprite, string)
    if type(sprite) == "table" then
        if string == "" then
            for _, s in pairs(sprite) do
                s.sprite:Load(s.load,true)
                s.sprite:Play("Idle", true)
            end
        else
            for _, s in pairs(sprite) do
                s.sprite:Load(string..s.name..".anm2",true)
                s.sprite:Play("Idle", true)
            end
        end
    else
        sprite:Load(string,true)
        sprite:Play("Idle", true)
    end
end

function TBoN.UI.Function.Custom.Render_Anm2(sprite,table,check)
    for i,p in pairs(table) do
        if not check then
            sprite:Render(p.pos)
        else

        end
    end
end