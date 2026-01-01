function TBoN_MOD:Remove_Hash_Table(entity)
    if TBoN.Magic.Table.magic_hash[GetPtrHash(entity)] then
        TBoN.Magic.Table.magic_hash[GetPtrHash(entity)] = nil
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, TBoN_MOD.Remove_Hash_Table)

function TBoN_MOD:Refresh_Hash_Table()
    TBoN.Magic.Table.magic_hash = {}
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, TBoN_MOD.Refresh_Hash_Table)

function TBoN_MOD:Entity_Rotation(entity)
    if entity.Variant >=3100 then
        local v_aim
        if entity.Velocity:Length() > 0 then
            v_aim = math.atan(entity.Velocity.Y, entity.Velocity.X)
        else
            v_aim = 0
        end
        local degrees = math.deg(v_aim)
        entity.SpriteRotation = degrees
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Entity_Rotation)
