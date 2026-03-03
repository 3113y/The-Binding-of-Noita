--黑洞

--移除生成烟雾
function TBoN_MOD:Spawn_Animation_Remove(entity)
    if entity.Type == 1000 and entity.Variant == 15 then
        if entity.SpawnerType == TBoN.Magic.Table.Info.Type.Black_Hole_Entity then
            return false
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, TBoN_MOD.Spawn_Animation_Remove)
--碰撞逻辑
function TBoN_MOD:Black_Hole_Collision(entity)
    for idx = 0, Game():GetRoom():GetGridSize() - 1 do
        if TBoN.Magic.Function.Custom.Check_Pos(entity.Position, Game():GetRoom():GetGridPosition(idx), 40) and Game():GetRoom():GetGridEntity(idx) then
            Game():GetRoom():GetGridEntity(idx):Destroy()
        end
    end
    for _, ent in pairs(Isaac.GetRoomEntities()) do
        if ent.Variant ~= TBoN.Render.Variable.Num.Hand_Item_Variant then
            ent.Velocity = ent.Velocity + (entity.Position - ent.Position):Normalized() * TBoN.Magic.Function.Custom.Get_Hole_Gravity(entity,ent)
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Black_Hole_Collision, TBoN.Magic.Table.Info.Variant.Black_Hole)

--消失逻辑
function TBoN_MOD:Black_Hole_Disappear(entity)
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
        entity:Kill()
    end
    if entity.Timeout <= 0 then
        entity:GetSprite():Play("Death", false)
        if entity:GetSprite():IsFinished("Death") then
            -- 检查死亡触发
            local entity_hash = GetPtrHash(entity)
            local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
            if trigger_data then
                TBoN_MOD:TriggerSystem_Death_Check(entity)
            else
                Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
                entity:Remove()
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Black_Hole_Disappear, TBoN.Magic.Table.Info.Variant.Black_Hole)
