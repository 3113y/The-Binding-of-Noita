function TBoN_MOD:Propane_Tank_Idle(entity)
    entity.SpriteRotation = entity.SpriteRotation + 5
end
TBoN_MOD:AddCallback(ModCallbacks.MC_NPC_UPDATE, TBoN_MOD.Propane_Tank_Idle, 749)