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
    self.sheet = nil
    return self
end

-- Define a spritesheet for this character
-- @param path: Path to the spritesheet image
-- @param frameW: Width of a single frame
-- @param frameH: Height of a single frame
function LoveCharacter:defineSheet(path, frameW, frameH)
    if not self.instanceId then return false end
    
    local img = ResourceManager:getImage(self.instanceId, path)
    if not img then return false end
    
    self.sheet = {
        texture = img,
        frameW = frameW,
        frameH = frameH,
        cols = math.floor(img:getWidth() / frameW),
        rows = math.floor(img:getHeight() / frameH)
    }
    return true
end

-- Add an expression using a frame index from the sheet
-- @param name: Name of the expression (e.g., "Happy")
-- @param index: 1-based index of the frame
function LoveCharacter:addFrame(name, index)
    if not self.sheet then
        print("Error: Cannot add frame, no sheet defined for " .. self.name)
        return false
    end
    
    local s = self.sheet
    local col = (index - 1) % s.cols
    local row = math.floor((index - 1) / s.cols)
    
    local quad = ResourceManager:getQuad(
        self.instanceId, 
        col * s.frameW, row * s.frameH, 
        s.frameW, s.frameH, 
        s.texture:getWidth(), s.texture:getHeight(), 
        self.name .. "_frame_" .. index
    )
    
    self.expressions[name] = {
        quad = quad,
        texture = s.texture,
        w = s.frameW, 
        h = s.frameH,
        sx = 1, sy = 1 -- Scales are calculated at draw time based on target size
    }
    
    if name == "Default" or not self.expressions.Default then 
        self.expressions.Default = self.expressions[name] 
    end
    
    return true
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
    
    -- Calculate scale to fit target w/h
    -- If w > 10 (arbitrary threshold), treat as pixels. Else treat as scale factor.
    local sx, sy = w, h
    if w > 10 and expr.w > 0 then sx = w / expr.w end
    if h > 10 and expr.h > 0 then sy = h / expr.h end

    love.graphics.draw(expr.texture, expr.quad, x, y, 0, sx, sy)
end

function LoveCharacter:hasPortrait() return next(self.expressions) ~= nil end
function LoveCharacter:getExpression(name) return self.expressions[name] or self.expressions.Default end

return LoveCharacter