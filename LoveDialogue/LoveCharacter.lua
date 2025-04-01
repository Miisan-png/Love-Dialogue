---@class Expression
---@field public quad love.Quad
---@field public texture love.Image

---@class LD_Character
---@field public name string
---@field public color table
---@field public nameColor table
---@field public expressions table<string, Expression>
local LD_Character = {}
LD_Character.__index = LD_Character

-- Constructor for LD_Character
-- @param name string
-- @param defaulExpression love.Quad or nil
-- @return LD_Character
function LD_Character.new(name, defaulExpression)
    local self = setmetatable({}, LD_Character)
    self.name = name or ""
    self.color = {r = love.math.random(), g = love.math.random(), b = love.math.random()}
    self.nameColor = {r = love.math.random(), g = love.math.random(), b = love.math.random()}
    self.expressions = {
        Default = defaulExpression
    }
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
    local rows, cols = getRowsAndColsFromQuad(expression.quad, expression.texture)
    love.graphics.draw(expression.texture, expression.quad, posX, posY, 0, sizeX * rows, sizeY * cols)
end

function LD_Character:getExpression(name)
    return self.expressions[name] or self.expressions.Default
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

-- Set the default expression for the character
-- @param expression Expression
function LD_Character:setDefaultExpression(expression)
    self.expressions.Default = expression
end

return LD_Character