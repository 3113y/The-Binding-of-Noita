include("scripts.guns.gun_used_functions")
include("scripts.guns.gun_actions")
include("scripts.guns.gun_table")
include("scripts.renders.render_table")
include("scripts.magics.magic_table")
-- 全局 c 变量，用于存储施法属性
c = {
    fire_rate_wait = 0,
    entity_type = nil,
    entity_variant = nil,
    speed = 1,
    speed_multiplier = 1,
    damage = 1,
    screenshake = 0,
    lifetime_add = 0,
    spread_degrees = 0,
    recoil_knockback = 0,
    damage_critical_chance = 0,
    damage_projectile_add = 0,
    -- 可以添加更多属性
}

-- 投射物修饰符表，用于存储额外的投射物效果
proj_modifier = {}

TBoN.Gun.Variable.Bool.fire_state = false
TBoN.Gun.Variable.Num.draw_act = 1
TBoN.Gun.Function.Vector.Aim_direc = Vector(0, 0)
TBoN.Gun.Table.current_projectiles = {}
TBoN.Gun.Variable.Num.last_cast_frame = 0

--按键处理
function TBoN_MOD:Input_Check()
    TBoN.Gun.Function.Custom.Update_Gun_States()
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Game():GetPlayer(i)
        if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
            local current_gun_index = TBoN.Render.Variable.Num.item_groove or 1
            local current_gun_state = TBoN.Gun.Table.gun_states[current_gun_index]
            local current_gun_info = TBoN.Gun.Table.gun_info[current_gun_index]
            
            -- 简化施法条件检查，减少对象创建
            local can_cast = current_gun_info and current_gun_info.name and 
                           current_gun_state and 
                           current_gun_state.cast_cooldown <= 0 and 
                           current_gun_state.recharge_cooldown <= 0
            
            if can_cast then
                local can_cast_spells = #current_gun_state.deck > 0 or #current_gun_state.discard_pile > 0
                local required_mana = TBoN.Gun.Function.Custom.Get_Required_Mana(current_gun_index, current_gun_info)
                local has_mana = current_gun_state.current_mana >= required_mana
                
                if can_cast_spells and has_mana and not TBoN.Gun.Variable.Bool.fire_state then
                    -- 记录施法帧数
                    TBoN.Gun.Variable.Num.last_cast_frame = current_frame
                    TBoN.Gun.Variable.Bool.fire_state = true
                    TBoN.Gun.Table.current_projectiles = {}
                    
                    local result = TBoN.Gun.Function.Custom.Get_Next_Shutted_Magic_Info(
                        current_gun_state,
                        current_gun_info
                    )

                    -- 只在成功施法时更新状态和输出信息
                    if result and result.projectiles and #result.projectiles > 0 then
                        current_gun_state.current_mana = result.remaining_mana
                        current_gun_state.cast_cooldown = result.total_cast_delay
                        current_gun_state.recharge_cooldown = result.recharge_time
                        TBoN.Gun.Table.current_projectiles = result.projectiles
                    else
                        -- 施法失败时立即清理状态
                        TBoN.Gun.Variable.Bool.fire_state = false
                        TBoN.Gun.Table.current_projectiles = {}
                    end
                end
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, TBoN_MOD.Input_Check)
--实体生成
function TBoN_MOD:Magic_Spawn(player)
    if TBoN.Gun.Variable.Bool.fire_state == true then
        if not TBoN.Render.Variable.Bool.Tab_Confirm then
            if #TBoN.Gun.Table.current_projectiles > 0 then
                for i, proj in ipairs(TBoN.Gun.Table.current_projectiles) do
                    -- 移除大部分 print 语句，只保留关键信息
                    
                    local scatter_direction = TBoN.Gun.Function.Custom.Calculate_Spread_Direction(
                        TBoN.Gun.Function.Vector.Aim_direc,
                        proj.spread_degrees or 0
                    )

                    local entity = Isaac.Spawn(
                        proj.entity_type,
                        proj.entity_variant,
                        0,
                        player.Position + scatter_direction * 40,
                        scatter_direction *(proj.speed)* (proj.speed_multiplier or 1),
                        player
                    )
                    
                    -- 简化实体设置
                    if entity:ToEffect() then
                        entity:ToEffect():SetTimeout(proj.lifetime_add or 0)
                    end
                    entity.Parent = player
                    
                    -- 存储到哈希表但不输出调试信息
                    local entity_hash = GetPtrHash(entity)
                    TBoN.Magic.Table.magic_hash[entity_hash] = {
                        damages = {
                            damage = proj.damage or 1,
                            damage_critical_chance = proj.damage_critical_chance or 0,
                            damage_projectile_add = proj.damage_projectile_add or 0
                        },
                        modifiers = proj.modifiers or {},
                        applied = false
                    }
                    
                    if proj.recoil_knockback and proj.recoil_knockback > 0 then
                        local recoil_force = -scatter_direction * proj.recoil_knockback * 0.01
                        player.Velocity = player.Velocity + recoil_force
                    end
                    local degrees
                    if TBoN.Gun.Function.Vector.Aim_direc.X > 0 then
                        degrees = 90 + math.deg(TBoN.Render.Variable.Num.radians)
                    else
                        degrees = math.deg(TBoN.Render.Variable.Num.radians) -90
                    end
                    if entity:ToTear() then
                        entity:ToTear().Rotation = degrees
                    end
                    entity.SpriteRotation = degrees
                    local sprite = entity:GetSprite()
                    if sprite then
                        sprite:Play("Idle", false)
                    end
                end
                -- 移除调试输出以减少内存使用
            end

            -- 重要：清理状态
            TBoN.Gun.Variable.Bool.fire_state = false
            TBoN.Gun.Table.current_projectiles = {}  -- 清空投射物表
            
            -- 强制垃圾回收
            collectgarbage("step")
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, TBoN_MOD.Magic_Spawn)

function TBoN_MOD:Init()
    TBoN.Gun.Function.Custom.Initialize_All_Gun_States()
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, TBoN_MOD.Init)
--[[function TBoN_MOD:OnPreEntityspawn(type, variant, subtype, position)
    if type == Black_Hole_Entity and variant == Black_Hole_Variant then
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, TBoN_MOD.OnPreEntityspawn)
]]
