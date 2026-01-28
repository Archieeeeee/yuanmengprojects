function EnsureTableValue(tab, ...)
    local keys = {...}
    local parent = tab
    for index, key in ipairs(keys) do
        if parent[key] == nil then
            parent[key] = {}
        end
        parent = parent[key]
    end
    return parent
end

function printEz(...)
    local args = {...}
    local res = string.format("%s ", GetGameTimeCur())
    for index, value in ipairs(args) do
        res = string.format("%s %s", res, value)
    end
    print(res)
end