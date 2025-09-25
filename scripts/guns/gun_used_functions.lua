function draw_actions(i,bool)
    draw_act = draw_act + i
end
function Get_Magic_Table_Of_Current_Gun(magic_table, gun_info_table, gun_index)
    if gun_index>4 then
        return {}
    end
    local result = {}
    if gun_info_table[gun_index].shuffle then
        local temp = {}
        for i, magic in pairs(magic_table[gun_index]) do
            if magic then
                table.insert(temp, magic)
            end
        end
        local rng = Isaac.GetPlayer():GetCollectibleRNG(1)
        for i = #temp, 2, -1 do
            local j = rng:RandomInt(i) + 1
            temp[i], temp[j] = temp[j], temp[i]
        end
        local t = 1
        for _, magic in ipairs(temp) do
            result[t] = magic
            t = t + 1
        end
    else
        local t = 1
        for _, magic in pairs(magic_table[gun_index]) do
            if magic then
                result[t] = magic
                t = t + 1
            end
        end
    end
    return result
end
function Get_Next_Shutted_Magic_Info(new_magic_table,gun)
    local draw_act = 1
    local c = {}
    for i, magic in pairs(magic_table) do
        if draw_act >= 1 then
        actions[actions_map[magic]].action()
        draw_act = draw_act - 1
        end
    end
    return c
end