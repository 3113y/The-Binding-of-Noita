Deer = include("scripts.entities.entity.entity_logic.deer_logic")
function TBoN_MOD:Deer_Update(entity)
    entity.CanShutDoors = false
    Deer:Update(entity)
end

TBoN_MOD:AddCallback(ModCallbacks.MC_NPC_UPDATE, TBoN_MOD.Deer_Update, TBoN.Entity.Table.Info.Type.Deer)

function TBoN_MOD:Deer_Death(entity)
    Deer:Remove(entity)
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, TBoN_MOD.Deer_Death, TBoN.Entity.Table.Info.Type.Deer)
