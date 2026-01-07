---@diagnostic disable: assign-type-mismatch
include("scripts.guns.gun_actions")
include("scripts.renders.render_used_functions")
include("scripts.renders.translations")
TBoN.Render.Variable.Bool.Tab_Confirm = false              --当前是否属于背包界面
TBoN.Render.Variable.Bool.anm_load = true                  --是否加载一遍anm2
TBoN.Render.Variable.Bool.hand_switch = true               --手中物品是否更新 【手上物品渲染相关】
TBoN.Render.Variable.Bool.btn_pre = false                  --是否按下左键
TBoN.Render.Variable.Num.item_groove = 1                   --物品栏选中/高光位置
TBoN.Render.Variable.Num.current_num = 1                   --当前所选取的物品索引
TBoN.Render.Variable.Num.chose_type = 0                    --左键拿起类型（法杖/物品/法术）
TBoN.Render.Variable.Num.pos_type = 0                      --鼠标所处位置物品种类
TBoN.Render.Variable.Num.Hand_Item_Variant = Isaac.GetEntityVariantByName("Hand Item")
TBoN.Render.Variable.String.hand_string = ""               --手中物品anm2路径 【手上物品渲染相关】
TBoN.Render.Variable.String.current_item = ""              --当前左键拿起的物品名称
TBoN.Render.Function.Sprite.current_item_render = Sprite() --当前左键拿起的物品渲染的sprite
TBoN.Render.Function.Sprite.hand_sprite = Sprite()         --【手上物品渲染相关 - 手持sprite对象】
TBoN.Render.Function.Sprite.full_inventory_box = Sprite()
TBoN.Render.Function.Sprite.full_inventory_box_highlight = Sprite()
TBoN.Render.Function.Sprite.background = Sprite()
TBoN.Render.Function.Sprite.info_box = Sprite()
TBoN.Render.Function.Sprite.gun_info_bg = Sprite()
TBoN.Render.Function.Sprite.magic_info_bg = Sprite()
TBoN.Render.Function.Vector.Aim_direc = Vector(0, 0)
TBoN.Render.Function.Font.font = Font()
TBoN.Render.Function.Font.font_cn = Font()
TBoN.Render.Function.Font.font_num = Font()

function TBoN_MOD:Player_Input_Update(player) --玩家输入更新（滚轮选择 + TAB切换）
    -- 计算鼠标方向
    if Game():GetRoom():IsMirrorWorld() then
        TBoN.Gun.Function.Vector.Aim_direc = (Isaac.WorldToScreen(Input.GetMousePosition(true)) - Vector(Isaac.GetScreenWidth()- Isaac.WorldToScreen(player.Position).X, Isaac.WorldToScreen(player.Position).Y)):Normalized()
    else
        TBoN.Gun.Function.Vector.Aim_direc = (Input.GetMousePosition(true) - player.Position):Normalized()
    end
    TBoN.Render.Variable.Num.radians = math.atan(TBoN.Gun.Function.Vector.Aim_direc.Y /
        TBoN.Gun.Function.Vector.Aim_direc.X)
    -- 滚轮选择物品槽位
    if REPENTOGON then
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
        end
    else
        if Input.IsButtonTriggered(Keyboard.KEY_SPACE, player.ControllerIndex) then
            if TBoN.Render.Variable.Num.item_groove >= 8 then
                TBoN.Render.Variable.Num.item_groove = 1
                TBoN.Render.Variable.Bool.hand_switch = true
            else
                TBoN.Render.Variable.Num.item_groove = TBoN.Render.Variable.Num.item_groove + 1
                TBoN.Render.Variable.Bool.hand_switch = true
            end
        elseif Input.IsMouseBtnPressed(4) then
            if TBoN.Render.Variable.Num.item_groove <= 1 then
                TBoN.Render.Variable.Num.item_groove = 8
                TBoN.Render.Variable.Bool.hand_switch = true
            else
                TBoN.Render.Variable.Num.item_groove = TBoN.Render.Variable.Num.item_groove - 1
                TBoN.Render.Variable.Bool.hand_switch = true
            end
        end
    end

    -- TAB模式切换
    if player:GetPlayerType() == TBoN.Character.Variable.Num.Mina_Type then
        if Input.IsButtonTriggered(Keyboard.KEY_B, player.ControllerIndex) then
            TBoN.Render.Variable.Bool.Tab_Confirm = not TBoN.Render.Variable.Bool.Tab_Confirm
        end
    else
        TBoN.Render.Variable.Bool.Tab_Confirm = nil
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, TBoN_MOD.Player_Input_Update)

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
        for i, ba in pairs(TBoN.Render.Table.Bar) do
            if TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove] and 
               TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove].mana_max and 
               TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove].mana_max ~= 0 and
               TBoN.Gun.Table.gun_states[TBoN.Render.Variable.Num.item_groove] then
                if i == 1 then
                    local mana = TBoN.Gun.Table.gun_states[TBoN.Render.Variable.Num.item_groove].current_mana or 100
                    local percent = mana / TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove].mana_max
                    local frame = math.max(0, math.min(100, math.floor(percent * 100)))
                    ba.sprite:SetFrame(frame)
                    ba.sprite:Render(ba.pos)
                else
                    local recharge_time = math.max(1,
                        TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove].recharge_time or 1)
                    local recharge_cd = math.max(0, TBoN.Gun.Table.gun_states[TBoN.Render.Variable.Num.item_groove]
                        .recharge_cooldown or 0)
                    local percent = recharge_cd / recharge_time
                    local frame = math.max(0, math.min(100, math.floor(percent * 100)))
                    ba.sprite:SetFrame(100 - frame)
                    ba.sprite:Render(ba.pos)
                end
            end
        end
        for i, p in pairs(TBoN.Render.Table.gun_render_table) do
            TBoN.Render.Function.Sprite.full_inventory_box:Render(p.pos) --法杖槽渲染
            if TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name then
                p.sprite:Render(p.pos + Vector(0, 9))
                local min_uses = TBoN.Render.Function.Custom.Get_Wand_Min_Spell_Uses(i)
                if min_uses >= 0 then
                    TBoN.Render.Function.Font.font_num:DrawString(tostring(min_uses), p.pos.X + 14, p.pos.Y + 7,
                        KColor.White, 0)
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
            local magic_data = TBoN.Magic.Table.bag_magic_data[i]
            local magic_id = magic_data and magic_data.magic_id
            if magic_id and magic_id ~= 0 then
                p.sprite:Render(p.pos - Vector(1, 1))
                -- 渲染背包法术的剩余使用次数
                TBoN.Render.Function.Custom.Render_Spell_Uses_Count(p.pos, magic_data.current_uses)
            end
        end
        if TBoN.Render.Variable.Num.item_groove > 4 then
            TBoN.Render.Function.Sprite.full_inventory_box_highlight:Render(TBoN.Render.Table.item
                [TBoN.Render.Variable.Num.item_groove - 4].pos)
        else
            TBoN.Render.Function.Sprite.full_inventory_box_highlight:Render(TBoN.Render.Table.gun_render_table
                [TBoN.Render.Variable.Num.item_groove].pos)
        end
        -- 统一循环渲染法杖相关内容（分三个阶段保持渲染顺序）
        for i, p in pairs(TBoN.Render.Table.gun_render_table) do
            -- 阶段1: 渲染法杖槽和法杖本体
            TBoN.Render.Function.Sprite.full_inventory_box:Render(p.pos)
            if TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name then
                p.sprite:Render(p.pos + Vector(0, 9))
                local min_uses = TBoN.Render.Function.Custom.Get_Wand_Min_Spell_Uses(i)
                if min_uses >= 0 then
                    TBoN.Render.Function.Font.font_num:DrawString(tostring(min_uses), p.pos.X + 14, p.pos.Y + 7,
                        KColor.White, 0)
                end
            end
        end
        for i, p in pairs(TBoN.Render.Table.gun_render_table) do
            -- 阶段2: 渲染法杖信息框
            if TBoN.Gun.Table.gun_info[i].name then
                TBoN.Render.Function.Sprite.info_box:Render(TBoN.Render.Table.info_box_pos[i].pos)
                p.sprite:Render(TBoN.Render.Table.info_box_pos[i].pos + Vector(2, 11))
                TBoN.Render.Table.gun_des_render_table[1].sprite:Render(TBoN.Render.Table.info_box_pos[i].pos +
                    Vector(27, 5))
                TBoN.Render.Table.gun_des_render_table[2].sprite:Render(TBoN.Render.Table.info_box_pos[i].pos +
                    Vector(27, 15))
                TBoN.Render.Function.Font.font:DrawString(TBoN.Render.Table.gun_des_render_table[1].name,
                    TBoN.Render.Table.info_box_pos[i].pos.X + 36, TBoN.Render.Table.info_box_pos[i].pos.Y + 1,
                    KColor.White, 0)
                TBoN.Render.Function.Font.font:DrawString(tostring(TBoN.Gun.Table.gun_info[i].shuffle),
                    TBoN.Render.Table.info_box_pos[i].pos.X + 85,
                    TBoN.Render.Table.info_box_pos[i].pos.Y + 1, KColor.Yellow, 0)
                TBoN.Render.Function.Font.font:DrawString(TBoN.Render.Table.gun_des_render_table[2].name,
                    TBoN.Render.Table.info_box_pos[i].pos.X + 36, TBoN.Render.Table.info_box_pos[i].pos.Y + 11,
                    KColor.White, 0)
                TBoN.Render.Function.Font.font:DrawString(tostring(TBoN.Gun.Table.gun_info[i].capacity),
                    TBoN.Render.Table.info_box_pos[i].pos.X + 85, TBoN.Render.Table.info_box_pos[i].pos.Y + 11,
                    KColor.Cyan, 0)
            end
        end
        for i, p in pairs(TBoN.Render.Table.gun_render_table) do
            -- 阶段3: 渲染法杖内的法术
            if TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].name then
                for k = 1, TBoN.Gun.Table.gun_info[i].capacity do
                    if TBoN.Render.Table.gun_magic_render_table[i][k] then
                        TBoN.Render.Function.Sprite.full_inventory_box:Render(TBoN.Render.Table.gun_magic_render_table[i][k].pos)
                        local magic_data = TBoN.Gun.Table.gun_magic_data[i][k]
                        if magic_data and magic_data.magic_id and magic_data.magic_id ~= false and magic_data.magic_id ~= 0 then
                            local spell_pos = TBoN.Render.Table.gun_magic_render_table[i][k].pos
                            TBoN.Render.Table.gun_magic_render_table[i][k].sprite:Render(spell_pos - Vector(1, 1))
                            if TBoN.Gun.Table.gun_info[i].always_cast then
                                TBoN.Render.Table.Always_cast[i].sprite:Render(TBoN.Render.Table.Always_cast[i].pos)
                            end
                            TBoN.Render.Function.Custom.Render_Spell_Uses_Count(spell_pos, magic_data.current_uses)
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
                    TBoN.Render.Function.Custom.Swap_Wand_Groups(TBoN.Render.Table.gun_render_table,
                        TBoN.Render.Variable.Num.current_num, i)
                    TBoN.Render.Variable.Bool.btn_pre = false
                    TBoN.Render.Variable.Bool.hand_switch = true
                elseif not TBoN.Render.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), TBoN.Render.Table.gun_render_table, 1) and TBoN.Render.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    -- 丢弃法杖逻辑
                    if TBoN.Render.Variable.String.current_item and TBoN.Render.Variable.String.current_item ~= false then
                        TBoN.World.Function.Custom.Drop_Wand(TBoN.Render.Variable.Num.current_num)
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
                    -- 交换法术ID和使用次数信息
                    local temp_magic = all_magic[i].magic
                    local temp_current_uses = all_magic[i].current_uses
                    local temp_max_uses = all_magic[i].max_uses

                    all_magic[i].magic = all_magic[TBoN.Render.Variable.Num.current_num].magic
                    all_magic[i].current_uses = all_magic[TBoN.Render.Variable.Num.current_num].current_uses
                    all_magic[i].max_uses = all_magic[TBoN.Render.Variable.Num.current_num].max_uses

                    all_magic[TBoN.Render.Variable.Num.current_num].magic = temp_magic
                    all_magic[TBoN.Render.Variable.Num.current_num].current_uses = temp_current_uses
                    all_magic[TBoN.Render.Variable.Num.current_num].max_uses = temp_max_uses

                    TBoN.Render.Function.Custom.Split_Merged_To_Original(all_magic)
                elseif not TBoN.Render.Function.Custom.Mouse_Pos_Pos_Check(Input.GetMousePosition(true), all_magic, 3) and TBoN.Render.Variable.Bool.btn_pre and not Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
                    if TBoN.Render.Variable.String.current_item and TBoN.Render.Variable.String.current_item ~= false then
                        local current_magic = all_magic[TBoN.Render.Variable.Num.current_num]
                        TBoN.World.Function.Custom.Drop_Spell(
                            TBoN.Render.Variable.String.current_item,
                            current_magic.current_uses,
                            current_magic.max_uses,
                            Isaac.GetPlayer().Position + 70 * TBoN.Gun.Function.Vector.Aim_direc,
                            Vector(0, 0)
                        )
                        all_magic[TBoN.Render.Variable.Num.current_num].magic = false
                        TBoN.Render.Function.Custom.Split_Merged_To_Original(all_magic)
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

function TBoN_MOD:Hand_Item_Update(entityeffect)
    local player = entityeffect.Parent
    if player.Velocity.Y < 0 then
        entityeffect.Position = player.Position + Vector(0, -1)
    else
        entityeffect.Position = player.Position + Vector(0, 1)
    end
    local degrees
    if TBoN.Gun.Function.Vector.Aim_direc.X < 0 then
        degrees = 180 + math.deg(TBoN.Render.Variable.Num.radians)
    else
        degrees = math.deg(TBoN.Render.Variable.Num.radians)
    end
    -- 镜世界渲染时需要翻转Y轴
    if Game():GetRoom():IsMirrorWorld() then
        degrees = -degrees + 180
    end
    entityeffect.SpriteScale = Vector(1.2, 1.2)
    entityeffect.SpriteRotation = degrees
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Hand_Item_Update,TBoN.Render.Variable.Num.Hand_Item_Variant)

function TBoN_MOD:Anm2_load(player) --加载anm2
    if player:GetPlayerType() ~= TBoN.Character.Variable.Num.Mina_Type then
        return
    end
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
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Table.gun_des_render_table, "")
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Table.magic_des_render_table, "")
        TBoN.Render.Function.Font.font:Load("font/luaminioutlined.fnt")
        TBoN.Render.Function.Font.font_num:Load("font/luamini.fnt")
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
                if TBoN.Gun.Table.gun_info[i].always_cast then
                    TBoN.Render.Table.Always_cast[i].sprite:Load(
                    "gfx/ui/gun_actions/" .. string.lower(TBoN.Gun.Table.gun_info[i].always_cast) .. "anm2", true)
                    TBoN.Render.Table.Always_cast[i].sprite:Play("Idle", true)
                end
            end
            local capacity = TBoN.Gun.Table.gun_info[i] and TBoN.Gun.Table.gun_info[i].capacity or 0
            for j = 1, capacity do
                local magicData = TBoN.Gun.Table.gun_magic_data[i][j]
                if magicData and magicData.magic_id and magicData.magic_id ~= false then
                    local magicSlot = TBoN.Render.Table.gun_magic_render_table[i][j]
                    if magicSlot then
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
        TBoN.Render.Function.Custom.Load_Anm2(TBoN.Render.Table.Bar, "")
        if TBoN.Render.Variable.Num.item_groove <= 4 then
            if TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove] and TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove].name then
                for i, entity in ipairs(Isaac.GetRoomEntities()) do
                    if entity.Type == 1000 and entity.Variant == TBoN.Render.Variable.Num.Hand_Item_Variant then
                        entity:Remove()
                    end
                end
                local entity = Isaac.Spawn(1000, TBoN.Render.Variable.Num.Hand_Item_Variant, 0,
                    player.Position + Vector(0, -1), Vector(0, 0), nil)
                local sprite = entity:GetSprite()
                entity.Parent = player
                entity.SpriteOffset = Vector(0, -4)
                sprite:Load(
                    "gfx/gun/" .. TBoN.Gun.Table.gun_info[TBoN.Render.Variable.Num.item_groove].name .. ".anm2",
                    true)
                sprite:Play("Idle", true)
            end
        else
        end
        TBoN.Render.Variable.Bool.hand_switch = false
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, TBoN_MOD.Anm2_load)
