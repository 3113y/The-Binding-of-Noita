function Mouse_Pos_But_Check(Mouse_Pos, Aim_pos) --检测鼠标位置（即在某小格）
    mous_pos = Isaac.WorldToScreen(Mouse_Pos)
    if mous_pos.X >= Aim_pos.X and mous_pos.X <= Aim_pos.X + 20 then
        if mous_pos.Y >= Aim_pos.Y and mous_pos.Y <= Aim_pos.Y + 20 then
            return true
        else
            return false
        end
    end
end

function Mouse_Pos_Pos_Check(Mouse_Pos, table, i) --检测鼠标位置（即在某区域）
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

function swapGunGroups(gunTable, i, j)
    -- 边界检查
    local gunI = gunTable[i]
    local gunJ = gunTable[j]
    
    -- 交换gun_info中的所有信息
    gun_info[i], gun_info[j] = gun_info[j], gun_info[i]

    -- 交换magic数据
    gun_magic_data[i], gun_magic_data[j] = gun_magic_data[j], gun_magic_data[i]
end

function mergeMagicAndGunMagic(magicTable, gunTable)
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
        local capacity = gun_info[gunIndex].capacity or 0
        local gunMagicSlots = gun_magic_render_table[gunIndex] or {}

        -- 只合并前capacity个法术槽
        for i = 1, capacity do
            local magicSlot = gunMagicSlots[i]
            if magicSlot then
                table.insert(merged, {
                    pos = magicSlot.pos,
                    sprite = magicSlot.sprite,
                    magic = gun_magic_data[gunIndex][i],
                    source = "gun",
                    gunIndex = gunIndex
                })
            end
        end
    end

    return merged
end

function splitMergedToOriginal(mergedTable, originalMagic, originalGun)
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
        local capacity = gun_info[gunIndex].capacity or 0
        for i = 1, capacity do
            local mergedItem = mergedTable[gunPos]
            if mergedItem and mergedItem.source == "gun" and mergedItem.gunIndex == gunIndex then
                gun_magic_data[gunIndex][i] = mergedItem.magic
                gunPos = gunPos + 1
            else
                gun_magic_data[gunIndex][i] = false
            end
        end
    end
end

function deepCopy(orig) -- 深拷贝表的工具函数
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end
