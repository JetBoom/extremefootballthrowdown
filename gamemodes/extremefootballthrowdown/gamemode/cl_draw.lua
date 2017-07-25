local draw_SimpleText = draw.SimpleText
local draw_DrawText = draw.DrawText

local colShadow = Color(0, 0, 0)
function draw.SimpleTextBlurBG(text, font, x, y, col, xalign, yalign)
	colShadow.a = col.a

	local fs = font.."_shd"

	draw_SimpleText(text, fs, x, y, colShadow, xalign, yalign)
	draw_SimpleText(text, fs, x, y, colShadow, xalign, yalign)
	draw_SimpleText(text, font, x, y, col, xalign, yalign)
end

function draw.DrawTextBlurBG(text, font, x, y, col, xalign)
	colShadow.a = col.a

	local fs = font.."_shd"

	draw_DrawText(text, fs, x, y, colShadow, xalign)
	draw_DrawText(text, fs, x, y, colShadow, xalign)
	draw_DrawText(text, font, x, y, col, xalign)
end
