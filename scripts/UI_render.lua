Tab_Confirm = false
anm_load = true
btn_pre = false
local temp_magic
local full_inventory_box = Sprite()
local full_inventory_box_highlight = Sprite()
local background = Sprite()
full_inventory_box:Load("gfx/ui/inventory/full_inventory_box.anm2")
full_inventory_box_highlight:Load("gfx/ui/inventory/full_inventory_box_highlight.anm2")
background:Load("gfx/ui/inventory/background.anm2")
full_inventory_box:Play("Idle", true)
full_inventory_box_highlight:Play("Idle", true)
background:Play("Idle", true)
function TBoN_MOD:UI_RENDER()
    for _, p in pairs(gun) do
        full_inventory_box:Render(p.pos)
    end
    for _, p in pairs(item) do
        full_inventory_box:Render(p.pos)
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.UI_RENDER)

--按下TAB后UI渲染
function TBoN_MOD:TAB_UI_Render()
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
    if Tab_Confirm then
        background:Render(Vector(47, 97))
        background.Rotation = 90
        for _, p in pairs(gun) do
            full_inventory_box:Render(p.pos)
        end
        for _, p in pairs(item) do
            full_inventory_box:Render(p.pos)
        end
        for _, p in pairs(magic) do
            full_inventory_box:Render(p.pos)
            if p.type then
                p.sprite:Render(p.pos)
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.TAB_UI_Render)
function TBoN_MOD:Chose_Render()
    for i = 1, #magic do
        if Tab_Confirm then
            if Mouse_Pos_Check(Input.GetMousePosition(true), magic[i].pos) and magic[i].type == true and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) == true then
                btn_pre = true
                magic[i].type = false
                temp_magic = magic[i].magic
                magic[i].magic = false
            elseif Mouse_Pos_Check(Input.GetMousePosition(true), magic[i].pos) and btn_pre == true and Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) == false then
                btn_pre = false
                magic[i].type = true
                magic[i].magic = temp_magic
                anm_load = true
            end
        end
    end
    if btn_pre == true then
        magic[1].sprite:Render(Isaac.WorldToScreen(Input.GetMousePosition(true)))
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_RENDER, TBoN_MOD.Chose_Render)
function Mouse_Pos_Check(Mouse_Pos, Aim_pos) --检测鼠标位置
    pos = Isaac.WorldToScreen(Mouse_Pos)
    if pos.X >= Aim_pos.X and pos.X <= Aim_pos.X + 20 then
        if pos.Y >= Aim_pos.Y and pos.Y <= Aim_pos.Y + 20 then
            return true
        else
            return false
        end
    end
end

function Anm2_load() --加载anm2
    local pattern = ".+/(.+)%..+"
    if anm_load == true then
        for _, ma in pairs(magic) do
            if ma.type == true then
                ma.sprite:Load("gfx/ui/gun_actions/" .. actions[actions_map[ma.magic]].sprite:match(pattern) .. ".anm2")
                ma.sprite:Play("Idle", true)
            end
        end
        anm_load = false
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_UPDATE, Anm2_load)
