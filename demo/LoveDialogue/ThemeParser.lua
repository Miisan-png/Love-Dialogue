local ThemeParser = {}

-- Convert property names from theme file to internal object property names
local PROPERTY_MAP = {
    box_color = "boxColor",
    text_color = "textColor",
    name_color = "nameColor",
    font_size = "fontSize",
    name_font_size = "nameFontSize",
    box_height = "boxHeight",
    padding = "padding",
    typing_speed = "typingSpeed",
    fade_in = "fadeInDuration",
    fade_out = "fadeOutDuration"
}

function ThemeParser.parseColor(colorStr)
    local r, g, b, a = colorStr:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    if r and g and b and a then
        return {
            tonumber(r)/255,
            tonumber(g)/255,
            tonumber(b)/255,
            tonumber(a)/255
        }
    end
    return nil
end

function ThemeParser.parseTheme(filePath)
    local theme = {}
    local content = love.filesystem.read(filePath)
    if not content then return nil end

    local isThemeSection = false
    
    for line in content:gmatch("[^\r\n]+") do
        if line:match("^%[theme%]") then
            isThemeSection = true
        elseif line:match("^%[") then
            isThemeSection = false
        elseif isThemeSection then
            local property, value = line:match("^%s*([%w_]+)%s*:%s*(.+)%s*$")
            if property and value then
                local mappedProperty = PROPERTY_MAP[property] or property
                if property:match("color$") then
                    theme[mappedProperty] = ThemeParser.parseColor(value)
                else
                    theme[mappedProperty] = tonumber(value)
                end
            end
        end
    end
    
    return theme
end

function ThemeParser.applyTheme(dialogue, theme)
    for themeKey, dialogueKey in pairs(PROPERTY_MAP) do
        local value = theme[dialogueKey]
        if value then
            if themeKey == "font_size" then
                dialogue.font = love.graphics.newFont(value)
            elseif themeKey == "name_font_size" then
                dialogue.nameFont = love.graphics.newFont(value)
            else
                dialogue[dialogueKey] = value
            end
        end
    end
end

return ThemeParser