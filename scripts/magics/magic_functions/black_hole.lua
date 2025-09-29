--黑洞
include("scripts.magics.magic_used_functions")
local Black_Hole_Entity = Isaac.GetEntityTypeByName("Black Hole")
local Black_Hole_Variant = Isaac.GetEntityVariantByName("Black Hole")

--移除生成烟雾
function TBoN_MOD:Spawn_Animation_Remove(entity)
    if entity.Type == 1000 and entity.Variant == 15 then
        if entity.SpawnerType == Black_Hole_Entity then
            return false
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, TBoN_MOD.Spawn_Animation_Remove)
--碰撞逻辑
function TBoN_MOD:Black_Hole_Collision(Entity)
    for idx = 0, Game():GetRoom():GetGridSize() - 1 do
        if Check_Pos(Entity.Position, Game():GetRoom():GetGridPosition(idx), 40) and Game():GetRoom():GetGridEntity(idx) then
            Game():GetRoom():GetGridEntity(idx):Destroy()
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Black_Hole_Collision, Black_Hole_Variant)
--吸引逻辑
function TBoN_MOD:Black_Hole_Attract(Entity)
    for _, ent in pairs(Isaac.GetRoomEntities()) do
        if ent:IsEnemy() and ent:GetType() ~= 1000 then
        ent.Velocity = ent.Velocity + Get_Hole_Velocity_Vector(Entity,ent) * Get_Hole_Gravity(Entity,ent) * 5
        end
     end
end
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Black_Hole_Attract, Black_Hole_Variant)
--消失逻辑
function TBoN_MOD:Black_Hole_Disappear(entity)
    if entity.Position.X < -80 or entity.Position.X > 800 or entity.Position.Y < 0 or entity.Position.Y > 600 then
        entity:Kill()
    end
    if entity.Timeout <= 0 then
        entity:GetSprite():Play("Death", false)
        if entity:GetSprite():IsFinished("Death") then
            entity:Remove()
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Black_Hole_Disappear, Black_Hole_Variant)
