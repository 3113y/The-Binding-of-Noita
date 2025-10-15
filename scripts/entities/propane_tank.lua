function TBoN_MOD:Propane_Tank_Action(entity)
    local chance = 0
    local rng    = RNG()
    rng:SetSeed(Game():GetSeeds():GetPlayerInitSeed())
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Game():GetPlayer(i)
        local distance = (entity.Position - player.Position):Length()
        if distance < 50 then
            chance = 0.002
        elseif distance < 300 then
            chance = 0.002 * (1 - (distance - 50) / 250)
        end
        if chance > 0 and rng:RandomFloat() < chance then
            entity:SetExplosionCountdown(0)
        end
        local degrees
        local v_aim
        if entity.Velocity:Length() > 0 then
            v_aim = math.atan(entity.Velocity.Y / entity.Velocity.X)
        else    
            v_aim = 0
        end
        if entity.Velocity.X > 0 then
            degrees = 90 + math.deg(v_aim)
        else
            degrees = math.deg(v_aim) - 90
        end
        entity.SpriteRotation = degrees
        entity.Velocity = entity.Velocity * 1.05 + RandomVector() * 0.85 +
        (player.Position - entity.Position)/(player.Position - entity.Position):Length() * 0.07
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, TBoN_MOD.Propane_Tank_Action, 799)

function TBoN_MOD:Propane_Tank_Appear(entity)
    entity.ExplosionDamage = 100
    entity.RadiusMultiplier = 3
    entity:SetExplosionCountdown(150)
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, TBoN_MOD.Propane_Tank_Appear, 799)
