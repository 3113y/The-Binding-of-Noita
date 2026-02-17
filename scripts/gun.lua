include("scripts.guns.gun_used_functions")
include("scripts.guns.gun_actions")
include("scripts.guns.gun_table")
include("scripts.renders.render_table")
include("scripts.magics.magic_table")

TBoN.Gun.Variable.Bool.fire_state = false
TBoN.Gun.Variable.Num.draw_act = 1
TBoN.Gun.Function.Vector.Aim_direc = Vector(0, 0)
TBoN.Gun.Table.current_projectiles = {}
TBoN.Gun.Variable.Num.last_cast_frame = 0
TBoN.Gun.Variable.Num.forced_cooldown = 0  -- 强制冷却计数器（帧数）

--按键处理
function TBoN_MOD:Input_Check()
    TBoN.Gun.Function.Custom.Update_Gun_States()
    
    -- 更新强制冷却计数器
    if TBoN.Gun.Variable.Num.forced_cooldown > 0 then
        TBoN.Gun.Variable.Num.forced_cooldown = TBoN.Gun.Variable.Num.forced_cooldown - 1
    end
    if TBoN.Render.Variable.Bool.Tab_Confirm then
        return
    end
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
                           current_gun_state.recharge_cooldown <= 0 and
                           TBoN.Gun.Variable.Num.forced_cooldown <= 0  -- 检查强制冷却
            
            if can_cast then
                local can_cast_spells = #current_gun_state.deck > 0 or #current_gun_state.discard_pile > 0
                
                if can_cast_spells and not TBoN.Gun.Variable.Bool.fire_state then
                    -- 记录施法帧数
                    TBoN.Gun.Variable.Num.last_cast_frame = current_frame
                    TBoN.Gun.Variable.Bool.fire_state = true
                    TBoN.Gun.Table.current_projectiles = {}
                    
                    local result = TBoN.Gun.Function.Custom.Get_Next_Shutted_Magic_Info(
                        current_gun_state,
                        current_gun_info
                    )

                    -- 检查施法结果
                    if result and result.projectiles and #result.projectiles > 0 then
                        -- 施法成功：更新状态
                        current_gun_state.current_mana = result.remaining_mana
                        current_gun_state.cast_cooldown = result.total_cast_delay
                        current_gun_state.recharge_cooldown = result.recharge_time
                        TBoN.Gun.Table.current_projectiles = result.projectiles
                    else
                        -- 施法失败（mana不足，施法块为空）：强制冷却30帧
                        TBoN.Gun.Variable.Bool.fire_state = false
                        TBoN.Gun.Table.current_projectiles = {}
                        TBoN.Gun.Variable.Num.forced_cooldown = 30  -- 0.5秒 = 30帧

                    end
                end
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, TBoN_MOD.Input_Check)
--实体生成
function TBoN_MOD:Magic_Spawn(player)
    if TBoN.Gun.Variable.Bool.fire_state and player:GetPlayerType() == TBoN.Character.Variable.Num.Mina_Type then
        if not TBoN.Render.Variable.Bool.Tab_Confirm then
            if #TBoN.Gun.Table.current_projectiles > 0 then

                -- 创建一个基于当前帧的RNG用于散射
                local scatter_rng = RNG()
                local frame = Game():GetFrameCount()
                scatter_rng:SetSeed(frame+1, 35)
                
                for i, proj in ipairs(TBoN.Gun.Table.current_projectiles) do
                    local scatter_direction = TBoN.Gun.Function.Custom.Calculate_Spread_Direction(
                        TBoN.Gun.Function.Vector.Aim_direc,
                        proj.spread_degrees or 0,
                        scatter_rng
                    )
                    if Game():GetRoom():IsMirrorWorld() then
                        scatter_direction = Vector(-scatter_direction.X, scatter_direction.Y)
                    end

                    local position = player.Position - Vector(0, 10) + scatter_direction * 40
                    local velocity = scatter_direction * (proj.speed) * (proj.speed_multiplier or 1)
                    TBoN.Gun.Function.Custom.Spawn_Projectile_Entity(proj, position, velocity, player)

                    -- 后坐力
                    if proj.recoil_knockback and proj.recoil_knockback > 0 then
                        local recoil_force = -scatter_direction * proj.recoil_knockback * 0.01
                        player.Velocity = player.Velocity + recoil_force
                    end
                end
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
