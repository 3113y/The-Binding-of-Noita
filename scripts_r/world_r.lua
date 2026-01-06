include("scripts_r.worlds_r.world_r_used_functions")

function TBoN_MOD:Open_Challenge(_,entitypickup,player,is_natural_spawn)
    if is_natural_spawn then 
        TBoN.R.Room.Function.Custom.Try_Begin_Challenge_Wave()
    end
end
TBoN_MOD:AddCallback(TBoN.Callback.MC_POST_PICKUP_MAGIC,TBoN_MOD.Open_Challenge)
TBoN_MOD:AddCallback(TBoN.Callback.MC_POST_PICKUP_WAND,TBoN_MOD.Open_Challenge)