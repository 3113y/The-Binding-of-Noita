-- 这个表将保存4个法杖的详细状态
gun_states = {}

-- 根据全局的 gun_info 和 gun_magic_data 初始化所有法杖的状态
function Initialize_All_Gun_States()
    for i = 1, 4 do
        gun_states[i] = {
            deck = {},              -- 当前可以施放的法术
            discard_pile = {},      -- 已施放、等待充能的法术
            
            -- 动态状态
            current_mana = 0,
            cast_cooldown = 0,
            recharge_cooldown = 0,
        }
        
        local current_gun_info = gun_info and gun_info[i]
        if current_gun_info and current_gun_info.name then
            -- 复制法杖信息
            gun_states[i].current_mana = current_gun_info.mana_max or 0
            
            -- 填充初始牌库
            local initial_deck = {}
            local magic_data = gun_magic_data and gun_magic_data[i]
            if magic_data then
                for _, spell_name in ipairs(magic_data) do
                    if spell_name then
                        table.insert(initial_deck, spell_name)
                    end
                end
            end
            
            -- 如果是乱序法杖，在开始时洗牌
            if current_gun_info.shuffle then
                local rng = Isaac.GetPlayer():GetCollectibleRNG(1)
                for j = #initial_deck, 2, -1 do
                    local k = rng:RandomInt(j-1) + 1
                    initial_deck[j], initial_deck[k] = initial_deck[k], initial_deck[j]
                end
            end
            gun_states[i].deck = initial_deck
        end
    end
    print("所有法杖状态已初始化。")
end

-- 在游戏开始或需要时调用
-- Initialize_All_Gun_States()
