do
  local auto, assign

  function auto(tab, key)
    if getmetatable(tab).dim > 1 then
      return setmetatable({}, {
        __index = auto,
        __newindex = assign,
        dim = getmetatable(tab).dim - 1,
        parent = tab,
        key = key
      })
    else
      return nil
    end
  end

  function assign(tab, key, val)
    if val ~= nil then
      local oldmt = getmetatable(tab)
      local dim = oldmt.dim
      oldmt.parent[oldmt.key] = tab
      setmetatable(tab, {__index = auto, dim = dim})
      tab[key] = val
    end
  end

  function table.autotable(dim)
    return setmetatable({}, {__index = auto, dim = dim})
  end
end

--[[
m = table.autotable(2)
m[1][2] = 'x'
m[3][4] = 'y'
assert(m[1][2] == 'x')
assert(type(m[2]) == 'table')
assert(type(m[2][3]) == 'nil')
assert(type(auto) == 'nil')
assert(type(assign) == 'nil')
for i,inner in pairs(m) do
  for j,v in pairs(inner) do
    print(i, j, v)
  end
end
--]]
