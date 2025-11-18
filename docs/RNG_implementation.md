# RNG 伪随机系统实现文档

## 概述

项目已完全从 `math.random()` 真随机系统迁移到 Isaac 的 RNG 伪随机系统。这确保了：

1. ✅ **确定性** - 相同种子产生相同结果
2. ✅ **可重现性** - 可以重播录像/调试
3. ✅ **一致性** - 符合 Isaac 游戏机制
4. ✅ **性能** - 优化的 Xorshift 算法

## 为什么使用伪随机

### 真随机的问题

```lua
-- ❌ 不要这样做
local damage = math.random(10, 20)
```

**问题：**
- 每次运行结果不同
- 无法重现 bug
- 破坏录像回放
- 违反 Isaac 设计原则

### 伪随机的优势

```lua
-- ✅ 正确做法
local rng = RNG()
rng:SetSeed(entity.InitSeed, 35)
local damage = rng:RandomInt(11) + 10  -- 10-20
```

**优势：**
- 相同种子 → 相同结果
- 可重现行为
- 支持录像回放
- 符合游戏机制

## RNG 基础使用

### 创建 RNG 对象

```lua
local rng = RNG()
```

**注意：** 新创建的 RNG 对象种子为 `2853650767`，**必须**先设置种子！

### 设置种子

```lua
-- 推荐的 ShiftIdx 为 35（Blade 审查游戏内部后推荐）
local RECOMMENDED_SHIFT_IDX = 35

rng:SetSeed(seed, RECOMMENDED_SHIFT_IDX)
```

**ShiftIdx 说明：**
- 范围：0-80（包含）
- 推荐值：35
- 不同值产生不同随机序列
- 使用常量避免魔数

### 生成随机数

#### RandomInt - 随机整数

```lua
-- 返回 0 到 max-1 之间的整数（包含0，不包含max）
local value = rng:RandomInt(4)  -- 返回 0, 1, 2 或 3

-- 生成 10-20 之间的随机数
local damage = rng:RandomInt(11) + 10  -- 10, 11, ..., 20
```

#### RandomFloat - 随机浮点数

```lua
-- 返回 0.0 到 1.0 之间的浮点数（包含0，不包含1）
local chance = rng:RandomFloat()

if chance < 0.3 then  -- 30% 概率
    -- 做某事
end
```

## 种子选择策略

### 1. 基于游戏开始种子

**用途：** 整局游戏保持一致的随机结果

```lua
local rng = RNG()
local seeds = Game():GetSeeds()
local start_seed = seeds:GetStartSeed()
rng:SetSeed(start_seed, 35)
```

**示例：** 法杖生成系统

### 2. 基于房间种子

**用途：** 每个房间独立的随机结果

```lua
local rng = RNG()
local room = Game():GetLevel():GetCurrentRoom()
local room_seed = room:GetDecorationSeed()
rng:SetSeed(room_seed, 35)
```

**示例：** 房间奖励生成

### 3. 基于实体初始种子

**用途：** 每个实体独立的随机行为

```lua
local rng = RNG()
rng:SetSeed(entity.InitSeed, 35)
```

**示例：** 敌人 AI 行为

### 4. 基于帧数

**用途：** 时间相关的随机事件

```lua
local rng = RNG()
local frame = Game():GetFrameCount()
rng:SetSeed(frame, 35)
```

**示例：** 投射物散射角度

### 5. 基于实体哈希

**用途：** 触发系统等需要实体唯一性的场景

```lua
local rng = RNG()
local entity_hash = GetPtrHash(entity)
rng:SetSeed(entity_hash, 35)
```

**示例：** 触发法术散射

## 项目中的实现

### 1. 法杖生成系统 (`wand_generation.lua`)

#### 正态分布随机数

```lua
-- Box-Muller变换生成正态分布
local function RandomNormal(mean, stddev, rng)
    local u1 = rng:RandomFloat()
    local u2 = rng:RandomFloat()
    local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return mean + z * stddev
end
```

**使用场景：** 法杖属性生成（容量、法力、延迟等）

#### 法杖生成主函数

```lua
function TBoN.World.Function.Custom.GenerateWand(floor, is_better, rng)
    -- 如果没有提供RNG，创建基于游戏种子的RNG
    if not rng then
        rng = RNG()
        local seeds = Game():GetSeeds()
        local start_seed = seeds:GetStartSeed()
        rng:SetSeed(start_seed, 35)
    end
    
    -- 使用 rng 生成所有属性
    local stats = TBoN.World.Function.Custom.GenerateWandStats(floor, is_better, rng)
    -- ...
end
```

#### 房间生成法杖

```lua
function TBoN_MOD:OnRoomClearWandSpawn()
    -- 基于房间种子确保每个房间独立
    local rng = RNG()
    local room = Game():GetLevel():GetCurrentRoom()
    local room_seed = room:GetDecorationSeed()
    rng:SetSeed(room_seed, 35)
    
    -- 10% 概率生成法杖
    if rng:RandomFloat() < 0.1 then
        -- 5% 概率是 Better 法杖
        local is_better = (rng:RandomFloat() < 0.05)
        local wand_data, spell_slots = TBoN.World.Function.Custom.GenerateWand(stage, is_better, rng)
    end
end
```

### 2. 散射角度计算 (`gun_used_functions.lua`)

```lua
function TBoN.Gun.Function.Custom.Calculate_Spread_Direction(base_direction, spread_degrees, rng)
    if not spread_degrees or spread_degrees <= 0 then
        return base_direction:Normalized()
    end
    
    -- 如果没有提供RNG，创建基于游戏帧的RNG
    if not rng then
        rng = RNG()
        local frame = Game():GetFrameCount()
        rng:SetSeed(frame, 35)
    end
    
    local base_angle_rad = math.atan(base_direction.Y, base_direction.X)
    
    if spread_degrees >= 360 then
        -- 完全随机方向
        local final_angle_rad = rng:RandomFloat() * 2 * math.pi
        return Vector(math.cos(final_angle_rad), math.sin(final_angle_rad))
    else
        -- 在扩散范围内随机
        local spread_rad = math.rad(spread_degrees)
        local random_offset = (rng:RandomFloat() - 0.5) * 2 * spread_rad
        local final_angle_rad = base_angle_rad + random_offset
        return Vector(math.cos(final_angle_rad), math.sin(final_angle_rad))
    end
end
```

**调用示例：**

```lua
-- 在 gun.lua 中
local scatter_rng = RNG()
local frame = Game():GetFrameCount()
scatter_rng:SetSeed(frame, 35)

for i, proj in ipairs(TBoN.Gun.Table.current_projectiles) do
    local scatter_direction = TBoN.Gun.Function.Custom.Calculate_Spread_Direction(
        TBoN.Gun.Function.Vector.Aim_direc,
        proj.spread_degrees or 0,
        scatter_rng  -- 传递RNG对象
    )
end
```

### 3. 触发系统 (`trigger_system.lua`)

```lua
-- 在触发点生成投射物
local trigger_rng = RNG()
local entity_hash = GetPtrHash(entity)
trigger_rng:SetSeed(entity_hash, 35)

local scatter_direction = TBoN.Gun.Function.Custom.Calculate_Spread_Direction(
    spawn_velocity,
    c.spread_degrees or 0,
    trigger_rng
)
```

**为什么用实体哈希：**
- 每个触发实体独立的散射
- 确保相同触发产生相同结果
- 可重现的触发行为

## 常见模式

### 模式1: 概率判断

```lua
-- ❌ 错误
if math.random() < 0.3 then

-- ✅ 正确
local rng = RNG()
rng:SetSeed(appropriate_seed, 35)
if rng:RandomFloat() < 0.3 then
```

### 模式2: 范围随机

```lua
-- ❌ 错误
local value = math.random(10, 20)

-- ✅ 正确
local rng = RNG()
rng:SetSeed(appropriate_seed, 35)
local value = rng:RandomInt(11) + 10  -- 10-20
```

### 模式3: 数组随机选择

```lua
-- ❌ 错误
local item = items[math.random(1, #items)]

-- ✅ 正确
local rng = RNG()
rng:SetSeed(appropriate_seed, 35)
local index = rng:RandomInt(#items) + 1  -- Lua数组从1开始
local item = items[index]
```

### 模式4: 加权随机

```lua
local function SelectByWeight(items, rng)
    local total_weight = 0
    for _, item in ipairs(items) do
        total_weight = total_weight + item.weight
    end
    
    local roll = rng:RandomFloat() * total_weight
    local cumulative = 0
    
    for _, item in ipairs(items) do
        cumulative = cumulative + item.weight
        if roll <= cumulative then
            return item
        end
    end
    
    return items[1]
end

-- 使用
local rng = RNG()
rng:SetSeed(seed, 35)
local selected = SelectByWeight(spell_pool, rng)
```

## 调试技巧

### 1. 固定种子调试

```lua
-- 使用固定种子重现问题
local DEBUG_SEED = 123456
local rng = RNG()
rng:SetSeed(DEBUG_SEED, 35)

-- 现在每次运行结果都相同
```

### 2. 打印种子

```lua
local rng = RNG()
rng:SetSeed(seed, 35)
print("[DEBUG] RNG Seed: " .. rng:GetSeed())
```

### 3. 验证确定性

```lua
-- 测试代码
local rng = RNG()
rng:SetSeed(12345, 35)

print(rng:RandomInt(100))  -- 每次运行应该相同
print(rng:RandomFloat())   -- 每次运行应该相同
```

## 性能考虑

### RNG 对象重用

```lua
-- ❌ 低效 - 每次都创建新 RNG
for i = 1, 1000 do
    local rng = RNG()
    rng:SetSeed(seed + i, 35)
    local value = rng:RandomInt(10)
end

-- ✅ 高效 - 重用 RNG
local rng = RNG()
for i = 1, 1000 do
    rng:SetSeed(seed + i, 35)
    local value = rng:RandomInt(10)
end
```

### 批量生成

```lua
-- 如果需要多个随机数，不需要每次重新设置种子
local rng = RNG()
rng:SetSeed(seed, 35)

local value1 = rng:RandomInt(10)
local value2 = rng:RandomInt(10)  -- 自动迭代到下一个随机数
local value3 = rng:RandomFloat()
```

## 注意事项

### ⚠️ 种子为0会崩溃

```lua
-- ❌ 危险！会导致崩溃
local rng = RNG()
rng:SetSeed(0, 35)  -- 崩溃！
rng:RandomInt(10)

-- ✅ 安全检查
local seed = some_value
if seed == 0 then
    seed = 1  -- 或者使用其他默认值
end
rng:SetSeed(seed, 35)
```

### ⚠️ ShiftIdx 范围

```lua
-- ❌ 超出范围可能崩溃
rng:SetSeed(seed, 100)  -- 危险！

-- ✅ 使用推荐值
local RECOMMENDED_SHIFT_IDX = 35
rng:SetSeed(seed, RECOMMENDED_SHIFT_IDX)
```

### ⚠️ 自动迭代

```lua
-- RandomInt 和 RandomFloat 会自动调用 Next()
local rng = RNG()
rng:SetSeed(seed, 35)

local a = rng:RandomInt(10)  -- 种子迭代
local b = rng:RandomInt(10)  -- 不同的随机数

-- 如果想要相同的随机数，需要重新设置种子
rng:SetSeed(seed, 35)
local c = rng:RandomInt(10)  -- 与 a 相同
```

## 迁移清单

### 已完成

- [x] `wand_generation.lua` - 法杖生成系统
  - [x] RandomNormal 函数
  - [x] ClampedNormal 函数
  - [x] GenerateWandStats 函数
  - [x] SelectAlwaysCast 函数
  - [x] AddRandomSpells 函数
  - [x] GenerateWand 函数
  - [x] OnRoomClearWandSpawn 函数

- [x] `gun_used_functions.lua` - 散射角度计算
  - [x] Calculate_Spread_Direction 函数

- [x] `gun.lua` - 投射物生成散射
  - [x] Magic_Spawn 函数

- [x] `trigger_system.lua` - 触发法术散射
  - [x] ExecuteTriggerSpells 函数

### 文档更新

- [x] 创建 RNG_implementation.md 文档
- [x] 详细说明所有使用场景
- [x] 提供代码示例
- [x] 列出常见模式和最佳实践

## 总结

项目现在完全使用确定性伪随机系统：

1. **所有随机生成都基于种子** - 可重现
2. **符合 Isaac 游戏机制** - 支持录像回放
3. **适当的种子选择** - 根据场景选择合适的种子源
4. **性能优化** - RNG 对象重用和批量生成
5. **安全检查** - 避免种子为0或越界 ShiftIdx

这确保了模组行为的一致性和可调试性。
