include("scripts.guns.gun_used_functions")
include("scripts.guns.gun_actions")
include("scripts.guns.gun_table")
include("scripts.renders.render_table")
-- 全局 c 变量，用于存储施法属性
c = {
    fire_rate_wait = 0,
    entity_type = nil,
    entity_variant = nil,
    speed_multiplier = 1,
    damage = 1,
    screenshake = 0,
    lifetime_add = 0,
    spread_degrees = 0,
    recoil_knockback = 0,
    -- 可以添加更多属性
}

TBoN.Gun.Variable.Bool.fire_state = false
TBoN.Gun.Variable.Num.draw_act = 1
TBoN.Gun.Function.Vector.Aim_direc = Vector(0, 0)
TBoN.Gun.Table.current_projectiles = {}

--按键处理
function TBoN_MOD:Input_Check()
    -- 每帧更新魔杖状态
    TBoN.Gun.Function.Custom.Update_Gun_States()

    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Game():GetPlayer(i)
        if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
            local current_gun_index = TBoN.UI.Variable.Num.item_groove or 1 -- 如果item_groove未定义，默认使用1
            local current_gun_state = TBoN.Gun.Table.gun_states[current_gun_index]
            local current_gun_info = TBoN.Gun.Table.gun_info[current_gun_index]

            -- 检查当前魔杖是否可以施法
            local can_cast = true
            if not current_gun_info or not current_gun_info.name then
                print("当前没有装备魔杖 (索引: " .. tostring(current_gun_index) .. ")")
                can_cast = false
            elseif not current_gun_state then
                print("当前魔杖状态未初始化 (索引: " .. tostring(current_gun_index) .. ")")
                can_cast = false
            elseif current_gun_state.cast_cooldown > 0 then
                can_cast = false
            elseif current_gun_state.recharge_cooldown > 0 then
                can_cast = false
            end

            if can_cast then
                Options.FoundHUD = false
                TBoN.Gun.Variable.Bool.fire_state = true

                -- 清空之前的投射物信息
                TBoN.Gun.Table.current_projectiles = {}

                -- 检查是否有可施法的法术（牌库或弃牌堆）
                local can_cast_spells = #current_gun_state.deck > 0 or #current_gun_state.discard_pile > 0

                -- 调试信息
                print("=== 施法检查调试 ===")
                print("当前法杖索引: " .. tostring(current_gun_index))
                print("牌库大小: " .. tostring(#current_gun_state.deck))
                print("弃牌堆大小: " .. tostring(#current_gun_state.discard_pile))
                if #current_gun_state.deck > 0 then
                    print("牌库内容:")
                    for i, spell in ipairs(current_gun_state.deck) do
                        print("  " .. i .. ": " .. tostring(spell))
                    end
                end
                if #current_gun_state.discard_pile > 0 then
                    print("弃牌堆内容:")
                    for i, spell in ipairs(current_gun_state.discard_pile) do
                        print("  " .. i .. ": " .. tostring(spell))
                    end
                end
                print("可施法: " .. tostring(can_cast_spells))

                if can_cast_spells then
                    -- 执行施法，传递整个法杖状态和索引
                    local result = TBoN.Gun.Function.Custom.Get_Next_Shutted_Magic_Info(
                        current_gun_state,
                        current_gun_info
                    )

                    -- 更新状态
                    current_gun_state.current_mana = result.remaining_mana
                    current_gun_state.cast_cooldown = result.total_cast_delay
                    current_gun_state.recharge_cooldown = result.recharge_time

                    -- 弃牌堆逻辑现在由 gun_used_functions.lua 处理

                    -- 收集所有投射物信息
                    TBoN.Gun.Table.current_projectiles = result.projectiles or {}

                    print("=== 施法报告 ===")
                    print("本次施法冷却: " .. tostring(result.total_cast_delay) .. " 帧")
                    print("本次充能冷却: " .. tostring(result.recharge_time) .. " 帧")
                    print("本次法力消耗: " .. tostring(result.mana_cost))
                    print("剩余法力: " .. tostring(result.remaining_mana))
                    print("投射物数量: " .. tostring(#TBoN.Gun.Table.current_projectiles))
                    for i, proj in ipairs(TBoN.Gun.Table.current_projectiles) do
                        print("投射物 " ..
                        i ..
                        ": " ..
                        proj.spell_name .. " (Type: " .. proj.entity_type .. ", Variant: " .. proj.entity_variant .. ")")
                    end
                else
                    print("当前魔杖没有可施法的法术，需要充能")
                end
            end
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, TBoN_MOD.Input_Check)
--实体生成
function TBoN_MOD:Magic_Spawn(player)
    if TBoN.Gun.Variable.Bool.fire_state == true then
        if not TBoN.UI.Variable.Bool.Tab_Confirm then
            -- 生成所有收集到的投射物
            if #TBoN.Gun.Table.current_projectiles > 0 then
                for i, proj in ipairs(TBoN.Gun.Table.current_projectiles) do
                    print("生成投射物: " ..
                    proj.spell_name .. " (Type: " .. proj.entity_type .. ", Variant: " .. proj.entity_variant .. ")")

                    -- 使用投射物的散射角度参数计算方向
                    local scatter_direction = TBoN.Gun.Function.Custom.Calculate_Spread_Direction(
                        TBoN.Gun.Function.Vector.Aim_direc,
                        proj.spread_degrees or 0
                    )

                    -- 生成实体
                    local entity = Isaac.Spawn(
                        proj.entity_type,
                        proj.entity_variant,
                        0,
                        player.Position + scatter_direction * 40,
                        scatter_direction * (proj.speed_multiplier or 1),
                        player
                    )
                    if entity:ToEffect() then
                        entity:ToEffect():SetTimeout(proj.lifetime_add or 0) -- 使用投射物的lifetime_add值
                    end
                    if proj.recoil_knockback and proj.recoil_knockback > 0 then
                        local recoil_force = -scatter_direction * proj.recoil_knockback * 0.01
                        player.Velocity = player.Velocity + recoil_force
                    end
                    local degrees
                    if TBoN.Gun.Function.Vector.Aim_direc.X > 0 then
                        degrees = 90 + math.deg(TBoN.UI.Variable.Num.radians)
                    else
                        degrees = math.deg(TBoN.UI.Variable.Num.radians) -90
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

                print("总共生成了 " .. #TBoN.Gun.Table.current_projectiles .. " 个投射物")
            end

            TBoN.Gun.Variable.Bool.fire_state = false
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
