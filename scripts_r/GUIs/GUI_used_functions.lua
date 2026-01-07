-- GUI 使用的函数
-- 包含所有GUI相关的逻辑函数

TBoN.GUI = TBoN.GUI or {}
TBoN.GUI.Function = TBoN.GUI.Function or {}
TBoN.GUI.Function.Custom = TBoN.GUI.Function.Custom or {}

-- ==================== 辅助函数 ====================

-- 获取玩家实体
function TBoN.GUI.Function.Custom.Get_Player()
    return Isaac.GetPlayer(0)
end

-- 生成法术到背包
function TBoN.GUI.Function.Custom.Spawn_Spell_To_Inventory(spell_id, current_uses, max_uses)
    -- 查找空槽位
    local empty_slot = nil
    for i = 1, #TBoN.Magic.Table.bag_magic_data do
        if not TBoN.Magic.Table.bag_magic_data[i].magic_id or 
           TBoN.Magic.Table.bag_magic_data[i].magic_id == false then
            empty_slot = i
            break
        end
    end
    
    if empty_slot then
        TBoN.Magic.Table.bag_magic_data[empty_slot] = {
            magic_id = spell_id,
            current_uses = current_uses,
            max_uses = max_uses
        }
        
        -- 重新加载sprite
        if TBoN.Render.Table.bag_magic_render_table and TBoN.Render.Table.bag_magic_render_table[empty_slot] then
            local sprite = TBoN.Render.Table.bag_magic_render_table[empty_slot].sprite
            if sprite then
                sprite:Load("gfx/ui/gun_actions/" .. string.lower(spell_id) .. ".anm2", true)
                sprite:Play("Idle", true)
            end
        end
        
        -- 设置需要重新加载anm2标志
        if TBoN.Render and TBoN.Render.Variable and TBoN.Render.Variable.Bool then
            TBoN.Render.Variable.Bool.anm_load = true
        end
        
        Isaac.DebugString("TBoN GUI: 已添加法术 " .. spell_id .. " 到背包槽位 " .. empty_slot)
        ImGui.PushNotification("法术已添加到背包！", ImGuiNotificationType.SUCCESS, 3000)
        return true
    else
        Isaac.DebugString("TBoN GUI: 背包已满，无法添加法术")
        ImGui.PushNotification("背包已满，无法添加法术！", ImGuiNotificationType.ERROR, 3000)
        return false
    end
end

-- 生成法术到世界（玩家脚下）
function TBoN.GUI.Function.Custom.Spawn_Spell_To_World(spell_id, current_uses, max_uses)
    local player = TBoN.GUI.Function.Custom.Get_Player()
    if not player then
        Isaac.DebugString("TBoN GUI: 无法获取玩家实体")
        ImGui.PushNotification("无法获取玩家实体！", ImGuiNotificationType.ERROR, 3000)
        return false
    end
    
    -- 使用封装的Drop_Spell函数生成法术
    local entity = TBoN.Render.Function.Custom.Drop_Spell(
        spell_id,
        nil,  -- spell_subtype 会自动计算
        current_uses,
        max_uses,
        player.Position,
        Vector(0, 0),
        false  -- 不是玩家丢弃，是GUI生成
    )
    
    if entity then
        Isaac.DebugString("TBoN GUI: 在位置 " .. tostring(player.Position) .. " 生成法术 " .. spell_id)
        ImGui.PushNotification("法术已生成！", ImGuiNotificationType.SUCCESS, 3000)
        return true
    else
        Isaac.DebugString("TBoN GUI: 生成法术失败")
        ImGui.PushNotification("生成法术失败！", ImGuiNotificationType.ERROR, 3000)
        return false
    end
end

-- 添加法杖到背包
function TBoN.GUI.Function.Custom.Add_Wand_To_Inventory(wand_data)
    -- 查找空法杖槽位 (1-4)
    local empty_slot = nil
    for i = 1, 4 do
        if not TBoN.Gun.Table.gun_info[i].name or 
           TBoN.Gun.Table.gun_info[i].name == false then
            empty_slot = i
            break
        end
    end
    
    if not empty_slot then
        Isaac.DebugString("TBoN GUI: 法杖槽位已满")
        return false
    end
    
    -- 设置法杖信息
    TBoN.Gun.Table.gun_info[empty_slot] = {
        name = wand_data.name,
        shuffle = wand_data.shuffle,
        capacity = wand_data.capacity,
        cast_delay = wand_data.cast_delay,
        recharge_time = wand_data.recharge_time,
        mana_max = wand_data.mana_max,
        mana_charge_speed = wand_data.mana_charge_speed,
        spread_degrees = wand_data.spread_degrees,
        always_cast = wand_data.always_cast ~= "" and wand_data.always_cast or nil,
    }
    
    -- 设置法杖内的法术
    TBoN.Gun.Table.gun_magic_data = TBoN.Gun.Table.gun_magic_data or {{}, {}, {}, {}}
    TBoN.Gun.Table.gun_magic_data[empty_slot] = {}
    
    for _, spell_data in ipairs(wand_data.spells) do
        table.insert(TBoN.Gun.Table.gun_magic_data[empty_slot], {
            magic_id = spell_data.id,
            current_uses = spell_data.uses,
            max_uses = spell_data.uses,
        })
    end
    
    -- 初始化法杖状态
    if TBoN.Gun.Function and TBoN.Gun.Function.Custom and 
       TBoN.Gun.Function.Custom.Initialize_All_Gun_States then
        TBoN.Gun.Function.Custom.Initialize_All_Gun_States()
    end
    
    Isaac.DebugString("TBoN GUI: 已添加法杖 '" .. wand_data.name .. "' 到槽位 " .. empty_slot)
    return true
end

-- 生成法杖到世界
function TBoN.GUI.Function.Custom.Spawn_Wand_To_World(wand_data)
    local player = TBoN.GUI.Function.Custom.Get_Player()
    if not player then
        Isaac.DebugString("TBoN GUI: 无法获取玩家实体")
        ImGui.PushNotification("无法获取玩家实体！", ImGuiNotificationType.ERROR, 3000)
        return false
    end
    
    -- 提取wand_id
    local wand_id = tonumber(string.match(wand_data.name, "wand_(%d+)")) or 0
    
    -- 准备spell_slots数据
    local spell_slots = {}
    for _, spell_data in ipairs(wand_data.spells) do
        table.insert(spell_slots, {
            magic_id = spell_data.id,
            current_uses = spell_data.uses,
            max_uses = spell_data.uses,
        })
    end
    
    -- 保存法杖信息
    TBoN.World.Function.Custom.Save_Wand_Info(wand_id, wand_data, spell_slots, false)
    
    -- 生成法杖实体
    local entity = Isaac.Spawn(5, TBoN.Magic.Info.Variant.Pickup_Wand, wand_id, 
        player.Position, Vector(0, 0), nil)
    
    if entity then
        -- 设置wand_hash
        local pickup_index = GetPtrHash(entity)
        TBoN.World.Table.wand_hash[pickup_index] = {
            wand_data = wand_data,
            spell_slots = spell_slots
        }
        
        Isaac.DebugString("TBoN GUI: 在位置 " .. tostring(player.Position) .. " 生成法杖")
        ImGui.PushNotification("法杖已生成到世界！", ImGuiNotificationType.SUCCESS, 3000)
        return true
    else
        Isaac.DebugString("TBoN GUI: 生成法杖失败")
        ImGui.PushNotification("生成法杖失败！", ImGuiNotificationType.ERROR, 3000)
        return false
    end
end

-- 更新法杖法术列表显示
function TBoN.GUI.Function.Custom.Update_Wand_Spell_List()
    if not TBoN.GUI.Table.state.initialized then return end
    
    local text = "当前法术列表:\n"
    if #TBoN.GUI.Table.state.wand.spells == 0 then
        text = text .. "(空)"
    else
        for i, spell in ipairs(TBoN.GUI.Table.state.wand.spells) do
            local uses_str = spell.uses == -1 and "∞" or tostring(spell.uses)
            text = text .. i .. ". " .. spell.id:gsub("_", " ") .. " (" .. uses_str .. ")\n"
        end
    end
    
    ImGui.UpdateText("wandSpellList", text)
end

-- ==================== GUI初始化 ====================

function TBoN.GUI.Function.Custom.Initialize_GUI()
    if TBoN.GUI.Table.state.initialized then return end
    
    local state = TBoN.GUI.Table.state
    local all_spells = TBoN.GUI.Table.all_spells
    local spell_names = TBoN.GUI.Table.spell_display_names
    
    -- 在REPENTOGON菜单栏创建菜单入口
    ImGui.CreateMenu("tbonMenu", "TBoN")
    ImGui.AddElement("tbonMenu", "tbonMenuBtn", ImGuiElement.MenuItem, "调试工具")
    
    -- 创建主窗口
    ImGui.CreateWindow("tbonDebugWindow", "TBoN - 调试工具")
    
    -- 将窗口链接到菜单按钮
    ImGui.LinkWindowToElement("tbonDebugWindow", "tbonMenuBtn")
    
    -- 添加标签栏到窗口
    ImGui.AddTabBar("tbonDebugWindow", "mainTabBar")
    
    -- ========== 法术生成器标签页 ==========
    ImGui.AddTab("mainTabBar", "spellTab", "法术生成器")
    
    -- 法术选择下拉框
    ImGui.AddText("spellTab", "选择法术:")
    ImGui.AddCombobox("spellTab", "spellSelector", "", function(index, val)
        state.spell.selected_spell_index = index + 1
        state.spell.selected_spell_id = all_spells[index + 1]
    end, spell_names, 0, false)
    
    -- 无限使用复选框
    ImGui.AddCheckbox("spellTab", "spellInfiniteUses", "无限使用", function(checked)
        state.spell.infinite_uses = checked
    end, true)
    
    -- 最大使用次数
    ImGui.AddInputInteger("spellTab", "spellMaxUses", "最大使用次数", function(val)
        state.spell.max_uses = math.max(0, val)
    end, 5, 1, 10)
    
    -- 当前使用次数
    ImGui.AddInputInteger("spellTab", "spellCurrentUses", "当前使用次数", function(val)
        state.spell.current_uses = math.max(0, math.min(val, state.spell.max_uses))
    end, 5, 1, 10)
    
    -- 分隔符
    ImGui.AddElement("spellTab", "spellSep1", ImGuiElement.Separator, "")
    
    -- 生成位置
    ImGui.AddText("spellTab", "生成位置:")
    ImGui.AddRadioButtons("spellTab", "spellLocation", function(index)
        state.spell.spawn_location = index
    end, {"添加到背包", "生成到世界"}, 1, true)
    
    -- 分隔符
    ImGui.AddElement("spellTab", "spellSep2", ImGuiElement.Separator, "")
    
    -- 生成按钮
    ImGui.AddButton("spellTab", "spellGenerateBtn", "\u{f0eb} 生成法术", function()
        local uses = state.spell.infinite_uses and -1 or state.spell.max_uses
        local current_uses = state.spell.infinite_uses and -1 or state.spell.current_uses
        
        if state.spell.spawn_location == 1 then
            TBoN.GUI.Function.Custom.Spawn_Spell_To_Inventory(state.spell.selected_spell_id, current_uses, uses)
        else
            TBoN.GUI.Function.Custom.Spawn_Spell_To_World(state.spell.selected_spell_id, current_uses, uses)
        end
    end, false)
    
    -- ========== 法杖生成器标签页 ==========
    ImGui.AddTab("mainTabBar", "wandTab", "法杖生成器")
    
    -- 法杖属性部分
    ImGui.AddText("wandTab", "法杖属性", false, "wandPropsHeader")
    ImGui.SetTextColor("wandPropsHeader", 1, 0.8, 0.2, 1)
    ImGui.AddElement("wandTab", "wandSep1", ImGuiElement.Separator, "")
    
    -- 法杖名称
    ImGui.AddInputText("wandTab", "wandName", "法杖名称", function(text)
        state.wand.name = text
    end, "自定义法杖", "输入法杖名称...")
    
    -- 洗牌模式
    ImGui.AddCheckbox("wandTab", "wandShuffle", "洗牌模式", function(checked)
        state.wand.shuffle = checked
    end, false)
    
    -- 容量
    ImGui.AddSliderInteger("wandTab", "wandCapacity", "容量 (法术槽位)", function(val)
        state.wand.capacity = val
    end, 5, 1, 26, "%d")
    
    -- 施法延迟
    ImGui.AddSliderInteger("wandTab", "wandCastDelay", "施法延迟 (帧)", function(val)
        state.wand.cast_delay = val
    end, 10, -30, 100, "%d")
    
    -- 充能时间
    ImGui.AddSliderInteger("wandTab", "wandRechargeTime", "充能时间 (帧)", function(val)
        state.wand.recharge_time = val
    end, 30, 0, 300, "%d")
    
    -- 最大魔力
    ImGui.AddSliderInteger("wandTab", "wandManaMax", "最大魔力", function(val)
        state.wand.mana_max = val
    end, 500, 0, 3000, "%d")
    
    -- 魔力充能速度
    ImGui.AddSliderInteger("wandTab", "wandManaCharge", "魔力充能速度", function(val)
        state.wand.mana_charge_speed = val
    end, 150, 0, 1000, "%d")
    
    -- 散射角度
    ImGui.AddSliderInteger("wandTab", "wandSpread", "散射角度 (度)", function(val)
        state.wand.spread_degrees = val
    end, 3, -10, 50, "%d")
    
    -- 始终施放法术
    ImGui.AddInputText("wandTab", "wandAlwaysCast", "始终施放法术", function(text)
        state.wand.always_cast = text
    end, "", "留空表示无...")
    
    ImGui.AddElement("wandTab", "wandSep2", ImGuiElement.Separator, "")
    
    -- 法杖内法术部分
    ImGui.AddText("wandTab", "\u{f0d0} 法杖内法术", false, "wandSpellsHeader")
    ImGui.SetTextColor("wandSpellsHeader", 0.5, 0.8, 1, 1)
    ImGui.AddElement("wandTab", "wandSep3", ImGuiElement.Separator, "")
    
    -- 法术列表显示（动态更新）
    ImGui.AddText("wandTab", "当前法术列表:\n(空)", false, "wandSpellList")
    
    -- 添加法术选择器
    ImGui.AddCombobox("wandTab", "wandSpellSelector", "选择法术", function(index, val)
        -- ImGui的Combobox索引从0开始，Lua数组从1开始
        state.wand.selected_spell_for_wand = index + 1
    end, spell_names, 1, false)
    
    -- 法术使用次数
    ImGui.AddInputInteger("wandTab", "wandSpellUses", "使用次数 (-1=无限)", function(val)
        state.wand.spell_max_uses = val
    end, -1, 1, 10)
    
    -- 添加法术按钮
    ImGui.AddButton("wandTab", "wandAddSpellBtn", "\u{f067} 添加法术", function()
        if #state.wand.spells < state.wand.capacity then
            table.insert(state.wand.spells, {
                id = all_spells[state.wand.selected_spell_for_wand],
                uses = state.wand.spell_max_uses
            })
            TBoN.GUI.Function.Custom.Update_Wand_Spell_List()
        else
            ImGui.PushNotification("法杖已满，无法添加更多法术！", ImGuiNotificationType.WARNING, 3000)
        end
    end, false)
    
    ImGui.AddElement("wandTab", "", ImGuiElement.SameLine, "")
    
    -- 清空法术列表按钮
    ImGui.AddButton("wandTab", "wandClearSpellsBtn", "\u{f014} 清空列表", function()
        state.wand.spells = {}
        TBoN.GUI.Function.Custom.Update_Wand_Spell_List()
    end, false)
    
    ImGui.AddElement("wandTab", "wandSep4", ImGuiElement.Separator, "")
    
    -- 生成位置
    ImGui.AddText("wandTab", "生成位置:")
    ImGui.AddRadioButtons("wandTab", "wandLocation", function(index)
        state.wand.spawn_location = index
    end, {"添加到背包", "生成到世界"}, 1, true)
    
    ImGui.AddElement("wandTab", "wandSep5", ImGuiElement.Separator, "")
    
    -- 生成法杖按钮
    ImGui.AddButton("wandTab", "wandGenerateBtn", "\u{f0d1} 生成法杖", function()
        if state.wand.spawn_location == 1 then
            if TBoN.GUI.Function.Custom.Add_Wand_To_Inventory(state.wand) then
                ImGui.PushNotification("法杖已添加到背包！", ImGuiNotificationType.SUCCESS, 3000)
            else
                ImGui.PushNotification("背包已满，无法添加法杖！", ImGuiNotificationType.ERROR, 3000)
            end
        else
            if TBoN.GUI.Function.Custom.Spawn_Wand_To_World(state.wand) then
                ImGui.PushNotification("法杖已生成到世界！", ImGuiNotificationType.SUCCESS, 3000)
            end
        end
    end, false)
    
    state.initialized = true
    Isaac.DebugString("TBoN GUI: 界面初始化完成")
end
