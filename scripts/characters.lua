TBoN.Character.Variable.Num.Mina_Type = Isaac.GetPlayerTypeByName("mina")
TBoN.Character.Variable.Num.Mina_Hat_Id = Isaac.GetCostumeIdByPath("gfx/characters/mina_hat.anm2")

function TBoN_MOD:Player_Costume_Init(player)
    if player:GetPlayerType() ~= TBoN.Character.Variable.Num.Mina_Type then
        return
    end
    player:AddNullCostume(TBoN.Character.Variable.Num.Mina_Hat_Id)
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,TBoN_MOD.Player_Costume_Init)