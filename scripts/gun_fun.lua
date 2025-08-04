local fire_cold = 1
local fire_state = false
local Aim_direc
--黑洞

local Black_Hole_Entity = Isaac.GetEntityTypeByName("Black Hole")
local Black_Hole_Variant = Isaac.GetEntityVariantByName("Black Hole")

--生成逻辑

--碰撞逻辑
function TBoN_MOD:Black_Hole_Collision(Entity, GridIndex, GridEntity)
    if Entity.Variant == Black_Hole_Variant then
        GridEntity:Destroy()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_NPC_GRID_COLLISION, TBoN_MOD.Black_Hole_Collision, Black_Hole_Entity)
--吸引逻辑
--消失逻辑
function TBoN_MOD:Black_Hole_Disappear(entity)
    if entity.Position.X < -80 or entity.Position.X > 800 or entity.Position.Y < 0 or entity.Position.Y > 600 then
        entity:Kill()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_NPC_UPDATE, TBoN_MOD.Black_Hole_Disappear, Black_Hole_Entity)
--移除生成烟雾
function TBoN_MOD:Spawn_Animation_Remove(entity)
    if entity.Type == 1000 and entity.Variant == 15 then
        if entity.SpawnerType == Black_Hole_Entity then
            return false
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, TBoN_MOD.Spawn_Animation_Remove)
local gun = Sprite()
gun:Load("gfx/gun/guns.anm2")
gun:Play("wand_0000", true)
function TBoN_MOD:gun_rotation(player)
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
    gun:Render(Isaac.WorldToScreen(player.Position) + Vector(0, -5))
    gun.Rotation = degrees
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, TBoN_MOD.gun_rotation)
--按键处理
function TBoN_MOD:Input_Check()
    fire_cold = fire_cold + 1
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Game():GetPlayer(i)
        if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) == true and fire_cold >= 10 then
            Options.FoundHUD = false
            fire_cold = 1
            fire_state = true
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, TBoN_MOD.Input_Check)
--实体生成
function TBoN_MOD:Magic_Spawn(player)
    if fire_state == true then
        if not Tab_Confirm then
            Aim_direc = Vector(
                (Input.GetMousePosition(true).X - player.Position.X) /
                math.sqrt((Input.GetMousePosition(true).X - player.Position.X) ^ 2 +
                    (Input.GetMousePosition(true).Y - player.Position.Y) ^ 2),
                (Input.GetMousePosition(true).Y - player.Position.Y) /
                math.sqrt((Input.GetMousePosition(true).X - player.Position.X) ^ 2 +
                    (Input.GetMousePosition(true).Y - player.Position.Y) ^ 2))
            entity = Isaac.Spawn(Black_Hole_Entity,
                Black_Hole_Variant,
                0,
                player.Position + Aim_direc * 40,
                Aim_direc * 10,
                player)
            sprite = entity:GetSprite()
            sprite:Play("Idle", true)
            fire_state = false
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, TBoN_MOD.Magic_Spawn)

--[[function TBoN_MOD:OnPreEntityspawn(type, variant, subtype, position)
    if type == Black_Hole_Entity and variant == Black_Hole_Variant then
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, TBoN_MOD.OnPreEntityspawn)
]]
