function TBoN_MOD:Teleport_Projectiles(entity)
    if entity.Position.X < -80 or entity.Position.X > 800 or entity.Position.Y < 0 or entity.Position.Y > 600 then
        entity:Kill()
    end
    if entity.Timeout <= 0 then
        entity.Parent.Position = entity.Position
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Teleport_Projectiles, 802)
