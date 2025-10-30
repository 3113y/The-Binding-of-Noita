import os
import re
from PIL import Image

# 路径配置
actions_lua_path = "scripts/guns/gun_actions.lua"
spell_img_dir = "resources/gfx/ui/gun_actions/gun_actions"
bg_img_dir = "resources/gfx/ui/inventory/inventory"
output_dir = "resources/gfx/ui/sp"
os.makedirs(output_dir, exist_ok=True)

# 解析actions表
with open(actions_lua_path, encoding="utf-8") as f:
    lua = f.read()

# 匹配法术id和type
pattern = re.compile(r'id\s*=\s*"([^"]+)"[^\n]*\n.*?type\s*=\s*"([^"]+)"', re.DOTALL)
spells = pattern.findall(lua)

# type到背景图片名的映射
type_bg_map = {
    "ACTION_TYPE_PROJECTILE": "item_bg_projectile.png",
    "ACTION_TYPE_STATIC_PROJECTILE": "item_bg_static_projectile.png",
    "ACTION_TYPE_MODIFIER": "item_bg_modifier.png",
    "ACTION_TYPE_DRAW_MANY": "item_bg_draw_many.png",
    "ACTION_TYPE_MATERIAL": "item_bg_material.png",
    "ACTION_TYPE_OTHER": "item_bg_other.png",
    "ACTION_TYPE_UTILITY": "item_bg_utility.png",
    "ACTION_TYPE_PASSIVE": "item_bg_passive.png"
}

for spell_id, spell_type in spells:
    spell_img_path = os.path.join(spell_img_dir, f"{spell_id.lower()}.png")
    bg_img_name = type_bg_map.get(spell_type)
    bg_img_path = os.path.join(bg_img_dir, bg_img_name) if bg_img_name else None

    if not os.path.exists(spell_img_path) or not bg_img_path or not os.path.exists(bg_img_path):
        print(f"跳过: {spell_id} ({spell_type})")
        continue

    # 合成图片
    bg = Image.open(bg_img_path).convert("RGBA")
    spell = Image.open(spell_img_path).convert("RGBA")
    # 居中叠加
    x = (bg.width - spell.width) // 2
    y = (bg.height - spell.height) // 2
    bg.paste(spell, (x, y), spell)
    out_path = os.path.join(output_dir, f"{spell_id.lower()}.png")
    bg.save(out_path)
    print(f"生成: {out_path}")

print("全部完成！")