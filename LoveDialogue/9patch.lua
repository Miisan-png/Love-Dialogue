local lib = {}

function lib.load(filename, arg1, arg2, arg3, arg4)
	local image = love.graphics.newImage(filename)

	if arg3 == nil and arg4 == nil then
		return lib.loadSameEdge(image, arg1, arg2)
	end

	return lib.loadDiffrntEdge(image, arg1, arg2, arg3, arg4)
end

function lib.loadDiffrntEdge(image, left, right, top, bottom)
	local imageW, imageH = image:getDimensions()

	local quad1 = love.graphics.newQuad(0,              0, left,                 top, image)
	local quad2 = love.graphics.newQuad(left,           0, imageW - (right * 2), top, image)
	local quad3 = love.graphics.newQuad(imageW - right, 0, right,                top, image)

	local quad4 = love.graphics.newQuad(0,              top, left,                 imageH - (bottom * 2), image)
	local quad5 = love.graphics.newQuad(left,           top, imageW - (right * 2), imageH - (bottom * 2), image)
	local quad6 = love.graphics.newQuad(imageW - right, top, right,                imageH - (bottom * 2), image)

	local quad7 = love.graphics.newQuad(0,              imageH - bottom, left,                 bottom, image)
	local quad8 = love.graphics.newQuad(left,           imageH - bottom, imageW - (right * 2), bottom, image)
	local quad9 = love.graphics.newQuad(imageW - right, imageH - bottom, right,                bottom, image)
	
	local quadPatch = {
		width = imageW,
		height = imageH,
		left = left,
		right = right,
		top = top,
		bottom = bottom,
		quads = {quad1, quad2, quad3, quad4, quad5, quad6, quad7, quad8, quad9},
		image = image,
	}
	return quadPatch
end

function lib.loadSameEdge(image, edgeW, edgeH)
	local imageW, imageH = image:getDimensions()
	local middleW = imageW - 2 * edgeW
	local middleH = imageH - 2 * edgeH
	
	local quad1 = love.graphics.newQuad(0, 0, edgeW, edgeH, image)
	local quad2 = love.graphics.newQuad(edgeW, 0, middleW, edgeH, image)
	local quad3 = love.graphics.newQuad(edgeW + middleW, 0, edgeW, edgeH, image)
	
	local quad4 = love.graphics.newQuad(0, edgeH, edgeW, middleH, image)
	local quad5 = love.graphics.newQuad(edgeW, edgeH, middleW, middleH, image)
	local quad6 = love.graphics.newQuad(edgeW + middleW, edgeH, edgeW, middleH, image)
	
	local quad7 = love.graphics.newQuad(0, edgeH + middleH, edgeW, edgeH, image)
	local quad8 = love.graphics.newQuad(edgeW, edgeH + middleH, middleW, edgeH, image)
	local quad9 = love.graphics.newQuad(edgeW + middleW, edgeH + middleH, edgeW, edgeH, image)
	
	local quadPatch = {
		width = imageW,
		height = imageH,
		left = edgeW,
		right = edgeW,
		top = edgeH,
		bottom = edgeH,
		quads = {quad1, quad2, quad3, quad4, quad5, quad6, quad7, quad8, quad9},
		image = image,
	}
	return quadPatch
end

function lib.draw(patch, x, y, width, height, scale)
    scale = scale or 1
	local imageW, imageH = patch.width, patch.height

    local sLeft = patch.left * scale
    local sRight = patch.right * scale
    local sTop = patch.top * scale
    local sBottom = patch.bottom * scale

	local middleScaleX = (width - sLeft - sRight) / (imageW - patch.left - patch.right)
	local middleScaleY = (height - sTop - sBottom) / (imageH - patch.top - patch.bottom)

	local x2 = x + sLeft
	local x3 = x + width - sRight

	local y2 = y + sTop
	local y3 = y + height - sBottom

    -- Top Row
	love.graphics.draw(patch.image, patch.quads[1], x, y, 0, scale, scale)
	love.graphics.draw(patch.image, patch.quads[2], x2, y, 0, middleScaleX, scale)
	love.graphics.draw(patch.image, patch.quads[3], x3, y, 0, scale, scale)

    -- Middle Row
	love.graphics.draw(patch.image, patch.quads[4], x, y2, 0, scale, middleScaleY)
	love.graphics.draw(patch.image, patch.quads[5], x2, y2, 0, middleScaleX, middleScaleY)
	love.graphics.draw(patch.image, patch.quads[6], x3, y2, 0, scale, middleScaleY)

    -- Bottom Row
	love.graphics.draw(patch.image, patch.quads[7], x, y3, 0, scale, scale)
	love.graphics.draw(patch.image, patch.quads[8], x2, y3, 0, middleScaleX, scale)
	love.graphics.draw(patch.image, patch.quads[9], x3, y3, 0, scale, scale)
end

return lib