local ResourceManager = {}
ResourceManager.fonts = ResourceManager.fonts or {}  -- 初始化字体缓存表
ResourceManager.sounds = {} -- 存储预加载的音效


ResourceManager.resources = {
    images = {},
    -- fonts = {},
    quads = {},
    -- sounds = {},  -- For future sound support (not yet LOL)
    custom = {}  
}

ResourceManager.instanceRegistry = {}

-- Add a resource to be tracked by a specific dialogue instance
-- @param instanceId string or number: unique identifier for the dialogue instance
-- @param resourceType string: type of resource ("images", "fonts", etc.)
-- @param resource userdata: the Love2D resource to track
-- @param name string (optional): a name to identify this resource
-- @return the resource for chaining
function ResourceManager:track(instanceId, resourceType, resource, name)
    if not self.instanceRegistry[instanceId] then
        self.instanceRegistry[instanceId] = {}
    end
    
    if not self.instanceRegistry[instanceId][resourceType] then
        self.instanceRegistry[instanceId][resourceType] = {}
    end
    
    table.insert(self.instanceRegistry[instanceId][resourceType], {
        resource = resource,
        name = name or "unnamed_" .. #self.instanceRegistry[instanceId][resourceType]
    })
    
    if not self.resources[resourceType] then
        self.resources[resourceType] = {}
    end
    
    self.resources[resourceType][name or resource] = resource
    
    return resource
end

-- Create and track an image
-- @param instanceId string: dialogue instance identifier
-- @param path string: path to the image file
-- @param name string (optional): name for this resource
-- @return love.Image or nil if creation failed
function ResourceManager:newImage(instanceId, path, name)
    local success, result = pcall(love.graphics.newImage, path)
    if success and result then
        return self:track(instanceId, "images", result, name or path)
    else
        print("ResourceManager: Failed to load image " .. path .. ": " .. tostring(result))
        return nil
    end
end

-- Create and track a font
-- @param instanceId string: dialogue instance identifier
-- @param size number: font size
-- @param path string (optional): path to font file
-- @param name string (optional): name for this resource
-- @return love.Font or nil if creation failed
function ResourceManager:newFont(instanceId, size, path, name)
    local success, result
    if path then
        success, result = pcall(love.graphics.newFont, path, size)
    else
        success, result = pcall(love.graphics.newFont, size)
    end
    
    if success and result then
        return self:track(instanceId, "fonts", result, name or tostring(size))
    else
        print("ResourceManager: Failed to load font: " .. tostring(result))
        return nil
    end
end

-- Create and track a quad
-- @param instanceId string: dialogue instance identifier
-- @param x, y, width, height: quad dimensions
-- @param sw, sh: texture dimensions
-- @param name string (optional): name for this quad
-- @return love.Quad or nil if creation failed
function ResourceManager:newQuad(instanceId, x, y, width, height, sw, sh, name)
    local success, result = pcall(love.graphics.newQuad, x, y, width, height, sw, sh)
    if success and result then
        return self:track(instanceId, "quads", result, name)
    else
        print("ResourceManager: Failed to create quad: " .. tostring(result))
        return nil
    end
end


function ResourceManager:releaseInstance(instanceId)
    if not self.instanceRegistry[instanceId] then
        print("ResourceManager: No resources found for instance " .. tostring(instanceId))
        return
    end
    
    for resourceType, resources in pairs(self.instanceRegistry[instanceId]) do
        for _, resourceData in ipairs(resources) do
            local resource = resourceData.resource
            local name = resourceData.name
            
            if resource.release and type(resource.release) == "function" then
                local success, err = pcall(resource.release, resource)
                if not success then
                    print("ResourceManager: Error releasing " .. resourceType .. " " .. name .. ": " .. tostring(err))
                end
            elseif resource.type and resource:type() == "Canvas" then
                if resource.release and type(resource.release) == "function" then
                    pcall(resource.release, resource)
                end
            end
            
            if self.resources[resourceType] then
                self.resources[resourceType][name] = nil
            end
        end
    end
    
    self.instanceRegistry[instanceId] = nil
    collectgarbage("collect")
end

-- Get a resource by name
-- @param resourceType string: type of resource ("images", "fonts", etc.)
-- @param name string: name of the resource
-- @return resource or nil if not found
function ResourceManager:get(resourceType, name)
    if self.resources[resourceType] and self.resources[resourceType][name] then
        return self.resources[resourceType][name]
    end
    return nil
end
function ResourceManager:releaseAll()
    for instanceId, _ in pairs(self.instanceRegistry) do
        self:releaseInstance(instanceId)
    end
    for resourceType, _ in pairs(self.resources) do
        self.resources[resourceType] = {}
    end
end

function ResourceManager:loadFonts(instanceId, directory)
    local files = love.filesystem.getDirectoryItems(directory)
    for _, file in ipairs(files) do
        if file:match("%.ttf$") then
            local fullPath = directory .. "/" .. file
            local font = self:newFont(instanceId, 12, fullPath, file)
            if font then
                self.fonts[file] = font
                print("Loaded font: " .. file .. " at " .. fullPath)
            else
                print("Warning: Failed to load font: " .. fullPath)
            end
        end
    end
end

-- function ResourceManager:newSound(instanceId, path, name, sourceType)
--     sourceType = sourceType or "static"
--     local success, result = pcall(love.audio.newSource, path, sourceType)
--     if success and result then
--         return self:track(instanceId, "sounds", result, name or path)
--     else
--         print("ResourceManager: Failed to load sound: " .. tostring(result))
--         return nil
--     end
-- end

function ResourceManager:newSound(instanceId, path, name)
    local success, result = pcall(love.audio.newSource, path, "static")
    if success and result then
        return self:track(instanceId, "sounds", result, name or path)
    else
        print("ResourceManager: Failed to load sound " .. path .. ": " .. tostring(result))
        return nil
    end
end

function ResourceManager:loadSounds(instanceId, directory)
    local files = love.filesystem.getDirectoryItems(directory)
    for _, file in ipairs(files) do
        if file:match("%.wav$") or file:match("%.mp3$") or file:match("%.ogg$") then
            local fullPath = directory .. "/" .. file
            local sound = self:newSound(instanceId, fullPath, file)
            if sound then
                self.sounds[file] = sound
            else
                print("Warning: Failed to load sound: " .. fullPath)
            end
        end
    end
end

return ResourceManager