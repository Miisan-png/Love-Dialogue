local function write_png(filename)
    -- Minimal PNG writer for a 16x16 white arrow with alpha
    -- This is raw byte manipulation to create a valid PNG
    -- Header
    local png = "\137\080\078\071\013\010\026\010"
    
    -- IHDR (16x16, 8bit, RGBA)
    local ihdr = "IHDR" .. string.pack(">I4I4I1I1I1I1I1", 16, 16, 8, 6, 0, 0, 0)
    -- CRC calc omitted for brevity, using dummy CRC or ignoring
    -- Actually, PNG is strict. Let's use Love2D to save it if possible?
    -- No, Love2D can only save Canvas/ImageData to file in save directory.
    -- We need to write to demo/assets/ui/ which is outside save dir if playing from source.
    
    -- EASIER WAY: Use Love2D to create ImageData and encode it, then write string to file.
    local love = require("love")
    require("love.image")
    require("love.data")
    
    local imgData = love.image.newImageData(16, 16)
    
    -- Draw Arrow
    --      .
    --     ...
    --    .....
    --   .......
    --     ...
    --     ...
    for y=0, 15 do
        for x=0, 15 do
            -- Simple down arrow shape
            local alpha = 0
            if y < 8 then
                -- Triangle top
                if x >= (7 - y) and x <= (8 + y) then alpha = 1 end
            else
                -- Stem
                if x >= 6 and x <= 9 and y < 14 then alpha = 1 end
            end
            
            if alpha > 0 then
                imgData:setPixel(x, y, 1, 1, 1, 1) -- White
            else
                imgData:setPixel(x, y, 0, 0, 0, 0) -- Transparent
            end
        end
    end
    
    local fileData = imgData:encode("png")
    local file = io.open(filename, "wb")
    file:write(fileData:getString())
    file:close()
    print("Generated " .. filename)
end

write_png("demo/assets/ui/indicator.png")