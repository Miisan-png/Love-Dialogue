local Logic = {}

function Logic.evaluate(condition, variables)
    if not condition or condition == "" then return true end
    local env = setmetatable({}, { __index = variables })
    local chunk, err = load("return " .. condition, "logic_eval", "t", env)
    if not chunk then
        print("Logic Error in condition [" .. condition .. "]: " .. tostring(err))
        return false
    end
    local success, result = pcall(chunk)
    if not success then
        print("Logic Runtime Error [" .. condition .. "]: " .. tostring(result))
        return false
    end
    return result
end

function Logic.execute(statement, variables)
    if not statement or statement == "" then return end
    local env = setmetatable({}, { __index = variables, __newindex = variables })
    local chunk, err = load(statement, "logic_exec", "t", env)
    if not chunk then
        print("Logic Error in statement [" .. statement .. "]: " .. tostring(err))
        return
    end
    local success, res = pcall(chunk)
    if not success then print("Logic Runtime Error [" .. statement .. "]: " .. tostring(res)) end
end

function Logic.interpolate(text, variables)
    if not text:find("${") then return text end
    return text:gsub("${(.-)}", function(varName)
        varName = varName:match("^%s*(.-)%s*$")
        local val = variables[varName]
        if val == nil then return "nil" end
        return tostring(val)
    end)
end

return Logic