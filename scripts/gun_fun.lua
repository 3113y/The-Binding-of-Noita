include("scripts.guns.gun_used_functions")
include("scripts.guns.gun_actions")
include("scripts.guns.gun_used_table")

-- 全局 c 变量，用于存储施法属性
c = {
    fire_rate_wait = 0,
    entity_type = nil,
    entity_variant = nil,
    speed_multiplier = 1,
    damage = 1,
    screenshake = 0,
    -- 可以添加更多属性
}

local fire_state = false
local Aim_direc
local entity_pos
draw_act = 1
-- 全局变量存储当前施法的投射物信息
local current_projectiles = {}

-- 初始化所有法杖的状态
Initialize_All_Gun_States()

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

-- 重置指定魔杖的施法状态（切换魔杖时调用）
function Reset_Gun_Cast_State(gun_index)
    if gun_index and gun_index >= 1 and gun_index <= 4 then
        local state = gun_states[gun_index]
        if state then
            -- 将弃牌堆的牌放回牌库
            for _, spell in ipairs(state.discard_pile) do
                table.insert(state.deck, spell)
            end
            state.discard_pile = {}

            -- 如果是乱序法杖，重新洗牌
            if gun_info[gun_index] and gun_info[gun_index].shuffle then
                 local rng = Isaac.GetPlayer():GetCollectibleRNG(1)
                for j = #state.deck, 2, -1 do
                    local k = rng:RandomInt(j-1) + 1
                    state.deck[j], state.deck[k] = state.deck[k], state.deck[j]
                end
            end

            state.cast_cooldown = 0
            state.recharge_cooldown = 0
            if gun_info[gun_index] then
                state.current_mana = gun_info[gun_index].mana_max
            end
            print("重置魔杖 " .. gun_index .. " 的施法状态")
        end
    end
end

-- 重置所有魔杖的施法状态
function Reset_All_Gun_Cast_States()
    Initialize_All_Gun_States()
    print("重置所有魔杖的施法状态")
end

-- 更新魔杖状态（每帧调用）
function Update_Gun_States()
    for i = 1, 4 do
        local state = gun_states[i]
        local info = gun_info[i]
        if state and info and info.name then
            -- 减少施法冷却
            if state.cast_cooldown > 0 then
                state.cast_cooldown = state.cast_cooldown - 1
            end
            
            -- 减少充能冷却
            if state.recharge_cooldown > 0 then
                state.recharge_cooldown = state.recharge_cooldown - 1
                -- 充能完成
                if state.recharge_cooldown == 0 then
                    print("魔杖 " .. i .. " 充能完成！")
                    
                    -- 充能完成后，从gun_magic_data重新构建完整牌库
                    state.deck = {}
                    state.discard_pile = {} -- 确保弃牌堆为空
                    
                    local magic_data = gun_magic_data and gun_magic_data[i]
                    if magic_data then
                        for _, spell_name in ipairs(magic_data) do
                            if spell_name then
                                table.insert(state.deck, spell_name)
                            end
                        end
                    end
                    
                    print("  从gun_magic_data重新构建牌库，大小: " .. #state.deck)

                    -- 如果是乱序法杖，重新洗牌
                    if info.shuffle then
                        local rng = Isaac.GetPlayer():GetCollectibleRNG(1)
                        for j = #state.deck, 2, -1 do
                            local k = rng:RandomInt(j-1) + 1
                            state.deck[j], state.deck[k] = state.deck[k], state.deck[j]
                        end
                        print("  法杖已重新洗牌。")
                    end
                end
            end
            
            -- 回复法力
            local mana_charge_per_frame = info.mana_charge_speed / 60
            state.current_mana = math.min(
                state.current_mana + mana_charge_per_frame, 
                info.mana_max
            )
        end
    end
end

--按键处理
function TBoN_MOD:Input_Check()
    -- 每帧更新魔杖状态
    Update_Gun_States()
    
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Game():GetPlayer(i)
        if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
            
            local current_gun_index = item_groove
            local current_gun_state = gun_states[current_gun_index]
            local current_gun_info = gun_info[current_gun_index]

            -- 检查当前魔杖是否可以施法
            local can_cast = true
            if not current_gun_info or not current_gun_info.name then
                print("当前没有装备魔杖")
                can_cast = false
            elseif current_gun_state.cast_cooldown > 0 then
                can_cast = false
            elseif current_gun_state.recharge_cooldown > 0 then
                can_cast = false
            end
            
            if can_cast then
                Options.FoundHUD = false
                fire_state = true
                
                -- 清空之前的投射物信息
                current_projectiles = {}
                
                -- 检查是否有可施法的法术（牌库或弃牌堆）
                local can_cast_spells = #current_gun_state.deck > 0 or #current_gun_state.discard_pile > 0
                
                if can_cast_spells then
                    -- 执行施法，传递整个法杖状态和索引
                    local result = Get_Next_Shutted_Magic_Info(
                        current_gun_state, 
                        current_gun_info,
                        current_gun_index
                    )

                    -- 更新状态
                    current_gun_state.current_mana = result.remaining_mana
                    current_gun_state.cast_cooldown = result.total_cast_delay
                    current_gun_state.recharge_cooldown = result.recharge_time

                    -- 弃牌堆逻辑现在由 gun_used_functions.lua 处理

                    -- 收集所有投射物信息
                    current_projectiles = result.projectiles or {}

                    print("=== 施法报告 ===")
                    print("本次施法冷却: " .. tostring(result.total_cast_delay) .. " 帧")
                    print("本次充能冷却: " .. tostring(result.recharge_time) .. " 帧")
                    print("本次法力消耗: " .. tostring(result.mana_cost))
                    print("剩余法力: " .. tostring(result.remaining_mana))
                    print("投射物数量: " .. tostring(#current_projectiles))
                    for i, proj in ipairs(current_projectiles) do
                        print("投射物 " .. i .. ": " .. proj.spell_name .. " (Type: " .. proj.entity_type .. ", Variant: " .. proj.entity_variant .. ")")
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
    if fire_state == true then
        if not Tab_Confirm then
            -- 计算瞄准方向
            Aim_direc = Vector(
                (Input.GetMousePosition(true).X - player.Position.X) /
                math.sqrt((Input.GetMousePosition(true).X - player.Position.X) ^ 2 +
                    (Input.GetMousePosition(true).Y - player.Position.Y) ^ 2),
                (Input.GetMousePosition(true).Y - player.Position.Y) /
                math.sqrt((Input.GetMousePosition(true).X - player.Position.X) ^ 2 +
                    (Input.GetMousePosition(true).Y - player.Position.Y) ^ 2))
            
            -- 生成所有收集到的投射物
            if #current_projectiles > 0 then
                for i, proj in ipairs(current_projectiles) do
                    print("生成投射物: " .. proj.spell_name .. " (Type: " .. proj.entity_type .. ", Variant: " .. proj.entity_variant .. ")")
                    
                    -- 计算每个投射物的偏移（如果有多个）
                    local offset_angle = 0
                    if #current_projectiles > 1 then
                        -- 多个投射物时添加散射效果
                        offset_angle = (i - (#current_projectiles + 1) / 2) * 0.2 -- 每个投射物间隔0.2弧度
                    end
                    
                    -- 计算带偏移的方向
                    local offset_direction = Vector(
                        Aim_direc.X * math.cos(offset_angle) - Aim_direc.Y * math.sin(offset_angle),
                        Aim_direc.X * math.sin(offset_angle) + Aim_direc.Y * math.cos(offset_angle)
                    )
                    
                    -- 生成实体
                    local entity = Isaac.Spawn(
                        proj.entity_type,
                        proj.entity_variant,
                        0,
                        player.Position + offset_direction * 40,
                        offset_direction * (proj.speed_multiplier or 1),
                        player
                    )
                    
                    -- 设置实体属性
                    if entity:ToEffect() then
                        entity:ToEffect():SetTimeout(90)
                    end
                    
                    local sprite = entity:GetSprite()
                    if sprite then
                        sprite:Play("Idle", true)
                    end
                end
                
                print("总共生成了 " .. #current_projectiles .. " 个投射物")
            end
            
            fire_state = false
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, TBoN_MOD.Magic_Spawn)


--[[function TBoN_MOD:OnPreEntityspawn(type, variant, subtype, position)
    if type == Black_Hole_Entity and variant == Black_Hole_Variant then
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, TBoN_MOD.OnPreEntityspawn)
]]