local ColorModTimeSlow = {
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 1,
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

function GM:RenderScreenspaceEffects()
	if render.GetDXLevel() < 80 then return end

	ColorModTimeSlow["$pp_colour_colour"] = math.Approach(ColorModTimeSlow["$pp_colour_colour"], 1.6 - math.Clamp(game.GetTimeScale(), 0, 1) * 0.6, RealFrameTime() * 2)

	if ColorModTimeSlow["$pp_colour_colour"] ~= 1 then
		DrawColorModify(ColorModTimeSlow)
	end
end
