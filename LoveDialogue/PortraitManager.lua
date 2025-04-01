local LD_PATH = (...):match('(.-)[^%.]+$')
local ResourceManager = require(LD_PATH .. "ResourceManager")

local PortraitManager = {}

local portraits = {}
local portraitOwners = {} 

function PortraitManager.loadPortrait(character, imagePath, instanceId)
    if not love.filesystem.getInfo(imagePath) then
        print("Warning: Portrait image not found: " .. imagePath)
        return false
    end

    local image
    if instanceId then
        image = ResourceManager:newImage(instanceId, imagePath, "portrait_" .. character)
    else
        local success, result = pcall(love.graphics.newImage, imagePath)
        if not success then
            print("Error loading portrait: " .. imagePath)
            return false
        end
        image = result
    end
    
    if not image then
        return false
    end

    portraits[character] = {
        image = image,
        path = imagePath
    }
    
    if instanceId then
        portraitOwners[character] = instanceId
    end
    
    return true
end

function PortraitManager.getPortrait(character)
    if portraits[character] then
        return portraits[character].image
    end
    return nil
end

function PortraitManager.hasPortrait(character)
    return portraits[character] ~= nil
end

-- Clear all portraits or just those for a specific dialogue instance
function PortraitManager.clear(instanceId)
    if instanceId then
        -- Clear only portraits owned by this instance
        local charactersToRemove = {}
        
        for character, ownerId in pairs(portraitOwners) do
            if ownerId == instanceId then
                table.insert(charactersToRemove, character)
            end
        end
        
        for _, character in ipairs(charactersToRemove) do
            portraits[character] = nil
            portraitOwners[character] = nil
        end
    else
        -- Clear all portraits
        portraits = {}
        portraitOwners = {}
    end
end

return PortraitManager