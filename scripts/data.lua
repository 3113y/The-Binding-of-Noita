include("scripts.data.data_table")
include("scripts.data.data_used_functions")
TBoN.Data.Function.Custom.Json = include("json")

local function Deep_Copy_Or_Default(value, default_value)
    if type(value) ~= "table" then
        value = default_value
    end
    return TBoN.Data.Function.Custom.Deep_Copy(value)
end

local function Initialize_Mina_Data()
    local rng = RNG()
    rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)

    TBoN.Magic.Table.bag_magic_data = Deep_Copy_Or_Default(nil, TBoN.Data.Table.bag_magic_data_init)
    TBoN.Gun.Table.gun_magic_data = Deep_Copy_Or_Default(nil, TBoN.Data.Table.gun_magic_data_init)
    TBoN.Gun.Table.gun_info = Deep_Copy_Or_Default(nil, TBoN.Data.Table.gun_info_init)
    TBoN.Pickup.Table.dropped_spell_temp = {}
    TBoN.Pickup.Table.dropped_wand_temp = {}

    TBoN.Gun.Table.gun_info[1], TBoN.Gun.Table.gun_magic_data[1] = TBoN.Pickup.Function.Custom.GenerateStarterWand(rng)
    rng:Next()
    TBoN.Gun.Table.gun_info[2], TBoN.Gun.Table.gun_magic_data[2] = TBoN.Pickup.Function.Custom.GenerateStarterBombWand(rng)
end

local function Load_Saved_Data()
    if not TBoN_MOD:HasData() then
        return nil
    end

    local success, saved_data = pcall(function()
        return TBoN.Data.Function.Custom.Json.decode(TBoN_MOD:LoadData())
    end)
    if success and type(saved_data) == "table" then
        return saved_data
    end
    return nil
end

function TBoN_MOD:Data_Load(IsContinued)
    local has_mina = false
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Game():GetPlayer(i)
        if player:GetPlayerType() == TBoN.Character.Variable.Num.Mina_Type then
            has_mina = true
            break
        end
    end

    local saved_data = Load_Saved_Data()
    if not has_mina then
        if saved_data and saved_data.Settings and saved_data.Settings.FoundHUD ~= nil then
            Options.FoundHUD = saved_data.Settings.FoundHUD
        end
        return
    end

    if TBoN.Info.Mod_Env == "dev" then
        TBoN.Gun.Table.gun_info = TBoN.Data.Function.Custom.Deep_Copy(TBoN.Gun.Table.gun_info_dev)
        TBoN.Magic.Table.bag_magic_data = TBoN.Data.Function.Custom.Deep_Copy(TBoN.Magic.Table.bag_magic_data_dev)
    elseif IsContinued and not TBoN_MOD:HasData() then
        Initialize_Mina_Data()
        TBoN.Info.Settings.FoundHUD = Options.FoundHUD
    elseif IsContinued and saved_data then
        TBoN.Magic.Table.bag_magic_data = Deep_Copy_Or_Default(saved_data.bag_magic_data, TBoN.Data.Table.bag_magic_data_init)
        TBoN.Gun.Table.gun_magic_data = Deep_Copy_Or_Default(saved_data.gun_magic_data, TBoN.Data.Table.gun_magic_data_init)
        TBoN.Gun.Table.gun_info = Deep_Copy_Or_Default(saved_data.gun_info, TBoN.Data.Table.gun_info_init)
        TBoN.Pickup.Table.dropped_spell_temp = TBoN.Data.Function.Custom.Decompress_Sparse_Table(saved_data.dropped_spell_temp_compressed)
        TBoN.Pickup.Table.dropped_wand_temp = TBoN.Data.Function.Custom.Decompress_Sparse_Table(saved_data.dropped_wand_temp_compressed)
        if saved_data.Settings and saved_data.Settings.FoundHUD ~= nil then
            TBoN.Info.Settings.FoundHUD = saved_data.Settings.FoundHUD
        else
            TBoN.Info.Settings.FoundHUD = Options.FoundHUD
        end
    else
        Initialize_Mina_Data()
        TBoN.Info.Settings.FoundHUD = Options.FoundHUD
    end

    Options.FoundHUD = false
    TBoN.Render.Variable.Bool.hand_switch = true
    TBoN.Render.Variable.Bool.anm_load = true
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, TBoN_MOD.Data_Load)

function TBoN_MOD:Data_Save(bool)
    if TBoN.Info.Mod_Env == "dev" then
        return
    end
    if bool then
        local success, result = pcall(function()
            local saved_data = {
                bag_magic_data = TBoN.Data.Function.Custom.Deep_Copy(TBoN.Magic.Table.bag_magic_data),
                gun_magic_data = TBoN.Data.Function.Custom.Deep_Copy(TBoN.Gun.Table.gun_magic_data),
                gun_info = TBoN.Data.Function.Custom.Deep_Copy(TBoN.Gun.Table.gun_info),
                -- 使用压缩函数处理稀疏表，避免序列化大量nil
                dropped_spell_temp_compressed = TBoN.Data.Function.Custom.Compress_Sparse_Table(TBoN.Pickup.Table.dropped_spell_temp),
                dropped_wand_temp_compressed = TBoN.Data.Function.Custom.Compress_Sparse_Table(TBoN.Pickup.Table.dropped_wand_temp),
                Settings = {
                    FoundHUD = TBoN.Info.Settings.FoundHUD
                }
            }
            return TBoN.Data.Function.Custom.Json.encode(saved_data)
        end)
        
        if success then
            TBoN_MOD:SaveData(result)
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, TBoN_MOD.Data_Save)
