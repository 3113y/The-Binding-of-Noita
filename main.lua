TBoN_MOD = RegisterMod("The Binding of Noita", 1)
TBoN = {
    Render ={
        Variable ={
            Bool = {},
            Num = {},
            String = {}},
        Table ={
            Translations = {}},
        Function ={
            Custom = {},
            Sprite = {},
            Font = {}}},
    Gun ={
        Variable ={
            Bool = {},
            Num = {},
            String = {}},
        Table ={},
        Function ={
            Custom = {},
            Vector = {},
            Sprite = {},
            Font = {}}},
    Magic ={
        Variable ={
            Bool = {},
            Num = {},
            String = {}},
        Info = {
            Type = {},
            Variant = {}},
        Table ={},
        Function ={
            Custom = {},
            Sprite = {},
            Font = {}}},}
include("scripts.gun_fun")
include("scripts.magic")
include("scripts.render")
include("scripts.entity")
