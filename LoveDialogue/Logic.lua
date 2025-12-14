local Logic = {}

-- Safely evaluate a condition string (e.g. "gold > 10")
-- returns: boolean
function Logic.evaluate(condition, variables)
    if not condition or condition == "" then return true end
    
    -- Create a sandbox environment with the variables
    -- We use a metatable to allow direct variable access
    local env = setmetatable({}, {
        __index = variables
    })
    
    -- Prepend "return " to make it an expression
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

-- Execute a statement string (e.g. "gold = gold + 1")
-- updates the variables table
function Logic.execute(statement, variables)
    if not statement or statement == "" then return end
    
    -- Creating a sandbox that writes back to the variables table
    local env = setmetatable({}, {
        __index = variables,
        __newindex = variables
    })
    
    local chunk, err = load(statement, "logic_exec", "t", env)
    
    if not chunk then
        print("Logic Error in statement [" .. statement .. "]: " .. tostring(err))
        return
    end
    
    local success, res = pcall(chunk)
    if not success then
         print("Logic Runtime Error [" .. statement .. "]: " .. tostring(res))
    end
end

-- Interpolate variables into string (e.g. "Hello ${name}!")
function Logic.interpolate(text, variables)
    if not text:find("${") then return text end
    
    return text:gsub("${(.-)}", function(varName)
        -- Trim whitespace
        varName = varName:match("^%s*(.-)%s*$")
        local val = variables[varName]
        if val == nil then return "nil" end
        return tostring(val)
    end)
end

return Logic