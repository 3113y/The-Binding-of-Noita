TBoN.Character.Variable.Num.Mina_Type = Isaac.GetPlayerTypeByName("mina")
TBoN.Character.Variable.Num.Mina_Hat_Id = Isaac.GetCostumeIdByPath("gfx/characters/mina_hat.anm2")

function TBoN_MOD:Player_Init()
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Game():GetPlayer(i)
        if player:GetPlayerType() == TBoN.Character.Variable.Num.Mina_Type then
            player:AddNullCostume(TBoN.Character.Variable.Num.Mina_Hat_Id)
            local oldChallenge = Isaac.GetChallenge()
            Game().Challenge = 6
            player:UpdateCanShoot()
            --player:AddNullCostume(NullItemID.ID_BLINDFOLD)
            Game().Challenge = oldChallenge
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, TBoN_MOD.Player_Init)
