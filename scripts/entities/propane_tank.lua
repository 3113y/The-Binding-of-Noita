function TBoN_MOD:Propane_Tank_Idle(entity)

    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Game():GetPlayer(i)
        local distance = (entity.Position - player.Position):Length()
        print("玩家与丙烷罐距离: " .. distance)
        local max_chance_per_frame = 0.001
        local chance = 0
        if distance < 50 then
            chance = max_chance_per_frame
        elseif distance < 300 then
            chance = max_chance_per_frame * (1 - (distance - 5) / 295)
        end
        if chance > 0 and math.random() < chance then
            entity:SetExplosionCountdown(0)
        end
    end
end
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, TBoN_MOD.Propane_Tank_Idle, 799)

function TBoN_MOD:Propane_Tank_Anm(entity)
    entity:GetSprite():Play("Idle", true)
    entity.ExplosionDamage = 100
    entity.RadiusMultiplier = 3
    entity:SetExplosionCountdown(10000)
end
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, TBoN_MOD.Propane_Tank_Anm, 799)