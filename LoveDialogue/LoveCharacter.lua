---@class Expression
---@field public quad love.Quad
---@field public texture love.Image

---@class LD_Character
---@field public name string
---@field public color table
---@field public nameColor table
---@field public expressions table<string, Expression>
---@field public instanceId string|nil Owner dialogue instance for resource tracking
---@field public defaultExpression string
---@field public nameFont love.Font|nil
local LD_Character = {}
LD_Character.__index = LD_Character

local LD_PATH = (...):match('(.-)[^%.]+$')
local ResourceManager = require(LD_PATH .. "ResourceManager")

-- Constructor for LD_Character
-- @param name string
-- @param defaultExpression Expression or nil
-- @param instanceId string or nil: The ID of the dialogue instance that owns this character
-- @return LD_Character
function LD_Character.new(name, defaultExpression, instanceId)
    local self = setmetatable({}, LD_Character)
    self.name = name or ""
    self.color = {r = 1, g = 1, b = 1, a = 1}           -- Default white
    self.nameColor = {r = 1, g = 0.8, b = 0.2, a = 1}   -- Default name color
    self.expressions = {}
    self.defaultExpression = "Default"
    self.nameFont = nil                  -- New: character name font
    self.instanceId = instanceId         -- Track the owner for resource management
    
    if defaultExpression then
        self.expressions["Default"] = defaultExpression
    end
    
    return self
end

-- Weird workaround to get the number of rows and columns from a quad
local function getRowsAndColsFromQuad(quad, texture)
    local imageWidth = texture:getWidth()
    local imageHeight = texture:getHeight()
    local _,_,quadWidth, quadHeight = quad:getViewport()
    return imageWidth / quadWidth, imageHeight / quadHeight
end

function LD_Character:draw(expressionName, posX, posY, sizeX, sizeY)
    local expression = self:getExpression(expressionName)
    if not expression then return end
    
    local rows, cols = getRowsAndColsFromQuad(expression.quad, expression.texture)
    love.graphics.draw(expression.texture, expression.quad, posX, posY, 0, sizeX * rows, sizeY * cols)
end

function LD_Character:getExpression(name)
    return self.expressions[name] or self.expressions[self.defaultExpression]
end

-- Check if the character has a portrait
-- @return boolean
function LD_Character:hasPortrait()
    return next(self.expressions) ~= nil
end

-- Add an expression to the character
-- @param name string
-- @param expression Expression
function LD_Character:addExpression(name, expression)
    self.expressions[name] = expression
end

-- Load an expression from a path
-- @param name string
-- @param path string
-- @param rows number
-- @param cols number
-- @param index number
-- @return boolean
function LD_Character:loadExpression(name, path, rows, cols, index)
    if not self.instanceId then
        print("Warning: Cannot load expression without an instance ID")
        return false
    end
    
    -- Use ResourceManager to load the image
    local image = ResourceManager:newImage(
        self.instanceId, 
        path, 
        "char_" .. self.name .. "_expr_" .. name
    )
    
    if not image then
        return false
    end
    
    local imageWidth = image:getWidth()
    local imageHeight = image:getHeight()
    local quadWidth = imageWidth / cols
    local quadHeight = imageHeight / rows
    
    -- Calculate position based on index
    local row = math.floor((index - 1) / cols)
    local col = (index - 1) % cols
    
    -- Create the quad using ResourceManager
    local quad = ResourceManager:newQuad(
        self.instanceId,
        col * quadWidth, row * quadHeight, 
        quadWidth, quadHeight,
        imageWidth, imageHeight,
        "char_" .. self.name .. "_quad_" .. name
    )
    
    if not quad then
        return false
    end
    
    -- Add the expression
    self:addExpression(name, {
        quad = quad,
        texture = image
    })
    
    return true
end

-- Set the default expression for the character
-- @param expression Expression
function LD_Character:setDefaultExpression(expression)
    self.expressions["Default"] = expression
end

-- Clear all expressions (useful for cleanupp)
function LD_Character:clearExpressions()
    self.expressions = {}
end

-- Set the owning dialogue instance
-- @param instanceId string
function LD_Character:setInstanceId(instanceId)
    self.instanceId = instanceId
end

-- Set the name font for the character
-- @param font love.Font
function LD_Character:setNameFont(font)
    self.nameFont = font
end

-- Get the name font for the character
-- @return love.Font|nil
function LD_Character:getNameFont()
    return self.nameFont
end

return LD_Character