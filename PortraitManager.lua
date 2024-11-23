local PortraitManager = {}

local portraits = {}

function PortraitManager.loadPortrait(character, imagePath)
    if not love.filesystem.getInfo(imagePath) then
        print("Warning: Portrait image not found: " .. imagePath)
        return false
    end

    -- Load the image
    local success, image = pcall(love.graphics.newImage, imagePath)
    if not success then
        print("Error loading portrait: " .. imagePath)
        return false
    end

    -- Store the portrait data
    portraits[character] = {
        image = image,
        path = imagePath
    }
    
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

function PortraitManager.clear()
    portraits = {}
end

return PortraitManager