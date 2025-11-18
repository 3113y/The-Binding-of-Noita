include("scripts.worlds.world_used_functions")
include("scripts.worlds.wand_generation")

function TBoN_MOD:Pickup_Morph(entitypickup)
    local rng = RNG()
    local seeds = Game():GetSeeds()
    local init_seed = seeds:GetPlayerInitSeed()
    rng:SetSeed(init_seed, 35)
    
    -- 0.95 概率生成法术, 0.05 概率生成法杖
    if rng:RandomFloat() < 0.95 then
        -- 生成法术
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
    else
        -- 生成法杖 (5% 概率)
        local stage = Game():GetLevel():GetStage()
        local is_better = (rng:RandomFloat() < 0.1)  -- 10% 概率是 Better 法杖
        
        -- 生成法杖数据
        local wand_data, spell_slots = TBoN.World.Function.Custom.GenerateWand(stage, is_better, rng)
        
        -- TODO: 将法杖数据保存并创建对应的拾取物
        -- 这里需要实现法杖拾取物的创建逻辑
        print("[WORLD] 生成法杖: " .. wand_data.name .. " (Better: " .. tostring(is_better) .. ")")
        
        -- 临时：先生成一个法术作为占位
        local spell_id = TBoN.World.Function.Custom.GetRandomSpellByFloor(stage, rng:RandomInt(50))
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