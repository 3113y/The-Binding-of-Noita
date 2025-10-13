include("scripts.guns.gun_actions")
include("scripts.renders.render_used_functions")
TBoN.UI.Variable.Bool.Tab_Confirm = false             --当前是否属于背包界面
TBoN.UI.Variable.Bool.anm_load = true                  --是否加载一遍anm2
TBoN.UI.Variable.Bool.hand_switch = true               --手中物品是否更新
TBoN.UI.Variable.Bool.btn_pre = false                  --是否按下左键
TBoN.UI.Variable.Num.item_groove = 1                   --物品栏选中/高光位置
TBoN.UI.Variable.Num.current_num = 1                   --当前所选取的物品索引
TBoN.UI.Variable.Num.chose_type = 0                    --左键拿起类型（法杖/物品/法术）
TBoN.UI.Variable.String.pattern = ".+/(.+)%..+"        --拼接用字符串
TBoN.UI.Variable.String.hand_string = ""               --手中物品anm2路径
TBoN.UI.Variable.String.current_item = ""              --当前左键拿起的物品名称
TBoN.UI.Function.Sprite.current_item_render = Sprite() --当前左键拿起的物品渲染的sprite
TBoN.UI.Function.Sprite.hand_sprite = Sprite()
TBoN.UI.Function.Sprite.full_inventory_box = Sprite()
TBoN.UI.Function.Sprite.full_inventory_box_highlight = Sprite()
TBoN.UI.Function.Sprite.background = Sprite()
TBoN.UI.Function.Sprite.info_box = Sprite()
TBoN.UI.Function.Font.font = Font()
function TBoN_MOD:IG_Choose() --滚轮选择
    if Input.GetMouseWheel().Y < 0 then
        if TBoN.UI.Variable.Num.item_groove >= 8 then
            TBoN.UI.Variable.Num.item_groove = 1
            TBoN.UI.Variable.Bool.hand_switch = true
        else
            TBoN.UI.Variable.Num.item_groove = TBoN.UI.Variable.Num.item_groove + 1
            TBoN.UI.Variable.Bool.hand_switch = true
        end
    elseif Input.GetMouseWheel().Y > 0 then
        if TBoN.UI.Variable.Num.item_groove <= 1 then
            TBoN.UI.Variable.Num.item_groove = 8
            TBoN.UI.Variable.Bool.hand_switch = true
        else
            TBoN.UI.Variable.Num.item_groove = TBoN.UI.Variable.Num.item_groove - 1
            TBoN.UI.Variable.Bool.hand_switch = true
        end
        TBoN.UI.Variable.Bool.hand_switch = true
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.IG_Choose)

function TBoN_MOD:TAB_Switch(player) --TAB模式切换
    if Input.IsButtonTriggered(Keyboard.KEY_TAB, player.ControllerIndex) then
        TBoN.UI.Variable.Bool.Tab_Confirm = not TBoN.UI.Variable.Bool.Tab_Confirm
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, TBoN_MOD.TAB_Switch)
function TBoN_MOD:NO_TAB_UI_Render() --按下Tab前UI渲染
    if not TBoN.UI.Variable.Bool.Tab_Confirm then
        for _, p in pairs(TBoN.UI.Table.gun_render_table) do
            TBoN.UI.Function.Sprite.full_inventory_box:Render(p.pos)
        end
        for _, p in pairs(TBoN.UI.Table.item) do
            TBoN.UI.Function.Sprite.full_inventory_box:Render(p.pos)
        end

        if TBoN.UI.Variable.Num.item_groove <= 4 then
            TBoN.UI.Function.Sprite.full_inventory_box_highlight:Render(TBoN.UI.Table.gun_render_table
            [TBoN.UI.Variable.Num.item_groove].pos)
        else
            TBoN.UI.Function.Sprite.full_inventory_box_highlight:Render(TBoN.UI.Table.item[TBoN.UI.Variable.Num.item_groove - 4].pos)
        end
        for i, p in pairs(TBoN.UI.Table.gun_render_table) do
            TBoN.UI.Function.Sprite.full_inventory_box:Render(p.pos) --法杖槽渲染
            if TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name then
                p.sprite:Render(p.pos + Vector(0, 9))
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.NO_TAB_UI_Render)

function TBoN_MOD:TAB_UI_Render() --按下Tab后UI渲染
    if TBoN.UI.Variable.Bool.Tab_Confirm then
        TBoN.UI.Function.Sprite.background:Render(Vector(47, 97))
        TBoN.UI.Function.Sprite.background.Rotation = 90
        for _, p in pairs(TBoN.UI.Table.gun_render_table) do
            TBoN.UI.Function.Sprite.full_inventory_box:Render(p.pos) --法杖槽渲染
        end
        for _, p in pairs(TBoN.UI.Table.item) do
            TBoN.UI.Function.Sprite.full_inventory_box:Render(p.pos) --物品槽渲染
        end
        for _, p in pairs(TBoN.UI.Table.magic) do
            TBoN.UI.Function.Sprite.full_inventory_box:Render(p.pos) --法术槽渲染
            if p.magic then
                TBoN.UI.Table.magic_background_render_table[TBoN.UI.Table.magic_background_type_map[actions[TBoN.UI.Table.actions_map[p.magic]].type]].sprite
                    :Render(p.pos)     --法术壳渲染（我说嵌套好写没人读
                p.sprite:Render(p.pos) --法术渲染
            end
        end
        if TBoN.UI.Variable.Num.item_groove > 4 then
            TBoN.UI.Function.Sprite.full_inventory_box_highlight:Render(TBoN.UI.Table.item[TBoN.UI.Variable.Num.item_groove - 4].pos)
        else
            TBoN.UI.Function.Sprite.full_inventory_box_highlight:Render(TBoN.UI.Table.gun_render_table
            [TBoN.UI.Variable.Num.item_groove].pos)
        end
        for i, p in pairs(TBoN.UI.Table.gun_render_table) do
            TBoN.UI.Function.Sprite.full_inventory_box:Render(p.pos) --法杖槽渲染
            if TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name then
                p.sprite:Render(p.pos + Vector(0, 9))
            end
        end
        for j, p in pairs(TBoN.UI.Table.gun_render_table) do
            if TBoN.Gun.Table.gun_info[j].name then
                TBoN.UI.Function.Sprite.info_box:Render(TBoN.UI.Table.info_box_pos[j].pos)
                p.sprite:Render(TBoN.UI.Table.info_box_pos[j].pos + Vector(2, 11))
                TBoN.UI.Table.gun_info_render_table[1].sprite:Render(TBoN.UI.Table.info_box_pos[j].pos + Vector(27, 5))
                TBoN.UI.Table.gun_info_render_table[2].sprite:Render(TBoN.UI.Table.info_box_pos[j].pos + Vector(27, 15))
                -- 分开渲染标签和值
                TBoN.UI.Function.Font.font:DrawString(TBoN.UI.Table.gun_info_render_table[1].name,
                    TBoN.UI.Table.info_box_pos[j].pos.X + 35 + #(TBoN.UI.Table.gun_info_render_table[1].name) * 5, TBoN.UI.Table.info_box_pos[j].pos.Y + 1,
                    KColor.White, 1)
                TBoN.UI.Function.Font.font:DrawString(TBoN.Gun.Table.gun_info[j].shuffle and " true" or "false",
                    TBoN.UI.Table.info_box_pos[j].pos.X + 85 + 20,
                    TBoN.UI.Table.info_box_pos[j].pos.Y + 1, KColor.Yellow, 1)
                TBoN.UI.Function.Font.font:DrawString(TBoN.UI.Table.gun_info_render_table[2].name,
                    TBoN.UI.Table.info_box_pos[j].pos.X + 36 + #(TBoN.UI.Table.gun_info_render_table[2].name) * 5, TBoN.UI.Table.info_box_pos[j].pos.Y + 11,
                    KColor.White, 1)
                TBoN.UI.Function.Font.font:DrawString(tostring(TBoN.Gun.Table.gun_info[j].capacity),
                    TBoN.UI.Table.info_box_pos[j].pos.X + 85 + #tostring(TBoN.Gun.Table.gun_info[j].capacity) * 5, TBoN.UI.Table.info_box_pos[j].pos.Y + 11,
                    KColor.Cyan, 1)
            end
        end
        for gunIndex, g in pairs(TBoN.UI.Table.gun_render_table) do
            if TBoN.Gun.Table.gun_info[gunIndex] and TBoN.Gun.Table.gun_info[gunIndex].name then
                for k = 1, TBoN.Gun.Table.gun_info[gunIndex].capacity do
                    if TBoN.UI.Table.gun_magic_render_table[gunIndex][k] then
                        TBoN.UI.Function.Sprite.full_inventory_box:Render(TBoN.UI.Table.gun_magic_render_table[gunIndex][k].pos)
                        if TBoN.Gun.Table.gun_magic_data[gunIndex][k] then
                            TBoN.UI.Table.gun_magic_render_table[gunIndex][k].sprite:Render(TBoN.UI.Table.gun_magic_render_table[gunIndex][k].pos)
                            TBoN.UI.Table.magic_background_render_table[TBoN.UI.Table.magic_background_type_map[actions[TBoN.UI.Table.actions_map[TBoN.Gun.Table.gun_magic_data[gunIndex][k]]].type]]
                                .sprite:Render(TBoN.UI.Table.gun_magic_render_table[gunIndex][k].pos)
                        end
                    end
                end
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.TAB_UI_Render)
function TBoN_MOD:Chose_Render() --按下左键时和后的法法杖/物品/法术交换逻辑和渲染逻辑
    if TBoN.UI.Variable.Bool.Tab_Confirm then
        if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and TBoN.UI.Variable.Bool.btn_pre == false then
            all_magic = TBoN.UI.Function.Custom.mergeMagicAndGunMagic(TBoN.UI.Table.magic, TBoN.UI.Table.gun_render_table)
            if TBoN.UI.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), TBoN.UI.Table.gun_render_table, 1) then
                TBoN.UI.Variable.Num.chose_type = 1
            elseif TBoN.UI.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), TBoN.UI.Table.item, 2) then
                TBoN.UI.Variable.Num.chose_type = 2
            elseif TBoN.UI.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), all_magic, 3) then
                TBoN.UI.Variable.Num.chose_type = 3
            else
                TBoN.UI.Variable.Num.chose_type = 0
            end
        end
        if TBoN.UI.Variable.Num.chose_type == 1 then
            for i = 1, #TBoN.UI.Table.gun_render_table do
                if TBoN.UI.Function.Custom.Mouse_Pos_But_Check(Input.GetMousePosition(true), TBoN.UI.Table.gun_render_table[i].pos) and TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and not TBoN.UI.Variable.Bool.btn_pre then
                    TBoN.UI.Variable.Num.current_num = i
                    TBoN.UI.Variable.String.current_item = TBoN.Gun.Table.gun_info[i].name
                    TBoN.UI.Function.Sprite.current_item_render = TBoN.UI.Table.gun_render_table[i].sprite
                    TBoN.UI.Variable.Bool.btn_pre = true
                elseif TBoN.UI.Function.Custom.Mouse_Pos_But_Check(Input.GetMousePosition(true), TBoN.UI.Table.gun_render_table[i].pos) and TBoN.UI.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    TBoN.UI.Function.Custom.swapGunGroups(TBoN.UI.Table.gun_render_table, TBoN.UI.Variable.Num.current_num, i)
                    TBoN.UI.Variable.Bool.btn_pre = false
                    TBoN.UI.Variable.Bool.hand_switch = true
                elseif not TBoN.UI.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), TBoN.UI.Table.gun_render_table, 1) and TBoN.UI.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    TBoN.UI.Variable.Bool.btn_pre = false
                    TBoN.UI.Variable.Bool.hand_switch = true
                end
            end
            TBoN.UI.Variable.Bool.anm_load = true
        elseif TBoN.UI.Variable.Num.chose_type == 2 then
            for i = 1, #TBoN.UI.Table.item do
                if TBoN.UI.Function.Custom.Mouse_Pos_But_Check(Input.GetMousePosition(true), TBoN.UI.Table.item[i].pos) and TBoN.UI.Table.item[i].gun and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and not TBoN.UI.Variable.Bool.btn_pre then
                    TBoN.UI.Variable.Num.current_num = i
                    TBoN.UI.Variable.Bool.btn_pre = true
                    TBoN.UI.Variable.String.current_item = TBoN.UI.Table.item[i].item
                    TBoN.UI.Function.Sprite.current_item_render = TBoN.UI.Table.item[i].sprite
                    TBoN.UI.Table.item[i].item = false
                elseif TBoN.UI.Function.Custom.Mouse_Pos_But_Check(Input.GetMousePosition(true), TBoN.UI.Table.item[i].pos) and TBoN.UI.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    TBoN.UI.Variable.Bool.btn_pre = false
                    if TBoN.UI.Table.item[i].item then
                        TBoN.UI.Table.item[TBoN.UI.Variable.Num.current_num].item = TBoN.UI.Table.item[i].item
                        TBoN.UI.Table.item[i].item = TBoN.UI.Variable.String.current_item
                    else
                        TBoN.UI.Table.item[i].item = TBoN.UI.Variable.String.current_item
                    end
                elseif not TBoN.UI.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), TBoN.UI.Table.item, 2) and TBoN.UI.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    TBoN.UI.Variable.Bool.btn_pre = false
                end
            end
            TBoN.UI.Variable.Bool.anm_load = true
        elseif TBoN.UI.Variable.Num.chose_type == 3 then
            for i = 1, #all_magic do
                if TBoN.UI.Function.Custom.Mouse_Pos_But_Check(Input.GetMousePosition(true), all_magic[i].pos) and all_magic[i].magic and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and not TBoN.UI.Variable.Bool.btn_pre then
                    TBoN.UI.Variable.Num.current_num = i
                    TBoN.UI.Variable.Bool.btn_pre = true
                    TBoN.UI.Variable.String.current_item = all_magic[i].magic
                    TBoN.UI.Function.Sprite.current_item_render = all_magic[i].sprite
                    all_magic[i].magic = false
                elseif TBoN.UI.Function.Custom.Mouse_Pos_But_Check(Input.GetMousePosition(true), all_magic[i].pos) and TBoN.UI.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    TBoN.UI.Variable.Bool.btn_pre = false
                    if all_magic[i].magic then
                        all_magic[TBoN.UI.Variable.Num.current_num].magic = all_magic[i].magic
                        all_magic[i].magic = TBoN.UI.Variable.String.current_item
                    else
                        all_magic[i].magic = TBoN.UI.Variable.String.current_item
                    end
                    TBoN.UI.Function.Custom.splitMergedToOriginal(all_magic, TBoN.UI.Table.magic, TBoN.UI.Table.gun_render_table)
                elseif not TBoN.UI.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), all_magic, 3) and TBoN.UI.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    TBoN.UI.Variable.Bool.btn_pre = false
                    all_magic[TBoN.UI.Variable.Num.current_num].magic = TBoN.UI.Variable.String.current_item
                    TBoN.UI.Function.Custom.splitMergedToOriginal(all_magic, TBoN.UI.Table.magic, TBoN.UI.Table.gun_render_table)
                end
            end

            TBoN.UI.Variable.Bool.anm_load = true
        end
        if TBoN.UI.Variable.Bool.btn_pre and TBoN.UI.Function.Sprite.current_item_render then
            TBoN.UI.Function.Sprite.current_item_render:Render(Isaac.WorldToScreen(Input.GetMousePosition(true)))
            if TBoN.UI.Variable.Num.chose_type == 3 then
                TBoN.UI.Table.magic_background_render_table
                    [TBoN.UI.Table.magic_background_type_map[actions[TBoN.UI.Table.actions_map[TBoN.UI.Variable.String.current_item]].type]].sprite
                    :Render(Isaac
                        .WorldToScreen(Input.GetMousePosition(true)))
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.Chose_Render)
function TBoN_MOD:gun_rotation(player) --玩家手中物品渲染
    TBoN.Gun.Function.Vector.Aim_direc = Vector(
        (Input.GetMousePosition(true).X - player.Position.X) /
        math.sqrt((Input.GetMousePosition(true).X - player.Position.X) ^ 2 +
            (Input.GetMousePosition(true).Y - player.Position.Y) ^ 2),
        (Input.GetMousePosition(true).Y - player.Position.Y) /
        math.sqrt((Input.GetMousePosition(true).X - player.Position.X) ^ 2 +
            (Input.GetMousePosition(true).Y - player.Position.Y) ^ 2))
    TBoN.UI.Variable.Num.radians = math.atan(TBoN.Gun.Function.Vector.Aim_direc.Y / TBoN.Gun.Function.Vector.Aim_direc.X)
    local degrees
    if TBoN.Gun.Function.Vector.Aim_direc.X < 0 then
        degrees = 180 + math.deg(TBoN.UI.Variable.Num.radians)
    else
        degrees = math.deg(TBoN.UI.Variable.Num.radians)
    end
    if TBoN.UI.Variable.Num.item_groove <= 4 then
        if TBoN.Gun.Table.gun_info[TBoN.UI.Variable.Num.item_groove] and TBoN.Gun.Table.gun_info[TBoN.UI.Variable.Num.item_groove].name then
            TBoN.UI.Function.Sprite.hand_sprite:Render(Isaac.WorldToScreen(player.Position) + Vector(0, -5))
            TBoN.UI.Function.Sprite.hand_sprite.Rotation = degrees
        end
    else
        if TBoN.UI.Table.item[TBoN.UI.Variable.Num.item_groove - 4].item then
            TBoN.UI.Function.Sprite.hand_sprite:Render(Isaac.WorldToScreen(player.Position) + Vector(0, -5))
            TBoN.UI.Function.Sprite.hand_sprite.Rotation = degrees
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, TBoN_MOD.gun_rotation)

function Anm2_load() --加载anm2
    if TBoN.UI.Variable.Bool.anm_load == true then
        TBoN.UI.Function.Sprite.full_inventory_box:Load("gfx/ui/inventory/full_inventory_box.anm2")
        TBoN.UI.Function.Sprite.full_inventory_box_highlight:Load("gfx/ui/inventory/full_inventory_box_highlight.anm2")
        TBoN.UI.Function.Sprite.background:Load("gfx/ui/inventory/background.anm2")
        TBoN.UI.Function.Sprite.info_box:Load("gfx/ui/inventory/info_box.anm2")
        TBoN.UI.Function.Sprite.full_inventory_box:Play("Idle", true)
        TBoN.UI.Function.Sprite.full_inventory_box_highlight:Play("Idle", true)
        TBoN.UI.Function.Sprite.background:Play("Idle", true)
        TBoN.UI.Function.Sprite.info_box:Play("Idle", true)
        TBoN.UI.Function.Font.font:Load("font/luaminioutlined.fnt")
        for _, ma in pairs(TBoN.UI.Table.magic) do
            if ma.magic then
                ma.sprite:Load(
                    "gfx/ui/gun_actions/" ..
                    actions[TBoN.UI.Table.actions_map[ma.magic]].sprite:match(TBoN.UI.Variable.String.pattern) .. ".anm2",
                    true)
                ma.sprite:Play("Idle", true)
            end
        end
        --[[for _, pa in pairs(particle_render) do
            pa.sprite:Load("gfx/particle/purple.anm2", true)
            pa.sprite:Play("Idle", true)
        end]]
        for _, gi in pairs(TBoN.UI.Table.gun_info_render_table) do
            gi.sprite:Load(gi.load, true)
            gi.sprite:Play("Idle", true)
        end
        for i = 1, 4 do
            if TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name then
                TBoN.UI.Table.gun_render_table[i].sprite:Load("gfx/gun/" .. TBoN.Gun.Table.gun_info[i].name .. ".anm2", true)
                TBoN.UI.Table.gun_render_table[i].sprite:Play("Idle", true)
            end
            local capacity = TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].capacity or 0
            for j = 1, capacity do
                local magicData = TBoN.Gun.Table.gun_magic_data[i][j]
                if magicData ~= false then
                    local magicSlot = TBoN.UI.Table.gun_magic_render_table[i][j]
                    if magicSlot then
                        magicSlot.sprite:Load(
                            "gfx/ui/gun_actions/" ..
                            actions[TBoN.UI.Table.actions_map[magicData]].sprite:match(TBoN.UI.Variable.String.pattern) .. ".anm2",
                            true)
                        magicSlot.sprite:Play("Idle", true)
                    end
                end
            end
        end
        for _, bg in pairs(TBoN.UI.Table.magic_background_render_table) do
            bg.sprite:Load("gfx/ui/inventory/item_bg_" .. bg.name .. ".anm2")
            bg.sprite:Play("Idle", true)
        end
        TBoN.UI.Variable.Bool.anm_load = false
    end
    if TBoN.UI.Variable.Bool.hand_switch == true then
        if TBoN.UI.Variable.Num.item_groove <= 4 then
            if TBoN.Gun.Table.gun_info[TBoN.UI.Variable.Num.item_groove] and TBoN.Gun.Table.gun_info[TBoN.UI.Variable.Num.item_groove].name then
                TBoN.UI.Variable.String.hand_string = TBoN.UI.Table.gun_render_table[TBoN.UI.Variable.Num.item_groove].sprite
                :GetFilename()
            end
        else
            if TBoN.UI.Table.item[TBoN.UI.Variable.Num.item_groove - 4].item then
                TBoN.UI.Variable.String.hand_string = TBoN.UI.Table.item[TBoN.UI.Variable.Num.item_groove - 4].sprite:GetFilename()
            end
        end
        ---@diagnostic disable-next-line: param-type-mismatch
        TBoN.UI.Function.Sprite.hand_sprite:Load(TBoN.UI.Variable.String.hand_string)
        TBoN.UI.Function.Sprite.hand_sprite:Play("Idle")
        TBoN.UI.Variable.Bool.hand_switch = false
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_UPDATE, Anm2_load)
