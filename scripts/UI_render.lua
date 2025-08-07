Tab_Confirm = false           --当前是否属于背包界面
anm_load = true               --是否加载一遍anm2
hand_switch = true            --手中物品是否更新
hand_string = false           --手中物品anm2路径
hand_sprite = Sprite()
btn_pre = false               --是否按下左键
local item_groove = 1         --物品栏选中/高光位置
local pattern = ".+/(.+)%..+" --拼接用字符串
local current_num             --当前所选取的物品索引
local current_item            --当前左键拿起的物品名称
local current_item_render     --当前左键拿起的物品渲染的sprite
local chose_type = 0          --左键拿起类型（法杖/物品/法术）
local full_inventory_box = Sprite()
local full_inventory_box_highlight = Sprite()
local background = Sprite()
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
            full_inventory_box:Render(p.pos)
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

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.TAB_UI_Render)
function TBoN_MOD:Chose_Render() --按下左键时和后的法法杖/物品/法术交换逻辑和渲染逻辑
    if Tab_Confirm then
        if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and btn_pre == false then
            if Mouse_Pos_Pos_Check(Input.GetMousePosition(true), gun) then
                chose_type = 1
            elseif Mouse_Pos_Pos_Check(Input.GetMousePosition(true), item) then
                chose_type = 2
            elseif Mouse_Pos_Pos_Check(Input.GetMousePosition(true), magic) then
                chose_type = 3
            else
                chose_type = 0
            end
        end
    end
    if chose_type == 1 then
        for i = 1, #gun do
            if Mouse_Pos_But_Check(Input.GetMousePosition(true), gun[i].pos) and gun[i].gun and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) == true and btn_pre == false then
                current_num = i
                btn_pre = true
                current_item = gun[i].gun
                current_item_render = gun[i].sprite
                gun[i].gun = false
            elseif Mouse_Pos_But_Check(Input.GetMousePosition(true), gun[i].pos) and btn_pre == true and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) == false then
                btn_pre = false
                if gun[i].gun then
                    gun[current_num].gun = gun[i].gun
                    gun[i].gun = current_item
                else
                    gun[i].gun = current_item
                end
                hand_switch = true
            elseif not Mouse_Pos_Pos_Check(Input.GetMousePosition(true), gun) and btn_pre == true and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) == false then
                btn_pre = false
                gun[current_num].gun = current_item
                                hand_switch = true
            end
        end
        anm_load = true
    elseif chose_type == 2 then
        for i = 1, #item do
            if Mouse_Pos_But_Check(Input.GetMousePosition(true), item[i].pos) and item[i].gun and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) == true and btn_pre == false then
                current_num = i
                btn_pre = true
                current_item = item[i].item
                current_item_render = item[i].sprite
                item[i].item = false
            elseif Mouse_Pos_But_Check(Input.GetMousePosition(true), item[i].pos) and btn_pre == true and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) == false then
                btn_pre = false
                if item[i].item then
                    item[current_num].item = item[i].item
                    item[i].item = current_item
                else
                    item[i].item = current_item
                end
            elseif not Mouse_Pos_Pos_Check(Input.GetMousePosition(true), item) and btn_pre == true and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) == false then
                btn_pre = false
                item[current_num].gun = current_item
            end
        end
        anm_load = true
    elseif chose_type == 3 then
        for i = 1, #magic do
            if Mouse_Pos_But_Check(Input.GetMousePosition(true), magic[i].pos) and magic[i].magic and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) == true and btn_pre == false then
                current_num = i
                btn_pre = true
                current_item = magic[i].magic
                current_item_render = magic[i].sprite
                magic[i].magic = false
                chose_type = 3
            elseif Mouse_Pos_But_Check(Input.GetMousePosition(true), magic[i].pos) and btn_pre == true and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) == false then
                btn_pre = false
                if magic[i].magic then
                    magic[current_num].magic = magic[i].magic
                    magic[i].magic = current_item
                else
                    magic[i].magic = current_item
                end
                chose_type = 0
            elseif not Mouse_Pos_Pos_Check(Input.GetMousePosition(true), magic) and btn_pre == true and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) == false then
                btn_pre = false
                magic[current_num].magic = current_item
            end
        end
        anm_load = true
    end

    if btn_pre == true then
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
        full_inventory_box:Play("Idle", true)
        full_inventory_box_highlight:Play("Idle", true)
        background:Play("Idle", true)
        for _, ma in pairs(magic) do
            if ma.magic then
                ma.sprite:Load("gfx/ui/gun_actions/" .. actions[actions_map[ma.magic]].sprite:match(pattern) .. ".anm2",
                    true)
                ma.sprite:Play("Idle", true)
            end
        end
        for _, gu in pairs(gun) do
            if gu.gun then
                gu.sprite:Load("gfx/gun/" .. gu.gun .. ".anm2", true)
                gu.sprite:Play("Idle", true)
            end
        end
        anm_load = false
        for _, bg in pairs(magic_backgroud) do
            bg.sprite:Load("gfx/ui/inventory/item_bg_" .. bg.name .. ".anm2")
            bg.sprite:Play("Idle", true)
        end
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
        hand_sprite:Load(hand_string)
        hand_sprite:Play("Idle")
        hand_switch = false
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_UPDATE, Anm2_load)
function Mouse_Pos_But_Check(Mouse_Pos, Aim_pos) --检测鼠标位置（即在某小格）
    pos = Isaac.WorldToScreen(Mouse_Pos)
    if pos.X >= Aim_pos.X and pos.X <= Aim_pos.X + 20 then
        if pos.Y >= Aim_pos.Y and pos.Y <= Aim_pos.Y + 20 then
            return true
        else
            return false
        end
    end
end

function Mouse_Pos_Pos_Check(Mouse_Pos, table) --检测鼠标位置（即在某区域）
    pos = Isaac.WorldToScreen(Mouse_Pos)
    Aim_pos = table[1].pos
    if table[1].pos == Vector(25, 101) then
        if pos.X >= Aim_pos.X and pos.X <= Aim_pos.X + 20 then
            if pos.Y >= Aim_pos.Y and pos.Y <= Aim_pos.Y + 80 then
                return 1
            else
                return false
            end
        end
    elseif table[1].pos == Vector(25, 183) then
        if pos.X >= Aim_pos.X and pos.X <= Aim_pos.X + 20 then
            if pos.Y >= Aim_pos.Y and pos.Y <= Aim_pos.Y + 80 then
                return 2
            else
                return false
            end
        end
    else
        if pos.X >= Aim_pos.X and pos.X <= Aim_pos.X + 40 then
            if pos.Y >= Aim_pos.Y and pos.Y <= Aim_pos.Y + 220 then
                return 3
            else
                return false
            end
        end
    end
end
