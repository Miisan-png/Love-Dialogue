local MODULE_PATH = (...):match('(.-)[^%.]+$')
local ResourceManager = require(MODULE_PATH .. "ResourceManager")

local LoveCharacter = {}
LoveCharacter.__index = LoveCharacter

function LoveCharacter.new(name, instanceId)
    local self = setmetatable({}, LoveCharacter)
    self.name = name or ""
    self.instanceId = instanceId
    self.color = {1, 1, 1}
    self.nameColor = {1, 0.8, 0.2}
    self.expressions = {}
    return self
end

function LoveCharacter:loadExpression(name, path, rows, cols, index)
    if not self.instanceId then return false end
    
    local img = ResourceManager:getImage(self.instanceId, path)
    if not img then return false end
    
    local w, h = img:getDimensions()
    local qw, qh = w / cols, h / rows
    local r, c = math.floor((index - 1) / cols), (index - 1) % cols
    local quad = ResourceManager:getQuad(self.instanceId, c * qw, r * qh, qw, qh, w, h, path..index)
    
    self.expressions[name] = {
        quad = quad,
        texture = img,
        w = qw, h = qh,
        sx = w/qw, sy = h/qh 
    }
    if name == "Default" or not self.expressions.Default then self.expressions.Default = self.expressions[name] end
    return true
end

function LoveCharacter:draw(exprName, x, y, w, h)
    local expr = self.expressions[exprName] or self.expressions.Default
    if not expr then return end
    
    -- If w/h are provided as scales (small numbers), use as scale. If large, treat as target size.
    local sx, sy = w, h
    if w > 10 and expr.w > 0 then sx = w / expr.w end
    if h > 10 and expr.h > 0 then sy = h / expr.h end

    love.graphics.draw(expr.texture, expr.quad, x, y, 0, sx, sy)
end

function LoveCharacter:hasPortrait() return next(self.expressions) ~= nil end
function LoveCharacter:getExpression(name) return self.expressions[name] or self.expressions.Default end

return LoveCharacter