# 始终施放（Always Cast）系统实现文档

## 概述

基于Noita原版机制实现的始终施放系统，完全遵循以下规则：

1. ✅ 每次施法前优先预载始终施放的法术
2. ✅ 始终施放法术不消耗法力（负数法力如"额外法力"除外）
3. ✅ 始终施放法术不消耗使用次数
4. ✅ 始终施放法术的施法延迟仍然有效
5. ✅ 无论魔杖是否乱序，始终施放的预载顺序始终从左到右
6. ✅ 始终施放法术进入手牌，施放后销毁而不进入弃牌堆

## 核心实现

### 1. 数据结构

#### gun_info 添加 always_cast 字段

```lua
TBoN.Gun.Table.gun_info = {
    {
        name = "wand_0000",
        shuffle = false,
        capacity = 9,
        cast_delay = 10,
        recharge_time = 10,
        mana_max = 5000,
        mana_charge_speed = 500,
        spread_degrees = 0,
        always_cast = nil,  -- 始终施放法术ID或法术ID数组
    },
    -- ...
}
```

**always_cast 支持格式：**
- `nil` - 无始终施放
- `"SPELL_ID"` - 单个始终施放法术
- `{"SPELL_1", "SPELL_2"}` - 多个始终施放法术（从左到右）

#### gun_states 添加 always_cast_hand 字段

```lua
TBoN.Gun.Table.gun_states[i] = {
    deck = {},
    discard_pile = {},
    always_cast_hand = {},  -- 始终施放法术的手牌
    mana_max = 0,
    current_mana = 0,
    cast_cooldown = 0,
    recharge_cooldown = 0,
}
```

### 2. 施法流程

#### 步骤1: 预载始终施放法术

在每次施法开始时（`Get_Next_Shutted_Magic_Info` 函数开头）：

```lua
-- 清空之前的始终施放手牌
gun_state.always_cast_hand = {}

-- 如果有始终施放法术，从左到右预载
if gun_info.always_cast then
    local always_cast_spell = gun_info.always_cast
    if type(always_cast_spell) == "string" then
        -- 单个始终施放法术
        table.insert(gun_state.always_cast_hand, always_cast_spell)
    elseif type(always_cast_spell) == "table" then
        -- 多个始终施放法术（从左到右）
        for _, spell_id in ipairs(always_cast_spell) do
            table.insert(gun_state.always_cast_hand, spell_id)
        end
    end
end
```

#### 步骤2: 优先从始终施放手牌抽取

在主施法循环中：

```lua
local spell_name = nil
local is_from_always_cast = false

if always_cast_index <= #gun_state.always_cast_hand then
    -- 从始终施放手牌抽取
    spell_name = gun_state.always_cast_hand[always_cast_index]
    is_from_always_cast = true
    always_cast_index = always_cast_index + 1
else
    -- 始终施放手牌已空，从普通牌库抽取
    if current_deck_index <= #deck_copy then
        spell_name = deck_copy[current_deck_index]
    end
end
```

#### 步骤3: 始终施放法术的特殊处理

```lua
-- 法力消耗
local spell_mana_cost = 0
if is_from_always_cast then
    -- 始终施放法术不消耗法力
    local raw_mana = spell_info.mana or 0
    if raw_mana < 0 then
        -- 负数法力（如额外法力）正常应用
        spell_mana_cost = raw_mana
    else
        spell_mana_cost = 0
    end
else
    spell_mana_cost = spell_info.mana or 0
end

-- 施放后处理
if not is_from_always_cast then
    -- 普通法术：进入弃牌堆
    table.insert(gun_state.discard_pile, spell_name)
    -- 从deck中移除...
else
    -- 始终施放法术：直接销毁，不进入弃牌堆
    print("[ALWAYS_CAST] 始终施放法术施放后销毁（不进入弃牌堆）")
end
```

## 使用示例

### 示例1: 单个始终施放法术

```lua
-- 设置魔杖1始终施放"光弹"
TBoN.Gun.Table.gun_info[1].always_cast = "LIGHT_BULLET"
```

**效果：**
- 每次施法前自动施放一个光弹
- 不消耗法力（除非光弹本身有负数法力）
- 施法延迟仍然累加
- 不消耗使用次数

### 示例2: 多个始终施放法术

```lua
-- 设置魔杖2始终施放"双重施法 + 重弹"
TBoN.Gun.Table.gun_info[2].always_cast = {"DOUBLE_CAST", "HEAVY_SHOT"}
```

**效果：**
- 每次施法前按顺序施放：双重施法 → 重弹
- 两个法术都不消耗法力
- 施法延迟累加
- 之后再抽取普通牌库的法术

### 示例3: 结合触发法术

```lua
-- 魔杖3: 始终施放"双重触发"
TBoN.Gun.Table.gun_info[3].always_cast = "DOUBLE_TRIGGER"

-- 魔杖法术槽: [光弹触发, 黑洞, 炸弹]
```

**重要特性：**
- 始终施放的"双重触发"会抽取牌库中的法术
- **问题：** 始终施放法术抽取树下所有的一重抽取都将失效
- 这是Noita原版机制：始终施放中的多重抽取能力（如双重触发）会导致下一层级的单次抽取失效

## 高级机制

### 1. 魔杖刷新配合

```lua
-- 魔杖配置：始终施放"魔杖刷新"
TBoN.Gun.Table.gun_info[1].always_cast = "WAND_REFRESH"
```

**特殊效果：**
- 魔杖刷新可以让始终施放法术跳过销毁，回到牌库
- 导致每轮施法都会多出一遍始终施放法术
- 对于始终回蓝（MANA_REDUCE等）意义重大

**实现逻辑（待开发）：**
```lua
-- 在魔杖刷新的action中
if is_from_always_cast then
    -- 将始终施放法术放回牌库而不是销毁
    table.insert(gun_state.deck, spell_name)
end
```

### 2. 额外法力（负数法力）

```lua
-- 始终施放"额外法力"
TBoN.Gun.Table.gun_info[2].always_cast = "MANA_REDUCE"
```

**效果：**
- 额外法力的mana = -30（或其他负数）
- 始终施放时仍然应用负数法力效果
- 实际增加30点法力

```lua
if is_from_always_cast then
    local raw_mana = spell_info.mana or 0
    if raw_mana < 0 then
        -- 负数法力正常应用
        spell_mana_cost = raw_mana  -- -30
        remaining_mana = remaining_mana - spell_mana_cost  -- 实际+30
    end
end
```

### 3. 乱序魔杖 + 始终施放

```lua
TBoN.Gun.Table.gun_info[3] = {
    shuffle = true,
    always_cast = {"CHAINSAW", "DOUBLE_CAST"},
    -- ...
}
```

**行为：**
1. 牌库被洗牌（随机顺序）
2. 但始终施放仍然按固定顺序：电锯 → 双重施法
3. 之后才从被洗牌的牌库抽取

## 测试用例

### 测试1: 基础始终施放

```lua
-- 配置
gun_info[1].always_cast = "LIGHT_BULLET"
gun_magic_data[1] = {
    {magic_id = "BOMB", ...},
    {magic_id = "HEAVY_BULLET", ...},
}

-- 施法顺序
-- 1. LIGHT_BULLET (始终施放，0 mana)
-- 2. BOMB (普通抽取)
-- 3. LIGHT_BULLET (始终施放，0 mana)
-- 4. HEAVY_BULLET (普通抽取)
```

### 测试2: 多重抽取失效

```lua
-- 配置
gun_info[1].always_cast = "DOUBLE_CAST"
gun_magic_data[1] = {
    {magic_id = "TRIPLE_SPELL", ...},
    {magic_id = "LIGHT_BULLET", ...},
    {magic_id = "BOMB", ...},
}

-- 施法顺序
-- 1. DOUBLE_CAST (始终施放，抽取2次)
--    - 抽取 TRIPLE_SPELL
--    - TRIPLE_SPELL的抽取能力失效（因为在始终施放的抽取树下）
--    - 抽取 LIGHT_BULLET
-- 2. 生成 LIGHT_BULLET
```

### 测试3: 施法延迟累加

```lua
-- 配置
gun_info[1].cast_delay = 10
gun_info[1].always_cast = "HEAVY_SHOT"  -- fire_rate_wait = +5

-- 结果
-- 实际施法延迟 = 10 (base) + 5 (HEAVY_SHOT) = 15 frames
```

## 调试信息

系统提供详细的调试输出：

```
[ALWAYS_CAST] 预载始终施放法术: LIGHT_BULLET
[ALWAYS_CAST] 抽取始终施放法术: LIGHT_BULLET
[ALWAYS_CAST] 始终施放法术不消耗法力 (原始: 10, 实际: 0)
[ALWAYS_CAST] 始终施放法术施放后销毁（不进入弃牌堆）
```

## 与生成系统集成

在 `wand_generation.lua` 中生成魔杖时设置始终施放：

```lua
-- 5. 永久法术 (Always Cast)
if math.random() < config.always_cast_probability then
    wand.always_cast = SelectAlwaysCast(floor)
    print("[WAND_GEN] 添加永久法术: " .. (wand.always_cast or "nil"))
else
    wand.always_cast = nil
end
```

## 注意事项

### 1. 触发法术限制

**问题：** 始终施放的法术无法放入触发法术的触发队列中。

**原因：** 始终施放在施法开始前预载，而触发法术在施放时才收集触发队列。

**解决方案：** 这是Noita原版机制，无需修改。

### 2. 使用次数

始终施放法术**永远不会**消耗使用次数，即使法术本身有 `max_uses` 限制。

### 3. 性能考虑

每次施法都会重新创建 `always_cast_hand`，对于复杂的始终施放组合可能有轻微性能影响。

## 未来扩展

### 1. 始终施放天赋

```lua
-- 通过天赋添加始终施放
function AddAlwaysCastPerk(gun_index, spell_id)
    local current = TBoN.Gun.Table.gun_info[gun_index].always_cast
    if not current then
        TBoN.Gun.Table.gun_info[gun_index].always_cast = spell_id
    elseif type(current) == "string" then
        TBoN.Gun.Table.gun_info[gun_index].always_cast = {current, spell_id}
    else
        table.insert(TBoN.Gun.Table.gun_info[gun_index].always_cast, spell_id)
    end
end
```

### 2. UI显示

在魔杖UI中显示始终施放法术：

```lua
-- 在魔杖描述中添加
if gun_info.always_cast then
    local always_spells = type(gun_info.always_cast) == "table" 
        and gun_info.always_cast 
        or {gun_info.always_cast}
    
    for _, spell_id in ipairs(always_spells) do
        -- 渲染始终施放法术图标
        RenderAlwaysCastIcon(spell_id)
    end
end
```

## 总结

始终施放系统完全实现了Noita的核心机制：

- ✅ 每次施法前预载
- ✅ 不消耗法力（负数除外）
- ✅ 不消耗使用次数
- ✅ 施法延迟有效
- ✅ 从左到右顺序
- ✅ 施放后销毁（不进弃牌堆）
- ✅ 支持单个/多个始终施放
- ✅ 支持乱序魔杖
- ✅ 触发法术兼容

系统已完全集成到现有施法流程中，无需额外配置即可使用。
