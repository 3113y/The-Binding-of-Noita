# The Binding of Noita - 项目架构规范

## 📋 目录结构

```
mod_root/
├── main.lua                    # 入口文件，定义全局命名空间
├── metadata.xml                # mod元数据
├── content/
│   └── entities2.xml           # 实体定义
├── resources/                  # 资源文件
│   └── gfx/
│       ├── gun/                # 法杖sprite
│       ├── ui/                 # UI sprite
│       └── particle/           # 粒子效果
└── scripts/                    # 所有Lua脚本
    ├── [module].lua            # 模块入口 (gun.lua, render.lua, magic.lua等)
    ├── [module]s/              # 模块子文件夹
    │   ├── [module]_table.lua      # 数据表
    │   ├── [module]_used_functions.lua  # 工具函数
    │   └── [module]_functions/     # 具体实现
    │       └── [feature].lua
    └── docs/                   # 文档
```

---

## 🏗️ 核心架构特点

### 1. **全局命名空间层级结构**

```lua
-- main.lua 中定义唯一全局变量
TBoN_MOD = RegisterMod("The Binding of Noita", 1)

TBoN = {
    [Module] = {                    -- 模块层
        Variable = {                -- 变量层
            Bool = {},              -- 按类型分类
            Num = {},
            String = {},
            Item = {}
        },
        Table = {},                 -- 数据表层
        Info = {                    -- 常量/枚举层
            Type = {},
            Variant = {}
        },
        Function = {                -- 函数层
            Custom = {},            -- 自定义函数
            Sprite = {},            -- Sprite相关
            Vector = {},            -- Vector相关
            Font = {}               -- Font相关
        }
    }
}
```

**模块示例**:
- `Render` - UI渲染
- `Gun` - 法杖系统
- `Magic` - 法术系统
- `World` - 世界交互
- `Character` - 角色相关

---

### 2. **模块化文件组织**

每个模块遵循固定的三层结构：

```
scripts/
├── [module].lua                         # 入口：include所有子文件
├── [module]s/                           # 复数形式的子文件夹
│   ├── [module]_table.lua              # 数据定义层
│   ├── [module]_used_functions.lua     # 工具函数层
│   └── [module]_functions/             # 具体实现层
│       ├── [feature_1].lua
│       ├── [feature_2].lua
│       └── ...
```

**实际示例**:

```
scripts/
├── gun.lua
├── guns/
│   ├── gun_table.lua              # 定义 gun_states, gun_info, gun_magic_data
│   ├── gun_used_functions.lua    # 工具函数如 Calculate_Spread_Direction
│   └── gun_actions.lua            # 所有法术action定义
├── magic.lua
├── magics/
│   ├── magic_table.lua            # 定义 magic_hash, bag_magic_data
│   ├── magic_used_functions.lua  # 工具函数
│   ├── trigger_system.lua         # 触发系统
│   └── magic_functions/
│       ├── bullet.lua
│       ├── black_hole.lua
│       └── ...
├── render.lua
└── renders/
    ├── render_table.lua           # UI位置、映射表
    ├── render_used_functions.lua # UI工具函数
    └── translations.lua           # 中文翻译表
```

---

## 📐 命名规范

### 变量命名

#### 1. **全局变量 - 大驼峰 + 模块前缀**

```lua
-- ✅ 正确
TBoN.Gun.Table.gun_states
TBoN.Render.Variable.Bool.Tab_Confirm
TBoN.Magic.Table.magic_hash

-- ❌ 错误
gunStates
tabConfirm
```

#### 2. **局部变量 - snake_case**

```lua
-- ✅ 正确
local entity_hash = GetPtrHash(entity)
local scatter_direction = Vector(0, 0)
local current_gun_index = 1
local spell_mana_cost = 10

-- ❌ 错误
local entityHash
local scatterDirection
```

#### 3. **函数命名 - 大驼峰，带模块路径**

```lua
-- ✅ 正确
function TBoN.Gun.Function.Custom.Calculate_Spread_Direction(...)
function TBoN.Render.Function.Custom.Mouse_Pos_But_Check(...)
function TBoN_MOD:Light_Bullet_Damage(entity)

-- ❌ 错误
function calculateSpreadDirection(...)
function mousePosButCheck(...)
```

#### 4. **表字段 - snake_case**

```lua
-- ✅ 正确
{
    magic_id = "BOMB",
    current_uses = -1,
    max_uses = -1,
    entity_type = 1000,
    entity_variant = 800,
    fire_rate_wait = 10
}

-- ❌ 错误
{
    magicId = "BOMB",
    currentUses = -1
}
```

#### 5. **常量/枚举 - SCREAMING_SNAKE_CASE**

```lua
-- ✅ 正确
TBoN.Magic.Info.TriggerType = {
    TIMER = 1,
    COLLISION = 2,
    DEATH = 3
}

local ACTION_TYPE_PROJECTILE = "ACTION_TYPE_PROJECTILE"

-- ❌ 错误
local ActionTypeProjectile = "..."
```

---

## 🔧 数据组织模式

### 1. **分离渲染与数据**

```lua
-- 数据层 (magic_table.lua)
TBoN.Magic.Table.bag_magic_data = {
    {magic_id = "BOMB", current_uses = -1, max_uses = -1},
    {magic_id = false, current_uses = 0, max_uses = 0}
}

-- 渲染层 (render_table.lua)
TBoN.Render.Table.bag_magic_render_table = {
    {pos = Vector(100, 100), sprite = Sprite()},
    {pos = Vector(120, 100), sprite = Sprite()}
}
```

通过索引关联：`bag_magic_data[i]` ↔ `bag_magic_render_table[i]`

### 2. **哈希表追踪实体**

```lua
-- 使用 GetPtrHash 追踪动态实体
local entity_hash = GetPtrHash(entity)

TBoN.Magic.Table.magic_hash[entity_hash] = {
    damages = {
        damage = 10,
        damage_critical_chance = 5
    },
    modifiers = {"HOMING", "ACCELERATING"},
    trigger_spells = {"BOMB"},
    applied = false
}

-- 使用时
local entity_data = TBoN.Magic.Table.magic_hash[GetPtrHash(entity)]
```

### 3. **配置与状态分离**

```lua
-- 静态配置 (不变)
TBoN.Gun.Table.gun_info = {
    {
        name = "wand_0000",
        shuffle = false,
        capacity = 9,
        mana_max = 5000
    }
}

-- 动态状态 (运行时变化)
TBoN.Gun.Table.gun_states = {
    {
        current_mana = 5000,
        cast_cooldown = 0,
        deck = {"BOMB", "LIGHT_BULLET"},
        discard_pile = {}
    }
}
```

---

## 🎯 回调函数命名模式

```lua
-- 模式: TBoN_MOD:[Feature]_[Action]
function TBoN_MOD:Light_Bullet_Damage(entity)
    -- 处理光弹伤害
end

function TBoN_MOD:Black_Hole_Attract(entity)
    -- 处理黑洞吸引
end

function TBoN_MOD:TriggerSystem_Timer_Update(entity)
    -- 处理定时触发更新
end

-- 注册回调
TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Light_Bullet_Damage, 800)
```

**参数约定**:
- `entity` - 实体参数
- `player` - 玩家参数
- 回调类型作为第三参数 (Variant ID)

---

## 📦 模块间通信

### 通过全局命名空间共享数据

```lua
-- gun.lua 中生成投射物
local entity_hash = GetPtrHash(entity)
TBoN.Magic.Table.magic_hash[entity_hash] = {
    damages = {...},
    modifiers = proj.modifiers
}

-- magic_functions/bullet.lua 中读取
function TBoN_MOD:Bullet_Damage(entity)
    local damage = TBoN.Magic.Function.Custom.Damage_Calculate(
        entity, 
        TBoN.Magic.Table.magic_hash  -- 访问其他模块数据
    )
end
```

---

## 🔄 include 模式

```lua
-- main.lua - 根级 include
include("scripts.gun")
include("scripts.magic")
include("scripts.render")

-- scripts/gun.lua - 模块级 include (使用点号路径)
include("scripts.guns.gun_table")
include("scripts.guns.gun_used_functions")
include("scripts.guns.gun_actions")

-- scripts/magic.lua
include("scripts.magics.magic_table")
include("scripts.magics.magic_used_functions")
include("scripts.magics.trigger_system")
include("scripts.magics.magic_functions.bullet")
include("scripts.magics.magic_functions.black_hole")
```

**规则**:
- 使用点号 `.` 代替路径分隔符
- 无需 `.lua` 后缀
- 按依赖顺序排列 (table → functions → features)

---

## 🎨 UI 渲染模式

### 位置表 + 数据表 + 映射表

```lua
-- 1. 位置表 - 定义屏幕坐标
TBoN.Render.Table.gun_render_table = {
    {pos = Vector(55, 55), sprite = Sprite()},
    {pos = Vector(78, 55), sprite = Sprite()},
    -- ...
}

-- 2. 数据表 - 法术ID到数组索引的映射
TBoN.Render.Table.actions_map = {
    ["BOMB"] = 1,
    ["LIGHT_BULLET"] = 2,
    ["BULLET"] = 6,
    -- ...
}

-- 3. 渲染时结合
for i, render_slot in pairs(TBoN.Render.Table.gun_render_table) do
    local magic_id = TBoN.Gun.Table.gun_magic_data[i].magic_id
    if magic_id then
        local spell_idx = TBoN.Render.Table.actions_map[magic_id]
        render_slot.sprite:Load("path/" .. string.lower(magic_id) .. ".png")
        render_slot.sprite:Render(render_slot.pos)
    end
end
```

---

## 🧮 施法系统架构

### c 变量全局状态机

```lua
-- 全局状态机 - 存储施法属性
c = {
    fire_rate_wait = 0,
    entity_type = nil,
    entity_variant = nil,
    speed = 1,
    damage = 1,
    lifetime_add = 0,
    spread_degrees = 0,
    -- 触发相关
    is_trigger = false,
    trigger_type = nil,
    trigger_param = nil
}

-- 法术修饰符栈
proj_modifier = {}

-- 法术执行时修改 c
actions = {
    {
        id = "BOMB",
        action = function()
            c.entity_type = EntityType.ENTITY_BOMB
            c.entity_variant = 0
            c.damage = 10
            c.fire_rate_wait = c.fire_rate_wait + 15
        end
    }
}
```

---

## 🔍 实体追踪模式

### 哈希表 + Variant ID

```lua
-- 1. 定义 Variant ID (magic_table.lua)
TBoN.Magic.Info.Type.Black_Hole_Entity = 1000
TBoN.Magic.Info.Variant.Black_Hole_Variant = 799

-- 2. 生成实体时存储
local entity = Isaac.Spawn(
    TBoN.Magic.Info.Type.Black_Hole_Entity,
    TBoN.Magic.Info.Variant.Black_Hole_Variant,
    0, position, velocity, player
)

local entity_hash = GetPtrHash(entity)
TBoN.Magic.Table.magic_hash[entity_hash] = {...}

-- 3. 回调时通过 Variant 过滤
function TBoN_MOD:Black_Hole_Update(entity)
    -- 自动过滤，只处理黑洞实体
end

TBoN_MOD:AddCallback(
    ModCallbacks.MC_POST_EFFECT_UPDATE, 
    TBoN_MOD.Black_Hole_Update, 
    799  -- Variant ID 过滤
)
```

---

## 🧩 注释规范

### 1. **文件头注释**

```lua
-- 触发系统 - 用于处理定时触发、碰撞触发、死亡触发等
-- 支持法术在特定条件下触发下一个施法块
```

### 2. **函数注释**

```lua
-- 散射角度计算函数
---@param base_direction: 基础方向向量 (Vector)
---@param spread_degrees: 散射角度 (度数)
---@return Vector: 计算后的方向向量 (Vector)
function TBoN.Gun.Function.Custom.Calculate_Spread_Direction(base_direction, spread_degrees)
```

### 3. **数据结构注释**

```lua
-- Gun magic data with usage tracking
-- Each slot contains {magic_id, current_uses, max_uses} where:
-- magic_id: spell identifier (false for empty slots)
-- current_uses: -1 = infinite uses, 0 = empty slot, >0 = remaining uses
-- max_uses: maximum uses for this spell (-1 for infinite)
TBoN.Gun.Table.gun_magic_data = { ... }
```

### 4. **逻辑块注释**

```lua
-- 收集触发法术队列
local trigger_spells = {}
if c.is_trigger then
    -- 触发法术：收集后续施法块的法术作为触发队列
    ...
end
```

---

## 🚀 性能优化模式

### 1. **局部化全局访问**

```lua
-- ✅ 好
local gun_states = TBoN.Gun.Table.gun_states
local gun_info = TBoN.Gun.Table.gun_info
for i = 1, 4 do
    local state = gun_states[i]
    local info = gun_info[i]
end

-- ❌ 差
for i = 1, 4 do
    local state = TBoN.Gun.Table.gun_states[i]
    local info = TBoN.Gun.Table.gun_info[i]
end
```

### 2. **提前退出**

```lua
function TBoN_MOD:Bullet_Damage(entity)
    local entities = Isaac.FindInRadius(entity.Position, 10, EntityPartition.ENEMY)
    if #entities == 0 then return end  -- 提前退出
    
    -- 处理碰撞
end
```

### 3. **垃圾回收控制**

```lua
-- 在大量生成实体后
TBoN.Gun.Variable.Bool.fire_state = false
TBoN.Gun.Table.current_projectiles = {}

-- 强制垃圾回收
collectgarbage("step")
```

---

## 📋 快速参考模板

### 创建新模块检查清单

```lua
-- [ ] 1. 在 main.lua 中添加模块命名空间
TBoN.NewModule = {
    Variable = { Bool = {}, Num = {}, String = {} },
    Table = {},
    Info = {},
    Function = { Custom = {} }
}

-- [ ] 2. 创建模块入口文件 scripts/newmodule.lua
include("scripts.newmodules.newmodule_table")
include("scripts.newmodules.newmodule_used_functions")

-- [ ] 3. 创建文件夹 scripts/newmodules/

-- [ ] 4. 创建数据表 newmodule_table.lua
TBoN.NewModule.Table.data = {}

-- [ ] 5. 创建工具函数 newmodule_used_functions.lua
function TBoN.NewModule.Function.Custom.Helper() end

-- [ ] 6. 在 main.lua 添加 include
include("scripts.newmodule")
```

---

## 💡 设计原则总结

1. **单一全局变量** - 只有 `TBoN` 和 `TBoN_MOD`
2. **层级命名空间** - Module → Layer (Variable/Table/Function) → Type
3. **数据渲染分离** - 数据表 + 渲染表，通过索引关联
4. **哈希表追踪** - 动态实体使用 `GetPtrHash` 追踪
5. **模块化文件** - 每个模块三层结构 (table/functions/features)
6. **统一命名风格** - snake_case 局部变量，PascalCase 函数，SCREAMING_SNAKE_CASE 常量
7. **点号 include** - 使用 `include("scripts.module.file")` 格式
8. **回调命名** - `TBoN_MOD:[Feature]_[Action]`
9. **提前退出** - 减少嵌套，提高可读性
10. **中文注释** - 关键逻辑用中文说明，代码用英文


---