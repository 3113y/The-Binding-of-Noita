--黑洞

--移除生成烟雾
function TBoN_MOD:Spawn_Animation_Remove(entity)
    if entity.Type == 1000 and entity.Variant == 15 then
        if entity.SpawnerType == TBoN.Magic.Info.Type.Black_Hole_Entity then
            return false
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, TBoN_MOD.Spawn_Animation_Remove)
--碰撞逻辑
function TBoN_MOD:Black_Hole_Collision(Entity)
    for idx = 0, Game():GetRoom():GetGridSize() - 1 do
        if TBoN.Magic.Function.Custom.Check_Pos(Entity.Position, Game():GetRoom():GetGridPosition(idx), 40) and Game():GetRoom():GetGridEntity(idx) then
            Game():GetRoom():GetGridEntity(idx):Destroy()
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Black_Hole_Collision, TBoN.Magic.Info.Variant.Black_Hole)
--吸引逻辑
function TBoN_MOD:Black_Hole_Attract(Entity)
    for _, ent in pairs(Isaac.GetRoomEntities()) do
        if ent:IsEnemy() and ent:GetType() ~= 1000 then
        ent.Velocity = ent.Velocity + Get_Hole_Velocity_Vector(Entity,ent) * TBoN.Magic.Function.Custom.Get_Hole_Gravity(Entity,ent) * 5
        end
     end
end
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Black_Hole_Attract, TBoN.Magic.Info.Variant.Black_Hole)
--消失逻辑
function TBoN_MOD:Black_Hole_Disappear(entity)
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
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
                entity:Remove()
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Black_Hole_Disappear, TBoN.Magic.Info.Variant.Black_Hole)
