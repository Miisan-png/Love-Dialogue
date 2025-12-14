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
    self.atlas = nil
    self.voice = nil 
    self.x = 0
    self.y = 0
    self.scale = 1
    self.alpha = 1
    self.rotation = 0
    self.visible = true
    return self
end

function LoveCharacter:setVoice(path)
    if not self.instanceId then return false end
    self.voice = ResourceManager:getSound(self.instanceId, path, "static")
    return self.voice ~= nil
end

function LoveCharacter:defineSheet(path, frameW, frameH)
    if not self.instanceId then return false end
    local img = ResourceManager:getImage(self.instanceId, path)
    if not img then return false end
    self.sheet = { texture = img, frameW = frameW, frameH = frameH, cols = math.floor(img:getWidth()/frameW), rows = math.floor(img:getHeight()/frameH) }
    return true
end

function LoveCharacter:defineAtlas(path)
    if not self.instanceId then return false end
    local img = ResourceManager:getImage(self.instanceId, path)
    if not img then return false end
    self.atlas = img
    return true
end

function LoveCharacter:addFrame(name, index)
    if not self.sheet then return false end
    local s = self.sheet
    local col, row = (index - 1) % s.cols, math.floor((index - 1) / s.cols)
    local quad = ResourceManager:getQuad(self.instanceId, col * s.frameW, row * s.frameH, s.frameW, s.frameH, s.texture:getWidth(), s.texture:getHeight(), self.name .. "_frame_" .. index)
    self.expressions[name] = { quad = quad, texture = s.texture, w = s.frameW, h = s.frameH }
    if name == "Default" or not self.expressions.Default then self.expressions.Default = self.expressions[name] end
    return true
end

function LoveCharacter:addRect(name, x, y, w, h)
    local texture = self.atlas or (self.sheet and self.sheet.texture)
    if not texture then return false end
    local quad = ResourceManager:getQuad(self.instanceId, x, y, w, h, texture:getWidth(), texture:getHeight(), self.name .. "_rect_" .. name)
    self.expressions[name] = { quad = quad, texture = texture, w = w, h = h }
    if name == "Default" or not self.expressions.Default then self.expressions.Default = self.expressions[name] end
    return true
end

function LoveCharacter:loadExpression(name, path, rows, cols, index)
    if not self.instanceId then return false end
    local img = ResourceManager:getImage(self.instanceId, path)
    if not img then return false end
    local w, h = img:getDimensions()
    local qw, qh = w/cols, h/rows
    local r, c = math.floor((index - 1) / cols), (index - 1) % cols
    local quad = ResourceManager:getQuad(self.instanceId, c * qw, r * qh, qw, qh, w, h, path..index)
    self.expressions[name] = { quad = quad, texture = img, w = qw, h = qh }
    if name == "Default" or not self.expressions.Default then self.expressions.Default = self.expressions[name] end
    return true
end

function LoveCharacter:draw(exprName, x, y, w, h, flipH)
    if not self.visible then return end
    local expr = self.expressions[exprName] or self.expressions.Default
    if not expr then return end
    
    local drawX = x + self.x
    local drawY = y + self.y
    local sx, sy = w, h
    if w > 10 and expr.w > 0 then sx = w / expr.w end
    if h > 10 and expr.h > 0 then sy = h / expr.h end
    
    sx = sx * self.scale
    sy = sy * self.scale
    local ox = 0
    if flipH then sx = -sx; ox = expr.w end

    love.graphics.setColor(1, 1, 1, self.alpha)
    love.graphics.draw(expr.texture, expr.quad, drawX, drawY, self.rotation, sx, sy, ox, 0)
end

function LoveCharacter:hasPortrait() return next(self.expressions) ~= nil end
function LoveCharacter:getExpression(name) return self.expressions[name] or self.expressions.Default end

return LoveCharacter