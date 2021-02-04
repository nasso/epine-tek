local array = {}

function array.append(dst, src)
    for _, v in ipairs(src) do
        dst[#dst + 1] = v
    end
end

function array.flatten_into(dst, t)
    for _, v in ipairs(t) do
        if type(v) == "table" then
            array.flatten_into(dst, v)
        else
            dst[#dst + 1] = v
        end
    end
end

function array.flatten(t)
    local flat = {}

    array.flatten_into(flat, t)

    return flat
end

function array.map(t, fn)
    local map = {}

    for _, v in ipairs(t) do
        map[#map + 1] = fn(v)
    end

    return map
end

function array.flatmap(t, fn)
    return array.map(array.flatten(t), fn)
end

return array
