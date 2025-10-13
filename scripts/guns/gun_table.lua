-- 这个表将保存4个法杖的详细状态
TBoN.Gun.Table.gun_states = {}

TBoN.Gun.Table.gun_info = {
    {
        name = "wand_0000",
        capacity = 9,
        shuffle = false,
        cast_delay = 10,
        recharge_time = 10,
        mana_max = 5000,
        mana_charge_speed = 180,
    },
    {
        name = "wand_0567",
        capacity = 20,
        shuffle = false,
        cast_delay = 0,
        recharge_time = 0,
        mana_max = 100,
        mana_charge_speed = 2,
    },
    {
        name = "wand_0001",
        capacity = 17,
        shuffle = true,
        cast_delay = 0,
        recharge_time = 0,
        mana_max = 80,
        mana_charge_speed = 1.5,
    },
    {
        name = false,
        capacity = 0,
        shuffle = false,
        cast_delay = 0,
        recharge_time = 0,
        mana_max = 0,
        mana_charge_speed = 0,
    }
}
TBoN.Gun.Table.gun_magic_data = {
    { false, false, false, false, "PROPANE_TANK", false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
    { false, false, false, false, false,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
    { false, false, false, false, false,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
    { false, false, false, false, false,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false }
}