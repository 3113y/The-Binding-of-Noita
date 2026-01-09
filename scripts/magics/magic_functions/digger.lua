-- DIGGER 投射物逻辑

-- 破坏材料逻辑
function TBoN_MOD:Digger_Destroy_Material(entity)
    local destroy_radius = 15  -- 破坏半径
    for idx = 0, Game():GetRoom():GetGridSize() - 1 do
        local grid_entity = Game():GetRoom():GetGridEntity(idx)
        if grid_entity then
            local grid_pos = Game():GetRoom():GetGridPosition(idx)
            -- 检查是否在破坏范围内
            if TBoN.Magic.Function.Custom.Check_Pos(entity.Position, grid_pos, destroy_radius) then
                grid_entity:Destroy()
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Digger_Destroy_Material, TBoN.Magic.Info.Variant.Digger)

-- 消失逻辑
function TBoN_MOD:Digger_Disappear(entity)
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
        return
    end
    
    if entity.Timeout <= 0 then
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Remove()
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Digger_Disappear, TBoN.Magic.Info.Variant.Digger)
