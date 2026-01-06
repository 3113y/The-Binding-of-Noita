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
