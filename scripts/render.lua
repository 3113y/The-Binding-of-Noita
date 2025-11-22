---@diagnostic disable: assign-type-mismatch
include("scripts.guns.gun_actions")
include("scripts.renders.render_used_functions")
include("scripts.renders.translations")
TBoN.Render.Variable.Bool.Tab_Confirm = false              --当前是否属于背包界面
TBoN.Render.Variable.Bool.anm_load = true                  --是否加载一遍anm2
TBoN.Render.Variable.Bool.hand_switch = true               --手中物品是否更新
TBoN.Render.Variable.Bool.btn_pre = false                  --是否按下左键
TBoN.Render.Variable.Num.item_groove = 1                   --物品栏选中/高光位置
TBoN.Render.Variable.Num.current_num = 1                   --当前所选取的物品索引
TBoN.Render.Variable.Num.chose_type = 0                    --左键拿起类型（法杖/物品/法术）
TBoN.Render.Variable.Num.pos_type = 0                      --鼠标所处位置物品种类
TBoN.Render.Variable.String.hand_string = ""               --手中物品anm2路径
TBoN.Render.Variable.String.current_item = ""              --当前左键拿起的物品名称
TBoN.Render.Function.Sprite.current_item_render = Sprite() --当前左键拿起的物品渲染的sprite
TBoN.Render.Function.Sprite.hand_sprite = Sprite()
TBoN.Render.Function.Sprite.full_inventory_box = Sprite()
TBoN.Render.Function.Sprite.full_inventory_box_highlight = Sprite()
TBoN.Render.Function.Sprite.background = Sprite()
TBoN.Render.Function.Sprite.info_box = Sprite()
TBoN.Render.Function.Sprite.gun_info_bg = Sprite()
TBoN.Render.Function.Sprite.magic_info_bg = Sprite()
TBoN.Render.Function.Font.font = Font()
TBoN.Render.Function.Font.font_cn = Font()
function TBoN_MOD:IG_Choose() --滚轮选择
    if Input.GetMouseWheel().Y < 0 then
        if TBoN.Render.Variable.Num.item_groove >= 8 then
            TBoN.Render.Variable.Num.item_groove = 1
            TBoN.Render.Variable.Bool.hand_switch = true
        else
            TBoN.Render.Variable.Num.item_groove = TBoN.Render.Variable.Num.item_groove + 1
            TBoN.Render.Variable.Bool.hand_switch = true
        end
    elseif Input.GetMouseWheel().Y > 0 then
        if TBoN.Render.Variable.Num.item_groove <= 1 then
            TBoN.Render.Variable.Num.item_groove = 8
            TBoN.Render.Variable.Bool.hand_switch = true
        else
            TBoN.Render.Variable.Num.item_groove = TBoN.Render.Variable.Num.item_groove - 1
            TBoN.Render.Variable.Bool.hand_switch = true
        end
        TBoN.Render.Variable.Bool.hand_switch = true
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.IG_Choose)

function TBoN_MOD:TAB_Switch(player) --TAB模式切换
    if player:GetPlayerType() == TBoN.Character.Variable.Num.Mina_Type then
        if Input.IsButtonTriggered(Keyboard.KEY_B, player.ControllerIndex) then
            TBoN.Render.Variable.Bool.Tab_Confirm = not TBoN.Render.Variable.Bool.Tab_Confirm
            TBoN.Gun.Function.Custom.Reset_All_Gun_Cast_States()
        end
    else
        TBoN.Render.Variable.Bool.Tab_Confirm = nil
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, TBoN_MOD.TAB_Switch)
function TBoN_MOD:NO_TAB_UI_Render() --按下Tab前UI渲染
    if TBoN.Render.Variable.Bool.Tab_Confirm == false then
        TBoN.Render.Function.Custom.Render_Anm2(TBoN.Render.Function.Sprite.full_inventory_box,
            TBoN.Render.Table.gun_render_table, false) --法杖槽渲染
        TBoN.Render.Function.Custom.Render_Anm2(TBoN.Render.Function.Sprite.full_inventory_box,
            TBoN.Render.Table.item, false)             --物品槽渲染
        if TBoN.Render.Variable.Num.item_groove <= 4 then
            TBoN.Render.Function.Sprite.full_inventory_box_highlight:Render(TBoN.Render.Table.gun_render_table
                [TBoN.Render.Variable.Num.item_groove].pos)
        else
            TBoN.Render.Function.Sprite.full_inventory_box_highlight:Render(TBoN.Render.Table.item
                [TBoN.Render.Variable.Num.item_groove - 4].pos)
        end
        for i, p in pairs(TBoN.Render.Table.gun_render_table) do
            TBoN.Render.Function.Sprite.full_inventory_box:Render(p.pos) --法杖槽渲染
            if TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name then
                p.sprite:Render(p.pos + Vector(0, 9))
            end
        end
        for i, ba in pairs(TBoN.Render.Table.Bar) do
            if TBoN.Gun.Table.gun_states[TBoN.Render.Variable.Num.item_groove] and TBoN.Gun.Table.gun_states[TBoN.Render.Variable.Num.item_groove].mana_max ~= 0 then
                if i == 1 then
                    local percent = TBoN.Gun.Table.gun_states[TBoN.Render.Variable.Num.item_groove].current_mana /
                        TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove].mana_max
                    local frame = math.max(0, math.min(100, math.floor(percent * 100)))
                    ba.sprite:SetFrame(frame)
                    ba.sprite:Render(ba.pos)
                else
                    local recharge_time = TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove].recharge_time or
                        1
                    local recharge_cd = TBoN.Gun.Table.gun_states[TBoN.Render.Variable.Num.item_groove]
                        .recharge_cooldown or
                        0
                    local percent = recharge_cd / recharge_time
                    local frame = math.max(0, math.min(100, math.floor(percent * 100)))
                    ba.sprite:SetFrame(100 - frame)
                    ba.sprite:Render(ba.pos)
                end
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.NO_TAB_UI_Render)

function TBoN_MOD:TAB_UI_Render() --按下Tab后UI渲染
    if TBoN.Render.Variable.Bool.Tab_Confirm then
        TBoN.Render.Function.Sprite.background:Render(Vector(47, 97))
        TBoN.Render.Function.Sprite.background.Rotation = 90
        TBoN.Render.Function.Custom.Render_Anm2(TBoN.Render.Function.Sprite.full_inventory_box,
            TBoN.Render.Table.gun_render_table, false)                   --法杖槽渲染
        TBoN.Render.Function.Custom.Render_Anm2(TBoN.Render.Function.Sprite.full_inventory_box,
            TBoN.Render.Table.item, false)                               --物品槽渲染
        for i, p in pairs(TBoN.Render.Table.bag_magic_render_table) do
            TBoN.Render.Function.Sprite.full_inventory_box:Render(p.pos) --法术槽渲染
            local magic_id = TBoN.Magic.Table.bag_magic_data[i] and TBoN.Magic.Table.bag_magic_data[i].magic_id
            if magic_id and magic_id ~= 0 then
                p.sprite:Render(p.pos - Vector(1, 1))
            end
        end
        if TBoN.Render.Variable.Num.item_groove > 4 then
            TBoN.Render.Function.Sprite.full_inventory_box_highlight:Render(TBoN.Render.Table.item
                [TBoN.Render.Variable.Num.item_groove - 4].pos)
        else
            TBoN.Render.Function.Sprite.full_inventory_box_highlight:Render(TBoN.Render.Table.gun_render_table
                [TBoN.Render.Variable.Num.item_groove].pos)
        end
        for i, p in pairs(TBoN.Render.Table.gun_render_table) do
            TBoN.Render.Function.Sprite.full_inventory_box:Render(p.pos) --法杖槽渲染
            if TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name then
                p.sprite:Render(p.pos + Vector(0, 9))
            end
        end
        for j, p in pairs(TBoN.Render.Table.gun_render_table) do
            if TBoN.Gun.Table.gun_info[j].name then
                TBoN.Render.Function.Sprite.info_box:Render(TBoN.Render.Table.info_box_pos[j].pos)
                p.sprite:Render(TBoN.Render.Table.info_box_pos[j].pos + Vector(2, 11))
                TBoN.Render.Table.gun_des_render_table[1].sprite:Render(TBoN.Render.Table.info_box_pos[j].pos +
                    Vector(27, 5))
                TBoN.Render.Table.gun_des_render_table[2].sprite:Render(TBoN.Render.Table.info_box_pos[j].pos +
                    Vector(27, 15))
                -- 分开渲染标签和值
                TBoN.Render.Function.Font.font:DrawString(TBoN.Render.Table.gun_des_render_table[1].name,
                    TBoN.Render.Table.info_box_pos[j].pos.X + 36, TBoN.Render.Table.info_box_pos[j].pos.Y + 1,
                    KColor.White, 0)
                TBoN.Render.Function.Font.font:DrawString(tostring(TBoN.Gun.Table.gun_info[j].shuffle),
                    TBoN.Render.Table.info_box_pos[j].pos.X + 85,
                    TBoN.Render.Table.info_box_pos[j].pos.Y + 1, KColor.Yellow, 0)
                TBoN.Render.Function.Font.font:DrawString(TBoN.Render.Table.gun_des_render_table[2].name,
                    TBoN.Render.Table.info_box_pos[j].pos.X + 36, TBoN.Render.Table.info_box_pos[j].pos.Y + 11,
                    KColor.White, 0)
                TBoN.Render.Function.Font.font:DrawString(tostring(TBoN.Gun.Table.gun_info[j].capacity),
                    TBoN.Render.Table.info_box_pos[j].pos.X + 85, TBoN.Render.Table.info_box_pos[j].pos.Y + 11,
                    KColor.Cyan, 0)
            end
        end
        for gunIndex, g in pairs(TBoN.Render.Table.gun_render_table) do
            if TBoN.Gun.Table.gun_info[gunIndex] and TBoN.Gun.Table.gun_info[gunIndex].name then
                for k = 1, TBoN.Gun.Table.gun_info[gunIndex].capacity do
                    if TBoN.Render.Table.gun_magic_render_table[gunIndex][k] then
                        TBoN.Render.Function.Sprite.full_inventory_box:Render(TBoN.Render.Table.gun_magic_render_table
                            [gunIndex]
                            [k].pos)
                        local magic_data = TBoN.Gun.Table.gun_magic_data[gunIndex][k]
                        if magic_data and magic_data.magic_id and magic_data.magic_id ~= false and magic_data.magic_id ~= 0 then
                            TBoN.Render.Table.gun_magic_render_table[gunIndex][k].sprite:Render(TBoN.Render.Table
                                .gun_magic_render_table[gunIndex][k].pos - Vector(1, 1))
                        end
                    end
                end
            end
        end
        if not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
            local mouse_item_info = TBoN.Render.Function.Custom.Get_Mouse_Pos_Item_Info(Input.GetMousePosition(true))
            TBoN.Render.Variable.Num.pos_type = mouse_item_info.type
            TBoN.Render.Table.pos_info = mouse_item_info.spell_info
            TBoN.Render.Function.Custom.Render_Info(mouse_item_info, nil,
                Isaac.WorldToScreen(Input.GetMousePosition(true)))
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.TAB_UI_Render)

function TBoN_MOD:Chose_Render() --按下左键时和后的法法杖/物品/法术交换逻辑和渲染逻辑
    if TBoN.Render.Variable.Bool.Tab_Confirm then
        if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and TBoN.Render.Variable.Bool.btn_pre == false then
            all_magic = TBoN.Render.Function.Custom.Merge_Magic(TBoN.Render.Table.bag_magic_render_table,
                TBoN.Render.Table
                .gun_render_table)

            if TBoN.Render.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), TBoN.Render.Table.gun_render_table, 1) then
                TBoN.Render.Variable.Num.chose_type = 1
            elseif TBoN.Render.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), TBoN.Render.Table.item, 2) then
                TBoN.Render.Variable.Num.chose_type = 2
            elseif TBoN.Render.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), all_magic, 3) then
                TBoN.Render.Variable.Num.chose_type = 3
            else
                TBoN.Render.Variable.Num.chose_type = 0
            end
        end
        if TBoN.Render.Variable.Num.chose_type == 1 then
            for i = 1, #TBoN.Render.Table.gun_render_table do
                if TBoN.Render.Function.Custom.Mouse_Pos_But_Check(Input.GetMousePosition(true), TBoN.Render.Table.gun_render_table[i].pos) and TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and not TBoN.Render.Variable.Bool.btn_pre then
                    TBoN.Render.Variable.Num.current_num = i
                    TBoN.Render.Variable.String.current_item = TBoN.Gun.Table.gun_info[i].name
                    TBoN.Render.Function.Sprite.current_item_render = TBoN.Render.Table.gun_render_table[i].sprite
                    TBoN.Render.Variable.Bool.btn_pre = true
                elseif TBoN.Render.Function.Custom.Mouse_Pos_But_Check(Input.GetMousePosition(true), TBoN.Render.Table.gun_render_table[i].pos) and TBoN.Render.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    TBoN.Render.Function.Custom.swapGunGroups(TBoN.Render.Table.gun_render_table,
                        TBoN.Render.Variable.Num.current_num, i)
                    TBoN.Render.Variable.Bool.btn_pre = false
                    TBoN.Render.Variable.Bool.hand_switch = true
                elseif not TBoN.Render.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), TBoN.Render.Table.gun_render_table, 1) and TBoN.Render.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    -- 丢弃法杖逻辑
                    if TBoN.Render.Variable.String.current_item and TBoN.Render.Variable.String.current_item ~= false then
                        TBoN.Render.Function.Custom.DropWand(TBoN.Render.Variable.Num.current_num)
                    end
                    TBoN.Render.Variable.Bool.btn_pre = false
                    TBoN.Render.Variable.Bool.hand_switch = true
                end
            end
        elseif TBoN.Render.Variable.Num.chose_type == 2 then
            for i = 1, #TBoN.Render.Table.item do
                if TBoN.Render.Function.Custom.Mouse_Pos_But_Check(Input.GetMousePosition(true), TBoN.Render.Table.item[i].pos) and TBoN.Render.Table.item[i].item and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and not TBoN.Render.Variable.Bool.btn_pre then
                    TBoN.Render.Variable.Num.current_num = i
                    TBoN.Render.Variable.Bool.btn_pre = true
                    TBoN.Render.Variable.String.current_item = TBoN.Render.Table.item[i].item
                    TBoN.Render.Function.Sprite.current_item_render = TBoN.Render.Table.item[i].sprite
                    TBoN.Render.Table.item[i].item = false
                elseif TBoN.Render.Function.Custom.Mouse_Pos_But_Check(Input.GetMousePosition(true), TBoN.Render.Table.item[i].pos) and TBoN.Render.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    TBoN.Render.Variable.Bool.btn_pre = false
                    if TBoN.Render.Table.item[i].item then
                        TBoN.Render.Table.item[TBoN.Render.Variable.Num.current_num].item = TBoN.Render.Table.item[i]
                            .item
                        TBoN.Render.Table.item[i].item = TBoN.Render.Variable.String.current_item
                    else
                        TBoN.Render.Table.item[i].item = TBoN.Render.Variable.String.current_item
                    end
                elseif not TBoN.Render.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), TBoN.Render.Table.item, 2) and TBoN.Render.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    TBoN.Render.Variable.Bool.btn_pre = false
                end
            end
        elseif TBoN.Render.Variable.Num.chose_type == 3 then
            for i = 1, #all_magic do
                if TBoN.Render.Function.Custom.Mouse_Pos_But_Check(Input.GetMousePosition(true), all_magic[i].pos) and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and not TBoN.Render.Variable.Bool.btn_pre then
                    TBoN.Render.Variable.Num.current_num = i
                    TBoN.Render.Variable.Bool.btn_pre = true
                    TBoN.Render.Variable.String.current_item = all_magic[i].magic or false
                    TBoN.Render.Function.Sprite.current_item_render = all_magic[i].sprite
                elseif TBoN.Render.Function.Custom.Mouse_Pos_But_Check(Input.GetMousePosition(true), all_magic[i].pos) and TBoN.Render.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    TBoN.Render.Variable.Bool.btn_pre = false
                    local temp_magic = all_magic[i].magic
                    all_magic[i].magic = TBoN.Render.Variable.String.current_item
                    all_magic[TBoN.Render.Variable.Num.current_num].magic = temp_magic
                    TBoN.Render.Function.Custom.Split_Merged_To_Original(all_magic)
                elseif not TBoN.Render.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), all_magic, 3) and TBoN.Render.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    if TBoN.Render.Variable.String.current_item and TBoN.Render.Variable.String.current_item ~= false then
                        all_magic[TBoN.Render.Variable.Num.current_num].magic = false
                        TBoN.Render.Function.Custom.Split_Merged_To_Original(all_magic)
                        Isaac.Spawn(5, 799, TBoN.Render.Table.actions_map[TBoN.Render.Variable.String.current_item],
                            Isaac.GetPlayer().Position + 70 * TBoN.Gun.Function.Vector.Aim_direc, Vector(0, 0), nil)
                    end
                    TBoN.Render.Variable.Bool.btn_pre = false
                end
            end
        end
        if TBoN.Render.Variable.Bool.btn_pre and TBoN.Render.Function.Sprite.current_item_render then
            TBoN.Render.Function.Sprite.current_item_render:Render(Isaac.WorldToScreen(Input.GetMousePosition(true)))
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.Chose_Render)

function TBoN_MOD:gun_rotation(player) --玩家手中物品渲染
    if player:GetPlayerType() ~= TBoN.Character.Variable.Num.Mina_Type then
        return
    end
    TBoN.Gun.Function.Vector.Aim_direc = (Input.GetMousePosition(true) - player.Position):Normalized()
    TBoN.Render.Variable.Num.radians = math.atan(TBoN.Gun.Function.Vector.Aim_direc.Y /
        TBoN.Gun.Function.Vector.Aim_direc.X)
    local degrees
    if TBoN.Gun.Function.Vector.Aim_direc.X < 0 then
        degrees = 180 + math.deg(TBoN.Render.Variable.Num.radians)
    else
        degrees = math.deg(TBoN.Render.Variable.Num.radians)
    end
    if TBoN.Render.Variable.Num.item_groove <= 4 then
        if TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove] and TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove].name then
            TBoN.Render.Function.Sprite.hand_sprite:Render(Isaac.WorldToScreen(player.Position) + Vector(0, -5))
            TBoN.Render.Function.Sprite.hand_sprite.Rotation = degrees
        end
    else
        if TBoN.Render.Table.item[TBoN.Render.Variable.Num.item_groove - 4].item then
            TBoN.Render.Function.Sprite.hand_sprite:Render(Isaac.WorldToScreen(player.Position) + Vector(0, -5))
            TBoN.Render.Function.Sprite.hand_sprite.Rotation = degrees
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, TBoN_MOD.gun_rotation)

function TBoN_MOD:Anm2_load() --加载anm2
    if TBoN.Render.Variable.Bool.anm_load == true then
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Function.Sprite.full_inventory_box,
            "gfx/ui/inventory/full_inventory_box.anm2")
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Function.Sprite.full_inventory_box_highlight,
            "gfx/ui/inventory/full_inventory_box_highlight.anm2")
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Function.Sprite.background, "gfx/ui/inventory/background.anm2")
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Function.Sprite.info_box, "gfx/ui/inventory/info_box.anm2")
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Function.Sprite.gun_info_bg,
            "gfx/ui/inventory/gun_info_bg.anm2")
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Function.Sprite.magic_info_bg,
            "gfx/ui/inventory/magic_info_bg.anm2")
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Table.Bar, "")
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Table.gun_des_render_table, "")
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Table.magic_des_render_table, "")
        TBoN.Render.Function.Font.font:Load("font/luaminioutlined.fnt")
        if EID and TBoN.Render.Function.Font.font_cn:Load("mods/external item descriptions_836319872/resources/font/eid_cn_alt.fnt.fnt") then
        else
            TBoN.Render.Function.Font.font_cn:Load("font/cjk/lanapixel.fnt")
        end
        for i, ma in pairs(TBoN.Render.Table.bag_magic_render_table) do
            local magic_id = TBoN.Magic.Table.bag_magic_data[i] and TBoN.Magic.Table.bag_magic_data[i].magic_id
            if magic_id and magic_id ~= 0 then
                ma.sprite:Load(
                    "gfx/ui/gun_actions/" .. string.lower(magic_id) .. ".anm2",
                    true)
                ma.sprite:Play("Idle", true)
            end
        end
        for i = 1, 4 do
            if TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name then
                TBoN.Render.Table.gun_render_table[i].sprite:Load(
                    "gfx/gun/" .. TBoN.Gun.Table.gun_info[i].name .. ".anm2",
                    true)
                TBoN.Render.Table.gun_render_table[i].sprite:Play("Idle", true)
            end
            local capacity = TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].capacity or 0
            for j = 1, capacity do
                local magicData = TBoN.Gun.Table.gun_magic_data[i][j]
                if magicData and magicData.magic_id and magicData.magic_id ~= false then
                    local magicSlot = TBoN.Render.Table.gun_magic_render_table[i][j]
                    if magicSlot then
                        -- 直接使用法术ID加载对应图片
                        magicSlot.sprite:Load(
                            "gfx/ui/gun_actions/" .. string.lower(magicData.magic_id) .. ".anm2",
                            true)
                        magicSlot.sprite:Play("Idle", true)
                    end
                end
            end
        end
        TBoN.Render.Variable.Bool.anm_load = false
    end
    if TBoN.Render.Variable.Bool.hand_switch == true then
        if TBoN.Render.Variable.Num.item_groove <= 4 then
            if TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove] and TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove].name then
                TBoN.Render.Variable.String.hand_string = TBoN.Render.Table.gun_render_table
                    [TBoN.Render.Variable.Num.item_groove].sprite:GetFilename()
            end
        else
            if TBoN.Render.Table.item[TBoN.Render.Variable.Num.item_groove - 4].item then
                TBoN.Render.Variable.String.hand_string = TBoN.Render.Table.item
                    [TBoN.Render.Variable.Num.item_groove - 4].sprite:GetFilename()
            end
        end
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Function.Sprite.hand_sprite,
            TBoN.Render.Variable.String.hand_string)
        TBoN.Render.Variable.Bool.hand_switch = false
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_UPDATE, TBoN_MOD.Anm2_load)
