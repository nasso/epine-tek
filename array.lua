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

function array.unmap(t, fn)
    local arr = {}

    for k, v in pairs(t) do
        arr[#arr + 1] = fn(k, v)
    end

    return arr
end

function array.mapf(t, f, ...)
    local map =
        array.map(
        t,
        function(v)
            return v[f]
        end
    )

    if ... then
        return array.mapf(map, ...)
    else
        return map
    end
end

function array.find(t, fn)
    for _, v in ipairs(t) do
        if fn(v) then
            return v
        end
    end

    return nil
end

function array.uniques(t)
    local uniques = {}
    local set = {}

    for _, v in ipairs(t) do
        if not set[v] then
            uniques[#uniques + 1] = v
            set[v] = true
        end
    end

    return uniques
end

return array
