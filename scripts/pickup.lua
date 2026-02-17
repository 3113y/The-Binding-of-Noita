include("scripts.pickups.pickup_used_functions")
include("scripts.pickups.wand_generation")
include("scripts.pickups.room")
function TBoN_MOD:Pickup_Morph(entitypickup)
    if entitypickup.SubType ~= 0 and Isaac.GetItemConfig():GetCollectible(entitypickup.SubType):HasTags(ItemConfig.TAG_QUEST) then
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
    -- 0.85 概率生成法术, 0.05 概率生成法杖
    if rng:RandomFloat() < 0.85 then
        local spell_id = TBoN.Pickup.Function.Custom.Get_Random_Spell_By_Floor(Game():GetLevel():GetAbsoluteStage(),
            rng:RandomFloat())
        local spell_subtype = TBoN.Render.Table.actions_map[spell_id]
        entitypickup:Morph(5, TBoN.Magic.Info.Variant.Pickup_Magic, spell_subtype, true, true)
        entitypickup.GridCollisionClass = 5
        if Game():GetLevel():GetCurrentRoomDesc().Data.Type == RoomType.ROOM_DUNGEON then
            entitypickup.Position = entitypickup.Position + Vector(0, -20)
        end
        -- 为新生成的法术初始化使用次数信息（使用封装函数）
        local action = actions[spell_subtype]
        local pickup_hash = entitypickup.InitSeed
        TBoN.Pickup.Function.Custom.Save_Spell_Info(
            pickup_hash,
            spell_id,
            action.max_uses or -1,
            action.max_uses or -1,
            false  -- 不是玩家丢弃的
        )

        local sprite = entitypickup:GetSprite()
        if spell_id then
            sprite:Load("gfx/ui/gun_actions/" .. string.lower(spell_id) .. ".anm2", true)
            sprite:Play("Idle", true)
            sprite.Offset = Vector(-9, -9)
        end
    else
        local stage = Game():GetLevel():GetStage()
        local is_better = (rng:RandomFloat() < 0.1)

        local wand_data, spell_slots = TBoN.Pickup.Function.Custom.GenerateWand(stage, is_better, rng)

        local wand_id = tonumber(string.match(wand_data.name, "wand_(%d+)")) or 0

        entitypickup:Morph(5, TBoN.Magic.Info.Variant.Pickup_Wand, wand_id, true, true)
        entitypickup.GridCollisionClass = 5
        if Game():GetLevel():GetCurrentRoomDesc().Data.Type == RoomType.ROOM_DUNGEON then
            entitypickup.Position = entitypickup.Position + Vector(0, -20)
        end
        local pickup_index = entitypickup.InitSeed
        TBoN.Pickup.Table.Wand_Hash [pickup_index] = {
            wand_data = wand_data,
            spell_slots = spell_slots
        }
        -- 使用封装函数保存法杖信息
        TBoN.Pickup.Function.Custom.Save_Wand_Info(pickup_index, wand_data, spell_slots, false)
        local sprite = entitypickup:GetSprite()
        sprite:Load("gfx/gun/" .. wand_data.name .. ".anm2", true)
        sprite:Play("Idle", true)
        sprite.Offset = Vector(-9, 0)
        Isaac.RunCallback(TBoN.Callback.TBON_POST_WAND_SPAWN, entitypickup, wand_data, spell_slots)
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, TBoN_MOD.Pickup_Morph, 100)

function TBoN_MOD:Col_With_Pickup_Magic(entitypickup, player)
    if player.Type == EntityType.ENTITY_PLAYER then
        local is_devil_room = Game():GetRoom():GetType() == RoomType.ROOM_DEVIL
        
        -- 恶魔房跳过价格判断
        if not is_devil_room then
            if player:ToPlayer():GetNumCoins() < entitypickup.Price then
                return true
            end
        end
        
        local pickup_hash = entitypickup.InitSeed
        for _, m in pairs(TBoN.Magic.Table.bag_magic_data) do
            if m.magic_id == false then
                m.magic_id = actions[entitypickup.SubType].id

                -- 检查是否有保存的使用次数信息
                if TBoN.Pickup.Table.dropped_spell_temp and TBoN.Pickup.Table.dropped_spell_temp[pickup_hash] then
                    local temp_data = TBoN.Pickup.Table.dropped_spell_temp[pickup_hash]
                    if Game():GetFrameCount() - temp_data.timestamp <= 36000 then
                        m.current_uses = temp_data.current_uses
                        m.max_uses = temp_data.max_uses
                        TBoN.Pickup.Table.dropped_spell_temp[pickup_hash] = nil
                    else
                        -- 超时，使用默认值
                        local action = actions[entitypickup.SubType]
                        m.current_uses = action.max_uses or -1
                        m.max_uses = action.max_uses or -1
                    end
                else
                    -- 新捡的法术，使用默认值
                    local action = actions[entitypickup.SubType]
                    m.current_uses = action.max_uses or -1
                    m.max_uses = action.max_uses or -1
                end
                
                -- 恶魔房扣红心容器，否则扣金币
                if is_devil_room then
                    player:ToPlayer():AddMaxHearts(-2)
                else
                    player:ToPlayer():AddCoins(-entitypickup.Price)
                end
                
                TBoN.Render.Variable.Bool.anm_load = true
                entitypickup:Remove()
                break  -- 找到空槽位并填充后立即跳出循环
            end
        end
        -- 检查是否为自然生成的法术（非玩家丢出）
        local is_natural_spawn = true
        if TBoN.Pickup.Table.dropped_spell_temp and TBoN.Pickup.Table.dropped_spell_temp[pickup_hash] then
            local temp_data = TBoN.Pickup.Table.dropped_spell_temp[pickup_hash]
            if temp_data.player_dropped then
                is_natural_spawn = false
            end
        end
        Isaac.RunCallback(TBoN.Callback.TBON_POST_PICKUP_MAGIC, entitypickup, player, is_natural_spawn)
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, TBoN_MOD.Col_With_Pickup_Magic,TBoN.Magic.Info.Variant.Pickup_Magic)

function TBoN_MOD:Col_With_Pickup_Wand(entitypickup, player)
    if player.Type == EntityType.ENTITY_PLAYER then
        local is_devil_room = Game():GetRoom():GetType() == RoomType.ROOM_DEVIL
        
        -- 恶魔房跳过价格判断
        if not is_devil_room then
            if player:ToPlayer():GetNumCoins() < entitypickup.Price then
                return true
            end
        end
        
        -- 获取法杖数据
        local pickup_index = entitypickup.InitSeed
        local wand_info = TBoN.Pickup.Table.Wand_Hash [pickup_index]
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
                    ui_name = wand_data.ui_name or wand_data.name,
                    shuffle = wand_data.shuffle,
                    capacity = wand_data.capacity,
                    cast_delay = wand_data.cast_delay,
                    recharge_time = wand_data.recharge_time,
                    mana_max = wand_data.mana_max,
                    mana_charge_speed = wand_data.mana_charge_speed,
                    spread_degrees = wand_data.spread_degrees,
                    speed_multiplier = wand_data.speed_multiplier or 1,
                    actions_per_round = wand_data.actions_per_round or 1,
                    always_cast = wand_data.always_cast,
                }

                -- 应用法术数据到gun_magic_data
                for slot_index, spell_data in ipairs(spell_slots) do
                    if TBoN.Gun.Table.gun_magic_data[gun_index] and TBoN.Gun.Table.gun_magic_data[gun_index][slot_index] then
                        TBoN.Gun.Table.gun_magic_data[gun_index][slot_index] = {
                            magic_id = spell_data.magic_id,
                            current_uses = spell_data.current_uses or spell_data.max_uses,
                            max_uses = spell_data.max_uses,
                        }
                    end
                end

                -- 初始化gun_states
                if not TBoN.Gun.Table.gun_states[gun_index] then
                    TBoN.Gun.Table.gun_states[gun_index] = {
                        deck = {},
                        discard_pile = {},
                        always_cast_hand = {},
                        mana_max = wand_data.mana_max,
                        current_mana = wand_data.mana_max,
                        cast_cooldown = 0,
                        recharge_cooldown = 0,
                        always_cast_index = 1,
                        wrapped_around = false,
                    }
                else
                    TBoN.Gun.Table.gun_states[gun_index].current_mana = wand_data.mana_max
                    TBoN.Gun.Table.gun_states[gun_index].mana_max = wand_data.mana_max
                    TBoN.Gun.Table.gun_states[gun_index].cast_cooldown = 0
                    TBoN.Gun.Table.gun_states[gun_index].recharge_cooldown = 0
                    TBoN.Gun.Table.gun_states[gun_index].always_cast_index = 1
                    TBoN.Gun.Table.gun_states[gun_index].wrapped_around = false
                    TBoN.Gun.Table.gun_states[gun_index].deck = {}
                    TBoN.Gun.Table.gun_states[gun_index].discard_pile = {}
                    TBoN.Gun.Table.gun_states[gun_index].always_cast_hand = {}
                end
                
                -- 初始化牌库
                local initial_deck = {}
                for slot_index, spell_data in ipairs(spell_slots) do
                    if spell_data.magic_id and spell_data.magic_id ~= false then
                        table.insert(initial_deck, spell_data.magic_id)
                    end
                end
                
                -- 如果需要洗牌
                if wand_data.shuffle then
                    local rng = RNG()
                    rng:SetSeed(Game():GetSeeds():GetNextSeed(), 35)
                    for j = #initial_deck, 2, -1 do
                        local k = rng:RandomInt(j-1) + 1
                        initial_deck[j], initial_deck[k] = initial_deck[k], initial_deck[j]
                    end
                end
                TBoN.Gun.Table.gun_states[gun_index].deck = initial_deck
                TBoN.Pickup.Table.Wand_Hash [pickup_index] = nil
                if TBoN.Pickup.Table.dropped_wand_temp and TBoN.Pickup.Table.dropped_wand_temp[pickup_index] then
                    TBoN.Pickup.Table.dropped_wand_temp[pickup_index] = nil
                end
                TBoN.Render.Variable.Bool.anm_load = true
                
                -- 恶魔房扣红心容器，否则扣金币
                if is_devil_room then
                    player:ToPlayer():AddMaxHearts(-2)
                else
                    player:ToPlayer():AddCoins(-entitypickup.Price)
                end
                
                entitypickup:Remove()
                break
            end
        end
        -- 检查是否为自然生成的法杖（非玩家丢出）
        local is_natural_spawn = true
        if TBoN.Pickup.Table.dropped_wand_temp and TBoN.Pickup.Table.dropped_wand_temp[pickup_index] then
            local temp_data = TBoN.Pickup.Table.dropped_wand_temp[pickup_index]
            if temp_data.player_dropped then
                is_natural_spawn = false
            end
        end
        Isaac.RunCallback(TBoN.Callback.TBON_POST_PICKUP_WAND, entitypickup, player, is_natural_spawn)
    elseif player:IsEnemy() then
        TBoN.Entity.Function.Custom.EntityNPC_Col_With_Pickup(entitypickup, player)
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, TBoN_MOD.Col_With_Pickup_Wand,TBoN.Magic.Info.Variant.Pickup_Wand)

function TBoN_MOD:Magic_Pickup_Init(entitypickup)
    entitypickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    local spell_id = actions[entitypickup.SubType].id
    entitypickup:GetSprite():Load("gfx/ui/gun_actions/" .. string.lower(spell_id) .. ".anm2", true)
    entitypickup:GetSprite():Play("Idle", true)
    entitypickup:GetSprite().Offset = Vector(-9, -9)
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, TBoN_MOD.Magic_Pickup_Init, TBoN.Magic.Info.Variant.Pickup_Magic)

function TBoN_MOD:Wand_Pickup_Init(entitypickup)
    entitypickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    local pickup_index = entitypickup.InitSeed
    local wand_info = TBoN.Pickup.Table.Wand_Hash [pickup_index]
    if not wand_info then
        if TBoN.Pickup.Table.dropped_wand_temp and TBoN.Pickup.Table.dropped_wand_temp[pickup_index] then
            local temp_data = TBoN.Pickup.Table.dropped_wand_temp[pickup_index]
            if Game():GetFrameCount() - temp_data.timestamp <= 36000 then
                TBoN.Pickup.Table.Wand_Hash [pickup_index] = {
                    wand_data = temp_data.wand_data,
                    spell_slots = temp_data.spell_slots
                }
                wand_info = TBoN.Pickup.Table.Wand_Hash [pickup_index]
                -- 不在这里删除dropped_wand_temp，以便房间切换后可以重新恢复
            end
        end
    end
    if wand_info and wand_info.wand_data then
        local wand_name = wand_info.wand_data.name
        local sprite = entitypickup:GetSprite()
        sprite:Load("gfx/gun/" .. wand_name .. ".anm2", true)
        sprite:Play("Idle", true)
        sprite.Offset = Vector(-9, 0)
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, TBoN_MOD.Wand_Pickup_Init)

function TBoN_MOD:Magic_Price(entitypickup)
    -- 检查是否为玩家扔下的法术，如果是则跳过价格设置
    local pickup_hash = entitypickup.InitSeed
    if TBoN.Pickup.Table.dropped_spell_temp and TBoN.Pickup.Table.dropped_spell_temp[pickup_hash] then
        local temp_data = TBoN.Pickup.Table.dropped_spell_temp[pickup_hash]
        if temp_data.player_dropped then
            return
        end
    end
    
    if Game():GetRoom():GetType() == RoomType.ROOM_SHOP then
        local base_price = math.ceil(0.06 * actions[entitypickup.SubType].price)
        entitypickup.AutoUpdatePrice = false
        entitypickup.Price = base_price
    end
    if Game():GetRoom():GetType() == RoomType.ROOM_DEVIL then
        entitypickup.AutoUpdatePrice = false
        entitypickup.Price = -1
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, TBoN_MOD.Magic_Price, TBoN.Magic.Info.Variant.Pickup_Magic)

function TBoN_MOD:Wand_Price(entitypickup)
    -- 检查是否为玩家扔下的法杖，如果是则跳过价格设置
    local pickup_hash = entitypickup.InitSeed
    if TBoN.Pickup.Table.dropped_wand_temp and TBoN.Pickup.Table.dropped_wand_temp[pickup_hash] then
        local temp_data = TBoN.Pickup.Table.dropped_wand_temp[pickup_hash]
        if temp_data.player_dropped then
            return
        end
    end
    
    -- 为自然生成的法杖设置价格（可以根据法杖品质调整）
    if Game():GetRoom():GetType() == RoomType.ROOM_SHOP then
        entitypickup.AutoUpdatePrice = false
        entitypickup.Price = 12 + Game():GetLevel():GetAbsoluteStage()
    end
    if Game():GetRoom():GetType() == RoomType.ROOM_DEVIL then
        entitypickup.AutoUpdatePrice = false
        entitypickup.Price = -1
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, TBoN_MOD.Wand_Price, TBoN.Magic.Info.Variant.Pickup_Wand)
