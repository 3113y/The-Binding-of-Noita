
--[[黑洞

local Black_Hole_Entity = Isaac.GetEntityTypeByName("Black Hole")
local Black_Hole_Variant = Isaac.GetEntityVariantByName("Black Hole")
--生成逻辑
function Gun_Action:Black_Hole(num)
    magic = {}
    if true then
        magic.Entity = Black_Hole_Entity
        magic.Variant = Black_Hole_Variant
        return magic
    end
end

--碰撞逻辑
function TBoN_MOD:Black_Hole_Collision(Entity, GridIndex, GridEntity)
    if Entity.Variant == Black_Hole_Variant then
        GridEntity:Destroy()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_NPC_GRID_COLLISION, TBoN_MOD.Black_Hole_Collision, Black_Hole_Entity)]]
--吸引逻辑
--消失逻辑
