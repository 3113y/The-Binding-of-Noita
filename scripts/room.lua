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