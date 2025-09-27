include("scripts.guns.gun_used_functions")
include("scripts.guns.gun_actions")

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

-- 添加施法状态追踪
local gun_cast_indexes = {1, 1, 1, 1} -- 每个魔杖的施法位置
local gun_current_mana = {} -- 每个魔杖的当前法力
local gun_cast_cooldown = {0, 0, 0, 0} -- 每个魔杖的施法冷却
local gun_recharge_cooldown = {0, 0, 0, 0} -- 每个魔杖的充能冷却

-- 初始化法力值
for i = 1, 4 do
    if gun_info and gun_info[i] then
        gun_current_mana[i] = gun_info[i].mana_max
    else
        gun_current_mana[i] = 0
    end
end

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
        gun_cast_indexes[gun_index] = 1
        gun_cast_cooldown[gun_index] = 0
        gun_recharge_cooldown[gun_index] = 0
        -- 重置法力到最大值
        if gun_info[gun_index] then
            gun_current_mana[gun_index] = gun_info[gun_index].mana_max
        end
        print("重置魔杖 " .. gun_index .. " 的施法状态")
    end
end

-- 重置所有魔杖的施法状态
function Reset_All_Gun_Cast_States()
    for i = 1, 4 do
        gun_cast_indexes[i] = 1
        gun_cast_cooldown[i] = 0
        gun_recharge_cooldown[i] = 0
        if gun_info[i] then
            gun_current_mana[i] = gun_info[i].mana_max
        end
    end
    print("重置所有魔杖的施法状态")
end

-- 更新魔杖状态（每帧调用）
function Update_Gun_States()
    for i = 1, 4 do
        if gun_info[i] and gun_info[i].name then
            -- 减少施法冷却
            if gun_cast_cooldown[i] > 0 then
                gun_cast_cooldown[i] = gun_cast_cooldown[i] - 1
            end
            
            -- 减少充能冷却
            if gun_recharge_cooldown[i] > 0 then
                gun_recharge_cooldown[i] = gun_recharge_cooldown[i] - 1
            end
            
            -- 回复法力
            local mana_charge_per_frame = gun_info[i].mana_charge_speed / 60
            gun_current_mana[i] = math.min(
                gun_current_mana[i] + mana_charge_per_frame, 
                gun_info[i].mana_max
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
            
            -- 检查当前魔杖是否可以施法
            local can_cast = true
            local current_gun_info = gun_info[item_groove]
            
            if not current_gun_info or not current_gun_info.name then
                print("当前没有装备魔杖")
                can_cast = false
            elseif gun_cast_cooldown[item_groove] > 0 then
                print("施法冷却中，剩余: " .. gun_cast_cooldown[item_groove] .. "帧")
                can_cast = false
            elseif gun_recharge_cooldown[item_groove] > 0 then
                print("充能冷却中，剩余: " .. gun_recharge_cooldown[item_groove] .. "帧")
                can_cast = false
            end
            
            if can_cast then
                Options.FoundHUD = false
                fire_state = true
                
                -- 清空之前的投射物信息
                current_projectiles = {}
                
                -- 获取当前魔杖的法术列表
                local temp = Get_Magic_Table_Of_Current_Gun(gun_magic_data, gun_info, item_groove)
                if temp and #temp > 0 then
                    -- 获取当前魔杖的施法位置
                    local current_index = gun_cast_indexes[item_groove] or 1
                    
                    -- 执行施法，传递法杖信息和当前法力
                    local result = Get_Next_Shutted_Magic_Info(
                        temp, 
                        current_index, 
                        current_gun_info,
                        gun_current_mana[item_groove]
                    )
                    
                    -- 更新状态
                    gun_cast_indexes[item_groove] = result.next_deck_index
                    gun_current_mana[item_groove] = result.remaining_mana
                    gun_cast_cooldown[item_groove] = result.total_cast_delay
                    gun_recharge_cooldown[item_groove] = result.recharge_time
                    
                    -- 打印详细施法结果
                    print("=== 最终施法结果 ===")
                    for block_i, block in ipairs(result.cast_blocks) do
                        print("施法块 " .. block_i .. ":")
                        for spell_i, spell_data in ipairs(block) do
                            print("  " .. spell_i .. ": " .. spell_data.name .. 
                                  " (法力: " .. spell_data.mana_cost .. ")")
                        end
                    end
                    print("下次施法位置: " .. result.next_deck_index)
                    print("施法冷却: " .. result.total_cast_delay .. "帧")
                    print("充能冷却: " .. result.recharge_time .. "帧")
                    
                    -- 执行施法块并收集投射物信息
                    local executed_result = Execute_Cast_Blocks(result.cast_blocks)
                    
                    -- 收集所有投射物信息
                    for _, block_result in ipairs(executed_result) do
                        for _, projectile in ipairs(block_result.projectiles) do
                            table.insert(current_projectiles, projectile)
                        end
                    end
                    
                    print("=== 投射物信息 ===")
                    for i, proj in ipairs(current_projectiles) do
                        print("投射物 " .. i .. ": " .. proj.spell_name .. " (Type: " .. proj.entity_type .. ", Variant: " .. proj.entity_variant .. ")")
                    end
                else
                    print("当前魔杖没有法术")
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