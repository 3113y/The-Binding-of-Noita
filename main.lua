TBoN_MOD = RegisterMod("The Binding of Noita", 1)
TBoN = {
    UI =
    {
        Variable =
        {
            Bool = {},
            Num = {},
            String = {}
        },
        Table =
        {

        },
        Function =
        {
            Sprite = {},
            Font = {}
        }
    },
    Gun =
    {
        Variable =
        {
            Bool = {},
            Num = {},
            String = {}
        },
        Table =
        {

        },
        Function =
        {
            Vector = {},
            Sprite = {},
            Font = {}
        }
    },
    Magic =
    {
        Variable =
        {
            Bool = {},
            Num = {},
            String = {}
        },
        Info = 
        {
            Type = {},
            Variant = {}
        },
        Table =
        {

        },
        Function =
        {
            Sprite = {},
            Font = {}
        }
    },
}
include("scripts.gun_fun")
include("scripts.magic")
include("scripts.UI_render")
include("scripts.entity")
