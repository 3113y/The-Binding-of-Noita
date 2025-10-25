include("scripts.worlds.world_used_functions")
TBoN.World.Variable.Item.Magic = Isaac.GetItemIdByName("Magic")
function TBoN_MOD:Spawn_Magic()
    return TBoN.World.Variable.Item.Magic
end
TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_GET_COLLECTIBLE, TBoN_MOD.Spawn_Magic)