-- CallbackHandler.lua
local CallbackHandler = {}
local registeredCallbacks = {}

local DEBUG = true

local function log(...)
    if DEBUG then
        print("[CallbackHandler]", ...)
    end
end

function CallbackHandler.registerFile(filePath)
    log("Attempting to register callbacks from:", filePath)
    
    if not love.filesystem.getInfo(filePath) then
        log("ERROR: File not found:", filePath)
        return false, "File not found: " .. filePath
    end
    
    local content = love.filesystem.read(filePath)
    if not content then
        log("ERROR: Failed to read file:", filePath)
        return false, "Failed to read file"
    end
    
    -- Clear existing callbacks before registering new ones
    registeredCallbacks = {}
    
    local env = setmetatable({}, {__index = _G})
    local chunk, err = load(content, filePath, "t", env)
    
    if not chunk then
        log("ERROR: Failed to load callback file:", err)
        return false, err
    end
    
    local success, result = pcall(chunk)
    if not success then
        log("ERROR: Failed to execute callback file:", result)
        return false, result
    end
    
    if type(result) ~= "table" then
        log("ERROR: Callback file must return a table of functions")
        return false, "Invalid callback file format"
    end
    
    -- Print all available callbacks for debugging
    log("Available callbacks in file:")
    for name, _ in pairs(result) do
        log("  -", name)
    end
    
    local count = 0
    for name, func in pairs(result) do
        if type(func) == "function" then
            log("Registered callback:", name)
            registeredCallbacks[name] = func
            count = count + 1
        else
            log("WARNING: Skipping invalid callback:", name, "- not a function")
        end
    end
    
    -- Print all registered callbacks for verification
    log("Currently registered callbacks:")
    for name, _ in pairs(registeredCallbacks) do
        log("  -", name)
    end
    
    log("Successfully registered", count, "callbacks")
    return true, count
end

function CallbackHandler.getCallback(name)
    log("Getting callback:", name)
    
    local callback = registeredCallbacks[name]
    if not callback then
        log("WARNING: Callback not found:", name)
        return nil, "Callback not found: " .. name
    end
    
    log("Successfully retrieved callback:", name)
    return callback
end

function CallbackHandler.executeCallback(name, ...)
    log("Executing callback:", name)
    
    local callback = CallbackHandler.getCallback(name)
    if not callback then
        return false, "Callback not found: " .. name
    end
    
    local success, result = pcall(callback, ...)
    if not success then
        log("ERROR: Failed to execute callback:", name, "-", result)
        return false, result
    end
    
    log("Successfully executed callback:", name)
    return true, result
end

function CallbackHandler.listCallbacks()
    local callbacks = {}
    for name, _ in pairs(registeredCallbacks) do
        table.insert(callbacks, name)
    end
    return callbacks
end

function CallbackHandler.clear()
    log("Clearing all callbacks")
    registeredCallbacks = {}
end

return CallbackHandler