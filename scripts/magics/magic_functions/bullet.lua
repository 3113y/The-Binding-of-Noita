function TBoN_MOD:Bullet_Init(entity)
    entity:GetSprite():Play("RegularTear6", true)
    entity.Rotation = 110
    entity.Height = -13
end
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_TEAR_RENDER, TBoN_MOD.Bullet_Init, 64)