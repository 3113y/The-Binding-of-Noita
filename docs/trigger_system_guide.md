# 触发系统实现指南

## 概述
触发系统允许投射物在特定条件下触发下一个施法块中的法术。支持三种触发类型:
1. **定时触发** (TIMER) - 在指定帧数后触发
2. **碰撞触发** (COLLISION) - 碰到敌人或障碍物时触发
3. **死亡触发** (DEATH) - 投射物消失时触发

## 数据结构

### trigger_data 哈希表
```lua
TBoN.Magic.Table.trigger_data = {
    [entity_hash] = {
        entity = entity,              -- 投射物实体引用
        trigger_type = TriggerType,   -- 触发类型
        spell_queue = {"SPELL_ID_1", "SPELL_ID_2"}, -- 待触发的法术队列
        trigger_param = 60,            -- 触发参数(定时器用)
        triggered = false,             -- 是否已触发
        init_frame = 12345,            -- 初始化帧
    }
}
```

### magic_hash 扩展
在现有的 `magic_hash` 表中添加 `trigger_spells` 字段:
```lua
TBoN.Magic.Table.magic_hash[entity_hash] = {
    damages = {...},
    modifiers = {...},
    trigger_spells = {"BOMB", "LIGHT_BULLET"}, -- 待触发的法术队列
    applied = false
}
```

## 使用流程

### 1. 在 gun_actions.lua 中定义触发法术

```lua
{
    id = "LIGHT_BULLET_TRIGGER",
    name = "$action_light_bullet_trigger",
    description = "$actiondesc_light_bullet_trigger",
    sprite = "data/ui_gfx/gun_actions/light_bullet_trigger.png",
    type = "ACTION_TYPE_PROJECTILE",
    spawn_level = "1,2,3",
    spawn_probability = "1,0.8,0.5",
    price = 150,
    mana = 15,
    action = function()
        c.entity_type = 1000
        c.entity_variant = 800  -- LIGHT_BULLET的variant
        c.damage = 4
        c.lifetime_add = 40
        c.speed = 12
        
        -- 标记这是一个触发法术
        c.is_trigger = true
        c.trigger_type = "COLLISION"  -- 或 "TIMER" 或 "DEATH"
        c.trigger_param = 60  -- 仅TIMER需要,表示60帧后触发
        
        -- draw_actions(1, true) 会抓取下一个法术加入触发队列
        draw_actions(1, true)
    end,
}
```

### 2. 修改 gun_used_functions.lua 处理触发

在 `Calculate_Cast_Result` 函数中:

```lua
-- 在处理投射物时
if spell_info.type == "ACTION_TYPE_PROJECTILE" then
    if c.entity_type and c.entity_variant then
        local modifiers_copy = {}
        for _, modifier in ipairs(proj_modifier) do
            table.insert(modifiers_copy, modifier)
        end
        
        -- 新增: 检查是否是触发法术
        local trigger_spells = {}
        if c.is_trigger and c.next_spell_queue then
            -- 将后续法术作为触发队列
            for _, spell in ipairs(c.next_spell_queue) do
                table.insert(trigger_spells, spell)
            end
        end
        
        table.insert(projectiles, {
            entity_type = c.entity_type,
            entity_variant = c.entity_variant,
            spell_name = spell_name,
            -- ...其他属性...
            modifiers = modifiers_copy,
            
            -- 新增触发相关属性
            is_trigger = c.is_trigger or false,
            trigger_type = c.trigger_type,
            trigger_param = c.trigger_param,
            trigger_spells = trigger_spells,
        })
        
        -- 如果是触发法术,清空next_spell_queue防止重复
        if c.is_trigger then
            c.next_spell_queue = {}
        end
    end
    new_cast_block_needed = true
end
```

### 3. 修改 gun.lua 生成投射物时注册触发

在 `Magic_Spawn` 函数中:

```lua
-- 存储到哈希表
local entity_hash = GetPtrHash(entity)
TBoN.Magic.Table.magic_hash[entity_hash] = {
    damages = {...},
    modifiers = proj.modifiers or {},
    trigger_spells = proj.trigger_spells or {},  -- 新增
    applied = false
}

-- 如果是触发法术,注册到触发系统
if proj.is_trigger and #(proj.trigger_spells or {}) > 0 then
    local trigger_type_map = {
        TIMER = TBoN.Magic.Info.TriggerType.TIMER,
        COLLISION = TBoN.Magic.Info.TriggerType.COLLISION,
        DEATH = TBoN.Magic.Info.TriggerType.DEATH,
    }
    
    TBoN.Magic.Function.Custom.RegisterTrigger(
        entity,
        trigger_type_map[proj.trigger_type] or TBoN.Magic.Info.TriggerType.COLLISION,
        proj.trigger_spells,
        proj.trigger_param
    )
end
```

### 4. 在具体法术文件中调用触发检测

例如 `light_bullet_trigger.lua`:

```lua
-- 碰撞检测
function TBoN_MOD:Light_Bullet_Trigger_Damage(entity)
    local entities = Isaac.FindInRadius(entity.Position, 10, EntityPartition.ENEMY)
    if #entities > 0 then
        entities[1]:TakeDamage(
            TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash),
            0, EntityRef(entity), 0
        )
        
        -- 调用触发系统
        TBoN_MOD:TriggerSystem_Collision_Check(entity, entities[1])
        
        if entity:Exists() then
            entity:Remove()
        end
    end
end
```

## draw_actions 扩展实现

需要修改 `draw_actions` 函数来支持收集后续法术:

```lua
function draw_actions(num, is_for_trigger)
    if is_for_trigger then
        -- 初始化触发法术队列
        c.next_spell_queue = c.next_spell_queue or {}
        
        -- 这里需要从当前deck中读取后续num个法术
        -- 并将它们的ID添加到 c.next_spell_queue
        -- 具体实现取决于你的施法系统设计
        
        TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act + num
    else
        TBoN.Gun.Variable.Num.draw_act = TBoN.Gun.Variable.Num.draw_act + num
    end
end
```

## 完整示例

### 法术配置
```lua
-- 带碰撞触发的光弹,碰撞时会释放炸弹
{
    id = "LIGHT_BULLET_TRIGGER",
    action = function()
        c.entity_type = 1000
        c.entity_variant = 800
        c.damage = 4
        c.is_trigger = true
        c.trigger_type = "COLLISION"
        draw_actions(1, true)  -- 下一个法术会在碰撞时触发
    end,
}
```

### 使用效果
玩家施放法杖: `[LIGHT_BULLET_TRIGGER] -> [BOMB]`
- 发射一个光弹
- 光弹碰到敌人时:
  1. 造成光弹伤害
  2. 触发系统在碰撞点生成炸弹
  3. 光弹消失

## 优势
1. **哈希表存储** - O(1)查找效率
2. **独立触发系统** - 不影响现有施法逻辑
3. **支持多种触发类型** - 定时/碰撞/死亡
4. **队列支持** - 可以触发多个法术
5. **自动清理** - 无效数据自动移除

## 注意事项
1. 触发法术会立即消耗,不会放回deck
2. 触发的法术也可以是触发法术,形成链式触发
3. 需要在投射物消失时调用清理函数避免内存泄漏
4. 触发法术的mana已在首次施放时消耗,触发时不再消耗
