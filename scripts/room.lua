include("scripts.rooms.room_table")
include("scripts.rooms.room_used_functions")
function TBoN.Room.Function.Room_Data_Refesh()
    TBoN.Room.Function.Current_Room = Game():GetLevel():GetCurrentRoom()
    TBoN.Room.Function.Current_Room_Desc = Game():GetLevel():GetCurrentRoomDesc()
    TBoN.Room.Variable.Current_Room_Shape = TBoN.Room.Table.Shape_Data[TBoN.Room.Function.Current_Room_Desc.Shape]
end
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, TBoN.Room.Function.Room_Data_Refesh)