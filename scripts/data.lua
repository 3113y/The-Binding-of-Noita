include("scripts.data.data_table")
include("scripts.data.data_used_functions")
TBoN.Data.Function.Custom.Json = include("json")

function TBoN_MOD:Data_Load(IsContinued)
    if TBoN.Info.Mod_Env == "dev" then
        TBoN.Gun.Table.gun_info = TBoN.Gun.Table.gun_info_dev
        TBoN.Magic.Table.bag_magic_data = TBoN.Magic.Table.bag_magic_data_dev
        TBoN.Render.Variable.Bool.hand_switch = true
        TBoN.Render.Variable.Bool.anm_load = true
        return
    end
    if IsContinued then
        if TBoN_MOD:HasData() then
            local saved_data = json.decode(TBoN_MOD:LoadData())
            TBoN.Magic.Table.bag_magic_data = saved_data.bag_magic_data or TBoN.Data.Table.bag_magic_data_init
            TBoN.Gun.Table.gun_magic_data = saved_data.gun_magic_data or TBoN.Data.Table.gun_magic_data_init
            TBoN.Gun.Table.gun_info = saved_data.gun_info or TBoN.Data.Table.gun_info_init
        end
    else
        local rng = RNG()
        rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
        TBoN.Magic.Table.bag_magic_data = TBoN.Data.Function.Custom.DeepCopy(TBoN.Data.Table.bag_magic_data_init)
        TBoN.Gun.Table.gun_magic_data = TBoN.Data.Function.Custom.DeepCopy(TBoN.Data.Table.gun_magic_data_init)
        TBoN.Gun.Table.gun_info = TBoN.Data.Function.Custom.DeepCopy(TBoN.Data.Table.gun_info_init)
        -- 生成初始魔杖
        TBoN.Gun.Table.gun_info[1], TBoN.Gun.Table.gun_magic_data[1] = TBoN.World.Function.Custom.GenerateStarterWand(
        rng)
        rng:Next()
        TBoN.Gun.Table.gun_info[2], TBoN.Gun.Table.gun_magic_data[2] = TBoN.World.Function.Custom
        .GenerateStarterBombWand(rng)
    end
    TBoN.Render.Variable.Bool.hand_switch = true
    TBoN.Render.Variable.Bool.anm_load = true
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, TBoN_MOD.Data_Load)

function TBoN_MOD:Data_Save(_, bool)
    if TBoN.Info.Mod_Env == "dev" then
        return
    end
    if bool then
        local saved_data = {
            bag_magic_data = TBoN.Magic.Table.bag_magic_data,
            gun_magic_data = TBoN.Gun.Table.gun_magic_data,
            gun_info = TBoN.Gun.Table.gun_info
        }
        TBoN_MOD:SaveData(json.encode(saved_data))
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, TBoN_MOD.Data_Save)
