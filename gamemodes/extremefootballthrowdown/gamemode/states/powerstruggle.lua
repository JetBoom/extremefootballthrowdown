STATE.Time = 7

STATE.PowerPerKey = 0.03

--[[function STATE:NoSuicide(pl)
	return true
end

function STATE:ImmuneToAll(pl)
	return true
end

function STATE:GetSeed(pl)
	local opp = self:GetOpponent(pl)
	if opp then
		return pl:GetStateStart() + opp:GetStateStart()
	end

	return 0
end

function STATE:GetMatchEndTime(pl)
	local seed = self:GetSeed(pl)
	local round = pl:GetStateInteger()

	local basetime = 0.7 + seed % 0.3
	local speedper = 0.06 + seed * 40 % 0.04

	return pl:GetStateStart() + round * (basetime - speedper ^ round)
end

function STATE:Started(pl, oldstate)
	pl:SetStateNumber(0.5)
	pl:SetStateBool(false)
	pl:SetStateBool2(false)
	pl:SetStateInteger(1)

	pl:ResetJumpPower(0)

	if CLIENT then
		for _, p in pairs(player.GetAll()) do
			p.PSPower = 0.5
		end
	end
end

function STATE:GetOpponent(pl)
	local opp = pl:GetStateEntity()
	if opp:IsValid() and opp:GetStateEntity() == pl and opp:GetState() == STATE_POWERSTRUGGLE then
		return opp
	end
end

function STATE:PrimaryAttack(pl)
	local opp = self:GetOpponent(pl)
	if not opp or pl:GetStateBool2() then return end

	if CurTime() >= self:GetMatchEndTime() - 0.1 then
		pl:SetStateBool(false)
	else
		pl:SetStateBool(true)
	end

	local req = self:GetRequiredPattern(pl)
	if req == key then
		if CLIENT then pl:EmitSound("buttons/lightswitch2.wav", 100, 120, 0.5) end
		pl:SetStateInteger(pl:GetStateInteger() + 1)
		self:AddPower(pl, opp)
	else
		if CLIENT then pl:EmitSound("common/wpn_moveselect.wav", 100, 120, 0.5) end
		opp:CallStateFunction("AddPower", pl)
	end
end

function STATE:AddPower(pl, opp)
	if SERVER then
		pl:SetStateNumber(pl:GetStateNumber() + self.PowerPerKey)
		opp:SetStateNumber(opp:GetStateNumber() - self.PowerPerKey)
	end

	if opp:GetStateNumber() <= 0 or pl:GetStateNumber() >= 1 then
		self:WinPowerStruggle(pl, opp)
	end
end

function STATE:WinPowerStruggle(winner, loser)
	winner:SetState(STATE_POWERSTRUGGLEWIN, nil, loser)
	loser:SetState(STATE_POWERSTRUGGLELOSE, nil, winner)

	gamemode.Call("OnPowerStruggleWin", winner, loser)
	gamemode.Call("OnPowerStruggleLose", loser, winner)
end

function STATE:IsIdle(pl)
	return false
end

function STATE:Move(pl, move)
	move:SetSideSpeed(0)
	move:SetForwardSpeed(0)
	move:SetMaxSpeed(0)
	move:SetMaxClientSpeed(0)

	return MOVE_STOP
end

function STATE:CreateMove(pl, cmd)
	local opp = self:GetOpponent(pl)
	if not opp then return end

	local ang = cmd:GetViewAngles()
	ang.yaw = (opp:GetPos() - pl:GetPos()):Angle().yaw
	cmd:SetViewAngles(ang)
end

function STATE:Think(pl)
	local opp = self:GetOpponent(pl)
	if not opp then
		pl:EndState(true)
	elseif opp:GetPos():Distance(pl:GetPos()) >= 128 then
		opp:EndState(true)
		pl:EndState(true)
	elseif CurTime() >= pl:GetStateStart() + self.Time then
		local opp = self:GetOpponent(pl)
		if opp then
			if opp:GetStateNumber() == pl:GetStateNumber() then
				opp:EndState(true)
				opp:ThrowFromPosition(pl:GetLaunchPos(self.LaunchZ), 300)
				pl:ThrowFromPosition(opp:GetLaunchPos(self.LaunchZ), 300)

				if SERVER then
					local effectdata = EffectData()
						effectdata:SetOrigin((pl:EyePos() + opp:EyePos()) / 2)
						effectdata:SetNormal((pl:EyePos() - opp:EyePos()):GetNormalized())
					util.Effect("powerstruggletie", effectdata, true, true)
				end
			elseif opp:GetStateNumber() > pl:GetStateNumber() then
				opp:EndState(true)
				self:WinPowerStruggle(opp, pl)
			else
				opp:EndState(true)
				self:WinPowerStruggle(pl, opp)
			end
		end
	end
end

function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("seq_meleeattack01")
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	if CLIENT then
		pl.PSPower = math.Approach(pl.PSPower or 0.5, math.Clamp(pl:GetStateNumber(), 0, 1), FrameTime() * 3)
		pl:SetCycle(0.25 + pl.PSPower * 0.15)
	else
		pl:SetCycle(0.25 + math.Clamp(pl:GetStateNumber(), 0, 1) * 0.15)
	end
	pl:SetPlaybackRate(0)

	return true
end

if not CLIENT then return end

local color_black_alpha160 = Color(0, 0, 0, 160)
function STATE:Draw3DHUD(pl)
	local w = 320
	local basex = w * -0.5
	local fadein = math.Clamp((CurTime() - pl:GetStateStart()) * 4, 0, 1)
	local time = CurTime()
	local sat = math.abs(math.sin(time * math.pi * 3))
	local colActive = Color(205 + 50 * sat, 180 + 30 * sat, 10 * sat, 255 * fadein)

	local keya, keyb = self:GetKeyPattern(pl)
	local reqkey = self:GetRequiredPattern(pl)

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), GAMEMODE.CameraYawLerp / 3)
	camang:RotateAroundAxis(camang:Forward(), 15)
	camang:RotateAroundAxis(camang:Up(), math.abs(math.cos(time * math.pi * 2)) ^ 4 * 20 - 10)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(0, 512), camang, 1 + math.abs(math.sin(time * math.pi * 2)) ^ 4 * 0.25)

		draw.SimpleText("POWER STRUGGLE!", "eft_3dheadertext", 0, 0, colActive, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()

	camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), GAMEMODE.CameraYawLerp / 3)
	camang:RotateAroundAxis(camang:Forward(), -15)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(0, -360), camang, 1)

		local boxsize = w * 0.25
		local x = basex
		local colActiveText = Color(0, 0, 0, 255 * fadein)
		local colInactiveText = Color(255, 255, 255, 255 * fadein)

		if reqkey == keya then
			local t = (time * 2) % 1
			local padding = t * 16
			for i=1, 5 do
				local psize = boxsize + padding * i
				draw.RoundedBox(16, x - psize * 0.5, psize * -0.5, boxsize + psize, boxsize + psize, Color(30, 30, 0, 120 - t * i * 20))
			end
			draw.RoundedBox(16, x, 0, boxsize, boxsize, colActive)
		else
			draw.RoundedBox(16, x, 0, boxsize, boxsize, color_black_alpha160)
		end
		draw.SimpleText(string.upper(input.LookupBinding(self.KeyBindings[keya] or "_") or self.KeyDefaultNames[keya] or "?"), "eft_3dstruggleicon", x + boxsize * 0.5, boxsize * 0.5, reqkey == keya and colActiveText or colInactiveText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		x = w - boxsize
		if reqkey == keyb then
			local t = (time * 2) % 1
			local padding = t * 16
			for i=1, 5 do
				local psize = boxsize + padding * i
				draw.RoundedBox(16, x - psize * 0.5, psize * -0.5, boxsize + psize, boxsize + psize, Color(30, 30, 0, 120 - t * i * 20))
			end
			draw.RoundedBox(16, x, 0, boxsize, boxsize, colActive)
		else
			draw.RoundedBox(16, x, 0, boxsize, boxsize, color_black_alpha160)
		end
		draw.SimpleText(string.upper(input.LookupBinding(self.KeyBindings[keyb] or "_") or self.KeyDefaultNames[keyb] or "?"), "eft_3dstruggleicon", x + boxsize * 0.5, boxsize * 0.5, reqkey == keyb and colActiveText or colInactiveText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		x = basex
		local y = boxsize + 32
		local barw, barh = w, 24
		local opp = self:GetOpponent(pl)
		if opp then
			draw.SimpleText("You", "eft_3dstruggletext", x - 8, y, Color(255, 255, 255, 255 * fadein), TEXT_ALIGN_RIGHT)
			surface.SetDrawColor(0, 0, 0, 120 * fadein)
			surface.DrawRect(x, y, barw, barh)
			surface.SetDrawColor(255, 255, 255, 220 * fadein)
			surface.DrawOutlinedRect(x, y, barw, barh)
			surface.DrawRect(x + 3, y + 3, (barw - 6) * pl.PSPower, barh - 6)

			y = y + 32
			draw.SimpleText("Them", "eft_3dstruggletext", x - 8, y, Color(255, 10, 10, 255 * fadein), TEXT_ALIGN_RIGHT)
			surface.SetDrawColor(0, 0, 0, 120 * fadein)
			surface.DrawRect(x, y, barw, barh)
			surface.SetDrawColor(255, 10, 10, 220 * fadein)
			surface.DrawOutlinedRect(x, y, barw, barh)
			surface.DrawRect(x + 3, y + 3, (barw - 6) * opp.PSPower, barh - 6)
		end

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end]]

STATE.PowerPerKey = 0.03

STATE.Keys = {
	IN_FORWARD,
	IN_BACK,
	IN_MOVELEFT,
	IN_MOVERIGHT
}

STATE.KeyDefaultNames = {
	[IN_FORWARD] = "W",
	[IN_BACK] = "S",
	[IN_MOVELEFT] = "A",
	[IN_MOVERIGHT] = "D"
}

STATE.KeyBindings = {
	[IN_FORWARD] = "+forward",
	[IN_BACK] = "+back",
	[IN_MOVELEFT] = "+moveleft",
	[IN_MOVERIGHT] = "+moveright"
}

function STATE:NoSuicide(pl)
	return true
end

function STATE:ImmuneToAll(pl)
	return true
end

function STATE:Started(pl, oldstate)
	pl:SetStateNumber(0.5)
	pl:SetStateInteger(0)
	pl:ResetJumpPower(0)

	local keys = table.Copy(self.Keys)
	local basea = math.Round(CurTime()) + pl:EntIndex() * 1024
	local baseb = math.Round(CurTime() * 4) + pl:EntIndex() * 4
	local slota = basea % #keys + 1
	local keya = keys[slota]
	table.remove(keys, slota)
	local keyb = keys[baseb % #keys + 1]

	self:SetKeyPattern(pl, keya, keyb)

	if CLIENT then
		for _, p in pairs(player.GetAll()) do
			p.PSPower = 0.5
		end
	end
end

function STATE:GetRequiredPattern(pl)
	local a, b = self:GetKeyPattern(pl)
	local i = pl:GetStateInteger() % 2
	return i == 0 and a or b
end

function STATE:SetKeyPattern(pl, a, b)
	local vec = pl:GetStateVector()
	vec.x = a
	vec.y = b

	pl:SetStateVector(vec)
end

function STATE:GetKeyPattern(pl)
	local vec = pl:GetStateVector()
	return vec.x, vec.y
end

function STATE:GetOpponent(pl)
	local opp = pl:GetStateEntity()
	if opp:IsValid() and opp:GetStateEntity() == pl and opp:GetState() == STATE_POWERSTRUGGLE then
		return opp
	end
end

function STATE:KeyPress(pl, key)
	if table.HasValue(self.Keys, key) then
		local opp = self:GetOpponent(pl)
		if not opp then return end

		local req = self:GetRequiredPattern(pl)
		if req == key then
			if CLIENT then pl:EmitSound("buttons/lightswitch2.wav", 100, 120, 0.5) end
			pl:SetStateInteger(pl:GetStateInteger() + 1)
			self:AddPower(pl, opp)
		else
			if CLIENT then pl:EmitSound("common/wpn_moveselect.wav", 100, 120, 0.5) end
			opp:CallStateFunction("AddPower", pl)
		end
	end
end

function STATE:AddPower(pl, opp)
	if SERVER then
		pl:SetStateNumber(pl:GetStateNumber() + self.PowerPerKey)
		opp:SetStateNumber(opp:GetStateNumber() - self.PowerPerKey)
	end

	if opp:GetStateNumber() <= 0 or pl:GetStateNumber() >= 1 then
		self:WinPowerStruggle(pl, opp)
	end
end

function STATE:WinPowerStruggle(winner, loser)
	winner:SetState(STATE_POWERSTRUGGLEWIN, nil, loser)
	loser:SetState(STATE_POWERSTRUGGLELOSE, nil, winner)

	gamemode.Call("OnPowerStruggleWin", winner, loser)
	gamemode.Call("OnPowerStruggleLose", loser, winner)
end

function STATE:IsIdle(pl)
	return false
end

function STATE:Move(pl, move)
	move:SetSideSpeed(0)
	move:SetForwardSpeed(0)
	move:SetMaxSpeed(0)
	move:SetMaxClientSpeed(0)

	return MOVE_STOP
end

function STATE:CreateMove(pl, cmd)
	local opp = self:GetOpponent(pl)
	if not opp then return end

	local ang = cmd:GetViewAngles()
	ang.yaw = (opp:GetPos() - pl:GetPos()):Angle().yaw
	cmd:SetViewAngles(ang)
end

function STATE:Think(pl)
	local opp = self:GetOpponent(pl)
	if not opp then
		pl:EndState(true)
	elseif opp:GetPos():Distance(pl:GetPos()) >= 128 then
		opp:EndState(true)
		pl:EndState(true)
	elseif CurTime() >= pl:GetStateStart() + self.Time then
		local opp = self:GetOpponent(pl)
		if opp then
			if opp:GetStateNumber() == pl:GetStateNumber() then
				opp:EndState(true)
				opp:ThrowFromPosition(pl:GetLaunchPos(self.LaunchZ), 300)
				pl:ThrowFromPosition(opp:GetLaunchPos(self.LaunchZ), 300)

				if SERVER then
					local effectdata = EffectData()
						effectdata:SetOrigin((pl:EyePos() + opp:EyePos()) / 2)
						effectdata:SetNormal((pl:EyePos() - opp:EyePos()):GetNormalized())
					util.Effect("powerstruggletie", effectdata, true, true)
				end
			elseif opp:GetStateNumber() > pl:GetStateNumber() then
				opp:EndState(true)
				self:WinPowerStruggle(opp, pl)
			else
				opp:EndState(true)
				self:WinPowerStruggle(pl, opp)
			end
		end
	end
end

function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("seq_meleeattack01")
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	if CLIENT then
		pl.PSPower = math.Approach(pl.PSPower or 0.5, math.Clamp(pl:GetStateNumber(), 0, 1), FrameTime() * 3)
		pl:SetCycle(0.25 + pl.PSPower * 0.15)
	else
		pl:SetCycle(0.25 + math.Clamp(pl:GetStateNumber(), 0, 1) * 0.15)
	end
	pl:SetPlaybackRate(0)

	return true
end

if not CLIENT then return end

local color_black_alpha160 = Color(0, 0, 0, 160)
function STATE:Draw3DHUD(pl)
	local w = 320
	local basex = w * -0.5
	local fadein = math.Clamp((CurTime() - pl:GetStateStart()) * 4, 0, 1)
	local time = CurTime()
	local sat = math.abs(math.sin(time * math.pi * 3))
	local colActive = Color(205 + 50 * sat, 180 + 30 * sat, 10 * sat, 255 * fadein)

	local keya, keyb = self:GetKeyPattern(pl)
	local reqkey = self:GetRequiredPattern(pl)

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), GAMEMODE.CameraYawLerp / 3)
	camang:RotateAroundAxis(camang:Forward(), 15)
	camang:RotateAroundAxis(camang:Up(), math.abs(math.cos(time * math.pi * 2)) ^ 4 * 20 - 10)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(0, 512), camang, 1 + math.abs(math.sin(time * math.pi * 2)) ^ 4 * 0.25)

		draw.SimpleText("POWER STRUGGLE!", "eft_3dheadertext", 0, 0, colActive, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()

	camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), GAMEMODE.CameraYawLerp / 3)
	camang:RotateAroundAxis(camang:Forward(), -15)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(0, -360), camang, 1)

		local boxsize = w * 0.25
		local x = basex
		local colActiveText = Color(0, 0, 0, 255 * fadein)
		local colInactiveText = Color(255, 255, 255, 255 * fadein)

		if reqkey == keya then
			local t = (time * 2) % 1
			local padding = t * 16
			for i=1, 5 do
				local psize = boxsize + padding * i
				draw.RoundedBox(16, x - psize * 0.5, psize * -0.5, boxsize + psize, boxsize + psize, Color(30, 30, 0, 120 - t * i * 20))
			end
			draw.RoundedBox(16, x, 0, boxsize, boxsize, colActive)
		else
			draw.RoundedBox(16, x, 0, boxsize, boxsize, color_black_alpha160)
		end
		draw.SimpleText(string.upper(input.LookupBinding(self.KeyBindings[keya] or "_") or self.KeyDefaultNames[keya] or "?"), "eft_3dstruggleicon", x + boxsize * 0.5, boxsize * 0.5, reqkey == keya and colActiveText or colInactiveText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		x = w - boxsize
		if reqkey == keyb then
			local t = (time * 2) % 1
			local padding = t * 16
			for i=1, 5 do
				local psize = boxsize + padding * i
				draw.RoundedBox(16, x - psize * 0.5, psize * -0.5, boxsize + psize, boxsize + psize, Color(30, 30, 0, 120 - t * i * 20))
			end
			draw.RoundedBox(16, x, 0, boxsize, boxsize, colActive)
		else
			draw.RoundedBox(16, x, 0, boxsize, boxsize, color_black_alpha160)
		end
		draw.SimpleText(string.upper(input.LookupBinding(self.KeyBindings[keyb] or "_") or self.KeyDefaultNames[keyb] or "?"), "eft_3dstruggleicon", x + boxsize * 0.5, boxsize * 0.5, reqkey == keyb and colActiveText or colInactiveText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		x = basex
		local y = boxsize + 32
		local barw, barh = w, 24
		local opp = self:GetOpponent(pl)
		if opp then
			draw.SimpleText("You", "eft_3dstruggletext", x - 8, y, Color(255, 255, 255, 255 * fadein), TEXT_ALIGN_RIGHT)
			surface.SetDrawColor(0, 0, 0, 120 * fadein)
			surface.DrawRect(x, y, barw, barh)
			surface.SetDrawColor(255, 255, 255, 220 * fadein)
			surface.DrawOutlinedRect(x, y, barw, barh)
			surface.DrawRect(x + 3, y + 3, (barw - 6) * pl.PSPower, barh - 6)

			y = y + 32
			draw.SimpleText("Them", "eft_3dstruggletext", x - 8, y, Color(255, 10, 10, 255 * fadein), TEXT_ALIGN_RIGHT)
			surface.SetDrawColor(0, 0, 0, 120 * fadein)
			surface.DrawRect(x, y, barw, barh)
			surface.SetDrawColor(255, 10, 10, 220 * fadein)
			surface.DrawOutlinedRect(x, y, barw, barh)
			surface.DrawRect(x + 3, y + 3, (barw - 6) * opp.PSPower, barh - 6)
		end

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end
