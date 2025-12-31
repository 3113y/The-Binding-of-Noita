function TBoN_MOD:Game_Start_Info()
    print("MOD NAME: " .. TBoN.Info.Mod_Name)
    print("MOD VERSION: " .. TBoN.Info.Mod_Version)
    print("MOD ENVIRONMENT: " .. TBoN.Info.Mod_Env)
end
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, TBoN_MOD.Game_Start_Info)

TBoN.Magic.Info.Type = {
    --Entity Effects
    Bullet = Isaac.GetEntityTypeByName("Bullet"),
    Black_Hole = Isaac.GetEntityTypeByName("Black Hole"),
    Light_Bullet = Isaac.GetEntityTypeByName("Light Bullet"),
    Heavy_Bullet = Isaac.GetEntityTypeByName("Heavy Bullet"),
    Slow_Bullet = Isaac.GetEntityTypeByName("Slow Bullet"),
    Teleport_Projectile = Isaac.GetEntityTypeByName("Teleport Projectile"),
    Disc_Bullet = Isaac.GetEntityTypeByName("Disc Bullet"),
    Disc_Bullet_Big = Isaac.GetEntityTypeByName("Disc Bullet Big"),
    Grenade = Isaac.GetEntityTypeByName("Grenade"),
    Spitter = Isaac.GetEntityTypeByName("Spitter"),
    Hook = Isaac.GetEntityTypeByName("Hook"),
    Propane_Tank = Isaac.GetEntityTypeByName("Propane Tank"),
    --Entity Bombs
    Grenade_b = Isaac.GetEntityTypeByName("Grenade b"),
    Propane_Tank_b = Isaac.GetEntityTypeByName("Propane Tank b"),
    --Entity Pickups
    Magic = Isaac.GetEntityTypeByName("Magic"),
    Gun = Isaac.GetEntityTypeByName("gun"),
}

TBoN.Magic.Info.Variant = {
    --Entity Effects
    Bullet = Isaac.GetEntityVariantByName("Bullet"),
    Black_Hole = Isaac.GetEntityVariantByName("Black Hole"),
    Light_Bullet = Isaac.GetEntityVariantByName("Light Bullet"),
    Heavy_Bullet = Isaac.GetEntityVariantByName("Heavy Bullet"),
    Slow_Bullet = Isaac.GetEntityVariantByName("Slow Bullet"),
    Teleport_Projectile = Isaac.GetEntityVariantByName("Teleport Projectile"),
    Disc_Bullet = Isaac.GetEntityVariantByName("Disc Bullet"),
    Disc_Bullet_Big = Isaac.GetEntityVariantByName("Disc Bullet Big"),
    Grenade = Isaac.GetEntityVariantByName("Grenade"),
    Spitter = Isaac.GetEntityVariantByName("Spitter"),
    Hook = Isaac.GetEntityVariantByName("Hook"),
    Propane_Tank = Isaac.GetEntityVariantByName("Propane Tank"),
    --Entity Bombs 
    Propane_Tank_b = Isaac.GetEntityVariantByName("Propane Tank b"),
    Grenade_b = Isaac.GetEntityVariantByName("Grenade b"),

    --Entity Pickups
    Magic = Isaac.GetEntityVariantByName("Magic"),
    Gun = Isaac.GetEntityVariantByName("gun"),
}
TBoN.Magic.Info.Subtype = {
    Grenade = 0,
    Grenade_Tier_2 = 1,
    Grenade_Tier_3 = 2,
    Grenade_b = 0,
    Grenade_Tier_2_b = 1,
    Grenade_Tier_3_b = 2,
    Grenade_Anti = 3,
    Spitter = 0,
    Spitter_Tier_2 = 1,
    Spitter_Tier_3 = 2,
}