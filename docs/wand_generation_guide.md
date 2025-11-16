# 法杖自然生成系统使用指南

## 概述

基于Noita原版算法实现的法杖自然生成系统，能够根据当前楼层自动生成平衡的法杖。

## 核心文件

- `scripts/worlds/wand_generation.lua` - 法杖生成核心逻辑
- `scripts/worlds/world_used_functions.lua` - 法术池过滤辅助函数

## 主要功能

### 1. 生成法杖属性

```lua
-- 生成指定楼层的法杖属性
local stats = TBoN.World.Function.Custom.GenerateWandStats(floor, is_better)

-- 返回值:
-- {
--     capacity = 7,
--     cast_delay = 10,
--     recharge_time = 35,
--     mana_max = 500,
--     mana_charge_speed = 200,
--     spread_degrees = 2,
--     shuffle = true
-- }
```

### 2. 生成完整法杖

```lua
-- 生成完整法杖数据和法术槽
local wand_data, spell_slots = TBoN.World.Function.Custom.GenerateWand(floor, is_better)

-- wand_data 包含:
-- - name: 法杖外观名称 (如 "wand_0042")
-- - shuffle: 是否洗牌
-- - capacity: 容量
-- - cast_delay: 施法延迟
-- - recharge_time: 装填时间
-- - mana_max: 最大法力
-- - mana_charge_speed: 充能速度
-- - spread_degrees: 扩散角度
-- - always_cast: 永久法术ID (可能为nil)

-- spell_slots 是法术数组:
-- [
--     {magic_id = "LIGHT_BULLET", current_uses = -1, max_uses = -1},
--     {magic_id = "BOMB", current_uses = -1, max_uses = -1},
--     {magic_id = false, current_uses = 0, max_uses = 0},  -- 空槽
--     ...
-- ]
```

## 生成配置

### 楼层配置

每个楼层有独立的生成配置：

| 楼层 | 容量范围 | 施法延迟 | 装填时间 | 法力 | 洗牌概率 | 永久法术概率 |
|------|----------|----------|----------|------|----------|--------------|
| 1 (Basement) | 3-6 | 5-20 | 30-70 | 100-300 | 70% | 2% |
| 2 (Caves) | 4-8 | 3-18 | 25-60 | 200-500 | 60% | 5% |
| 3 (Depths) | 5-10 | 0-15 | 20-50 | 300-700 | 50% | 8% |
| 4 (Womb) | 6-13 | -5-12 | 10-45 | 400-1000 | 40% | 12% |
| 5 (Cathedral) | 7-16 | -10-10 | 0-40 | 500-1500 | 30% | 15% |
| 6 (Chest) | 8-20 | -15-8 | -10-35 | 600-2000 | 20% | 20% |

### Better法杖

- 概率: 5% (在10%生成法杖的基础上)
- 效果:
  - 容量、法力、充能速度提升 10-30%
  - 施法延迟、装填时间降低 20%
  - 扩散角度降低 30%

## 法术选择逻辑

### 1. 法术池过滤

使用 `TBoN.World.Function.Custom.GetAvailableSpellsByFloor(floor)` 获取当前楼层可用法术：

- 检查 `action.spawn_level` 是否包含当前楼层
- 检查 `action.spawn_probability` 对应概率 > 0
- 检查 `TBoN.World.Table.UnlockedSpells[action.id]` 是否已解锁

### 2. 法术添加规则

1. **第一个法术必须是投射物**: 确保法杖有输出能力
2. **随机选择**: 从可用法术池中加权随机选择
3. **数量控制**: 
   - 最少法术数随楼层递增 (1层2个 → 6层7个)
   - 最多不超过法杖容量
4. **避免全空**: 至少添加 spell_count_min 个法术

### 3. 永久法术选择

永久法术池按楼层分级：

```lua
{id = "LIGHT_BULLET", min_floor = 1, weight = 5},
{id = "BULLET", min_floor = 1, weight = 6},
{id = "HEAVY_BULLET", min_floor = 3, weight = 7},
{id = "BOMB", min_floor = 3, weight = 4},
{id = "BLACK_HOLE", min_floor = 5, weight = 3},
{id = "TELEPORT_PROJECTILE", min_floor = 5, weight = 5},
```

## 集成到游戏

### 1. 清房后生成

```lua
-- 在 MC_PRE_SPAWN_CLEAN_AWARD 回调中
function TBoN_MOD:OnRoomClearWandSpawn()
    local level = Game():GetLevel()
    local stage = level:GetStage()
    
    -- 10%概率生成法杖
    if math.random() < 0.1 then
        local is_better = (math.random() < 0.05)
        local wand_data, spell_slots = TBoN.World.Function.Custom.GenerateWand(stage, is_better)
        
        -- 保存法杖数据到全局表
        table.insert(TBoN.Gun.Table.generated_wands, {
            wand = wand_data,
            spells = spell_slots
        })
        
        -- 生成拾取物实体
        local room = level:GetCurrentRoom()
        local pos = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true)
        local wand_pickup = Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.COLLECTIBLE,
            wand_item_id,
            pos,
            Vector.Zero,
            nil
        )
        
        -- 关联法杖数据到实体
        wand_pickup:GetData().wand_index = #TBoN.Gun.Table.generated_wands
    end
end
```

### 2. 拾取时应用数据

```lua
-- 在拾取回调中
function TBoN_MOD:OnWandPickup(pickup, player)
    local wand_index = pickup:GetData().wand_index
    if not wand_index then return end
    
    local wand_package = TBoN.Gun.Table.generated_wands[wand_index]
    if not wand_package then return end
    
    -- 找到空槽
    local empty_slot = nil
    for i = 1, 4 do
        if TBoN.Gun.Table.gun_info[i].name == false then
            empty_slot = i
            break
        end
    end
    
    if not empty_slot then
        print("法杖槽位已满!")
        return
    end
    
    -- 应用法杖数据
    TBoN.Gun.Table.gun_info[empty_slot] = wand_package.wand
    TBoN.Gun.Table.gun_magic_data[empty_slot] = wand_package.spells
    
    print("拾取法杖: " .. wand_package.wand.name)
end
```

## 算法细节

### 正态分布生成

使用Box-Muller变换生成正态分布随机数：

```lua
function RandomNormal(mean, stddev)
    local u1 = math.random()
    local u2 = math.random()
    local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return mean + z * stddev
end
```

这确保了：
- 大部分法杖属性接近平均值
- 偶尔出现极端属性的法杖
- 属性分布更自然，更接近Noita原版

### 加权随机选择

永久法术和法术池使用加权随机：

```lua
-- 计算总权重
local total_weight = 0
for _, item in ipairs(pool) do
    total_weight = total_weight + item.weight
end

-- 随机选择
local roll = math.random() * total_weight
local cumulative = 0
for _, item in ipairs(pool) do
    cumulative = cumulative + item.weight
    if roll <= cumulative then
        return item
    end
end
```

## 调试

生成时会输出调试信息：

```
[WAND_GEN] 为法杖添加了 5 个法术
[WAND_GEN] 添加永久法术: BLACK_HOLE
[WAND_GEN] 生成法杖完成:
  - 楼层: 3
  - 容量: 7
  - 法术数: 5
  - 洗牌: true
  - Better: false
[WAND_GEN] 在位置 (320, 240) 生成法杖
```

## 扩展建议

### 1. 添加更多永久法术

编辑 `ALWAYS_CAST_POOL` 添加新的永久法术选项。

### 2. 调整楼层配置

修改 `WAND_GENERATION_CONFIG` 调整各楼层的生成参数。

### 3. 实现特殊法杖类型

参考文档中的"快速法杖"、"爆炸法杖"等创建专门的生成函数：

```lua
function TBoN.World.Function.Custom.GenerateFastWand(floor)
    local wand_data, spell_slots = TBoN.World.Function.Custom.GenerateWand(floor, false)
    
    -- 强制快速属性
    wand_data.cast_delay = 2
    wand_data.recharge_time = 15
    wand_data.capacity = 10
    
    -- 只添加轻型法术
    -- ... 自定义逻辑
    
    return wand_data, spell_slots
end
```

## 总结

该系统完全实现了Noita的法杖生成算法，包括：

- ✅ 正态分布属性生成
- ✅ 楼层分级配置
- ✅ Better法杖机制
- ✅ 永久法术系统
- ✅ 法术池过滤和选择
- ✅ 洗牌概率控制
- ✅ 法术数量平衡

只需要实现拾取物生成和数据关联即可完全集成到游戏中。
