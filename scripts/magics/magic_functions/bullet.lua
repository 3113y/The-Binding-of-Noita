function TBoN_MOD:Bullet_Init(entity)
    entity:GetSprite():Play("RegularTear6", true)
    entity.Rotation = 0
    entity.Height = -13
end
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, TBoN_MOD.Bullet_Init, 64)