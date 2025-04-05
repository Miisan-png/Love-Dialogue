local FontManager = {
    loadedFonts = {},
    fontRegistry = {}
}

function FontManager.registerFont(name, path)
    if not name or not path then
        error("Font registration requires name and path")
    end
    FontManager.fontRegistry[name] = path
    print(string.format('[FontManager] 注册字体: "%s" -> %s', name, path))
end

-- 修改后的getFont方法

function FontManager.getFont(name, size)
    local cacheKey = name .. "_" .. tostring(size)
    print(string.format("[FontManager] 请求字体: %s 尺寸: %d", name, size))

    if not FontManager.loadedFonts[cacheKey] then
        local path = FontManager.fontRegistry[name]
        if not path then
            -- 未注册时，直接生成Love2D默认字体
            print(string.format('[FontManager] 字体 "%s" 未注册，使用Love2D默认字体', name))
            local success, font = pcall(love.graphics.newFont, size)
            if not success then
                error(string.format('加载Love2D默认字体失败: %s', font))
            end
            FontManager.loadedFonts[cacheKey] = font
            return font
        end

        -- 新增路径二次验证
        if not love.filesystem.getInfo(path) then
            error(string.format('注册的字体路径无效: "%s" -> %s', name, path))
        end

        print(string.format("[FontManager] 正在加载字体: %s -> %s", name, path))
        local success, font = pcall(love.graphics.newFont, path, size)
        if not success then
            error(string.format('字体加载失败: "%s"\nLOVE2D错误: %s', name, font))
        end

        FontManager.loadedFonts[cacheKey] = font
    end
    return FontManager.loadedFonts[cacheKey]
end

function FontManager.clearCache()
    FontManager.loadedFonts = {}
end

function FontManager.getFontSafe(name, size)
    local ok, font = pcall(FontManager.getFont, name, size)
    return ok and font or love.graphics.newFont(size) -- 失败时强制返回默认
end

return FontManager