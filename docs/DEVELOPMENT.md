# The Binding of Noita - 开发文档

## 项目概述

The Binding of Noita 是一个《以撒的结合：忏悔》mod，将《Noita》的法杖和法术系统移植到以撒中。

## 项目结构

```
The Binding of Noita/
├── main.lua                    # 主入口文件，初始化模块结构
├── main_r.lua                  # REPENTOGON 扩展支持
├── metadata.xml               # Mod 元数据
├── content/                   # 以撒内容定义
│   ├── costumes2.xml         # 角色服装
│   ├── entities2.xml         # 实体定义
│   ├── items.xml             # 物品定义
│   └── players.xml           # 玩家角色定义
├── resources/                 # 资源文件
│   └── gfx/
│       ├── characters/        # 角色图形
│       ├── gun/              # 法杖动画 (wand_XXXX.anm2)
│       ├── magic/            # 法术效果图形
│       └── ui/               # UI图形
└── scripts/                   # 脚本文件
    ├── characters.lua        # 角色相关
    ├── data.lua              # 数据模块入口
    ├── entity.lua            # 实体处理
    ├── gun.lua               # 法杖模块入口
    ├── info.lua              # 信息常量
    ├── magic.lua             # 法术模块入口
    ├── render.lua            # 渲染模块入口
    ├── room.lua              # 房间模块入口
    └── world.lua             # 世界模块入口
```

## 核心命名空间

项目使用 `TBoN` 作为全局命名空间，包含以下子模块：

| 模块 | 描述 |
|------|------|
| `TBoN.Render` | 渲染/UI相关 |
| `TBoN.Gun` | 法杖系统 |
| `TBoN.Magic` | 法术系统 |
| `TBoN.World` | 世界/生成系统 |
| `TBoN.Room` | 房间逻辑 |
| `TBoN.Data` | 数据持久化 |
| `TBoN.Character` | 角色系统 |

每个模块都有以下结构：
- `Variable` - 变量存储 (Bool/Num/String)
- `Table` - 表/数据存储
- `Function.Custom` - 自定义函数
- `Info` - 常量信息 (部分模块)

---

## 新法术添加 Workflow

<!-- TODO: 手动补充具体步骤 -->

### 1. 定义法术Action

文件: `scripts/guns/gun_actions.lua`

```lua
{
    id                  = "YOUR_SPELL_ID",
    name                = "$action_your_spell",
    description         = "$actiondesc_your_spell",
    sprite              = "data/ui_gfx/gun_actions/your_spell.png",
    type                = "ACTION_TYPE_PROJECTILE", -- 见法术类型
    spawn_level         = "0,1,2,3",  -- 生成等级
    spawn_probability   = "1,1,0.5,0.2",  -- 生成概率
    mana                = 10,  -- 魔力消耗
    max_uses            = -1,  -- 使用次数 (-1=无限)
    action              = function()
        c.entity_type = TBoN.Magic.Info.Type.Your_Spell
        c.entity_variant = TBoN.Magic.Info.Variant.Your_Spell
        c.damage = 10
        c.lifetime = 60
        c.speed = 15
        c.fire_rate_wait = c.fire_rate_wait + 5
        -- ... 其他属性
    end,
},
```

### 2. 注册实体信息

<!-- TODO: 补充实体信息注册位置和方式 -->

### 3. 创建法术逻辑文件

文件: `scripts/magics/magic_functions/your_spell.lua`

```lua
-- 伤害逻辑
function TBoN_MOD:Your_Spell_Damage(entity)
    local entities = Isaac.FindInRadius(entity.Position, 5, EntityPartition.ENEMY)
    if #entities > 0 then
        entities[1]:TakeDamage(
            TBoN.Magic.Function.Custom.Damage_Calculate(entity, TBoN.Magic.Table.magic_hash), 
            0, EntityRef(entity), 0
        )
        -- 触发检测
        local entity_hash = GetPtrHash(entity)
        local trigger_data = TBoN.Magic.Table.trigger_data[entity_hash]
        if trigger_data then
            TBoN_MOD:TriggerSystem_Entity_Collision_Check(entity, entities[1])
        else
            entity:Remove()
        end
    end
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Your_Spell_Damage, TBoN.Magic.Info.Variant.Your_Spell)

-- 消失逻辑
function TBoN_MOD:Your_Spell_Disappear(entity)
    if TBoN.Room.Function.Custom.Out_Of_Room(entity.Position) then
        entity:Kill()
    end
    -- ... 碰撞检测等
end

TBoN_MOD:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TBoN_MOD.Your_Spell_Disappear, TBoN.Magic.Info.Variant.Your_Spell)
```

### 4. 在magic.lua中包含新文件

```lua
include("scripts.magics.magic_functions.your_spell")
```

### 5. 添加UI资源

<!-- TODO: 补充UI资源添加位置 -->

### 6. 添加翻译

<!-- TODO: 补充翻译文件位置和格式 -->

### 7. 解锁法术

```lua
TBoN.World.Function.Custom.UnlockSpell("YOUR_SPELL_ID")
```

---

## 法术类型

| 类型 | 描述 |
|------|------|
| `ACTION_TYPE_PROJECTILE` | 投射物法术 |
| `ACTION_TYPE_STATIC_PROJECTILE` | 静态投射物 |
| `ACTION_TYPE_MODIFIER` | 修饰符法术 |
| `ACTION_TYPE_DRAW_MANY` | 多重抽取法术 |
| `ACTION_TYPE_OTHER` | 其他类型 |

---

## 触发系统

### 触发类型

| 类型 | 值 | 描述 |
|------|------|------|
| `TIMER` | 1 | 定时触发 |
| `COLLISION` | 2 | 碰撞触发 |
| `DEATH` | 3 | 死亡触发 |

### 使用触发法术

在 `action` 函数中设置:
```lua
c.is_trigger = true
c.trigger_type = "COLLISION"  -- 或 "TIMER"
c.trigger_param = 10  -- 对于TIMER是帧数
```

---

## 法杖系统

### 法杖属性

| 属性 | 描述 |
|------|------|
| `shuffle` | 是否乱序 |
| `capacity` | 法术槽容量 |
| `cast_delay` | 施法延迟(帧) |
| `recharge_time` | 充能时间(帧) |
| `mana_max` | 最大魔力 |
| `mana_charge_speed` | 魔力恢复速度 |
| `spread_degrees` | 散射角度 |
| `always_cast` | 始终施放法术 |

### 法杖状态 (`gun_states`)

| 属性 | 描述 |
|------|------|
| `deck` | 当前牌库 |
| `discard_pile` | 弃牌堆 |
| `always_cast_hand` | 始终施放手牌 |
| `current_mana` | 当前魔力 |
| `cast_cooldown` | 施法冷却 |
| `recharge_cooldown` | 充能冷却 |
| `wrapped_around` | 是否已回绕 |

---

## 投射物属性 (c 变量)

| 属性 | 描述 | 默认值 |
|------|------|--------|
| `entity_type` | 实体类型 | nil |
| `entity_variant` | 实体变体 | nil |
| `damage` | 伤害倍率 | 1 |
| `speed` | 速度 | 1 |
| `speed_multiplier` | 速度倍率 | 1 |
| `lifetime` | 生命周期(帧) | 0 |
| `lifetime_add` | 生命周期增加 | 0 |
| `fire_rate_wait` | 施法延迟增加 | 0 |
| `spread_degrees` | 散射角度 | 0 |
| `damage_critical_chance` | 暴击率(%) | 0 |
| `damage_projectile_add` | 附加伤害 | 0 |
| `recoil_knockback` | 后坐力 | 0 |
| `is_trigger` | 是否为触发法术 | false |
| `trigger_type` | 触发类型 | nil |
| `trigger_param` | 触发参数 | nil |

---

## 修饰符系统

修饰符存储在 `proj_modifier` 数组中，由修饰符法术添加，在投射物生成时应用。

<!-- TODO: 补充修饰符添加和应用的详细说明 -->

---

## 数据存储

### 法术使用次数

- `TBoN.Magic.Table.bag_magic_data` - 背包法术数据
- `TBoN.Gun.Table.gun_magic_data` - 法杖法术数据

每个法术槽位的数据结构:
```lua
{
    magic_id = "SPELL_ID",  -- 法术ID，false表示空槽位
    current_uses = -1,       -- 当前使用次数，-1表示无限
    max_uses = -1,           -- 最大使用次数
}
```

---

## 版本信息

当前版本: `TBoN.Info.Mod_Version`
环境: `TBoN.Info.Mod_Env` (release/dev)

---

## 待补充内容

<!-- 以下内容需要手动补充 -->

- [ ] 实体信息注册详细步骤
- [ ] UI资源添加指南
- [ ] 翻译文件格式和位置
- [ ] 修饰符系统详细说明
- [ ] 法杖生成逻辑
- [ ] 存档/读档系统
- [ ] 调试方法和技巧
