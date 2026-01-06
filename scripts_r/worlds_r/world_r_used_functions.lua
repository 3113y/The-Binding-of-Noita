function TBoN.R.Room.Function.Custom.Try_Begin_Challenge_Wave()
    if Game():GetLevel():GetCurrentRoomDesc().Data.Type == RoomType.ROOM_CHALLENGE then
        Ambush.StartChallenge()
    end
end