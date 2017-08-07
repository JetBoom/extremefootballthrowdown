STATE.Time = 5

STATE.NumKeys = 12
STATE.KeysPerBlock = 3
STATE.PowerPerKey = 1 / STATE.NumKeys
STATE.NumBlocks = STATE.NumKeys / STATE.KeysPerBlock

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

function STATE:Started(pl, oldstate)
	pl:SetCollisionMode(COLLISION_PASSTHROUGH)

	pl:SetStateInteger(0)
	pl:ResetJumpPower(0)

	if CLIENT then
		for _, p in pairs(player.GetAll()) do
			p.PSPower = 0.5
		end
	end
end

function STATE:GetKeys(pl)
	math.randomseed(pl:GetStateStart())

	local tab = {}
	local maxkey = #self.Keys
	for i=1, self.NumKeys do
		tab[i] = self.Keys[math.random(1, maxkey)]
	end

	return tab
end

function STATE:OnCorrectKey(pl)
	pl:SetStateInteger(pl:GetStateInteger() + 1)

	if CLIENT then
		pl:EmitSound("buttons/lightswitch2.wav", 100, 120, 0.5)
	end
end

function STATE:OnWrongKey(pl)
	pl:SetStateInteger(pl:GetStateInteger() - pl:GetStateInteger() % self.KeysPerBlock)

	if CLIENT then
		pl:EmitSound("common/wpn_moveselect.wav", 100, 120, 0.5)
	end
end

function STATE:GetRequiredKey(pl)
	return self:GetKeys(pl)[pl:GetStateInteger() + 1] or 0
end

function STATE:GetOpponent(pl)
	local opp = pl:GetStateEntity()
	if opp:IsValid() and opp:GetStateEntity() == pl and opp:GetState() == STATE_POWERSTRUGGLE then
		return opp
	end
end

function STATE:KeyPress(pl, key)
	local opp = self:GetOpponent(pl)
	if not opp then return end

	if pl:GetStateInteger() < self.NumKeys then
		if key == IN_ATTACK2 then
			opp:EndState(true)
			self:WinPowerStruggle(opp, pl)
		elseif self.KeyDefaultNames[key] then
			local req = self:GetRequiredKey(pl)
			if key == req then
				self:OnCorrectKey(pl)
			else
				self:OnWrongKey(pl)
			end
		end
	end
end

function STATE:GetPower(pl)
	local opponent = self:GetOpponent(pl)
	if opponent then
		local a = pl:GetStateInteger()
		local b = opponent:GetStateInteger()
		if a > 0 and b > 0 then
			if a < b then
				return math.Clamp(a / b, 0, 1)
			elseif a > b then
				return math.Clamp(1 - b / a, 0, 1)
			end
		end
	end

	return 0.5
end

function STATE:WinPowerStruggle(winner, loser)
	winner:SetState(STATE_POWERSTRUGGLEWIN, nil, loser)
	loser:SetState(STATE_POWERSTRUGGLELOSE, nil, winner)

	gamemode.Call("OnPowerStruggleWin", winner, loser)
	gamemode.Call("OnPowerStruggleLose", loser, winner)
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
	elseif opp:GetPos():DistToSqr(pl:GetPos()) >= 16384 then
		opp:EndState(true)
		pl:EndState(true)
	elseif CurTime() >= pl:GetStateStart() + self.Time or opp:GetStateInteger() >= self.NumKeys or pl:GetStateInteger() >= self.NumKeys then
		local opp = self:GetOpponent(pl)
		if opp then
			if opp:GetStateInteger() == pl:GetStateInteger() then
				opp:EndState(true)
				opp:ThrowFromPosition(pl:GetLaunchPos(self.LaunchZ), 300)
				pl:ThrowFromPosition(opp:GetLaunchPos(self.LaunchZ), 300)

				if SERVER then
					local effectdata = EffectData()
						effectdata:SetOrigin((pl:EyePos() + opp:EyePos()) / 2)
						effectdata:SetNormal((pl:EyePos() - opp:EyePos()):GetNormalized())
					util.Effect("powerstruggletie", effectdata, true, true)
				end
			elseif opp:GetStateInteger() > pl:GetStateInteger() then
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
		pl.PSPower = math.Approach(pl.PSPower or 0.5, self:GetPower(pl), FrameTime() * 3)
		pl:SetCycle(0.25 + pl.PSPower * 0.15)
	else
		pl:SetCycle(0.25 + self:GetPower(pl) * 0.15)
	end
	pl:SetPlaybackRate(0)

	return true
end

function STATE:Move(pl, move)
	move:SetSideSpeed(0)
	move:SetForwardSpeed(0)
	move:SetMaxSpeed(0)
	move:SetMaxClientSpeed(0)

	local opp = self:GetOpponent(pl)
	if opp then
		local pos = pl:GetPos()
		local opos = opp:GetPos()
		pos.z = 0
		opos.z = 0

		local dist = pos:DistToSqr(opos)

		if dist > 1124 then
			move:SetVelocity(0.5 * (opos - pos))
		elseif dist < 924 then
			move:SetVelocity(0.5 * (pos - opos))
		end
	end

	return MOVE_STOP
end

function STATE:IsIdle(pl)
	return false
end

function STATE:ImmuneToAll(pl)
	return true
end
STATE.NoSuicide = STATE.ImmuneToAll

if not CLIENT then return end

local color_black_alpha160 = Color(0, 0, 0, 160)
local colActiveText = Color(0, 0, 0)
local colInactiveText = Color(255, 255, 255)
local w = 320
local barw, barh = 320, 24
local boxsize = 64
local half_boxsize = boxsize / 2
local boxpadding = 16
local basex = (boxsize * STATE.NumKeys + boxpadding * (STATE.NumKeys - 1)) * -0.5
local boxspacing = boxsize + boxpadding
local camang, fadein, time, sat, colActive, keys, key, currentkey, x
function STATE:Draw3DHUD(pl)
	fadein = math.Clamp((CurTime() - pl:GetStateStart()) * 4, 0, 1)
	time = CurTime()
	sat = math.abs(math.sin(time * math.pi * 3))

	keys = self:GetKeys(pl)
	currentkey = pl:GetStateInteger() + 1

	colActive = Color(205 + 50 * sat, 180 + 30 * sat, 10 * sat, 255 * fadein)
	colActiveText.a = fadein * 255
	colInactiveText.a = colActiveText.a


	camang = EyeAngles3D2D()
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
	cam.Start3D2D(EyePos3D2DScreen(0, -256), camang, 1)

	draw.SimpleText("PRESS ["..(input.LookupBinding("+attack2") or "SECONDARY ATTACK").."] TO QUIT!", "eft_3dheadertext", 0, 0 --[[h / 2]], colActive, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)


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

	x = basex

	for i=1, self.NumKeys do
		key = keys[i]

		if currentkey == i then
			local t = (time * 2) % 1
			local padding = t * 16

			for i=1, 5 do
				local psize = boxsize + padding * i
				draw.RoundedBox(16, x - psize * 0.5, psize * -0.5, boxsize + psize, boxsize + psize, Color(30, 30, 0, 120 - t * i * 20))
			end

			draw.RoundedBox(16, x, 0, boxsize, boxsize, colActive)

			draw.SimpleTextBlurBG("▼", "eft_3dstruggleicon", x + half_boxsize, math.sin(RealTime() * 3) ^ 2 * -8, colActive, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		else
			draw.RoundedBox(16, x, 0, boxsize, boxsize, color_black_alpha160)
		end

		draw.SimpleText(string.upper(input.LookupBinding(self.KeyBindings[key] or "_") or self.KeyDefaultNames[key] or "?"), "eft_3dstruggleicon", x + half_boxsize, half_boxsize, currentkey == i and colActiveText or colInactiveText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		x = x + boxspacing

		if i < self.NumKeys and i % self.KeysPerBlock == 0 then
			surface.SetDrawColor(colActive)
			surface.DrawRect(x - boxpadding * 0.5 - 3, -8, 6, boxsize + 16)
		end
	end

	--[[x = basex

	local y = boxsize + 32
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
	--render.PopFilterMag()]]
end
