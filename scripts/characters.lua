TBoN.Character.Variable.Num.Mina_Type = Isaac.GetPlayerTypeByName("mina")
TBoN.Character.Variable.Num.Mina_Hat_Id = Isaac.GetCostumeIdByPath("gfx/characters/mina_hat.anm2")

function TBoN_MOD:Player_Init(player)
    if player:GetPlayerType() ~= TBoN.Character.Variable.Num.Mina_Type then
        return
    end
    player:AddNullCostume(TBoN.Character.Variable.Num.Mina_Hat_Id)
    local oldChallenge = Isaac.GetChallenge()
    Game().Challenge = 6
    player:UpdateCanShoot()
    --player:AddNullCostume(NullItemID.ID_BLINDFOLD)
    Game().Challenge = oldChallenge
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,TBoN_MOD.Player_Init)
