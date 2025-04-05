local ResourceManager = {}
local LD_PATH = (...):match('(.-)[^%.]+$')
local FontManager = require(LD_PATH .. "FontManager")

ResourceManager.resources = {
    images = {},
    fonts = {},
    quads = {},
    sounds = {},  -- For future sound support (not yet LOL)
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
-- File: ResourceManager.lua
function ResourceManager:newFont(instanceId, size, path, name)
    -- 未提供路径时，直接使用Love2D默认字体
    if not path then
        local success, defaultFont = pcall(love.graphics.newFont, size)
        if not success then
            error(string.format(
                "cannot load default font(love2d default font) (size: %d)\nerror msg: %s",
                size, defaultFont
            ))
        end
        -- 追踪资源并返回
        return self:track(instanceId, "fonts", defaultFont, name or "love_default_"..tostring(size))
    end

    -- 如果路径是已注册的字体名称，优先通过FontManager获取
    if FontManager.fontRegistry[path] then
        local fontName = path
        local font = FontManager.getFontSafe(fontName, size)
        return self:track(instanceId, "fonts", font, name or fontName.."_"..tostring(size))
    end

    -- 尝试直接加载字体文件（兼容未注册但提供有效路径的情况）
    local success, font = pcall(love.graphics.newFont, path, size)
    if success then
        -- 自动注册字体（假设路径即字体名称）
        if not FontManager.fontRegistry[path] then
            FontManager.registerFont(path, path)
            print(string.format("[ResourceManager] 自动注册字体: 名称=%s, 路径=%s", path, path))
        end
        -- 追踪资源并返回
        return self:track(instanceId, "fonts", font, name or path.."_"..tostring(size))
    else
        -- 增强错误信息
        error(string.format(
            "字体加载失败\n=> 路径: %s\n=> 大小: %d\n=> LOVE2D错误: %s",
            path, size, font
        ))
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

return ResourceManager