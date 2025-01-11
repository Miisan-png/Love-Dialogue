-- callbacks.lua
-- Callback example to be registered in the main.lua --
local callbacks = {}

callbacks.show_square = function()
    _G.square = {
        x = 100,
        y = 100,
        size = 50,
        visible = true
    }
    print("[Callback] Square created and made visible")
    return true
end

callbacks.hide_square = function()
    if _G.square then
        _G.square.visible = false
        print("[Callback] Square hidden")
    end
    return true
end

callbacks.move_square = function()
    if _G.square then
        _G.square.x = _G.square.x + 50
        _G.square.y = _G.square.y + 50
        print("[Callback] Square moved")
    end
    return true
end

return callbacks