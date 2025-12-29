function TBoN_MOD:Data_Load(IsContinued)
    if TBoN.Info.Mod_Env == "dev" then
        return
    end
    if IsContinued then
        if TBoN_MOD:HasData() then
            local saved_data = TBoN_MOD:LoadData()
            TBoN.Magic.Table.bag_magic_data = saved_data.bag_magic_data or TBoN.Magic.Table.bag_magic_data
            TBoN.Gun.Table.gun_magic_data = saved_data.gun_magic_data or TBoN.Gun.Table.gun_magic_data
            TBoN.Gun.Table.gun_info = saved_data.gun_info or TBoN.Gun.Table.gun_info
        end
    else
        local rng = RNG()
        rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
        
        -- 生成初始魔杖
        TBoN.Gun.Table.gun_info[1], TBoN.Gun.Table.gun_magic_data[1] = TBoN.World.Function.Custom.GenerateStarterWand(rng)
        rng:Next()
        TBoN.Gun.Table.gun_info[2], TBoN.Gun.Table.gun_magic_data[2] = TBoN.World.Function.Custom.GenerateStarterBombWand(rng)
    end
    TBoN.Render.Variable.Bool.anm_load = true
end
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, TBoN_MOD.Data_Load)