local DebugConsole = {}
local socket = require("socket.core")
--  Helper file to connect to the python console
local udp

function DebugConsole.init()
    udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername("127.0.0.1", 12345)
    print("Debug Console Initialized")
end

local originalPrint = print
_G.print = function(...)
    local args = {...}
    local message = ""
    for i, v in ipairs(args) do
        message = message .. tostring(v) .. "\t"
    end
    
    -- Send to Python console
    if udp then
        pcall(function()
            udp:send(message)
        end)
    end
    
    originalPrint(...)
end


return DebugConsole