# The Binding of Noita - API 文档

本文档记录 `*_used_functions.lua` 中的所有公开API函数。

---

## 目录

- [Magic 模块](#magic-模块)
- [Gun 模块](#gun-模块)
- [Render 模块](#render-模块)
- [Room 模块](#room-模块)
- [World 模块](#world-模块)
- [Data 模块](#data-模块)

---

## Magic 模块

文件: `scripts/magics/magic_used_functions.lua`

### `TBoN.Magic.Function.Custom.Damage_Calculate(entity, table)`

计算投射物最终伤害，包含暴击计算。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `entity` | Entity | 投射物实体 |
| `table` | table | 魔法哈希表 (通常为 `TBoN.Magic.Table.magic_hash`) |

**返回值:** `number` - 计算后的最终伤害

**说明:**
- 暴击率超过100%时，额外暴击率以50%转换为额外伤害
- 基础暴击伤害为5倍

---

### `TBoN.Magic.Function.Custom.Check_Pos(pos1, pos2, range)`

检查两个位置是否在指定范围内。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `pos1` | Vector | 主目标位置 |
| `pos2` | Vector | 待检测目标位置 |
| `range` | number | 检测范围 |

**返回值:** `boolean` - 在范围内返回 `true`，否则返回 `false`

---

### `TBoN.Magic.Function.Custom.Get_Hole_Gravity(entity1, entity2)`

获取两个实体之间的引力数值（用于黑洞等效果）。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `entity1` | Entity | 实体1 |
| `entity2` | Entity | 实体2 |

**返回值:** `number` - 引力值 (0-2)

**说明:**
- 如果 entity2 的质量 >= 99，返回 0
- 返回值上限为 2

---

### `TBoN.Magic.Function.Custom.Hash_Table_Init(table)`

初始化哈希表。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `table` | table | 待初始化的表 |

**返回值:** `table` - 空哈希表

---

### `TBoN.Magic.Function.Custom.Can_Col_With_Grid(grid_entity)`

检查是否可以与格子实体碰撞。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `grid_entity` | GridEntity | 格子实体 |

**返回值:** `boolean` - 可碰撞返回 `true`

**说明:**
- 检查类型是否在不可碰撞列表中
- State 为 2 或 1000 时不可碰撞

---

### `TBoN.Magic.Function.Custom.RegisterTrigger(entity, trigger_type, spell_queue, trigger_param)`

为投射物注册触发信息。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `entity` | Entity | 投射物实体 |
| `trigger_type` | number | 触发类型 (TIMER=1, COLLISION=2, DEATH=3) |
| `spell_queue` | table | 待触发的法术ID数组 |
| `trigger_param` | any | 触发参数 (TIMER为帧数) |

---

### `TBoN.Magic.Function.Custom.ExecuteTriggerSpells(entity, trigger_data)`

执行触发的法术队列。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `entity` | Entity | 触发源实体 |
| `trigger_data` | table | 触发数据 |

---

## Gun 模块

文件: `scripts/guns/gun_used_functions.lua`

### `draw_actions(i, bool)`

增加当前施法的抽取数量。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `i` | number | 增加的抽取数量 |
| `bool` | boolean | (未使用) |

---

### `TBoN.Gun.Function.Custom.Calculate_Spread_Direction(base_direction, spread_degrees, rng)`

计算带散射的方向向量。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `base_direction` | Vector | 基础方向向量 |
| `spread_degrees` | number | 散射角度(度数) |
| `rng` | RNG | RNG对象 (可选) |

**返回值:** `Vector` - 计算后的方向向量（已归一化）

**说明:**
- 如果散射角度 >= 360，则为全方向随机
- 未提供RNG时，基于游戏帧数创建

---

### `TBoN.Gun.Function.Custom.Initialize_All_Gun_States()`

初始化所有法杖（1-4号槽位）的状态。

**说明:**
- 初始化牌库、弃牌堆、魔力值等
- 如果法杖设置为乱序，会自动洗牌

---

### `TBoN.Gun.Function.Custom.Get_Next_Shutted_Magic_Info(gun_state, gun_info)`

核心施法函数，按照Noita机制获取下一个施法块的信息。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `gun_state` | table | 法杖状态表 |
| `gun_info` | table | 法杖信息表 |

**返回值:** `table` - 施法结果
```lua
{
    cast_blocks = {},           -- 施法块
    total_cast_delay = number,  -- 总施法延迟
    recharge_time = number,     -- 充能时间 (仅在需要充能时)
    mana_cost = number,         -- 总魔力消耗
    remaining_mana = number,    -- 剩余魔力
    used_spells_this_cast = {}, -- 本次使用的法术ID列表
    projectiles = {},           -- 投射物列表
}
```

**投射物结构:**
```lua
{
    entity_type = number,
    entity_variant = number,
    entity_subtype = number,
    spell_name = string,
    speed = number,
    speed_multiplier = number,
    damage = number,
    fire_rate_wait = number,
    lifetime = number,
    lifetime_add = number,
    spread_degrees = number,
    damage_critical_chance = number,
    damage_projectile_add = number,
    recoil_knockback = number,
    modifiers = {},
    is_trigger = boolean,
    trigger_type = string,
    trigger_param = any,
    trigger_spells = {},
}
```

---

### `TBoN.Gun.Function.Custom.Reset_Gun_Cast_State(gun_index)`

重置指定法杖的施法状态。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `gun_index` | number | 法杖索引 (1-4) |

**说明:**
- 将弃牌堆归入牌库
- 如果法杖为乱序则洗牌
- 重置冷却和魔力

---

### `TBoN.Gun.Function.Custom.Update_Gun_States()`

更新所有法杖状态（每帧调用）。

**说明:**
- 更新施法冷却和充能冷却
- 充能完成时重置牌库
- 恢复魔力

---

## Render 模块

文件: `scripts/renders/render_used_functions.lua`

### `TBoN.Render.Function.Custom.Mouse_Pos_But_Check(Mouse_Pos, Aim_pos)`

检查鼠标位置是否在指定按钮区域内。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `Mouse_Pos` | Vector | 世界坐标鼠标位置 |
| `Aim_pos` | Vector | 目标位置 (屏幕坐标) |

**返回值:** `boolean` - 在20x20区域内返回 `true`

---

### `TBoN.Render.Function.Custom.Mouse_Pos_Pos_Check(Mouse_Pos, table, i)`

检查鼠标位置是否在表中任意项目的位置上。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `Mouse_Pos` | Vector | 世界坐标鼠标位置 |
| `table` | table | 包含pos字段的表 |
| `i` | number | (未使用) |

**返回值:** `boolean`

---

### `TBoN.Render.Function.Custom.swapGunGroups(gunTable, i, j)`

交换两个法杖槽位的所有数据。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `gunTable` | table | (未使用) |
| `i` | number | 槽位索引1 |
| `j` | number | 槽位索引2 |

**说明:**
- 交换 gun_info、gun_magic_data、gun_states
- 自动更新sprite

---

### `TBoN.Render.Function.Custom.DropWand(gun_index)`

丢弃指定槽位的法杖，生成拾取物。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `gun_index` | number | 法杖槽位索引 |

**说明:**
- 生成带有完整数据的法杖拾取物
- 清空原槽位

---

### `TBoN.Render.Function.Custom.Merge_Magic(magicTable, gunTable)`

合并背包法术和法杖法术为统一列表。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `magicTable` | table | 背包法术渲染表 |
| `gunTable` | table | 法杖渲染表 |

**返回值:** `table` - 合并后的法术列表

**返回项结构:**
```lua
{
    pos = Vector,
    sprite = Sprite,
    magic = string|false,
    current_uses = number,
    max_uses = number,
    source = "magic"|"gun",
    bag_index = number,      -- source="magic"时
    gunIndex = number,       -- source="gun"时
    slotIndex = number,      -- source="gun"时
}
```

---

### `TBoN.Render.Function.Custom.Split_Merged_To_Original(mergedTable)`

将合并后的法术列表拆分回原始数据结构。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `mergedTable` | table | 合并后的法术列表 |

**说明:**
- 更新 bag_magic_data 和 gun_magic_data
- 自动更新相关sprite
- 重新初始化被修改法杖的牌库

---

### `TBoN.Render.Function.Custom.Get_Mouse_Pos_Item_Info(mouse_pos)`

获取鼠标位置下的物品信息。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `mouse_pos` | Vector | 鼠标位置 |

**返回值:** `table` - 物品信息
```lua
{
    type = number,          -- 0=无, 1=法杖, 2=物品, 3=法术
    item_name = string,
    item_index = number,
    gun_index = number,
    spell_slot_index = number,
    spell_info = table,
}
```

---

### `TBoN.Render.Function.Custom.Get_Spell_Info(spell_name)`

获取法术的详细信息。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `spell_name` | string | 法术ID |

**返回值:** `table|nil` - 法术信息
```lua
{
    name = string,
    type = string,
    mana_cost = number,
    fire_rate_wait = number,
    cast_delay = number,
    recharge_time = number,
    speed_multiplier = number,
    damage = number,
    speed = number,
    lifetime = number,
    lifetime_add = number,
    spread_degrees = number,
    recoil_knockback = number,
    damage_critical_chance = number,
    damage_projectile_add = number,
    modifiers = {},
    modifier_effects = {},  -- 仅修饰符类型
}
```

---

### `TBoN.Render.Function.Custom.Render_Info(info_table, render_table, mouse_pos)`

渲染物品/法术信息提示框。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `info_table` | table | 物品信息 (来自 Get_Mouse_Pos_Item_Info) |
| `render_table` | table | 渲染表 |
| `mouse_pos` | Vector | 渲染位置 |

---

### `TBoN.Render.Function.Custom.Load_Anm2(sprite, string)`

加载动画文件。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `sprite` | Sprite\|table | 单个Sprite或Sprite表 |
| `string` | string | 路径字符串 (空字符串使用每项的load属性) |

---

### `TBoN.Render.Function.Custom.Render_Spell_Uses_Count(pos, current_uses)`

渲染法术剩余使用次数。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `pos` | Vector | 法术槽位置 |
| `current_uses` | number | 当前使用次数 (负数不渲染) |

---

### `TBoN.Render.Function.Custom.Get_Wand_Min_Spell_Uses(gun_index)`

获取法杖中剩余使用次数最少的法术次数。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `gun_index` | number | 法杖索引 |

**返回值:** `number` - 最小使用次数，-1表示无限使用或无有限法术

---

### `TBoN.Render.Function.Custom.Render_Anm2(sprite, table, check)`

渲染动画到表中所有位置。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `sprite` | Sprite | Sprite对象 |
| `table` | table | 包含pos的表 |
| `check` | boolean | 检查标志 |

---

## Room 模块

文件: `scripts/rooms/room_used_functions.lua`

### `TBoN.Room.Function.Custom.Out_Of_Room(entity_pos)`

检查位置是否在房间边界外（含20像素边距）。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `entity_pos` | Vector | 实体位置 |

**返回值:** `boolean` - 在房间外返回 `true`

**说明:**
- 检查主房间边界
- 检查房间空洞区域

---

### `TBoN.Room.Function.Custom.Col_With_Room_Wall(entity_pos)`

检查位置是否与房间墙壁碰撞（精确边界）。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `entity_pos` | Vector | 实体位置 |

**返回值:** `boolean` - 碰撞返回 `true`

---

### `TBoN.Room.Function.Custom.Check_Grid_Collision(entity_pos, radius)`

检查与障碍物的碰撞。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `entity_pos` | Vector | 实体位置 |
| `radius` | number | 检测半径 |

**返回值:** 
- `GridEntity|nil` - 碰撞的格子实体
- `Vector|nil` - 格子位置

---

## World 模块

文件: `scripts/worlds/world_used_functions.lua`

### `TBoN.World.Function.Custom.Get_Random_Spell_By_Floor(floor, random_value)`

根据楼层和随机数选择法术。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `floor` | number | 楼层数 (1-11+) |
| `random_value` | number | 随机值 (0-1) |

**返回值:** `string|nil` - 法术ID

**楼层映射:**
| 以撒楼层 | Noita等级 |
|----------|-----------|
| 1-2 | 0 |
| 3-4 | 1 |
| 5 | 2 |
| 6 | 3 |
| 7 | 4 |
| 8 | 5 |
| 9 | 6 |
| 10 | 7 |
| 11+ | 10 |

---

### `TBoN.World.Function.Custom.Get_Available_Spells_By_Floor(floor)`

获取指定楼层所有可用法术列表（调试用）。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `floor` | number | 楼层数 |

**返回值:** `table` - 法术列表
```lua
{
    {
        id = string,
        name = string,
        weight = number,
        type = string,
    },
    ...
}
```

---

### `TBoN.World.Function.Custom.UnlockSpell(spell_id)`

添加已解锁的法术。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `spell_id` | string\|table | 法术ID或法术ID数组 |

**示例:**
```lua
-- 单个解锁
TBoN.World.Function.Custom.UnlockSpell("LIGHT_BULLET")

-- 批量解锁
TBoN.World.Function.Custom.UnlockSpell({"LIGHT_BULLET", "BULLET", "BOMB"})
```

---

## Data 模块

文件: `scripts/data/data_used_functions.lua`

### `TBoN.Data.Function.Custom.Deep_Copy(orig)`

深拷贝表。

**参数:**
| 参数 | 类型 | 描述 |
|------|------|------|
| `orig` | any | 原始值 |

**返回值:** `any` - 深拷贝后的值

**说明:**
- 递归复制嵌套表
- 保留元表

---

## 全局变量

### `c` - 当前投射物属性

施法时用于累积投射物属性的临时变量。

| 字段 | 类型 | 描述 |
|------|------|------|
| `fire_rate_wait` | number | 施法延迟增加量 |
| `entity_type` | number | 实体类型 |
| `entity_variant` | number | 实体变体 |
| `entity_subtype` | number | 实体子类型 |
| `speed` | number | 速度 |
| `speed_multiplier` | number | 速度倍率 |
| `damage` | number | 伤害 |
| `screenshake` | number | 屏幕震动 |
| `lifetime` | number | 生命周期 |
| `lifetime_add` | number | 生命周期增加量 |
| `spread_degrees` | number | 散射角度 |
| `recoil_knockback` | number | 后坐力 |
| `damage_critical_chance` | number | 暴击率 |
| `damage_projectile_add` | number | 附加伤害 |
| `is_trigger` | boolean | 是否为触发法术 |
| `trigger_type` | string | 触发类型 |
| `trigger_draw_count` | number | 触发抽取数量 |
| `trigger_param` | any | 触发参数 |

### `proj_modifier` - 投射物修饰符列表

存储当前施法块累积的修饰符，在投射物生成时应用。

### `current_reload_time` - 当前施法充能时间

全局变量，用于累积充能时间修改。

### `actions` - 法术定义表

包含所有法术定义的全局数组，索引由 `TBoN.Render.Table.actions_map` 映射。

---

## 常用数据表

### `TBoN.Magic.Table.magic_hash`

投射物实体的属性存储表，以 `GetPtrHash(entity)` 为键。

```lua
magic_hash[hash] = {
    damages = {
        damage = number,
        damage_critical_chance = number,
        damage_projectile_add = number,
    },
    modifiers = {},
    -- ...其他属性
}
```

### `TBoN.Magic.Table.trigger_data`

触发法术数据存储表。

```lua
trigger_data[hash] = {
    entity = Entity,
    trigger_type = number,
    spell_queue = {},
    trigger_param = any,
    triggered = boolean,
    init_frame = number,
}
```

### `TBoN.Gun.Table.gun_info`

法杖信息表 (1-4索引)。

### `TBoN.Gun.Table.gun_magic_data`

法杖法术槽数据表 (1-4索引，每个包含容量数量的槽位)。

### `TBoN.Gun.Table.gun_states`

法杖状态表 (1-4索引)。

### `TBoN.World.Table.UnlockedSpells`

已解锁法术表，键为法术ID，值为 `true`。
