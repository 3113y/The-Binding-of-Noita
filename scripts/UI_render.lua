include("scripts.renders.render_table")
include("scripts.guns.gun_actions")
include("scripts.renders.render_used_functions")
Tab_Confirm = false           --当前是否属于背包界面
anm_load = true               --是否加载一遍anm2
hand_switch = true            --手中物品是否更新
hand_string = false           --手中物品anm2路径
hand_sprite = Sprite()
btn_pre = false               --是否按下左键
item_groove = 1               --物品栏选中/高光位置
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
local font = Font()
local eg = Font()
eg:Load("font/cjk/lanapixel.fnt")
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
        for _, p in pairs(gun_render_table) do
            full_inventory_box:Render(p.pos)
        end
        for _, p in pairs(item) do
            full_inventory_box:Render(p.pos)
        end

        if item_groove <= 4 then
            full_inventory_box_highlight:Render(gun_render_table[item_groove].pos)
        else
            full_inventory_box_highlight:Render(item[item_groove - 4].pos)
        end
        for i, p in pairs(gun_render_table) do
            full_inventory_box:Render(p.pos) --法杖槽渲染
            if gun_info[i] and gun_info[i].name then
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
        for _, p in pairs(gun_render_table) do
            full_inventory_box:Render(p.pos) --法杖槽渲染
        end
        for _, p in pairs(item) do
            full_inventory_box:Render(p.pos) --物品槽渲染
        end
        for _, p in pairs(magic) do
            full_inventory_box:Render(p.pos)                                                                                      --法术槽渲染
            if p.magic then
                magic_background_render_table[magic_background_type_map[actions[actions_map[p.magic]].type]].sprite
                    :Render(p.pos)                                                                                                --法术壳渲染（我说嵌套好写没人读
                p.sprite:Render(p.pos)                                                                                            --法术渲染
            end
        end
        if item_groove > 4 then
            full_inventory_box_highlight:Render(item[item_groove - 4].pos)
        else
            full_inventory_box_highlight:Render(gun_render_table[item_groove].pos)
        end
        for i, p in pairs(gun_render_table) do
            full_inventory_box:Render(p.pos) --法杖槽渲染
            if gun_info[i] and gun_info[i].name then
                p.sprite:Render(p.pos + Vector(0, 9))
            end
        end
        for j, p in pairs(gun_render_table) do
            if gun_info[j].name then
                info_box:Render(info_box_pos[j].pos)
                p.sprite:Render(info_box_pos[j].pos + Vector(2, 11))
                gun_info_render_table[1].sprite:Render(info_box_pos[j].pos + Vector(27, 5))
                gun_info_render_table[2].sprite:Render(info_box_pos[j].pos + Vector(27, 15))
                -- 分开渲染标签和值
                font:DrawString(gun_info_render_table[1].name,
                    info_box_pos[j].pos.X + 35 + #(gun_info_render_table[1].name) * 5, info_box_pos[j].pos.Y + 1,
                    KColor.White, 1)
                font:DrawString(gun_info[j].shuffle and " true" or "false", info_box_pos[j].pos.X + 85 + 20,
                    info_box_pos[j].pos.Y + 1, KColor.Yellow, 1)
                font:DrawString(gun_info_render_table[2].name,
                    info_box_pos[j].pos.X + 36 + #(gun_info_render_table[2].name) * 5, info_box_pos[j].pos.Y + 11,
                    KColor.White, 1)
                font:DrawString(tostring(gun_info[j].capacity),
                    info_box_pos[j].pos.X + 85 + #tostring(gun_info[j].capacity) * 5, info_box_pos[j].pos.Y + 11,
                    KColor.Cyan, 1)
            end
        end
        for gunIndex, g in pairs(gun_render_table) do
            if gun_info[gunIndex] and gun_info[gunIndex].name then
                for k = 1, gun_info[gunIndex].capacity do
                    if gun_magic_render_table[gunIndex][k] then
                        full_inventory_box:Render(gun_magic_render_table[gunIndex][k].pos)
                        if gun_magic_data[gunIndex][k] then
                            gun_magic_render_table[gunIndex][k].sprite:Render(gun_magic_render_table[gunIndex][k].pos)
                            magic_background_render_table[magic_background_type_map[actions[actions_map[gun_magic_data[gunIndex][k]]].type]]
                                .sprite:Render(gun_magic_render_table[gunIndex][k].pos)
                        end
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
            all_magic = mergeMagicAndGunMagic(magic, gun_render_table)
            if Mouse_Pos_Pos_Check(Input.GetMousePosition(true), gun_render_table, 1) then
                chose_type = 1
            elseif Mouse_Pos_Pos_Check(Input.GetMousePosition(true), item, 2) then
                chose_type = 2
            elseif Mouse_Pos_Pos_Check(Input.GetMousePosition(true), all_magic, 3) then
                chose_type = 3
            else
                chose_type = 0
            end
        end
        if chose_type == 1 then
            for i = 1, #gun_render_table do
                if Mouse_Pos_But_Check(Input.GetMousePosition(true), gun_render_table[i].pos) and gun_info[i] and gun_info[i].name and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and not btn_pre then
                    current_num = i
                    current_item = gun_info[i].name
                    current_item_render = gun_render_table[i].sprite
                    btn_pre = true
                elseif Mouse_Pos_But_Check(Input.GetMousePosition(true), gun_render_table[i].pos) and btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    swapGunGroups(gun_render_table, current_num, i)
                    btn_pre = false
                    hand_switch = true
                elseif not Mouse_Pos_Pos_Check(Input.GetMousePosition(true), gun_render_table, 1) and btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
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
                    splitMergedToOriginal(all_magic, magic, gun_render_table)
                elseif not Mouse_Pos_Pos_Check(Input.GetMousePosition(true), all_magic, 3) and btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    btn_pre = false
                    all_magic[current_num].magic = current_item
                    splitMergedToOriginal(all_magic, magic, gun_render_table)
                end
            end

            anm_load = true
        end
        if btn_pre then
            current_item_render:Render(Isaac.WorldToScreen(Input.GetMousePosition(true)))
            if chose_type == 3 then
                magic_background_render_table[magic_background_type_map[actions[actions_map[current_item]].type]].sprite
                    :Render(Isaac
                        .WorldToScreen(Input.GetMousePosition(true)))
            end
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
        if gun_info[item_groove] and gun_info[item_groove].name then
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
        font:Load("font/luaminioutlined.fnt")
        for _, ma in pairs(magic) do
            if ma.magic then
                ma.sprite:Load("gfx/ui/gun_actions/" .. actions[actions_map[ma.magic]].sprite:match(pattern) .. ".anm2",
                    true)
                ma.sprite:Play("Idle", true)
            end
        end
        --[[for _, pa in pairs(particle_render) do
            pa.sprite:Load("gfx/particle/purple.anm2", true)
            pa.sprite:Play("Idle", true)
        end]]
        for _, gi in pairs(gun_info_render_table) do
            gi.sprite:Load(gi.load, true)
            gi.sprite:Play("Idle", true)
        end
        for i = 1, 4 do
            if gun_info[i] and gun_info[i].name then
                gun_render_table[i].sprite:Load("gfx/gun/" .. gun_info[i].name .. ".anm2", true)
                gun_render_table[i].sprite:Play("Idle", true)
            end
            local capacity = gun_info[i] and gun_info[i].capacity or 0
            for j = 1, capacity do
                local magicData = gun_magic_data[i][j]
                if magicData ~= false then
                    local magicSlot = gun_magic_render_table[i][j]
                    if magicSlot then
                        magicSlot.sprite:Load(
                            "gfx/ui/gun_actions/" .. actions[actions_map[magicData]].sprite:match(pattern) .. ".anm2",
                            true)
                        magicSlot.sprite:Play("Idle", true)
                    end
                end
            end
        end
        for _, bg in pairs(magic_background_render_table) do
            bg.sprite:Load("gfx/ui/inventory/item_bg_" .. bg.name .. ".anm2")
            bg.sprite:Play("Idle", true)
        end
        anm_load = false
    end
    if hand_switch == true then
        if item_groove <= 4 then
            if gun_info[item_groove] and gun_info[item_groove].name then
                hand_string = gun_render_table[item_groove].sprite:GetFilename()
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
