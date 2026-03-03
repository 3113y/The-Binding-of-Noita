Deer = include("scripts.entities.entity.entity_logic.deer_logic")
function TBoN_MOD:Deer_Update(entity)
    Deer:Update(entity)
end

TBoN_MOD:AddCallback(ModCallbacks.MC_NPC_UPDATE, TBoN_MOD.Deer_Update, TBoN.Entity.Table.Info.Type.Deer)