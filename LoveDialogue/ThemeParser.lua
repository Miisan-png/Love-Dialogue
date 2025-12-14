local ThemeParser = {}

local PROPERTY_MAP = {
    box_color = "boxColor",
    text_color = "textColor",
    name_color = "nameColor",
    font_size = "fontSize",
    name_font_size = "nameFontSize",
    box_height = "boxHeight",
    padding = "padding",
    nine_patch_scale = "ninePatchScale",
    typing_speed = "typingSpeed",
    fade_in = "fadeInDuration",
    fade_out = "fadeOutDuration"
}

function ThemeParser.parseColor(str)
    local r, g, b, a = str:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    return r and {tonumber(r)/255, tonumber(g)/255, tonumber(b)/255, tonumber(a)/255} or nil
end

function ThemeParser.parseTheme(path)
    local theme, section = {}, nil
    local content = love.filesystem.read(path)
    if not content then return nil end

    for line in content:gmatch("[^\r\n]+") do
        if line:match("^%[theme%]") then section = "theme"
        elseif line:match("^%[") then section = nil
        elseif section == "theme" then
            local k, v = line:match("^%s*([%w_]+)%s*:%s*(.+)%s*$")
            if k and v then
                local mapK = PROPERTY_MAP[k] or k
                theme[mapK] = k:match("color$") and ThemeParser.parseColor(v) or tonumber(v)
            end
        end
    end
    return theme
end

function ThemeParser.applyTheme(dialogue, theme)
    for k, v in pairs(theme) do
        if dialogue.config[k] ~= nil then dialogue.config[k] = v end
    end
    if theme.fontSize or theme.nameFontSize or theme.boxHeight or theme.padding then
        if dialogue.adjustLayout then dialogue:adjustLayout() end
    end
end

return ThemeParser