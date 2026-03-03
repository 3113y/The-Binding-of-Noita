-- 初始化丙烷罐数据
function TBoN_MOD:Propane_Tank_Init(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    if not entity_data.propane_tank_data then
        entity_data.propane_tank_data = {
            has_exploded = false, -- 是否已爆炸
            countdown = 150 -- 爆炸倒计时
        }
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, TBoN_MOD.Propane_Tank_Init, TBoN.Magic.Table.Info.Variant.Propane_Tank)

-- 丙烷罐的运动和触发逻辑
function TBoN_MOD:Propane_Tank_Action(entity)
    local entity_hash = GetPtrHash(entity)
    if not TBoN.Magic.Table.magic_hash[entity_hash] then
        return
    end
    
    local entity_data = TBoN.Magic.Table.magic_hash[entity_hash]
    TBoN_MOD:Propane_Tank_Init(entity)
    
    if entity_data.propane_tank_data.has_exploded then
        return
    end
    
    -- 边界检测：超出房间范围时触发爆炸
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        TBoN_MOD:Propane_Tank_Explode(entity)
        entity_data.propane_tank_data.has_exploded = true
        return
    end
    
    -- 倒计时递减
    entity_data.propane_tank_data.countdown = entity_data.propane_tank_data.countdown - 1
    
    local chance = 0
    local rng = RNG()
    rng:SetSeed(Game():GetSeeds():GetNextSeed(), 35)
    
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Game():GetPlayer(i)
        local distance = (entity.Position - player.Position):Length()
        if distance < 50 then
            chance = 0.002
        elseif distance < 300 then
            chance = 0.002 * (1 - (distance - 50) / 250)
        end
        
        -- 随机触发爆炸或倒计时结束
        if (chance > 0 and rng:RandomFloat() < chance) or entity_data.propane_tank_data.countdown <= 0 then
            TBoN_MOD:Propane_Tank_Explode(entity)
            entity_data.propane_tank_data.has_exploded = true
            return
        end
        
        -- 计算旋转角度
        local degrees
        local v_aim
        if entity.Velocity:Length() > 0 then
            v_aim = math.atan(entity.Velocity.Y / entity.Velocity.X)
        else    
            v_aim = 0
        end
        if entity.Velocity.X > 0 then
            degrees = 90 + math.deg(v_aim)
        else
            degrees = math.deg(v_aim) - 90
        end
        entity.SpriteRotation = degrees
        
        -- 移动逻辑
        entity.Velocity = entity.Velocity * 1.05 + RandomVector() * 0.85 +
        (player.Position - entity.Position)/(player.Position - entity.Position):Length() * 0.07
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Propane_Tank_Action, TBoN.Magic.Table.Info.Variant.Propane_Tank)

-- 爆炸函数 - 生成炸弹并立即引爆
function TBoN_MOD:Propane_Tank_Explode(entity)
    -- 在effect位置生成炸弹实体
    local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, 799, 0, entity.Position, Vector.Zero, entity.Parent):ToBomb()
    if bomb then
        bomb.ExplosionDamage = 100
        bomb.RadiusMultiplier = 3
        bomb:SetExplosionCountdown(0)
    end
    -- 移除effect实体
    Isaac.RunCallback(TBoN.Callback.TBON_PRE_MAGIC_REMOVE, entity)
    entity:Remove()
end
