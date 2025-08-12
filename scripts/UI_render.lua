Tab_Confirm = false           --当前是否属于背包界面
anm_load = true               --是否加载一遍anm2
hand_switch = true            --手中物品是否更新
hand_string = false           --手中物品anm2路径
hand_sprite = Sprite()
btn_pre = false               --是否按下左键
local item_groove = 1         --物品栏选中/高光位置
local pattern = ".+/(.+)%..+" --拼接用字符串
local current_gun_info        --当前拿起法杖的基本信息
local current_num             --当前所选取的物品索引
local current_item            --当前左键拿起的物品名称
local current_item_render     --当前左键拿起的物品渲染的sprite
local chose_type = 0          --左键拿起类型（法杖/物品/法术）
local full_inventory_box = Sprite()
local full_inventory_box_highlight = Sprite()
local background = Sprite()
local info_box = Sprite()
function TBoN_MOD:IG_Choose() --滚轮选择
    if Input.GetMouseWheel().Y < 0 then
        if item_groove >= 8 then
            item_groove = 1
            hand_switch = true
        else
            item_groove = item_groove + 1
            hand_switch = true
        end
    elseif Input.GetMouseWheel().Y > 0 then
        if item_groove <= 1 then
            item_groove = 8
            hand_switch = true
        else
            item_groove = item_groove - 1
            hand_switch = true
        end
        hand_switch = true
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.IG_Choose)
function TBoN_MOD:TAB_Switch() --TAB模式切换
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Game():GetPlayer(i)
        if Input.IsButtonTriggered(Keyboard.KEY_TAB, player.ControllerIndex) then
            if Tab_Confirm then
                Tab_Confirm = false
            else
                Tab_Confirm = true
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.TAB_Switch)
function TBoN_MOD:NO_TAB_UI_Render() --按下Tab前UI渲染
    if not Tab_Confirm then
        for _, p in pairs(gun) do
            full_inventory_box:Render(p.pos)
        end
        for _, p in pairs(item) do
            full_inventory_box:Render(p.pos)
        end

        if item_groove <= 4 then
            full_inventory_box_highlight:Render(gun[item_groove].pos)
        else
            full_inventory_box_highlight:Render(item[item_groove - 4].pos)
        end
        for _, p in pairs(gun) do
            full_inventory_box:Render(p.pos) --法杖槽渲染
            if p.gun then
                p.sprite:Render(p.pos + Vector(0, 9))
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.NO_TAB_UI_Render)

function TBoN_MOD:TAB_UI_Render() --按下Tab后UI渲染
    if Tab_Confirm then
        background:Render(Vector(47, 97))
        background.Rotation = 90
        for _, p in pairs(gun) do
            full_inventory_box:Render(p.pos) --法杖槽渲染
        end
        for _, p in pairs(item) do
            full_inventory_box:Render(p.pos) --物品槽渲染
        end
        for _, p in pairs(magic) do
            full_inventory_box:Render(p.pos)                                                                       --法术槽渲染
            if p.magic then
                magic_backgroud[magic_backgroud_type_map[actions[actions_map[p.magic]].type]].sprite:Render(p.pos) --法术壳渲染（我说嵌套好写没人读
                p.sprite:Render(p.pos)                                                                             --法术渲染
            end
        end
        if item_groove > 4 then
            full_inventory_box_highlight:Render(item[item_groove - 4].pos)
        else
            full_inventory_box_highlight:Render(gun[item_groove].pos)
        end
        for _, p in pairs(gun) do
            full_inventory_box:Render(p.pos) --法杖槽渲染
            if p.gun then
                p.sprite:Render(p.pos + Vector(0, 9))
            end
        end
        for j, p in pairs(gun) do
            if p.gun then
                info_box:Render(info_box_pos[j].pos) --信息栏
                p.sprite:Render(info_box_pos[j].pos + Vector(2, 11))
                --Font():Load("font/terminus.fnt")
                --Font():DrawString("乱序",info_box_pos[i].pos.X+25,info_box_pos[i].pos.Y+3,KColor.Black)
            end
        end
        for _, g in pairs(gun) do
            if g.gun ~= nil then
                for k, p in pairs(g.info.gun_magic) do
                    if k <= g.info.capacity then
                        full_inventory_box:Render(p.pos)
                    end
                    if p.magic then
                        p.sprite:Render(p.pos)
                        magic_backgroud[magic_backgroud_type_map[actions[actions_map[p.magic]].type]].sprite:Render(p
                            .pos)
                    end
                end
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.TAB_UI_Render)
function TBoN_MOD:Chose_Render() --按下左键时和后的法法杖/物品/法术交换逻辑和渲染逻辑
    if Tab_Confirm then
        if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and btn_pre == false then
            all_magic = mergeMagicAndGunMagic(magic, gun)
            if Mouse_Pos_Pos_Check(Input.GetMousePosition(true), gun, 1) then
                chose_type = 1
            elseif Mouse_Pos_Pos_Check(Input.GetMousePosition(true), item, 2) then
                chose_type = 2
            elseif Mouse_Pos_Pos_Check(Input.GetMousePosition(true), all_magic, 3) then
                chose_type = 3
            else
                chose_type = 0
            end
        end
    end
    if chose_type == 1 then
        for i = 1, #gun do
            if Mouse_Pos_But_Check(Input.GetMousePosition(true), gun[i].pos) and gun[i].gun and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and not btn_pre then
                current_num = i
                current_item = gun[i].gun
                current_item_render = gun[i].sprite
                btn_pre = true
            elseif Mouse_Pos_But_Check(Input.GetMousePosition(true), gun[i].pos) and btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                swapGunGroups(gun, current_num, i)
                btn_pre = false
                hand_switch = true
            elseif not Mouse_Pos_Pos_Check(Input.GetMousePosition(true), gun, 1) and btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                btn_pre = false
                hand_switch = true
            end
        end
        anm_load = true
    elseif chose_type == 2 then
        for i = 1, #item do
            if Mouse_Pos_But_Check(Input.GetMousePosition(true), item[i].pos) and item[i].gun and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and not btn_pre then
                current_num = i
                btn_pre = true
                current_item = item[i].item
                current_item_render = item[i].sprite
                item[i].item = false
            elseif Mouse_Pos_But_Check(Input.GetMousePosition(true), item[i].pos) and btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                btn_pre = false
                if item[i].item then
                    item[current_num].item = item[i].item
                    item[i].item = current_item
                else
                    item[i].item = current_item
                end
            elseif not Mouse_Pos_Pos_Check(Input.GetMousePosition(true), item, 2) and btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                btn_pre = false
            end
        end
        anm_load = true
    elseif chose_type == 3 then
        for i = 1, #all_magic do
            if Mouse_Pos_But_Check(Input.GetMousePosition(true), all_magic[i].pos) and all_magic[i].magic and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and not btn_pre then
                current_num = i
                btn_pre = true
                current_item = all_magic[i].magic
                current_item_render = all_magic[i].sprite
                all_magic[i].magic = false
            elseif Mouse_Pos_But_Check(Input.GetMousePosition(true), all_magic[i].pos) and btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                btn_pre = false
                if all_magic[i].magic then
                    all_magic[current_num].magic = all_magic[i].magic
                    all_magic[i].magic = current_item
                else
                    all_magic[i].magic = current_item
                end
                splitMergedToOriginal(all_magic, magic, gun)
            elseif not Mouse_Pos_Pos_Check(Input.GetMousePosition(true), all_magic, 3) and btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                btn_pre = false
                all_magic[current_num].magic = current_item
                splitMergedToOriginal(all_magic, magic, gun)
            end
        end

        anm_load = true
    end
    if btn_pre then
        current_item_render:Render(Isaac.WorldToScreen(Input.GetMousePosition(true)))
        if chose_type == 3 then
            magic_backgroud[magic_backgroud_type_map[actions[actions_map[current_item]].type]].sprite:Render(Isaac
                .WorldToScreen(Input.GetMousePosition(true)))
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.Chose_Render)
function TBoN_MOD:gun_rotation(player) --玩家手中物品渲染
    local rot = Vector(
        (Input.GetMousePosition(true).X - player.Position.X) /
        math.sqrt((Input.GetMousePosition(true).X - player.Position.X) ^ 2 +
            (Input.GetMousePosition(true).Y - player.Position.Y) ^ 2),
        (Input.GetMousePosition(true).Y - player.Position.Y) /
        math.sqrt((Input.GetMousePosition(true).X - player.Position.X) ^ 2 +
            (Input.GetMousePosition(true).Y - player.Position.Y) ^ 2))
    local radians = math.atan(rot.Y / rot.X)
    local degrees
    if rot.X < 0 then
        degrees = 180 + math.deg(radians)
    else
        degrees = math.deg(radians)
    end
    if item_groove <= 4 then
        if gun[item_groove].gun then
            hand_sprite:Render(Isaac.WorldToScreen(player.Position) + Vector(0, -5))
            hand_sprite.Rotation = degrees
        end
    else
        if item[item_groove - 4].item then
            hand_sprite:Render(Isaac.WorldToScreen(player.Position) + Vector(0, -5))
            hand_sprite.Rotation = degrees
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, TBoN_MOD.gun_rotation)

function Anm2_load() --加载anm2
    if anm_load == true then
        full_inventory_box:Load("gfx/ui/inventory/full_inventory_box.anm2")
        full_inventory_box_highlight:Load("gfx/ui/inventory/full_inventory_box_highlight.anm2")
        background:Load("gfx/ui/inventory/background.anm2")
        info_box:Load("gfx/ui/inventory/info_box.anm2")
        full_inventory_box:Play("Idle", true)
        full_inventory_box_highlight:Play("Idle", true)
        background:Play("Idle", true)
        info_box:Play("Idle", true)
        for _, ma in pairs(magic) do
            if ma.magic then
                ma.sprite:Load("gfx/ui/gun_actions/" .. actions[actions_map[ma.magic]].sprite:match(pattern) .. ".anm2",
                    true)
                ma.sprite:Play("Idle", true)
            end
        end

        for i = 1, 4 do
            if gun[i].gun then
                gun[i].sprite:Load("gfx/gun/" .. gun[i].gun .. ".anm2", true)
                gun[i].sprite:Play("Idle", true)
            end
            for j, ma in pairs(gun[i].info.gun_magic) do
                if j <= gun[i].info.capacity then
                    if ma.magic ~= false then
                        ma.sprite:Load(
                            "gfx/ui/gun_actions/" .. actions[actions_map[ma.magic]].sprite:match(pattern) .. ".anm2",
                            true)
                        ma.sprite:Play("Idle", true)
                    end
                end
            end
        end
        for _, bg in pairs(magic_backgroud) do
            bg.sprite:Load("gfx/ui/inventory/item_bg_" .. bg.name .. ".anm2")
            bg.sprite:Play("Idle", true)
        end
        anm_load = false
    end
    if hand_switch == true then
        if item_groove <= 4 then
            if gun[item_groove].gun then
                hand_string = gun[item_groove].sprite:GetFilename()
            end
        else
            if item[item_groove - 4].item then
                hand_string = item[item_groove - 4].sprite:GetFilename()
            end
        end
        ---@diagnostic disable-next-line: param-type-mismatch
        hand_sprite:Load(hand_string)
        hand_sprite:Play("Idle")
        hand_switch = false
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_UPDATE, Anm2_load)
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

function swapGunGroups(gunTable, i, j) -- 交换gun表中索引i和j的成组属性
    -- 边界检查：确保索引有效且存在info和gun_magic
    local gunI = gunTable[i]
    local gunJ = gunTable[j]
    -- 1. 交换gun字段（物品名称）
    gunI.gun, gunJ.gun = gunJ.gun, gunI.gun

    -- 2. 交换info.capacity（容量）
    local capI = gunI.info.capacity
    local capJ = gunJ.info.capacity
    gunI.info.capacity = capJ
    gunJ.info.capacity = capI

    -- 3. 交换info.gun_magic中的magic子属性（使用原始预定义的pos，仅交换magic）
    local magicI = gunI.info.gun_magic
    local magicJ = gunJ.info.gun_magic

    -- 按最大容量遍历（使用两个法杖容量的最大值，避免遗漏）
    for k = 1, 25 do
        magicI[k].magic, magicJ[k].magic = magicJ[k].magic, magicI[k].magic
    end
end

function mergeMagicAndGunMagic(magicTable, gunTable) -- 合并magic表与gun表中info的gun_magic表（按容量限制）
    local merged = {}                                -- 存储合并后的结果

    -- 第一步：合并magic表中的所有法术槽
    -- magic表中的每个元素视为独立法术槽，全部按顺序加入
    for _, magicSlot in pairs(magicTable) do
        -- 仅保留交换逻辑所需的核心属性（位置、精灵、法术标识）
        table.insert(merged, {
            pos = magicSlot.pos,
            sprite = magicSlot.sprite,
            magic = magicSlot.magic,
            source = "magic" -- 标记来源，便于后续区分
        })
    end

    -- 第二步：按顺序合并每个gun的有效法术槽（受capacity限制）
    for _, gunItem in pairs(gunTable) do
        -- 校验gun的info和capacity有效性，避免空引用错误
        local gunInfo = gunItem.info
        local capacity = gunInfo.capacity or 0
        local gunMagicSlots = gunInfo.gun_magic or {}

        -- 只合并前capacity个法术槽（容量限制）
        for i = 1, capacity do
            local magicSlot = gunMagicSlots[i]
            if magicSlot then -- 确保槽位存在
                table.insert(merged, {
                    pos = magicSlot.pos,
                    sprite = magicSlot.sprite,
                    magic = magicSlot.magic,
                    source = "gun", -- 标记来源
                    gunIndex = _    -- 记录所属gun在gunTable中的索引
                })
            end
        end
    end

    return merged
end

function splitMergedToOriginal(mergedTable, originalMagic, originalGun) -- 将合并后的法术槽表拆分回原始的magic表和gun表的gun_magic中
    -- 1. 处理magic表部分（从merged中提取source为"magic"的元素）
    local magicPos = 1 -- 跟踪原始magic表的当前索引
    for _, mergedItem in ipairs(mergedTable) do
        if mergedItem.source == "magic" then
            -- 只处理原始magic表中存在的槽位
            if originalMagic[magicPos] then
                -- 仅更新法术标识（pos和sprite保持原始表不变）
                originalMagic[magicPos].magic = mergedItem.magic
                magicPos = magicPos + 1
            else
                -- 超出原始magic表长度的部分忽略
                break
            end
        else
            -- 遇到非magic来源的元素，说明magic部分已处理完毕
            break
        end
    end

    -- 2. 处理gun表部分（从merged中提取source为"gun"的元素）
    local gunPos = magicPos -- 从magic部分结束的位置开始处理gun部分
    for gunIndex, gunItem in ipairs(originalGun) do
        local capacity = gunItem.info.capacity or 0
        local gunMagic = gunItem.info.gun_magic or {}

        -- 按容量处理当前gun的前capacity个法术槽
        for i = 1, capacity do
            local mergedItem = mergedTable[gunPos]
            -- 校验merged元素是否属于当前gun
            if mergedItem and mergedItem.source == "gun" and mergedItem.gunIndex == gunIndex then
                -- 更新对应gun_magic槽位的法术标识
                if gunMagic[i] then
                    gunMagic[i].magic = mergedItem.magic
                end
                gunPos = gunPos + 1 -- 移动到下一个merged元素
            else
                -- 若merged中无对应元素，清空该槽位（或保持原始值，根据需求调整）
                if gunMagic[i] then
                    gunMagic[i].magic = false
                end
            end
        end
    end
end

function deepCopy(orig) -- 深拷贝表的工具函数
    -- 检查原始值的类型
    local orig_type = type(orig)
    local copy
    -- 如果是表类型，则进行深拷贝
    if orig_type == 'table' then
        copy = {}
        -- 遍历表中的每个元素
        for orig_key, orig_value in next, orig, nil do
            -- 递归拷贝每个元素，包括嵌套的表
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        -- 复制元表
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        -- 非表类型直接返回原值
        copy = orig
    end

    return copy
end
