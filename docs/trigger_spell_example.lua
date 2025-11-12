-- 触发法术示例配置
-- 这些示例展示如何在 gun_actions.lua 中定义触发法术

-- 示例1: 碰撞触发的光弹
-- 发射光弹，碰到敌人时在碰撞位置释放一个炸弹
{
    id = "LIGHT_BULLET_TRIGGER",
    name = "$action_light_bullet_trigger",
    description = "$actiondesc_light_bullet_trigger",
    sprite = "data/ui_gfx/gun_actions/light_bullet_trigger.png",
    type = "ACTION_TYPE_PROJECTILE",
    spawn_level = "1,2,3",
    spawn_probability = "1,0.8,0.5",
    price = 150,
    mana = 20,  -- 光弹本身消耗 + 触发的炸弹也会消耗
    action = function()
        c.entity_type = 1000
        c.entity_variant = 800  -- LIGHT_BULLET的variant
        c.damage = 4
        c.lifetime_add = 40
        c.speed = 12
        c.fire_rate_wait = c.fire_rate_wait + 3
        
        -- 标记为触发法术
        c.is_trigger = true
        c.trigger_type = "COLLISION"  -- 碰撞触发
        c.trigger_draw_count = 1      -- 抓取下1个法术作为触发内容
    end,
}

-- 示例2: 定时触发的能量球
-- 发射能量球，60帧(1秒)后在当前位置释放下一个法术
{
    id = "SLOW_BULLET_TIMER",
    name = "$action_slow_bullet_timer",
    description = "$actiondesc_slow_bullet_timer",
    sprite = "data/ui_gfx/gun_actions/slow_bullet_timer.png",
    type = "ACTION_TYPE_PROJECTILE",
    spawn_level = "2,3,4",
    spawn_probability = "0.8,0.6,0.4",
    price = 180,
    mana = 25,
    action = function()
        c.entity_type = 1000
        c.entity_variant = 801  -- SLOW_BULLET的variant
        c.damage = 6
        c.lifetime_add = 60
        c.speed = 8
        c.fire_rate_wait = c.fire_rate_wait + 5
        
        -- 标记为定时触发
        c.is_trigger = true
        c.trigger_type = "TIMER"
        c.trigger_param = 60       -- 60帧后触发
        c.trigger_draw_count = 1   -- 抓取1个法术
    end,
}

-- 示例3: 死亡触发的手雷
-- 发射手雷，手雷消失(超时/碰撞)时在消失位置释放多个法术
{
    id = "GRENADE_TRIGGER",
    name = "$action_grenade_trigger",
    description = "$actiondesc_grenade_trigger",
    sprite = "data/ui_gfx/gun_actions/grenade_trigger.png",
    type = "ACTION_TYPE_PROJECTILE",
    spawn_level = "2,3,4,5",
    spawn_probability = "0.7,0.7,0.5,0.3",
    price = 220,
    mana = 35,
    action = function()
        c.entity_type = EntityType.ENTITY_BOMB
        c.entity_variant = 0
        c.damage = 10
        c.lifetime_add = 90
        c.speed = 7
        c.fire_rate_wait = c.fire_rate_wait + 15
        
        -- 标记为死亡触发
        c.is_trigger = true
        c.trigger_type = "DEATH"
        c.trigger_draw_count = 3   -- 抓取3个法术，手雷消失时释放
    end,
}

-- 示例4: 多重触发
-- 碰撞触发，但抓取多个法术
{
    id = "HEAVY_BULLET_TRIGGER",
    name = "$action_heavy_bullet_trigger",
    description = "$actiondesc_heavy_bullet_trigger",
    sprite = "data/ui_gfx/gun_actions/heavy_bullet_trigger.png",
    type = "ACTION_TYPE_PROJECTILE",
    spawn_level = "1,2,3,4",
    spawn_probability = "0.9,0.7,0.5,0.3",
    price = 200,
    mana = 30,
    action = function()
        c.entity_type = 1000
        c.entity_variant = 801  -- HEAVY_BULLET的variant
        c.damage = 8
        c.lifetime_add = 50
        c.speed = 10
        c.fire_rate_wait = c.fire_rate_wait + 8
        
        -- 碰撞时释放2个法术
        c.is_trigger = true
        c.trigger_type = "COLLISION"
        c.trigger_draw_count = 2   -- 抓取2个法术
    end,
}

-- 使用示例：
-- 法杖配置: [LIGHT_BULLET_TRIGGER] -> [BOMB] -> [LIGHT_BULLET]
-- 效果:
--   1. 发射LIGHT_BULLET_TRIGGER (光弹触发)
--   2. 光弹飞行中
--   3. 光弹碰到敌人:
--      - 造成光弹伤害
--      - 在碰撞位置生成BOMB (炸弹)
--      - 光弹消失
--   4. 炸弹爆炸
--   5. 后续的LIGHT_BULLET正常发射 (如果mana足够)

-- 法杖配置: [SLOW_BULLET_TIMER] -> [BLACK_HOLE]
-- 效果:
--   1. 发射SLOW_BULLET_TIMER (能量球定时触发)
--   2. 能量球飞行60帧
--   3. 60帧后:
--      - 在能量球当前位置生成BLACK_HOLE (黑洞)
--      - 能量球消失

-- 法杖配置: [GRENADE_TRIGGER] -> [LIGHT_BULLET] -> [LIGHT_BULLET] -> [LIGHT_BULLET]
-- 效果:
--   1. 发射GRENADE_TRIGGER (手雷死亡触发)
--   2. 手雷飞行并弹跳
--   3. 手雷消失(超时或碰撞)时:
--      - 在消失位置生成3个LIGHT_BULLET (光弹)
--      - 3个光弹向不同方向飞出

-- 嵌套触发示例:
-- 法杖配置: [LIGHT_BULLET_TRIGGER] -> [SLOW_BULLET_TIMER] -> [BOMB]
-- 效果:
--   1. 发射LIGHT_BULLET_TRIGGER
--   2. 光弹碰到敌人时生成SLOW_BULLET_TIMER (能量球定时触发)
--   3. 能量球飞行60帧后生成BOMB
--   注意: 这需要SLOW_BULLET_TIMER也实现触发逻辑
