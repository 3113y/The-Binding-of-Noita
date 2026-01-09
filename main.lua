TBoN_MOD = RegisterMod("The Binding of Noita", 1)
TBoN = {
    Render = {
        Variable = { Bool = {}, Num = {}, String = {} },
        Table = { Translations = {} },
        Function = { Custom = {}, Sprite = {}, Font = {}, Vector = {} }
    },
    Gun = {
        Variable = { Bool = {}, Num = {}, String = {} },
        Table = {},
        Function = { Custom = {}, Vector = {}, Sprite = {}, Font = {} }
    },
    Magic = {
        Variable = { Bool = {}, Num = {}, String = {} },
        Info = { Type = {}, Variant = {} },
        Table = {},
        Function = { Custom = {}, Sprite = {}, Font = {} }
    },
    World = {
        Variable = { Item = {}, Bool = {}, Num = {}, String = {} },
        Table = {},
        Function = { Custom = {}}
    },
    Room = {
        Variable = { Item = {}, Bool = {}, Num = {}, String = {} },
        Table = {},
        Function = { Custom = {}}
    },
    Character = {
        Variable = { Item = {}, Bool = {}, Num = {}, String = {} },
        Table = {},
        Function = { Custom = {} }
    },
    Data = {
        Table = {},
        Function = { Custom = {} }
    },
    Callback = {},
    Info = {
        Mod_Name = "The Binding of Noita",
        Mod_Version = "0.4.11",
        Mod_Env = "release",
        Settings = {}
    }
}
include("scripts.callback")
include("scripts.info")
include("scripts.characters")
include("scripts.gun")
include("scripts.magic")
include("scripts.render")
include("scripts.entity")
include("scripts.world")
include("scripts.room")
include("scripts.data")
if REPENTOGON then
    include("main_r.lua")
end
function TBoN_MOD:Game_Start_Info(player)
    if player:GetPlayerType() == TBoN.Character.Variable.Num.Mina_Type then
        if Options.Language == "zh" then
            print(REPENTOGON and "[TBoN]已基于[忏悔龙]加载(" .. TBoN.Info.Mod_Version .. ")(" .. TBoN.Info.Mod_Env .. ")" or
            "[TBoN]已加载" .. TBoN.Info.Mod_Version .. ")(" .. TBoN.Info.Mod_Env .. ")")
        else
            print(REPENTOGON and "[TBoN]loaded base [RGON](" .. TBoN.Info.Mod_Version .. ")(" .. TBoN.Info.Mod_Env .. ")" or
            "[TBoN]loaded" .. TBoN.Info.Mod_Version .. ")(" .. TBoN.Info.Mod_Env .. ")")
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, TBoN_MOD.Game_Start_Info)
--[[To do
2.恶魔交易
3.永久施放法术渲染


]] --
