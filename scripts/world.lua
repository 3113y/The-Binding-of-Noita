include("scripts.worlds.world_used_functions")
include("scripts.worlds.wand_generation")
include("scripts.worlds.room")
function TBoN_MOD:Pickup_Morph(entitypickup)
    if Isaac.GetItemConfig():GetCollectible(entitypickup.SubType):HasTags(ItemConfig.TAG_QUEST) then
        return
    end
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Game():GetPlayer(i)
        if player:GetPlayerType() ~= TBoN.Character.Variable.Num.Mina_Type then
            return
        end
    end
    local rng = RNG()
    local seeds = Game():GetSeeds()
    local init_seed = seeds:GetNextSeed()
    rng:SetSeed(init_seed, 35)
    print(rng:GetSeed())
    -- 0.95 概率生成法术, 0.05 概率生成法杖
    if rng:RandomFloat() < 0.85 then
        local spell_id = TBoN.World.Function.Custom.GetRandomSpellByFloor(Game():GetLevel():GetAbsoluteStage(), rng:RandomFloat())
        print(spell_id)
        entitypickup:Morph(5,799,TBoN.Render.Table.actions_map[spell_id],true,true)
        print(entitypickup.SubType)
        entitypickup.GridCollisionClass = 5
        local sprite = entitypickup:GetSprite()
        if spell_id then
            sprite:Load(0,"gfx/ui/gun_actions/" .. string.lower(spell_id) .. ".anm2",true)
            sprite:Play("Idle", true)
            sprite.Offset = Vector(-9, -9)
        end
    else
        local stage = Game():GetLevel():GetStage()
        local is_better = (rng:RandomFloat() < 0.1)

        local wand_data, spell_slots = TBoN.World.Function.Custom.GenerateWand(stage, is_better, rng)

        local wand_id = tonumber(string.match(wand_data.name, "wand_(%d+)")) or 0

        entitypickup:Morph(5, 800, wand_id, true, true)
        entitypickup.GridCollisionClass = 5

        local pickup_index = GetPtrHash(entitypickup)
        TBoN.World.Table.wand_hash[pickup_index] = {
            wand_data = wand_data,
            spell_slots = spell_slots
        }  
        local sprite = entitypickup:GetSprite()
        sprite:Load("gfx/gun/" .. wand_data.name .. ".anm2", true)
        sprite.Offset = Vector(-9, 0)
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

function TBoN_MOD:Col_With_Wand(entitypickup, player)
    if player.Type == EntityType.ENTITY_PLAYER then
        -- 获取法杖数据
        local pickup_index = GetPtrHash(entitypickup)
        local wand_info = TBoN.World.Table.wand_hash[pickup_index]
        
        if not wand_info then
            return true
        end
        
        local wand_data = wand_info.wand_data
        local spell_slots = wand_info.spell_slots
        
        -- 查找空闲的gun槽位
        for gun_index = 1, 4 do
            if TBoN.Gun.Table.gun_info[gun_index].name == false then
                -- 应用法杖属性到gun_info
                TBoN.Gun.Table.gun_info[gun_index] = {
                    name = wand_data.name,
                    shuffle = wand_data.shuffle,
                    capacity = wand_data.capacity,
                    cast_delay = wand_data.cast_delay,
                    recharge_time = wand_data.recharge_time,
                    mana_max = wand_data.mana_max,
                    mana_charge_speed = wand_data.mana_charge_speed,
                    spread_degrees = wand_data.spread_degrees,
                    always_cast = wand_data.always_cast,
                }
                
                -- 应用法术数据到gun_magic_data
                for slot_index, spell_data in ipairs(spell_slots) do
                    if TBoN.Gun.Table.gun_magic_data[gun_index] and TBoN.Gun.Table.gun_magic_data[gun_index][slot_index] then
                        TBoN.Gun.Table.gun_magic_data[gun_index][slot_index] = {
                            magic_id = spell_data.magic_id,
                            current_uses = spell_data.current_uses,
                            max_uses = spell_data.max_uses,
                        }
                    end
                end
                
                -- 初始化gun_states
                if not TBoN.Gun.Table.gun_states[gun_index] then
                    TBoN.Gun.Table.gun_states[gun_index] = {
                        mana = wand_data.mana_max,
                        cast_delay_current = 0,
                        recharge_time_current = 0,
                        deck_index = 1,
                        discard_pile = {},
                        always_cast_hand = {},
                    }
                else
                    TBoN.Gun.Table.gun_states[gun_index].mana = wand_data.mana_max
                    TBoN.Gun.Table.gun_states[gun_index].cast_delay_current = 0
                    TBoN.Gun.Table.gun_states[gun_index].recharge_time_current = 0
                    TBoN.Gun.Table.gun_states[gun_index].deck_index = 1
                    TBoN.Gun.Table.gun_states[gun_index].discard_pile = {}
                    TBoN.Gun.Table.gun_states[gun_index].always_cast_hand = {}
                end
                TBoN.World.Table.wand_hash[pickup_index] = nil
                TBoN.Render.Variable.Bool.anm_load = true  
                entitypickup:Remove()
                return false
            end
        end
        return true
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, TBoN_MOD.Col_With_Wand, 800)

function TBoN_MOD:Pickup_Init(entitypickup)
    entitypickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    local spell_id = actions[entitypickup.SubType].id
    entitypickup:GetSprite():Load("gfx/ui/gun_actions/" .. string.lower(spell_id) .. ".anm2", true)
    entitypickup:GetSprite():Play("Idle", true)
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, TBoN_MOD.Pickup_Init, 799)

function TBoN_MOD:Wand_Pickup_Init(entitypickup)
    entitypickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    local pickup_index = GetPtrHash(entitypickup)
    local wand_info = TBoN.World.Table.wand_hash[pickup_index]
    if not wand_info then
        local wand_id = entitypickup.SubType
        if TBoN.World.Table.dropped_wand_temp and TBoN.World.Table.dropped_wand_temp[wand_id] then
            local temp_data = TBoN.World.Table.dropped_wand_temp[wand_id]
            if Game():GetFrameCount() - temp_data.timestamp <= 5 then
                TBoN.World.Table.wand_hash[pickup_index] = {
                    wand_data = temp_data.wand_data,
                    spell_slots = temp_data.spell_slots
                }         
                wand_info = TBoN.World.Table.wand_hash[pickup_index]
                TBoN.World.Table.dropped_wand_temp[wand_id] = nil
            end
        end
    end
    
    if wand_info and wand_info.wand_data then
        local wand_name = wand_info.wand_data.name
        local sprite = entitypickup:GetSprite()
        sprite:Load("gfx/gun/" .. wand_name .. ".anm2", true)
        sprite:Play("Idle", true)
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, TBoN_MOD.Wand_Pickup_Init, 800)