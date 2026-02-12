include("scripts.rooms.room_table")
include("scripts.rooms.room_used_functions")
function TBoN_MOD:Room_Data_Refesh()
    TBoN.Render.Variable.Bool.hand_switch = true
    TBoN.Room.Function.Current_Room = Game():GetLevel():GetCurrentRoom()
    TBoN.Room.Function.Current_Room_Desc = Game():GetLevel():GetCurrentRoomDesc()
    TBoN.Room.Variable.Current_Room_Shape = TBoN.Room.Table.Shape_Data[TBoN.Room.Function.Current_Room_Desc.Data.Shape]
end
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, TBoN_MOD.Room_Data_Refesh)

function TBoN_MOD:Magic_Uses_Refresh()
    -- 刷新背包法术使用次数
    if TBoN.Magic.Table.bag_magic_data then
        for i, magic_data in ipairs(TBoN.Magic.Table.bag_magic_data) do
            if magic_data and magic_data.magic_id and magic_data.magic_id ~= false then
                magic_data.current_uses = magic_data.max_uses
            end
        end
    end
    
    -- 刷新法杖法术使用次数
    if TBoN.Gun.Table.gun_magic_data then
        for gun_index, gun_magic_slots in ipairs(TBoN.Gun.Table.gun_magic_data) do
            if gun_magic_slots then
                for slot_index, magic_data in ipairs(gun_magic_slots) do
                    if magic_data and magic_data.magic_id and magic_data.magic_id ~= false then
                        magic_data.current_uses = magic_data.max_uses
                    end
                end
            end
        end
    end
end
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, TBoN_MOD.Magic_Uses_Refresh)

function TBoN_MOD:Spawn_Wand_In_Room()
    -- 检查是否为普通房间
    local room_type = Game():GetLevel():GetCurrentRoomDesc().Data.Type
    if room_type ~= RoomType.ROOM_DEFAULT then
        return
    end
    local rng = RNG()
    rng:SetSeed(Game():GetLevel():GetCurrentRoomDesc().SpawnSeed, 35)
    if rng:RandomFloat() >= 0.015 then
        return
    end
    local enemies = {}
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:IsVulnerableEnemy() and entity:IsActiveEnemy(false) then
            table.insert(enemies, entity)
        end
    end
    if #enemies == 0 then
        return
    end
    local target_enemy = enemies[rng:RandomInt(#enemies) + 1]
    local max_attempts = 50
    local spawn_pos = nil
    for i = 1, max_attempts do
        local angle = rng:RandomFloat() * math.pi * 2
        local distance = rng:RandomFloat() * 2 * 40
        local offset = Vector(math.cos(angle) * distance, math.sin(angle) * distance)
        local test_pos = target_enemy.Position + offset
        local grid_entity, _ = TBoN.Room.Function.Custom.Check_Grid_Collision(test_pos, 10)
        if not grid_entity then
            spawn_pos = test_pos
            break
        end
    end
    if not spawn_pos then
        return
    end
    local stage = Game():GetLevel():GetStage()
    local is_better = (rng:RandomFloat() < 0.1)
    local wand_data, spell_slots = TBoN.Pickup.Function.Custom.GenerateWand(stage, is_better, rng)
    local wand_id = tonumber(string.match(wand_data.name, "wand_(%d+)")) or 0
    local entity = Isaac.Spawn(5, TBoN.Magic.Info.Variant.Pickup_Wand, wand_id, spawn_pos, Vector(0, 0), nil)
    local pickup_index = entity.InitSeed
    TBoN.Pickup.Table.Wand_Hash[pickup_index] = {
        wand_data = wand_data,
        spell_slots = spell_slots
    }
    TBoN.Pickup.Function.Custom.Save_Wand_Info(pickup_index, wand_data, spell_slots, false)
    local sprite = entity:GetSprite()
    sprite:Load("gfx/gun/" .. wand_data.name .. ".anm2", true)
    sprite:Play("Idle", true)
    sprite.Offset = Vector(-9, 0)
    Isaac.RunCallback(TBoN.Callback.TBON_POST_WAND_SPAWN, entity, wand_data, spell_slots)
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, TBoN_MOD.Spawn_Wand_In_Room)