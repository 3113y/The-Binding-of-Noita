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
    -- 交换gun_info
    TBoN.Gun.Table.gun_info[i], TBoN.Gun.Table.gun_info[j] = TBoN.Gun.Table.gun_info[j], TBoN.Gun.Table.gun_info[i]
    -- 交换gun_magic_data
    TBoN.Gun.Table.gun_magic_data[i], TBoN.Gun.Table.gun_magic_data[j] = TBoN.Gun.Table.gun_magic_data[j], TBoN.Gun.Table.gun_magic_data[i]
    -- 交换gun_states
    TBoN.Gun.Table.gun_states[i], TBoN.Gun.Table.gun_states[j] = TBoN.Gun.Table.gun_states[j], TBoN.Gun.Table.gun_states[i]
    
    -- 更新交换后的两个法杖的sprite
    for _, gun_index in ipairs({i, j}) do
        if TBoN.Gun.Table.gun_info[gun_index] and TBoN.Gun.Table.gun_info[gun_index].name then
            -- 更新法杖sprite
            if TBoN.Render.Table.gun_render_table[gun_index] then
                TBoN.Render.Table.gun_render_table[gun_index].sprite:Load(
                    "gfx/gun/" .. TBoN.Gun.Table.gun_info[gun_index].name .. ".anm2",
                    true)
                TBoN.Render.Table.gun_render_table[gun_index].sprite:Play("Idle", true)
            end
            
            -- 更新法杖内所有法术sprite
            local capacity = TBoN.Gun.Table.gun_info[gun_index].capacity or 0
            for slot_index = 1, capacity do
                local magic_data = TBoN.Gun.Table.gun_magic_data[gun_index][slot_index]
                if magic_data and magic_data.magic_id and magic_data.magic_id ~= false then
                    local magicSlot = TBoN.Render.Table.gun_magic_render_table[gun_index][slot_index]
                    if magicSlot then
                        magicSlot.sprite:Load(
                            "gfx/ui/gun_actions/" .. string.lower(magic_data.magic_id) .. ".anm2",
                            true)
                        magicSlot.sprite:Play("Idle", true)
                    end
                end
            end
        end
    end
end

function TBoN.Render.Function.Custom.DropWand(gun_index)
    local wand_name = TBoN.Gun.Table.gun_info[gun_index].name
    if not wand_name or wand_name == false then
        return
    end
    
    -- 提取wand_id (wand_0000 -> 0)
    local wand_id = tonumber(string.match(wand_name, "wand_(%d+)")) or 0
    
    -- 保存法杖完整数据
    local wand_data = {
        name = TBoN.Gun.Table.gun_info[gun_index].name,
        shuffle = TBoN.Gun.Table.gun_info[gun_index].shuffle,
        capacity = TBoN.Gun.Table.gun_info[gun_index].capacity,
        cast_delay = TBoN.Gun.Table.gun_info[gun_index].cast_delay,
        recharge_time = TBoN.Gun.Table.gun_info[gun_index].recharge_time,
        mana_max = TBoN.Gun.Table.gun_info[gun_index].mana_max,
        mana_charge_speed = TBoN.Gun.Table.gun_info[gun_index].mana_charge_speed,
        spread_degrees = TBoN.Gun.Table.gun_info[gun_index].spread_degrees,
        always_cast = TBoN.Gun.Table.gun_info[gun_index].always_cast,
    }
    
    -- 保存法术槽数据（只遍历 capacity 范围）
    local spell_slots = {}
    if TBoN.Gun.Table.gun_magic_data[gun_index] then
        for slot_index = 1, wand_data.capacity do
            local magic_data = TBoN.Gun.Table.gun_magic_data[gun_index][slot_index]
            if magic_data then
                table.insert(spell_slots, {
                    magic_id = magic_data.magic_id,
                    current_uses = magic_data.current_uses,
                    max_uses = magic_data.max_uses,
                })
            end
        end
    end
    
    -- 将数据存储到临时表，等待拾取物生成
    if not TBoN.World.Table.dropped_wand_temp then
        TBoN.World.Table.dropped_wand_temp = {}
    end
    TBoN.World.Table.dropped_wand_temp[wand_id] = {
        wand_data = wand_data,
        spell_slots = spell_slots,
        timestamp = Game():GetFrameCount(),
        player_dropped = true  -- 标记为玩家扔下的法杖
    }
    
    -- 生成法杖拾取物（不在这里加载sprite，由Init回调处理）
    local entity = Isaac.Spawn(5, TBoN.Magic.Info.Variant.Pickup_Wand, wand_id, Isaac.GetPlayer().Position + 70 * TBoN.Gun.Function.Vector.Aim_direc, Vector(0, 0), nil)
    
    -- 同时设置wand_hash以便立即访问
    local pickup_index = GetPtrHash(entity)
    TBoN.World.Table.wand_hash[pickup_index] = {
        wand_data = wand_data,
        spell_slots = spell_slots
    }
    
    local sprite = entity:GetSprite()
    sprite:Load("gfx/gun/" .. wand_data.name .. ".anm2", true)
    sprite:Play("Idle", true)
    
    -- 清空法杖槽位 (使用 DeepCopy 确保数据结构一致)
    TBoN.Gun.Table.gun_info[gun_index] = TBoN.Data.Function.Custom.Deep_Copy(TBoN.Data.Table.gun_info_init[gun_index])
    TBoN.Gun.Table.gun_magic_data[gun_index] = TBoN.Data.Function.Custom.Deep_Copy(TBoN.Data.Table.gun_magic_data_init[gun_index])
    
    -- 重置法杖状态
    TBoN.Gun.Table.gun_states[gun_index] = {
        mana = 0,
        current_mana = 0,
        mana_max = 0,
        cast_delay_current = 0,
        recharge_time_current = 0,
        cast_cooldown = 0,
        recharge_cooldown = 0,
        deck_index = 1,
        deck = {},
        discard_pile = {},
        always_cast_hand = {},
        always_cast_index = 1,
        wrapped_around = false,
    }
end

function TBoN.Render.Function.Custom.Merge_Magic(magicTable, gunTable)
    local merged = {}

    for i, magicSlot in pairs(magicTable) do
        local magic_data = TBoN.Magic.Table.bag_magic_data[i]
        if magic_data then
            local magic_id = magic_data.magic_id
            table.insert(merged, {
                pos = magicSlot.pos,
                sprite = magicSlot.sprite,
                magic = magic_id == false and false or magic_id,
                current_uses = magic_data.current_uses or -1,
                max_uses = magic_data.max_uses or -1,
                source = "magic",
                bag_index = i
            })
        end
    end

    for gunIndex, gunItem in pairs(gunTable) do
        local gun_info = TBoN.Gun.Table.gun_info[gunIndex]
        if gun_info then
            local capacity = gun_info.capacity or 0
            local gunMagicSlots = TBoN.Render.Table.gun_magic_render_table[gunIndex] or {}
            local gun_magic_data = TBoN.Gun.Table.gun_magic_data[gunIndex]

            if gun_magic_data then
                for i = 1, capacity do
                    local magicSlot = gunMagicSlots[i]
                    if magicSlot then
                        local magic_data = gun_magic_data[i]
                        if magic_data then
                            local magic_id = magic_data.magic_id
                            table.insert(merged, {
                                pos = magicSlot.pos,
                                sprite = magicSlot.sprite,
                                magic = magic_id == false and false or magic_id,
                                current_uses = magic_data.current_uses or -1,
                                max_uses = magic_data.max_uses or -1,
                                source = "gun",
                                gunIndex = gunIndex,
                                slotIndex = i
                            })
                        end
                    end
                end
            end
        end
    end

    return merged
end

function TBoN.Render.Function.Custom.Split_Merged_To_Original(mergedTable)
    -- 跟踪哪些法杖被修改了
    local modified_guns = {}
    
    for i, mergedItem in ipairs(mergedTable) do
        if mergedItem.source == "magic" and mergedItem.bag_index then
            local bag_index = mergedItem.bag_index
            local bag_data = TBoN.Magic.Table.bag_magic_data[bag_index]
            if bag_data then
                local old_magic_id = bag_data.magic_id
                if mergedItem.magic and mergedItem.magic ~= false then
                    if old_magic_id ~= mergedItem.magic then
                        bag_data.magic_id = mergedItem.magic
                        -- 交换时携带使用次数信息
                        bag_data.current_uses = mergedItem.current_uses or -1
                        bag_data.max_uses = mergedItem.max_uses or -1
                        -- 只更新这个法术sprite
                        if TBoN.Render.Table.bag_magic_render_table[bag_index] then
                            TBoN.Render.Table.bag_magic_render_table[bag_index].sprite:Load(
                                "gfx/ui/gun_actions/" .. string.lower(mergedItem.magic) .. ".anm2",
                                true)
                            TBoN.Render.Table.bag_magic_render_table[bag_index].sprite:Play("Idle", true)
                        end
                    end
                else
                    bag_data.magic_id = false
                    bag_data.current_uses = 0
                    bag_data.max_uses = 0
                end
            end
        elseif mergedItem.source == "gun" and mergedItem.gunIndex and mergedItem.slotIndex then
            local gunIndex = mergedItem.gunIndex
            local slotIndex = mergedItem.slotIndex
            local gun_magic_data = TBoN.Gun.Table.gun_magic_data[gunIndex]
            if gun_magic_data and gun_magic_data[slotIndex] then
                local old_magic_id = gun_magic_data[slotIndex].magic_id
                if mergedItem.magic and mergedItem.magic ~= false then
                    if old_magic_id ~= mergedItem.magic then
                        gun_magic_data[slotIndex].magic_id = mergedItem.magic
                        -- 交换时携带使用次数信息
                        gun_magic_data[slotIndex].current_uses = mergedItem.current_uses or -1
                        gun_magic_data[slotIndex].max_uses = mergedItem.max_uses or -1
                        -- 只更新这个法术sprite
                        if TBoN.Render.Table.gun_magic_render_table[gunIndex] and 
                           TBoN.Render.Table.gun_magic_render_table[gunIndex][slotIndex] then
                            TBoN.Render.Table.gun_magic_render_table[gunIndex][slotIndex].sprite:Load(
                                "gfx/ui/gun_actions/" .. string.lower(mergedItem.magic) .. ".anm2",
                                true)
                            TBoN.Render.Table.gun_magic_render_table[gunIndex][slotIndex].sprite:Play("Idle", true)
                        end
                        -- 标记这个法杖需要重新初始化
                        modified_guns[gunIndex] = true
                    end
                else
                    gun_magic_data[slotIndex].magic_id = false
                    gun_magic_data[slotIndex].current_uses = 0
                    gun_magic_data[slotIndex].max_uses = 0
                    -- 标记这个法杖需要重新初始化
                    modified_guns[gunIndex] = true
                end
            end
        end
    end
    
    -- 重新初始化所有被修改的法杖的 deck
    for gun_index, _ in pairs(modified_guns) do
        local state = TBoN.Gun.Table.gun_states[gun_index]
        local gun_info = TBoN.Gun.Table.gun_info[gun_index]
        if state and gun_info and gun_info.name then
            -- 清空当前牌库和弃牌堆
            state.deck = {}
            state.discard_pile = {}
            
            -- 重新构建牌库
            local magic_data = TBoN.Gun.Table.gun_magic_data[gun_index]
            if magic_data then
                for _, spell_entry in ipairs(magic_data) do
                    if spell_entry and spell_entry.magic_id and spell_entry.magic_id ~= false then
                        table.insert(state.deck, spell_entry.magic_id)
                    end
                end
            end
            
            -- 如果需要洗牌
            if gun_info.shuffle and #state.deck > 0 then
                local rng = RNG()
                rng:SetSeed(Game():GetSeeds():GetNextSeed(), 35)
                for j = #state.deck, 2, -1 do
                    local k = rng:RandomInt(j-1) + 1
                    state.deck[j], state.deck[k] = state.deck[k], state.deck[j]
                end
            end
            
            -- 重置状态
            state.always_cast_index = 1
            state.wrapped_around = false
        end
    end
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
    
    -- 特殊处理 DAMAGE_FOREVER - 在执行action前就返回，避免访问mana导致nil报错
    if spell_name == "DAMAGE_FOREVER" then
        return {
            name = spell_name,
            type = spell_info.type,
            mana_cost = spell_info.mana or 0,
            fire_rate_wait = 15,
            cast_delay = 15,
            recharge_time = 10,
            speed_multiplier = 1,
            damage = 1,
            speed = 1,
            lifetime = 0,
            lifetime_add = 0,
            spread_degrees = 0,
            recoil_knockback = 0,
            damage_critical_chance = 0,
            damage_projectile_add = 0,
            modifiers = {},
        }
    end
    
    local old_c = TBoN.Data.Function.Custom.Deep_Copy(c)
    local old_proj_modifier = TBoN.Data.Function.Custom.Deep_Copy(proj_modifier)
    c = {
        fire_rate_wait = 0,
        entity_type = nil,
        entity_variant = nil,
        speed_multiplier = 1,
        damage = 1,
        screenshake = 0,
        lifetime = 0,
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
        lifetime = c.lifetime,
        lifetime_add = c.lifetime_add,
        spread_degrees = c.spread_degrees,
        recoil_knockback = c.recoil_knockback,
        damage_critical_chance = c.damage_critical_chance,
        damage_projectile_add = c.damage_projectile_add,
        modifiers = TBoN.Data.Function.Custom.Deep_Copy(proj_modifier),
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
            lifetime = c.lifetime ~= 0 and c.lifetime or nil,
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
            render_attrs(attrs, TBoN.Render.Table.gun_des_render_table, gun_info, y_offset, 0.8, 0.8)
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

            render_attrs(spell_attrs, TBoN.Render.Table.magic_des_render_table, spell_info, y_offset, 0.75, 0.75)
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

-- 渲染法术剩余使用次数
-- pos: 法术槽位置, current_uses: 当前使用次数
function TBoN.Render.Function.Custom.Render_Spell_Uses_Count(pos, current_uses)
    if current_uses and current_uses >= 0 then
        TBoN.Render.Function.Font.font_num:DrawString(
            tostring(current_uses),
            pos.X + 14,
            pos.Y + 7,
            KColor.White,
            0
        )
    end
end

-- 获取法杖中剩余使用次数最少的法术次数
-- 返回值：-1表示无限使用或无有限法术，>0表示最小使用次数
function TBoN.Render.Function.Custom.Get_Wand_Min_Spell_Uses(gun_index)
    local min_uses = -1  -- -1表示无限使用
    if TBoN.Gun.Table.gun_magic_data[gun_index] then
        for _, spell_data in ipairs(TBoN.Gun.Table.gun_magic_data[gun_index]) do
            if spell_data and spell_data.magic_id and spell_data.magic_id ~= false then
                local current_uses = spell_data.current_uses or -1
                -- 跳过无限使用的法术(-1)和空槽位
                if current_uses >= 0 then
                    if min_uses == -1 or current_uses < min_uses then
                        min_uses = current_uses
                    end
                end
            end
        end
    end
    return min_uses
end

function TBoN.Render.Function.Custom.Render_Anm2(sprite,table,check)
    for i,p in pairs(table) do
        if not check then
            sprite:Render(p.pos)
        else

        end
    end
end