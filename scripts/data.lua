include("scripts.data.data_table")
include("scripts.data.data_used_functions")
TBoN.Data.Function.Custom.Json = include("json")

function TBoN_MOD:Data_Load(IsContinued)
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Game():GetPlayer(i)
        if player:GetPlayerType() == TBoN.Character.Variable.Num.Mina_Type then
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
                    -- 加载保存的HUD状态，如果没有保存则默认为true
                    if saved_data.Settings and saved_data.Settings.FoundHUD ~= nil then
                        TBoN.Info.Settings.FoundHUD = saved_data.Settings.FoundHUD
                    else
                        TBoN.Info.Settings.FoundHUD = true
                    end
                end
            else
                local rng = RNG()
                rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
                TBoN.Magic.Table.bag_magic_data = TBoN.Data.Function.Custom.Deep_Copy(TBoN.Data.Table
                .bag_magic_data_init)
                TBoN.Gun.Table.gun_magic_data = TBoN.Data.Function.Custom.Deep_Copy(TBoN.Data.Table.gun_magic_data_init)
                TBoN.Gun.Table.gun_info = TBoN.Data.Function.Custom.Deep_Copy(TBoN.Data.Table.gun_info_init)
                TBoN.Gun.Table.gun_info[1], TBoN.Gun.Table.gun_magic_data[1] = TBoN.World.Function.Custom.GenerateStarterWand(rng)
                rng:Next()
                TBoN.Gun.Table.gun_info[2], TBoN.Gun.Table.gun_magic_data[2] = TBoN.World.Function.Custom.GenerateStarterBombWand(rng)
                -- 新游戏时保存当前HUD状态
                TBoN.Info.Settings.FoundHUD = Options.FoundHUD
            end
            Options.FoundHUD = false
            TBoN.Render.Variable.Bool.hand_switch = true
            TBoN.Render.Variable.Bool.anm_load = true
        else
            -- 非Mina角色，恢复保存的HUD状态
            if TBoN_MOD:HasData() then
                local saved_data = json.decode(TBoN_MOD:LoadData())
                if saved_data.Settings and saved_data.Settings.FoundHUD ~= nil then
                    Options.FoundHUD = saved_data.Settings.FoundHUD
                end
            end
        end
    end
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
            gun_info = TBoN.Gun.Table.gun_info,
            Settings = {
                FoundHUD = TBoN.Info.Settings.FoundHUD
            }
        }
        TBoN_MOD:SaveData(json.encode(saved_data))
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, TBoN_MOD.Data_Save)
