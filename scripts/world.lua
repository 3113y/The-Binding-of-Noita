include("scripts.worlds.world_used_functions")

TBoN.World.Variable.Item.Magic = Isaac.GetItemIdByName("Magic")

function TBoN_MOD:Spawn_Magic()
    return TBoN.World.Variable.Item.Magic
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_GET_COLLECTIBLE, TBoN_MOD.Spawn_Magic)

function TBoN_MOD:Pickup_Magic_Render(entity)
    entity:GetSprite():ReplaceSpritesheet(1, "resources/gfx/items/magic_item.png")
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PICKUP_RENDER, TBoN_MOD.Pickup_Magic_Render, 100)
