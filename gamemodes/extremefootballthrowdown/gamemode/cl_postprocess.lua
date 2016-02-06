local ColorModTime = {
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 0,
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

function GM:DoPostProcessing()
	if render.GetDXLevel() < 80 then return end

	local target = 1.6 - math.Clamp(game.GetTimeScale(), 0, 1) * 0.6

	if CurTime() < GetGlobalFloat("RoundStartTime", 0) --[[or self:IsWarmUp()]] then
		target = target * 0.05
	end

	ColorModTime["$pp_colour_colour"] = math.Approach(ColorModTime["$pp_colour_colour"], target, RealFrameTime() * 2)

	if ColorModTime["$pp_colour_colour"] ~= 1 then
		DrawColorModify(ColorModTime)
	end
end
