function TBoN.Data.Function.Custom.Deep_Copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[TBoN.Data.Function.Custom.Deep_Copy(orig_key)] = TBoN.Data.Function.Custom.Deep_Copy(orig_value)
        end
        setmetatable(copy, TBoN.Data.Function.Custom.Deep_Copy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- 将使用大数字索引的稀疏表压缩为键值对数组，避免JSON序列化大量nil
function TBoN.Data.Function.Custom.Compress_Sparse_Table(sparse_table)
    if not sparse_table or type(sparse_table) ~= 'table' then
        return {}
    end
    
    local compressed = {}
    for key, value in pairs(sparse_table) do
        -- 只保存非nil的键值对
        if value ~= nil then
            table.insert(compressed, {k = key, v = value})
        end
    end
    return compressed
end

-- 将压缩的键值对数组还原为原始的稀疏表
function TBoN.Data.Function.Custom.Decompress_Sparse_Table(compressed_table)
    if not compressed_table or type(compressed_table) ~= 'table' then
        return {}
    end
    
    local sparse = {}
    for _, pair in ipairs(compressed_table) do
        if pair.k ~= nil and pair.v ~= nil then
            sparse[pair.k] = pair.v
        end
    end
    return sparse
end
