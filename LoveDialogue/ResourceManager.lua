local ResourceManager = {}
local resources = {
    cache = {}, 
    owners = {} 
}

local function getCacheKey(type, uniqueKey, ...)
    local args = {...}
    local safeArgs = {}
    for i, v in ipairs(args) do
        table.insert(safeArgs, tostring(v))
    end
    return string.format("%s:%s:%s", type, tostring(uniqueKey), table.concat(safeArgs, ":"))
end

function ResourceManager:get(instanceId, type, uniqueKey, loader, ...)
    local key = getCacheKey(type, uniqueKey, ...)
    if not resources.cache[key] then
        local success, asset = pcall(loader, ...)
        if not success or not asset then
            print(string.format("ResourceManager: Failed to load %s (%s)", type, tostring(uniqueKey)))
            return nil
        end
        resources.cache[key] = { asset = asset, refCount = 0 }
    end

    local entry = resources.cache[key]
    if entry.asset.type and entry.asset:type() == "Image" and entry.asset.isReleased and entry.asset:isReleased() then
        local success, asset = pcall(loader, ...)
        if success and asset then entry.asset = asset end
    end

    if not resources.owners[instanceId] then resources.owners[instanceId] = {} end
    if not resources.owners[instanceId][key] then
        resources.owners[instanceId][key] = true
        entry.refCount = entry.refCount + 1
    end
    return entry.asset
end

function ResourceManager:getImage(id, path)
    return self:get(id, "image", path, love.graphics.newImage, path)
end

function ResourceManager:getFont(id, size, path, name)
    local loader = function(p, s) 
        if p and p ~= "default" and love.filesystem.getInfo(p) then return love.graphics.newFont(p, s)
        else return love.graphics.newFont(s) end
    end
    return self:get(id, "font", (path or "default")..size, loader, path, size)
end

function ResourceManager:getQuad(id, x, y, w, h, sw, sh, name)
    return self:get(id, "quad", name or string.format("%d_%d_%d_%d", x, y, w, h), love.graphics.newQuad, x, y, w, h, sw, sh)
end

function ResourceManager:getSound(id, path, type)
    type = type or "static"
    return self:get(id, "sound", path, love.audio.newSource, path, type)
end

function ResourceManager:registerManual(id, type, uniqueKey, asset, ...)
    local key = getCacheKey(type, uniqueKey, ...)
    if not resources.cache[key] then resources.cache[key] = { asset = asset, refCount = 1 } end
    if id then
        if not resources.owners[id] then resources.owners[id] = {} end
        if not resources.owners[id][key] then
            resources.owners[id][key] = true
            resources.cache[key].refCount = resources.cache[key].refCount + 1
        end
    end
end

function ResourceManager:releaseInstance(id)
    if not resources.owners[id] then return end
    for key in pairs(resources.owners[id]) do
        local entry = resources.cache[key]
        if entry then
            entry.refCount = entry.refCount - 1
            if entry.refCount <= 0 then
                if entry.asset.release then pcall(entry.asset.release, entry.asset) end
                resources.cache[key] = nil
            end
        end
    end
    resources.owners[id] = nil
    collectgarbage("collect")
end

function ResourceManager:cleanup()
    for id in pairs(resources.owners) do self:releaseInstance(id) end
end

function ResourceManager:releaseAll()
    self:cleanup()
end

return ResourceManager