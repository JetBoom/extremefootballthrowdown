include("cl_obj_entity_extend.lua")
include("cl_obj_player_extend.lua")

include("shared.lua")

include("animationsapi/cl_boneanimlib.lua")
include("animationsapi/cl_animeditor.lua")

include("cl_postprocess.lua")

MySelf = MySelf or NULL
hook.Add("InitPostEntity", "GetLocal", function()
	MySelf = LocalPlayer()

	GAMEMODE.HookGetLocal = GAMEMODE.HookGetLocal or (function(g) end)
	gamemode.Call("HookGetLocal", MySelf)
	RunConsoleCommand("initpostentity")
end)

language.Add("prop_ball", "Ball")

local color_black_alpha160 = Color(0, 0, 0, 160)
local color_black_alpha90 = Color(0, 0, 0, 90)

function GM:HookGetLocal()
	self.CreateMove = self._CreateMove
	self.PostDrawTranslucentRenderables = self._PostDrawTranslucentRenderables
	self.PrePlayerDraw = self._PrePlayerDraw
	self.PostPlayerDraw = self._PostPlayerDraw
end

function GM:HUDShouldDraw(name)
	if name == "CHudCrosshair" or name == "CHudHealth" or name == "CHudBattery" or name == "CHudDamageIndicator" then
		return false
	end

	return self.BaseClass.HUDShouldDraw(self, name)
end

function GM:PlayerStepSoundTime(pl, iType, bWalking)
	if iType == STEPSOUNDTIME_NORMAL or iType == STEPSOUNDTIME_WATER_FOOT then
		return math.max(200, 520 - pl:GetVelocity():Length())
	end

	if iType == STEPSOUNDTIME_ON_LADDER then
		return 500
	end

	if iType == STEPSOUNDTIME_WATER_KNEE then
		return 650
	end

	return 350
end

GM.PrevCameraYaw = 0
GM.CameraYawLerp = 0
function GM:_CreateMove(cmd)
	if MySelf:IsPlayingTaunt() and MySelf:Alive() then
		self:CreateMoveTaunt(cmd)
		return
	end

	local ang = cmd:GetViewAngles()

	self.CameraYawLerp = math.Clamp(self.CameraYawLerp + math.AngleDifference(self.PrevCameraYaw, ang.yaw) * FrameTime() * 120, -90, 90)
	self.CameraYawLerp = math.Approach(self.CameraYawLerp, 0, FrameTime() * math.max(15, math.abs(self.CameraYawLerp) ^ 1.15))
	self.PrevCameraYaw = ang.yaw

	return MySelf:CallStateFunction("CreateMove", cmd) or self.BaseClass.CreateMove(self, cmd)
end

function GM:CreateMoveTaunt(cmd)
	cmd:ClearButtons(0)
	cmd:ClearMovement()
end

function GM:_PrePlayerDraw(pl)
	return pl:CallStateFunction("PrePlayerDraw")
end

local colFriend = Color(10, 255, 10, 200)
local colFriendOT = Color(255, 160, 0, 200)
local matFriendRing = Material("SGM/playercircle")
function GM:_PostPlayerDraw(pl)
	if pl ~= MySelf and pl:IsFriend() then
		local pos = pl:GetPos() + Vector(0, 0, 0.5)
		local col = pl:Team() == MySelf:Team() and colFriend or colFriendOT
		render.SetMaterial(matFriendRing)
		render.DrawQuadEasy(pos, Vector(0, 0, 1), 32, 32, col)
		render.DrawQuadEasy(pos, Vector(0, 0, -1), 32, 32, col)
	end

	return pl:CallStateFunction("PostPlayerDraw")
end

local LookBehindAngles = {
	[3] = Angle(0, -30, -30),
	[4] = Angle(0, 0, -30),
	[6] = Angle(0, 0, -80)
}
function GM:Think()
	self.BaseClass.Think(self)

	local lbt = FrameTime() * 4

	local lp = LocalPlayer()
	for _, pl in pairs(player.GetAll()) do
		pl:SetIK(false)

		local rag = pl:GetRagdollEntity()
		if rag and rag:IsValid() and not rag.ScaledBones then
			rag.ScaledBones = true
			for bonename, scale in pairs(self.BoneScales) do
				local boneid = rag:LookupBone(bonename)
				if boneid then
					rag:ManipulateBoneScale(boneid, scale)
				end
			end
		end

		if pl:Alive() then
			if pl == lp then
				pl:ThinkSelf()
			else
				pl:CallStateFunction("ThinkOther")
			end

			local lookbehind = pl:GetState() == STATE_NONE and pl:GetStateInteger() == -1
			pl.LookBehind = math.Approach(pl.LookBehind or 0, lookbehind and 1 or 0, lbt)
			if pl.LookBehind == 0 then
				if pl.LookBehindScaled then
					pl.LookBehindScaled = false
					for boneid, scale in pairs(LookBehindAngles) do
						pl:ManipulateBoneAngles(boneid, angle_zero)
					end
				end
			else
				pl.LookBehindScaled = true
				for boneid, scale in pairs(LookBehindAngles) do
					pl:ManipulateBoneAngles(boneid, scale * pl.LookBehind)
				end 
			end
		end
	end
end

function GM:DrawPlayerRing(pl)
end

function GM:PostProcessPermitted()
	return false
end

function GM:PositionScoreboard(ScoreBoard)
	ScoreBoard:SetSize(math.min(600, ScrW() - 32), math.min(800, ScrH() - 32))
	ScoreBoard:Center()
end

function EyeAngles3D2D()
	local ang = EyeAngles()
	ang:RotateAroundAxis(ang:Up(), 180)
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), 270)
	return ang
end

function EyePos3D2DScreen(right, up, forward)
	local eyepos = EyePos()
	local eyeang = EyeAngles()
	return eyepos + eyeang:Forward() * (forward or 1024) + eyeang:Right() * right + eyeang:Up() * up
end

function HSVtoRGB(h)
	local r, g, b
	local f, p, q, t
	
	-- Make sure our arguments stay in-range
	h = math.max(0, math.min(360, h))
	
	s = 1
	v = 1
	
	if s == 0 then
		-- Achromatic (grey)
		local gray = math.Round(v * 255)
		return Color(gray, gray, gray)
	end
	
	h = h / 60 -- sector 0 to 5
	local i = math.floor(h)
	local f = h - i -- factorial part of h
	local q = v * (1 - f)
	local t = v * (1 - (1 - f))

	if i == 0 then
		r = v
		g = t
		b = 0
	elseif i == 1 then
		r = q
		g = v
		b = 0
	elseif i == 2 then
		r = 0
		g = v
		b = t
	elseif i == 3 then
		r = 0
		g = q
		b = v
	elseif i == 4 then
		r = t
		g = 0
		b = v
	else
		r = v
		g = 0
		b = q
	end
	
	return math.Round(r * 255), math.Round(g * 255), math.Round(b * 255)
end

function GM:_PostDrawTranslucentRenderables()
	if self.DrawingInSky then return end

	self:Draw3DHUD()
end

function GM:PreDrawSkyBox()
	self.DrawingInSky = true
end

function GM:PostDrawSkyBox()
	self.DrawingInSky = false
end

function GM:Draw3DTieBreaker()
	local tiebreaker = self.TieBreaker
	if not tiebreaker:IsValid() then return end

	local redplayer, blueplayer = tiebreaker:GetRedPlayer(), tiebreaker:GetBluePlayer()

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), self.CameraYawLerp / 5)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(0, 400), camang, 1)

		--draw.RoundedBox(16, -250, -32, 500, 64, color_black_alpha90)
		draw.SimpleText("TIE BREAKER", "eft_3dteamscore", 0, -32, Color(HSVtoRGB((CurTime() * 180) % 360)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		draw.RoundedBox(8, -342, -24, 300, 48, color_black_alpha90)
		if redplayer:IsValid() then
			local healthw = math.Clamp(redplayer:Health() / 100, 0, 1) * 292
			if healthw > 0 then
				draw.RoundedBox(math.Clamp(math.floor(healthw / 2), 0, 8), -46 - healthw, -20, healthw, 40, team.GetColor(TEAM_RED))
			end
		end

		draw.RoundedBox(8, 42, -24, 300, 48, color_black_alpha90)
		if blueplayer:IsValid() then
			local healthw = math.Clamp(blueplayer:Health() / 100, 0, 1) * 292
			if healthw > 0 then
				draw.RoundedBox(math.Clamp(math.floor(healthw / 2), 0, 8), 46, -20, healthw, 40, team.GetColor(TEAM_BLUE))
			end
		end

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

function GM:Draw3DHUD()
	if not self.TieBreaker then
		self:Draw3DBallIndicator()
	end

	cam.Start3D(EyePos(), EyeAngles(), 90)

	if self.TieBreaker then
		self:Draw3DTieBreaker()

		MySelf:CallStateFunction("Draw3DHUD")
	else
		if team.Joinable(MySelf:Team()) and MySelf:Team() ~= TEAM_SPECTATE then
			self:Draw3DHealthBar()
			self:Draw3DWeapon()
			self:Draw3DGoalIndicator()

			MySelf:CallStateFunction("Draw3DHUD")
		end

		self:Draw3DBallPowerup()
		self:Draw3DTeamScores()
		self:Draw3DGameState()
	end

	cam.End3D()
end

function GM:Draw3DPotentialWeapon()
	local wep = MySelf:GetPotentialCarry()
	if not wep or not wep:IsValid() or not wep.GetCarrier or wep:GetCarrier():IsValid() or not wep.Name then return end

	local w, h = 460, 40

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), self.CameraYawLerp / 3)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(0, -300), camang, 1)

		draw.RoundedBox(16, w * -0.5, 0, w, h, color_black_alpha90)
		draw.SimpleText("["..(input.LookupBinding("+use") or "USE").."] PICK UP "..string.upper(wep.Name), "eft_3dteamscore", 0, h / 2, Color(HSVtoRGB((CurTime() * 180) % 360)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

function GM:Draw3DWeapon()
	local wep = MySelf:GetCarry()
	if not IsValid(wep) or not wep.Name then
		return self:Draw3DPotentialWeapon()
	end

	local w, h = 300, 40

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), 30 + self.CameraYawLerp / 3)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(400, -450), camang, 1)

		draw.RoundedBox(16, w * -0.5, 0, w, h, color_black_alpha90)
		draw.SimpleText(string.upper(wep.Name).."!", "eft_3dteamscore", 0, h / 2, Color(HSVtoRGB((CurTime() * 180) % 360)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

function GM:Draw3DGoalIndicator()
	if MySelf:GetCarry() ~= self:GetBall() or not self.NearestGoal then return end

	local mypos = MySelf:GetPos()
	local dist = mypos:Distance(self.NearestGoal)
	if dist <= 100 then return end

	local dir = (mypos - self.NearestGoal):Angle()
	local eyeangles = EyeAngles()

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Up(), math.AngleDifference(dir.yaw, eyeangles.yaw) + 270)
	--camang:RotateAroundAxis(camang:Right(), math.AngleDifference(eyeangles.pitch, dir.pitch) / 2)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(0, 250), camang, 1)

		draw.SimpleText("GO >>>", "eft_3dteamscore", 0, 0, Color(HSVtoRGB((CurTime() * 180) % 360)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

net.Receive("eft_nearestgoal", function(length)
	GAMEMODE.NearestGoal = net.ReadVector()
end)

function GM:Initialize()
	self.BaseClass.Initialize(self)

	surface.CreateFont("eft_3dhealthbar",  {font = "coolvetica", size = 28, weight = 0, antialias = false, shadow = false, outline = true})
	surface.CreateFont("eft_3dstruggleicon",  {font = "coolvetica", size = 48, weight = 1000, antialias = false, shadow = false, outline = false})
	surface.CreateFont("eft_3dstruggletext",  {font = "coolvetica", size = 24, weight = 0, antialias = false, shadow = false, outline = true})
	surface.CreateFont("eft_3dpowertext",  {font = "coolvetica", size = 40, weight = 0, antialias = false, shadow = false, outline = true})
	surface.CreateFont("eft_3dpoweruptext",  {font = "coolvetica", size = 64, weight = 0, antialias = false, shadow = false, outline = true})
	surface.CreateFont("eft_3dpoweruptimetext",  {font = "coolvetica", size = 48, weight = 0, antialias = false, shadow = false, outline = true})
	surface.CreateFont("eft_3dheadertext",  {font = "coolvetica", size = 72, weight = 500, antialias = false, shadow = false, outline = true})
	surface.CreateFont("eft_3dnametext",  {font = "coolvetica", size = 32, weight = 0, antialias = false, shadow = false, outline = true})
	surface.CreateFont("eft_3dteamname",  {font = "coolvetica", size = 24, weight = 0, antialias = false, shadow = false, outline = true})
	surface.CreateFont("eft_3dteamscore",  {font = "coolvetica", size = 40, weight = 0, antialias = false, shadow = false, outline = true})
	surface.CreateFont("eft_3dpity",  {font = "coolvetica", size = 28, weight = 0, antialias = false, shadow = false, outline = true})
	surface.CreateFont("eft_3dballtext",  {font = "coolvetica", size = 32, weight = 0, antialias = false, shadow = false, outline = true})
	surface.CreateFont("eft_3dballtextsmall",  {font = "coolvetica", size = 24, weight = 0, antialias = false, shadow = false, outline = true})
	surface.CreateFont("eft_3dwinnertext",  {font = "coolvetica", size = 128, weight = 500, antialias = false, shadow = false, outline = true})

	self:RegisterWeapons()

	hook.Remove("PrePlayerDraw", "DrawPlayerRing")
end

function GM:Draw3DBallPowerup()
	local ball = self:GetBall()
	if not ball:IsValid() then return end

	if ball:GetState() == BALL_STATE_NONE then return end

	local time = CurTime()
	local statetable = ball:GetStateTable()
	local col = table.Copy(ball:CallStateFunction("GetBallColor", ball:GetCarrier()) or color_white)
	local timeleft = ball:GetStateEnd() == 0 and -1 or math.max(0, ball:GetStateEnd() - time)
	local fadein
	if timeleft == -1 then
		fadein = math.Clamp((time - ball:GetStateStart()) / 0.5, 0, 1)
	else
		fadein = math.Clamp(math.min(timeleft, time - ball:GetStateStart()) / 0.5, 0, 1)
	end

	col.a = 255 * fadein * (1 - math.abs(math.sin(time * math.pi * 4)) * 0.25)

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), self.CameraYawLerp / 3)
	camang:RotateAroundAxis(camang:Forward(), 15)
	camang:RotateAroundAxis(camang:Up(), (1 - fadein) * 720)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(0, 400), camang, 1 + math.abs(math.sin(time * math.pi * 2)) ^ 4 * 0.25)

		if statetable.Name then
			draw.SimpleText(string.upper(statetable.Name), "eft_3dpoweruptext", 0, -2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
		if timeleft ~= -1 then
			col.r = 255 col.g = 255 col.b = 255
			draw.SimpleText(util.ToMinutesSecondsMilliseconds(timeleft), "eft_3dpoweruptimetext", 0, 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

function GM:Draw3DGameWinner()
	local winner = self.GameWinner
	local starttime = self.GameEndTime

	local time = CurTime()

	local fadein = math.Clamp(time - starttime, 0, 1) ^ 0.5
	local rfadein = 1 - fadein

	local base = math.sin(time * math.pi)
	local base2 = math.cos(time * math.pi)
	base = base-- ^ 3
	base2 = base2-- ^ 3

	local ang = EyeAngles3D2D()
	ang:RotateAroundAxis(ang:Up(), base * 25)
	ang:RotateAroundAxis(ang:Right(), base2 * 25)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(0, 0), ang, 1.25)

		if winner == 0 then
			draw.SimpleText("TIE", "eft_3dwinnertext", -16 - rfadein * 1000, 0, team.GetColor(TEAM_RED), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText("GAME", "eft_3dwinnertext", 16 + rfadein * 1000, 0, team.GetColor(TEAM_BLUE), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText("V I C T O R Y", "eft_3dwinnertext", 0, -16 - rfadein * 1000, Color(HSVtoRGB((time * 180) % 360)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText(team.GetName(winner), "eft_3dwinnertext", 0, 16 + rfadein * 1000, team.GetColor(winner), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

function GM:Draw3DRoundWinner()
	if self.RoundEndScroll >= 1 then return end

	local time = CurTime()
	local realtime = RealTime()
	local winner = self.RoundWinner

	self.RoundEndScroll = self.RoundEndScroll + RealFrameTime() * (math.abs(self.RoundEndScroll - 0.5) <= 0.1 and 0.03 or 0.5)

	local distfromcenter = math.abs(self.RoundEndScroll - 0.5) * 2
	local size = 1 - distfromcenter * 0.4

	local col = table.Copy(team.GetColor(winner))
	local barcol = Color(HSVtoRGB((realtime * 400) % 360))
	col.a = 255 * (1 - math.abs(math.sin(time * math.pi * 4)) * 0.25)
	barcol.a = col.a

	local linea = (1 - distfromcenter) * 255

	local boxw, boxh = 3000, 40 + math.abs(math.sin(realtime * 3)) * 40

	local ang = EyeAngles3D2D()
	ang:RotateAroundAxis(ang:Forward(), -30)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(1200 - self.RoundEndScroll * 2400, 40), ang, size)

		draw.SimpleText("TOUCH DOWN!!", "eft_3dwinnertext", 0, 0, barcol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()

	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(-1200, 20), ang, 1)

		surface.SetDrawColor(0, 0, 0, linea)
		surface.DrawRect(0, boxh * -0.5, boxw, boxh)
		surface.SetDrawColor(barcol.r, barcol.g, barcol.b, linea)
		surface.DrawRect(0, boxh * -0.5 + 8, boxw, boxh - 16)

	cam.End3D2D()
	cam.IgnoreZ(false)

	ang:RotateAroundAxis(ang:Forward(), 60)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(-1200 + self.RoundEndScroll * 2400, -40), ang, size)

		draw.SimpleText(string.upper(team.GetName(winner)), "eft_3dwinnertext", 0, 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

function GM:Draw3DGameState()
	if self.GameWinner then
		self:Draw3DGameWinner()
	elseif self.RoundWinner then
		self:Draw3DRoundWinner()
	end
end

function GM:Draw3DTeamScores()
	local w, h = 128, 64

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), -30 + self.CameraYawLerp / 3)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(-400, 450), camang, 1)
		draw.RoundedBox(16, w * -0.5, 0, w, h, color_black_alpha90)
		draw.SimpleText(team.GetName(TEAM_RED), "eft_3dteamname", 0, 8, team.GetColor(TEAM_RED), TEXT_ALIGN_CENTER)
		draw.SimpleText(team.GetScore(TEAM_RED).." / "..self.ScoreLimit, "eft_3dteamscore", 0, h, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		if team.HasPity(TEAM_RED) then
			draw.SimpleText("RAGE!", "eft_3dpity", 0, h + 8, Color(HSVtoRGB(math.abs(math.sin(CurTime() * 4)) * 50)), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()

	camang:RotateAroundAxis(camang:Right(), 60)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(400, 450), camang, 1)

		draw.RoundedBox(16, w * -0.5, 0, w, h, color_black_alpha90)
		draw.SimpleText(team.GetName(TEAM_BLUE), "eft_3dteamname", 0, 8, team.GetColor(TEAM_BLUE), TEXT_ALIGN_CENTER)
		draw.SimpleText(team.GetScore(TEAM_BLUE).." / "..self.ScoreLimit, "eft_3dteamscore", 0, h, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		if team.HasPity(TEAM_BLUE) then
			draw.SimpleText("RAGE!", "eft_3dpity", 0, h + 8, Color(HSVtoRGB(math.abs(math.sin(CurTime() * 4)) * 50)), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

local colPlusIcon = Color(255, 255, 255)
-- And now presenting, the most expensive health bar in the world!
function GM:Draw3DHealthBar()
	local w, h = 320, 52
	local time = CurTime()
	local health = LocalPlayer():Health()

	if health <= 25 then
		colPlusIcon.a = 10 + math.abs(math.sin(time * 10) * 245)
	else
		colPlusIcon.a = 255
	end

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), -30 + self.CameraYawLerp / 3 + math.sin(time) * 8)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(-512, -512), camang, 1)

		local boxw = w * 0.1

		draw.RoundedBoxEx(16, 0, 0, boxw, h, color_black_alpha160, true, false, true, false)
		surface.SetDrawColor(0, 0, 0, 160)
		surface.DrawRect(boxw, h * 0.45, w * 0.75, h * 0.1)

		draw.SimpleText("HP", "eft_3dhealthbar", w * 0.05, h * 0.5, colPlusIcon, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if health > 0 then
			local numbox = 50
			local bw = (w - boxw) / numbox * (0.75 + math.sin(time * 2) * 0.01)
			local space = bw * 1.5
			local hx = boxw
			for i=0, 100, 100 / numbox do
				if health < i then break end

				local bh = h * math.abs(math.sin(time * 3 + i * 0.8)) + i * h * 0.01

				local r, g, b = HSVtoRGB((time * 60 + i) % 360)
				surface.SetDrawColor(r, g, b, 220)
				surface.DrawRect(hx, (h - bh) / 2, bw, bh)

				hx = hx + space
			end
		end

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

local matRing = Material("effects/select_ring")
function GM:Draw3DBallIndicator()
	local ball = self:GetBall()
	if not ball:IsValid() then return end

	local eyepos = EyePos()
	local ballpos = ball:GetPos()

	local wid, hei = 64, 64

	local dir = (ballpos - eyepos):GetNormalized()
	if eyepos:Distance(ballpos) >= 1024 then
		ballpos = eyepos + dir * 1024
		dir = (ballpos - eyepos):GetNormalized()
	end

	local ang = dir:Angle()
	ang.roll = 0
	ang:RotateAroundAxis(ang:Up(), 90)
	ang:RotateAroundAxis(ang:Right(), 180)
	ang:RotateAroundAxis(ang:Forward(), 270)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(ballpos, ang, 1)

		local ang2d = Angle(0, 0, math.sin(CurTime() * math.pi * 0.5) * 45 + 315)

		local carrier = ball:GetCarrier()
		local col = table.Copy(carrier:IsValid() and team.GetColor(carrier:Team()) or color_white)
		col.a = 200

		local autoreturn = ball:GetAutoReturn()
		if not carrier:IsValid() and autoreturn > 0 then
			local delta = autoreturn - CurTime()
			if delta <= 5 then
				draw.SimpleText(string.ToMinutesSecondsMilliseconds(math.max(0, delta)), "eft_3dballtextsmall", 0, -42, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
		end

		local dist = eyepos:Distance(ballpos)
		if dist > 256 and (dist > 2048 or util.TraceLine({start = ballpos, endpos = eyepos, mask = MASK_SOLID_BRUSHONLY}).Hit) then
			local up = ang2d:Up()
			draw.SimpleText("L", "eft_3dballtext", up.y * 50, up.z * 50, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			ang2d:RotateAroundAxis(ang2d:Forward(), 30)
			up = ang2d:Up()
			draw.SimpleText("L", "eft_3dballtext", up.y * 50, up.z * 50, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			ang2d:RotateAroundAxis(ang2d:Forward(), 30)
			up = ang2d:Up()
			draw.SimpleText("A", "eft_3dballtext", up.y * 50, up.z * 50, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			ang2d:RotateAroundAxis(ang2d:Forward(), 30)
			up = ang2d:Up()
			draw.SimpleText("B", "eft_3dballtext", up.y * 50, up.z * 50, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			local size = 64 + math.abs(math.cos(CurTime() * math.pi * 2)) ^ 2 * 12
			surface.SetMaterial(matRing)
			surface.SetDrawColor(col)
			surface.DrawTexturedRect(size * -0.5, size * -0.5, size, size)
		end

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

local EyeHullMins = Vector(-8, -8, -8)
local EyeHullMaxs = Vector(8, 8, 8)
local lerpfov
local roll = 0
local lerpdist = 256
function GM:CalcView(pl, origin, angles, fov, znear, zfar)
	local targetroll = 0

	if not GetGlobalBool("InRound", true) then
		local viewent = self:GetBall()
		if viewent:IsValid() then
			local lerp = 1
			if self.RoundEndCameraTime then
				lerp = math.Clamp(RealTime() - self.RoundEndCameraTime, 0, 1) ^ 0.5
			end

			origin:Set(viewent:LocalToWorld(viewent:OBBCenter()) * lerp + origin * (1 - lerp))

			local ang = Angle(-25, CurTime() * 25, 0)
			local tr = util.TraceHull({start = origin, endpos = origin + ang:Forward() * lerpdist, mask = MASK_SOLID_BRUSHONLY, filter = player.GetAll(), mins = EyeHullMins, maxs = EyeHullMaxs})
			local hitpos = tr.Hit and tr.HitPos + (tr.HitPos - origin):GetNormalized() * 4 or tr.HitPos

			if tr.Hit then
				lerpdist = math.min(lerpdist, hitpos:Distance(origin))
			else
				lerpdist = math.min(256, lerpdist + FrameTime() * 300)
			end

			origin = hitpos

			ang.pitch = 0
			ang:RotateAroundAxis(ang:Up(), 180)
			angles = ang

			return self.BaseClass.CalcView(self, pl, origin, angles, fov, znear, zfar)
		end
	end

	if pl:Alive() and pl:GetObserverMode() == OBS_MODE_NONE then
		if pl.LookBehind then
			angles:RotateAroundAxis(Vector(0, 0, 1), pl.LookBehind * -180)
		end

		-- 3rd person camera pos
		local camerapos = origin - angles:Forward() * 82

		pl:CallCarryFunction("GetCameraPos", camerapos, origin, angles, fov, znear, zfar)
		pl:CallStateFunction("GetCameraPos", camerapos, origin, angles, fov, znear, zfar)

		local tr = util.TraceHull({start = origin, endpos = camerapos, mask = MASK_SOLID_BRUSHONLY, mins = EyeHullMins, maxs = EyeHullMaxs})
		origin = tr.Hit and tr.HitPos + (tr.HitPos - origin):GetNormalized() * 4 or tr.HitPos

		-- FOV scaling
		local vel = pl:GetVelocity()
		local speed = vel:Length()
		fov = fov + fov * math.Clamp(math.abs(angles:Forward():Dot(vel:GetNormalized())) * ((speed - 100) / 250), 0, 1) * 0.15

		-- View rolling
		targetroll = targetroll + vel:GetNormalized():Dot(angles:Right()) * math.min(30, speed / 100)
	end

	roll = math.Approach(roll, targetroll, math.max(0.25, math.sqrt(math.abs(roll))) * 30 * FrameTime())
	angles.roll = angles.roll + roll
	lerpfov = math.Approach(lerpfov or fov, fov, FrameTime() * 60)

	return self.BaseClass.CalcView(self, pl, origin, angles, lerpfov, znear, zfar)
end

local colNameBG1 = Color(0, 0, 0, 120)
local colNameBG2 = Color(0, 0, 0, 50)
local traceTargetID = {mask = MASK_SOLID}
function GM:HUDDrawTargetID()
	local eyepos = EyePos()
	traceTargetID.start = eyepos
	traceTargetID.endpos = eyepos + EyeVector() * 1024
	traceTargetID.filter = MySelf
	local tr = util.TraceLine(traceTargetID)
	local pl = tr.Entity
	if not (pl and pl:IsValid() and pl:IsPlayer()) then return end

	local font = "TargetID"
	local text = pl:Name()
	local col = team.GetColor(pl:Team())

	local x = ScrW() / 2
	local y = ScrH() / 2

	y = y + 30

	draw.SimpleText(text, font, x + 1, y + 1, colNameBG1, TEXT_ALIGN_CENTER)
	draw.SimpleText(text, font, x + 2, y + 2, colNameBG2, TEXT_ALIGN_CENTER)
	draw.SimpleText(text, font, x, y, col, TEXT_ALIGN_CENTER)

	local w, h = surface.GetTextSize(text)
	y = y + h + 5

	local text = pl:Health() .. "%"
	local font = "TargetIDSmall"

	draw.SimpleText(text, font, x + 1, y + 1, colNameBG1, TEXT_ALIGN_CENTER)
	draw.SimpleText(text, font, x + 2, y + 2, colNameBG2, TEXT_ALIGN_CENTER)
	draw.SimpleText(text, font, x, y, col, TEXT_ALIGN_CENTER)
end

local color_black_alpha60 = Color(10, 10, 10, 60)
function GM:DrawBallLineHUD()
	local ball = self:GetBall()
	if ball:IsValid() then
		local redcenter = ball:GetRedGoalCenter()
		local bluecenter = ball:GetBlueGoalCenter()
		local ballpos = ball:GetPos()
		local wid, hei = 200, 32
		draw.RoundedBox(4, 0, 0, wid, hei, color_black_alpha60)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawLine(16, hei * 0.5, wid - 16, hei * 0.5)
		surface.SetDrawColor(255, 10, 10, 255)
		surface.DrawRect(8, hei * 0.5 - 4, 8, 8)
		surface.SetDrawColor(20, 20, 255, 255)
		surface.DrawRect(wid - 16, hei * 0.5 - 4, 8, 8)
		local totaldist = redcenter:Distance(bluecenter)
		if totaldist > 0 then
			local balldistfromred = math.min(ballpos:Distance(redcenter), totaldist)
			local balldistfromblue = math.min(ballpos:Distance(bluecenter), totaldist)
			local halfline = wid - 32
			local carrier = ball:GetCarrier()
			local col = carrier:IsValid() and carrier:IsPlayer() and team.GetColor(carrier:Team()) or color_white
			if balldistfromred < balldistfromblue then
				surface.DrawCircle(16 + (balldistfromred / totaldist) * halfline, hei * 0.5, 4, col)
			else
				surface.DrawCircle((wid - 16) - (balldistfromblue / totaldist) * halfline, hei * 0.5, 4, col)
			end
		end
	end
end

function GM:DrawCrosshair()
	local pl = LocalPlayer()
	if not pl:IsValid() then return end

	if not pl:CallCarryFunction("ShouldDrawCrosshair") and not pl:CallStateFunction("ShouldDrawCrosshair") then return end

	local w, h = ScrW(), ScrH()
	local x, y = w / 2, h /2
	local screenscale = math.Clamp(h / 1080, 0.5, 1)
	local size = screenscale * 64
	local rotation = CurTime() * 180 % 360

	surface.SetMaterial(matRing)
	for i=1, 3 do
		surface.SetDrawColor(255, 255, 255, 100 - i * 30)
		surface.DrawTexturedRectRotated(x, y, size, size, rotation)

		size = size * 1.25
	end

	if not (wep and wep:IsValid() and wep.ShouldDrawAngleFinder and wep:ShouldDrawAngleFinder() or pl:CallStateFunction("ShouldDrawAngleFinder")) then return end

	local pitch = pl:EyeAngles().pitch
	local pitchy = pitch / 180
	x = x + size / 2 + 16
	h = h / 4

	surface.SetDrawColor(255, 255, 255, 60)
	local on = true
	for i=0, h, 8 do
		if on then
			surface.DrawRect(x, y - h / 2 + i, 2, math.min(8, h - i))
		end
		on = not on
	end

	surface.SetDrawColor(255, 0, 0, 100)
	surface.DrawRect(x - 8, y + pitchy * h - 4, 8, 4)
end

local matScreenCrack = CreateMaterial("eft_screencrack", "UnlitGeneric", {
	["$basetexture"] = "Decals/rollermine_crater",
	["$nodecal"] = 1,
	--["$additive"] = 1,
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1,
	["$nocull"] = 1,
	["$ignorez"] = 1
})
local ScreenCracks = {}

function GM:AddScreenCrack()
	table.insert(ScreenCracks, {DieTime = CurTime() + 5, x = math.Rand(0.2, 0.8), y = math.Rand(0.2, 0.8), size = math.Rand(0.2, 0.35), rot = math.Rand(0, 360)})
end

function GM:OnHUDPaint()
	self:DrawBallLineHUD()
	self:DrawCrosshair()

	if #ScreenCracks == 0 then return end

	local time = CurTime()
	local w, h = ScrW(), ScrH()

	surface.SetMaterial(matScreenCrack)
	local done = true
	for _, crack in pairs(ScreenCracks) do
		if time >= crack.DieTime then continue end

		done = false

		local size = h * crack.size
		surface.SetDrawColor(255, 255, 255, math.Clamp((crack.DieTime - time) * 255, 0, 200))
		surface.DrawTexturedRectRotated(w * crack.x, h * crack.y, size, size, crack.rot)
	end

	if done then
		ScreenCracks = {}
	end
end

function GM:UpdateHUD_Alive( InRound )

	if ( GAMEMODE.RoundBased || GAMEMODE.TeamBased ) then
	
		local Bar = vgui.Create( "DHudBar" )
		GAMEMODE:AddHUDItem( Bar, 2 )

		if ( GAMEMODE.TeamBased && GAMEMODE.ShowTeamName ) then
		
			local TeamIndicator = vgui.Create( "DHudUpdater" );
				TeamIndicator:SizeToContents()
				TeamIndicator:SetValueFunction( function() 
													return team.GetName( LocalPlayer():Team() )
												end )
				TeamIndicator:SetColorFunction( function() 
													return team.GetColor( LocalPlayer():Team() )
												end )
				TeamIndicator:SetFont( "HudSelectionText" )
			Bar:AddItem( TeamIndicator )
			
		end
		
		if ( GAMEMODE.RoundBased ) then 
		
			local RoundNumber = vgui.Create( "DHudUpdater" );
				RoundNumber:SizeToContents()
				RoundNumber:SetValueFunction( function() return GetGlobalInt( "RoundNumber", 0 ) end )
				RoundNumber:SetLabel( "ROUND" )
			Bar:AddItem( RoundNumber )
			
			local RoundTimer = vgui.Create( "DHudCountdown" );
				RoundTimer:SizeToContents()
				RoundTimer:SetValueFunction( function() 
												if ( GetGlobalFloat( "RoundStartTime", 0 ) > CurTime() ) then return GetGlobalFloat( "RoundStartTime", 0 )  end 
												return GAMEMODE:GetTimeLimit() end )
				RoundTimer:SetLabel( "TIME" )
			Bar:AddItem( RoundTimer )

		end
		
	end

end

function GM:EndOfGame(winner)
	self.GameWinner = winner
	self.GameEndTime = CurTime()
end

function GM:TeamScored(teamid, hitter, points)
	if not MySelf:IsValid() then return end

	if teamid == MySelf:Team() or not team.Joinable(MySelf:Team()) then
		surface.PlaySound("vo/coast/odessa/male01/nlo_cheer0"..math.random(4)..".wav")
	else
		surface.PlaySound("npc/dog/dog_on_dropship.wav")
	end

	self.RoundWinner = teamid
	self.RoundEndScroll = 0
	self.RoundEndCameraTime = RealTime()
end
net.Receive("eft_teamscored", function(length)
	local teamid = net.ReadUInt(8)
	local pl = net.ReadEntity()
	local points = net.ReadUInt(8)

	gamemode.Call("TeamScored", teamid, pl, points)
end)

net.Receive("eft_localsound", function(length)
	local soundfile = net.ReadString()
	local pitch = net.ReadFloat()
	local vol = net.ReadFloat()

	if LocalPlayer():IsValid() then
		LocalPlayer():EmitSound(soundfile, 0, pitch, vol)
	end
end)

net.Receive("eft_endofgame", function(length)
	local winner = net.ReadUInt(8)

	gamemode.Call("EndOfGame", winner)
end)

net.Receive("eft_screencrack", function(length)
	GAMEMODE:AddScreenCrack()
end)

-- Temporary fix
function render.DrawQuadEasy(pos, dir, xsize, ysize, color, rotation)
	xsize = xsize / 2
	ysize = ysize / 2

	local ang = dir:Angle()

	if rotation then
		ang:RotateAroundAxis(ang:Forward(), rotation)
	end

	local upoffset = ang:Up() * ysize
	local rightoffset = ang:Right() * xsize

	render.DrawQuad(pos - upoffset - rightoffset, pos - upoffset + rightoffset, pos + upoffset + rightoffset, pos + upoffset - rightoffset, color)
end
