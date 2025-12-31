TBoN.Magic.Table.magic_hash =  {}

-- 背包法术数据表，存储法术ID和使用次数
TBoN.Magic.Table.bag_magic_data = {
    {magic_id = "PROPANE_TANK", current_uses = -1, max_uses = -1},
    {magic_id = "GRENADE_TIER_2", current_uses = -1, max_uses = -1},
    {magic_id = "GRENADE_TIER_3", current_uses = -1, max_uses = -1},
    {magic_id = "SPITTER", current_uses = -1, max_uses = -1},
    {magic_id = "SPITTER_TIER_2", current_uses = -1, max_uses = -1},
    {magic_id = "SPITTER_TIER_3", current_uses = -1, max_uses = -1},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0},
    {magic_id = false, current_uses = 0, max_uses = 0}
}

--[[max_uses怎么写?
要有一个表存储每个法术的使用次数
抽取法术时检测当前剩余的使用次数,每次减一.但是当同时拥有多个相同法术时,要区分开来,而且不能用实体哈希值实现.
如果在TBoN.UI.Table.magic和TBoN.Gun.Table.gun_magic里存储使用次数,会导致UI和枪械数据混乱吗?不会吧?
法术ID不行,因为可能会有多个相同ID的法术.,所以要用上述表存储每个法术实体的使用次数.
所以现在为了方便后续操作,要先将TBoN.UI.Table.magic中sprite,pos和magic解耦,magic存到TBoN.Magic.Table.bag_magic_data里.
然后将TBoN.UI.Table.magic重命名为TBoN.UI.Table.bag_magic_render_table,只存储sprite和pos.
这样就能通过TBoN.Magic.Table.bag_magic_data来存储背包每个法术实体的使用次数了,然后再在TBoN.Gun.Table.gun_magic_data中也加上法术使用次数.
然后在抽取法术时检测使用次数,如果为0则不能抽取.
另外,在法术被移除时,要清理TBoN.Magic.Table.bag_magic_data和TBoN.Gun.Table.gun_magic_data中的对应数据.
还有,要修改UI渲染函数,让其从TBoN.Magic.Table.bag_magic_data中获取法术数据进行渲染.
还有法术交换时,要交换TBoN.Magic.Table.bag_magic_data中的数据.要修改对应的函数.]]