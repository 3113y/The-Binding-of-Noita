function TBoN_MOD:Teleport_Projectiles(entity)
    if entity.Position.X < -80 or entity.Position.X > 800 or entity.Position.Y < 0 or entity.Position.Y > 600 then
        entity:Kill()
    end
    if entity.Timeout <= 0 then
        entity.Parent.Position = entity.Position
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Teleport_Projectiles, TBoN.Magic.Info.Variant.Teleport_Projectile)
