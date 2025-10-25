function TBoN.Render.Function.Custom.Mouse_Pos_But_Check(Mouse_Pos, Aim_pos)
    mous_pos = Isaac.WorldToScreen(Mouse_Pos)
    if mous_pos.X >= Aim_pos.X and mous_pos.X <= Aim_pos.X + 20 then
        if mous_pos.Y >= Aim_pos.Y and mous_pos.Y <= Aim_pos.Y + 20 then
            return true
        else
            return false
        end
    end
end

function TBoN.Render.Function.Custom.Mouse_Pos_Pos_Check(Mouse_Pos, table, i)
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

function TBoN.Render.Function.Custom.swapGunGroups(gunTable, i, j)
    TBoN.Gun.Table.gun_info[i], TBoN.Gun.Table.gun_info[j] = TBoN.Gun.Table.gun_info[j], TBoN.Gun.Table.gun_info[i]
    TBoN.Gun.Table.gun_magic_data[i], TBoN.Gun.Table.gun_magic_data[j] = TBoN.Gun.Table.gun_magic_data[j], TBoN.Gun.Table.gun_magic_data[i]
end

function TBoN.Render.Function.Custom.Merge_Magic(magicTable, gunTable)
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
        local gunMagicSlots = TBoN.Render.Table.gun_magic_render_table[gunIndex] or {}

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

function TBoN.Render.Function.Custom.Split_Merged_To_Original(mergedTable)
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

function TBoN.Render.Function.Custom.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[TBoN.Render.Function.Custom.deepCopy(orig_key)] = TBoN.Render.Function.Custom.deepCopy(orig_value)
        end
        setmetatable(copy, TBoN.Render.Function.Custom.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function TBoN.Render.Function.Custom.Get_Mouse_Pos_Item_Info(mouse_pos)
    local result = {
        type = 0,
        item_name = nil,
        item_index = nil,
        gun_index = nil,
        spell_slot_index = nil,
        spell_info = nil
    }
    local function set_spell_info(magic_id)
        if magic_id and magic_id ~= false then
            result.item_name = magic_id
            result.spell_info = TBoN.Render.Function.Custom.Get_Spell_Info(magic_id)
        end
    end
    for i, gun in pairs(TBoN.Render.Table.gun_render_table) do
        if TBoN.Render.Function.Custom.Mouse_Pos_But_Check(mouse_pos, gun.pos) then
            result.type = 1
            result.gun_index = i
            result.item_name = TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name or nil
            return result
        end
    end
    for i, item in pairs(TBoN.Render.Table.item) do
        if TBoN.Render.Function.Custom.Mouse_Pos_But_Check(mouse_pos, item.pos) then
            result.type = 2
            result.item_index = i
            result.item_name = item.item or nil
            return result
        end
    end
    for i, magic in pairs(TBoN.Render.Table.bag_magic_render_table) do
        if TBoN.Render.Function.Custom.Mouse_Pos_But_Check(mouse_pos, magic.pos) then
            result.type = 3
            result.spell_slot_index = i
            set_spell_info(TBoN.Magic.Table.bag_magic_data[i] and TBoN.Magic.Table.bag_magic_data[i].magic_id)
            return result
        end
    end
    for gunIndex, gun in pairs(TBoN.Render.Table.gun_magic_render_table) do
        if TBoN.Gun.Table.gun_info[gunIndex] and TBoN.Gun.Table.gun_info[gunIndex].name then
            local capacity = TBoN.Gun.Table.gun_info[gunIndex].capacity or 0
            for k = 1, capacity do
                local magicSlot = TBoN.Render.Table.gun_magic_render_table[gunIndex] and TBoN.Render.Table.gun_magic_render_table[gunIndex][k]
                if magicSlot and TBoN.Render.Function.Custom.Mouse_Pos_But_Check(mouse_pos, magicSlot.pos) then
                    result.type = 3
                    result.gun_index = gunIndex
                    result.spell_slot_index = k
                    set_spell_info(TBoN.Gun.Table.gun_magic_data[gunIndex] and TBoN.Gun.Table.gun_magic_data[gunIndex][k] and TBoN.Gun.Table.gun_magic_data[gunIndex][k].magic_id)
                    return result
                end
            end
        end
    end
    return result
end

function TBoN.Render.Function.Custom.Get_Spell_Info(spell_name)
    if not spell_name then return nil end
    local idx = TBoN.Render.Table.actions_map[spell_name]
    local spell_info = idx and actions[idx] or nil
    if not spell_info then return nil end
    local old_c = TBoN.Render.Function.Custom.deepCopy(c)
    local old_proj_modifier = TBoN.Render.Function.Custom.deepCopy(proj_modifier)
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
    if spell_info.action then spell_info.action() end
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
        modifiers = TBoN.Render.Function.Custom.deepCopy(proj_modifier),
    }
    if spell_info.type == "ACTION_TYPE_PROJECTILE" or spell_info.type == "ACTION_TYPE_STATIC_PROJECTILE" then
        result.damage = c.damage
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

function TBoN.Render.Function.Custom.Render_Info(info_table, render_table, mouse_pos)
    local function render_attrs(attrs, icon_table, data, y_offset, label_scale, value_scale)
        for _, attr in ipairs(attrs) do
            local icon = icon_table[attr.icon_idx]
            if icon then
                icon.sprite:Render(mouse_pos + Vector(20, y_offset + 2))
                TBoN.Render.Function.Font.font_cn:DrawStringScaledUTF8(attr.label, mouse_pos.X + 35, mouse_pos.Y + y_offset, label_scale, label_scale, KColor(1,1,1,0.9), 0)
                TBoN.Render.Function.Font.font_cn:DrawStringScaledUTF8(attr.format and attr.format(data[attr.key]) or attr.value, mouse_pos.X + 75, mouse_pos.Y + y_offset, value_scale, value_scale, KColor(1,1,0.9,0.9), 0)
                y_offset = y_offset + 11
            end
        end
        return y_offset
    end
    if info_table.type == 1 and Options.Language == "zh" then
        local gun_index = info_table.gun_index
        if gun_index and TBoN.Gun.Table.gun_info[gun_index] then
            local gun_info = TBoN.Gun.Table.gun_info[gun_index]
            local y_offset = 11
            local attrs = {
                {key = "shuffle", icon_idx = 1, label = "乱序", format = function(v) return v and "是" or "否" end},
                {key = "capacity", icon_idx = 2, label = "容量", format = tostring},
                {key = "cast_delay", icon_idx = 3, label = "施法延迟", format = tostring},
                {key = "recharge_time", icon_idx = 4, label = "充能时间", format = tostring},
                {key = "mana_max", icon_idx = 5, label = "最大魔力", format = tostring},
                {key = "mana_charge_speed", icon_idx = 6, label = "魔力恢复", format = tostring},
                {key = "spread_degrees", icon_idx = 7, label = "散射度", format = tostring}
            }
            TBoN.Render.Function.Sprite.gun_info_bg:Render(mouse_pos + Vector(15,10))
            render_attrs(attrs, TBoN.Render.Table.gun_info_render_table, gun_info, y_offset, 0.8, 0.8)
        end
    elseif info_table.type == 3 and Options.Language == "zh" then
        local spell_info = info_table.spell_info
        if spell_info then
            local y_offset = 11
            TBoN.Render.Function.Sprite.magic_info_bg:Render(mouse_pos + Vector(15,10))

            local name_key = "action_" .. string.lower(spell_info.name or "")
            local desc_key = "actiondesc_" .. string.lower(spell_info.name or "")
            local chinese_name = TBoN.Render.Table.Translations.Action[name_key] or spell_info.name or "未知法术"
            local chinese_desc = TBoN.Render.Table.Translations.ActionDesc[desc_key]

            TBoN.Render.Function.Font.font_cn:DrawStringScaledUTF8(chinese_name, mouse_pos.X + 20, mouse_pos.Y + y_offset, 0.9, 0.9, KColor(1, 1, 0, 1), 0)
            y_offset = y_offset + 13

            if chinese_desc then
                TBoN.Render.Function.Font.font_cn:DrawStringScaledUTF8(chinese_desc, mouse_pos.X + 20, mouse_pos.Y + y_offset, 0.7, 0.7, KColor(0.9, 0.9, 0.9, 1), 0)
                y_offset = y_offset + 11
            end

            local spell_attrs = {
                {icon_idx = 1, label = "类型", value = TBoN.Render.Table.TYPE_NAMES[spell_info.type] or spell_info.type or "未知"},
            }
            if spell_info.mana_cost and spell_info.mana_cost > 0 then
                table.insert(spell_attrs, {icon_idx = 2, label = "魔力", value = tostring(spell_info.mana_cost)})
            end
            if spell_info.damage and spell_info.damage ~= 1 then
                table.insert(spell_attrs, {icon_idx = 3, label = "伤害", value = string.format("%.1f", spell_info.damage)})
            end
            if spell_info.speed_multiplier and spell_info.speed_multiplier ~= 1 then
                table.insert(spell_attrs, {icon_idx = 4, label = "速度", value = "x" .. string.format("%.2f", spell_info.speed_multiplier)})
            end
            if spell_info.spread_degrees and spell_info.spread_degrees ~= 0 then
                table.insert(spell_attrs, {icon_idx = 5, label = "散射", value = string.format("%.1f°", spell_info.spread_degrees)})
            end
            if spell_info.fire_rate_wait and spell_info.fire_rate_wait ~= 0 then
                table.insert(spell_attrs, {icon_idx = 6, label = "施法延迟", value = tostring(spell_info.fire_rate_wait)})
            end
            if spell_info.recharge_time and spell_info.recharge_time > 0 then
                table.insert(spell_attrs, {icon_idx = 7, label = "充能", value = tostring(spell_info.recharge_time)})
            end

            render_attrs(spell_attrs, TBoN.Render.Table.magic_info_render_table, spell_info, y_offset, 0.75, 0.75)
        end
    end
end

function TBoN.Render.Function.Custom.Load_Anm2(sprite, string)
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

function TBoN.Render.Function.Custom.Render_Anm2(sprite,table,check)
    for i,p in pairs(table) do
        if not check then
            sprite:Render(p.pos)
        else

        end
    end
end