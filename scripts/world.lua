include("scripts.worlds.world_used_functions")

function TBoN_MOD:Pickup_Morph(entitypickup)
    local rng = RNG()
    rng:SetSeed(Game():GetSeeds():GetPlayerInitSeed())
    local spell_id = TBoN.World.Function.Custom.GetRandomSpellByFloor(Game():GetLevel():GetAbsoluteStage(), rng:RandomInt(50))
    entitypickup:Morph(5,799,TBoN.Render.Table.actions_map[spell_id],true,true)
    entitypickup.GridCollisionClass = 5
    local sprite = entitypickup:GetSprite()
    if spell_id then
        sprite:ReplaceSpritesheet(0, "gfx/ui/sp/" .. string.lower(spell_id) .. ".png")
    else
        sprite:ReplaceSpritesheet(0, "")
    end
    sprite:Play("Idle", true)
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, TBoN_MOD.Pickup_Morph, 100)

function TBoN_MOD:Col_With_Pickup(entitypickup,player)

    if player.Type == EntityType.ENTITY_PLAYER then
        for _,m in pairs(TBoN.Magic.Table.bag_magic_data) do
            if m.magic_id == false then
                m.magic_id = actions[entitypickup.SubType].id
                TBoN.Render.Variable.Bool.anm_load = true
                entitypickup:Remove()
                return false
            end
        end
        return true
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, TBoN_MOD.Col_With_Pickup, 799)

function TBoN_MOD:Pickup_Init(entitypickup)
    entitypickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    entitypickup:GetSprite():Load("gfx/pickup/magic.anm2", true)
    entitypickup:GetSprite():ReplaceSpritesheet(0, "gfx/ui/sp/" .. string.lower(actions[entitypickup.SubType].id) .. ".png")
    entitypickup:GetSprite():LoadGraphics()
    entitypickup:GetSprite():Play("Idle", true)
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, TBoN_MOD.Pickup_Init, 799)