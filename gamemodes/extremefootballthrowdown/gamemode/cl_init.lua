include("sh_globals.lua")

include("cl_obj_entity_extend.lua")
include("cl_obj_player_extend.lua")

include("shared.lua")

--[[include("animationsapi/cl_boneanimlib.lua")
include("animationsapi/cl_animeditor.lua")]]

include("cl_draw.lua")
include("cl_postprocess.lua")

include("vgui/dex3dnotification.lua")

GM.LerpRateOn = 10
GM.LerpRateOff = 8

local OldHealth = 0
local LastHealthLoss = 0
local PrevFrameHealth = 100
local color_black_alpha160 = Color(0, 0, 0, 160)
local color_black_alpha90 = Color(0, 0, 0, 90)

local vector_origin = vector_origin
local STEPSOUNDTIME_NORMAL = STEPSOUNDTIME_NORMAL
local STEPSOUNDTIME_WATER_FOOT = STEPSOUNDTIME_WATER_FOOT
local STEPSOUNDTIME_ON_LADDER = STEPSOUNDTIME_ON_LADDER
local STEPSOUNDTIME_WATER_KNEE = STEPSOUNDTIME_WATER_KNEE
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local TEXT_ALIGN_TOP = TEXT_ALIGN_TOP
local TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM
local TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
local TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT
local SCALE3D2D = SCALE3D2D
local SCALE3D2DI = SCALE3D2DI
local SCALE3D2D_LARGE = SCALE3D2D_LARGE
local SCALE3D2D_LARGEI = SCALE3D2D_LARGEI
local bit_band = bit.band
local MOVETYPE_WALK = MOVETYPE_WALK
--local IN_DUCK = IN_DUCK
local ScrH = ScrH
local math_max = math.max
local math_min = math.min

local tempColRed = Color(1, 1, 1)
local tempColBlue = Color(1, 1, 1)

GM.ThrowingGuide = CreateClientConVar("eft_throwingguide", "1", true, false):GetBool()
cvars.AddChangeCallback("eft_throwingguide", function(cvar, oldvalue, newvalue)
	GAMEMODE.ThrowingGuide = tonumber(newvalue) == 1
end)

MySelf = MySelf or NULL
hook.Add("InitPostEntity", "GetLocal", function()
	MySelf = LocalPlayer()

	GAMEMODE.HookGetLocal = GAMEMODE.HookGetLocal or (function(g) end)
	gamemode.Call("HookGetLocal", MySelf)
	RunConsoleCommand("initpostentity")
end)

language.Add("prop_ball", "Ball")

function BetterScreenScale()
	return math_max(0.6, math_min(1, ScrH() / 1080))
end

function GM:HookGetLocal()
	self.CreateMove = self._CreateMove
	self.PostDrawTranslucentRenderables = self._PostDrawTranslucentRenderables
	self.PrePlayerDraw = self._PrePlayerDraw
	self.PostPlayerDraw = self._PostPlayerDraw
end

local matRing = Material("effects/select_ring")
function GM:DrawCircle(x, y, radius, color)
	surface.SetMaterial(matRing)
	surface.SetDrawColor(color)
	surface.DrawTexturedRect(x - radius, y - radius, radius * 2, radius * 2)
end

function GM:HUDShouldDraw(name)
	if name == "CHudCrosshair" or name == "CHudHealth" or name == "CHudBattery" or name == "CHudDamageIndicator" then
		return false
	end

	return self.BaseClass.HUDShouldDraw(self, name)
end

function GM:PlayerStepSoundTime(pl, iType, bWalking)
	if iType == STEPSOUNDTIME_NORMAL or iType == STEPSOUNDTIME_WATER_FOOT then
		return math_max(200, 520 - pl:GetVelocity():Length())
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

	-- Prevent ducking unless on the ground or swimming.
	--[[if bit_band(cmd:GetButtons(), IN_DUCK) ~= 0 and MySelf:GetMoveType() == MOVETYPE_WALK and not MySelf:OnGround() and not MySelf:IsSwimming() and MySelf:Alive() then
		cmd:SetButtons(cmd:GetButtons() - IN_DUCK)
	end]]

	local ang = cmd:GetViewAngles()

	self.CameraYawLerp = math.Clamp(self.CameraYawLerp + math.AngleDifference(self.PrevCameraYaw, ang.yaw) * FrameTime() * 120, -90, 90)
	self.CameraYawLerp = math.Approach(self.CameraYawLerp, 0, FrameTime() * math_max(15, math.abs(self.CameraYawLerp) ^ 1.15))
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

local HealthBarDistance = 1024
local HealthBarDistanceEnemy = 768
local colFriend = Color(10, 255, 10, 200)
local colFriendOT = Color(255, 160, 0, 200)
local vecUp = Vector(0, 0, 1)
local vecDown = Vector(0, 0, -1)
local matFriendRing = Material("SGM/playercircle")
function GM:_PostPlayerDraw(pl)
	if pl ~= MySelf then
		local myteam = MySelf:Team()
		local isobs = myteam == TEAM_SPECTATOR
		local teamid = pl:Team()
		local pos = pl:GetPos() + Vector(0, 0, 10)

		if pl:IsFriend() then
			local col = teamid == myteam and colFriend or colFriendOT
			render.SetMaterial(matFriendRing)
			render.DrawQuadEasy(pos, vecUp, 32, 32, col)
			render.DrawQuadEasy(pos, vecDown, 32, 32, col)
		end

		local eyepos = EyePos()
		local dist = pos:Distance(eyepos)
		local maxdist = teamid == myteam and HealthBarDistance or HealthBarDistanceEnemy
		if isobs or pos:Distance(eyepos) <= maxdist then
			local camang = EyeAngles3D2D()
			local col = teamid == TEAM_RED and tempColRed or tempColBlue
			local fade
			if not isobs and dist > maxdist / 2 then
				fade = 1 - (dist - maxdist / 2) / maxdist * 2
			else
				fade = 1
			end

			col.a = fade * 255
			if pl:Health() < 25 then
				col.a = col.a * math.abs(math.sin((CurTime() + pl:EntIndex()) * 7))
			end

			camang[3] = 90

			--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
			--render.PushFilterMag(TEXFILTER.ANISOTROPIC)

			cam.Start3D2D(pos + camang:Up() * 20, camang, (1 + fade) * 0.1 * SCALE3D2DI)
			--cam.IgnoreZ(true)

			--draw.SimpleTextBlurBG(pl:Name().." ("..pl:Health().."%)", "eft_3dothernametext", 0, 0, col, TEXT_ALIGN_CENTER)
			draw.SimpleTextBlurBG(pl:Name(), "eft_3dothernametext", 0, 0, col, TEXT_ALIGN_CENTER)

			--cam.IgnoreZ(false)
			cam.End3D2D()

			--render.PopFilterMin()
			--render.PopFilterMag()
		end
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

		if pl:Alive() and pl:GetObserverMode() == OBS_MODE_NONE then
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

		if pl == lp then
			self:HealthThink(pl)
		end
	end
end

function GM:HealthThink(pl)
	local newhealth = pl:Health()
	if newhealth ~= PrevFrameHealth then
		if newhealth < PrevFrameHealth then
			LastHealthLoss = CurTime()
			OldHealth = PrevFrameHealth
		else
			LastHealthLoss = 0
			OldHealth = newhealth
		end
		PrevFrameHealth = newhealth
	end
end

function GM:DrawPlayerRing(pl)
end

function GM:PostProcessPermitted()
	return false
end

function GM:PositionScoreboard(ScoreBoard)
	ScoreBoard:SetSize(math_min(800, ScrW() - 32), math_min(800, ScrH() - 32))
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
	local f, i, q, t

	-- Make sure our arguments stay in-range
	h = math_max(0, math_min(360, h))

	s = 1
	v = 1

	if s == 0 then
		-- Achromatic (grey)
		local gray = math.floor(v * 255)
		return Color(gray, gray, gray)
	end

	h = h / 60 -- sector 0 to 5
	i = math.floor(h)
	f = h - i -- factorial part of h
	q = v * (1 - f)
	t = v * (1 - (1 - f))

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

	return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
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

	MySelf:CallStateFunction("PreDraw3DHUD")

	cam.Start3D(EyePos(), EyeAngles(), 90)

	if self.TieBreaker then
		self:Draw3DTieBreaker()

		MySelf:CallStateFunction("Draw3DHUD")
	else
		if team.Joinable(MySelf:Team()) and MySelf:Team() ~= TEAM_SPECTATOR then
			self:Draw3DHealthBar()
			self:Draw3DWeapon()
			self:Draw3DPotentialWeapon()
			self:Draw3DGoalIndicator()

			MySelf:CallStateFunction("Draw3DHUD")
		end

		self:Draw3DBallPowerup()
		self:Draw3DTeamScores()
		self:Draw3DGameState()
	end

	self:Draw3DNotices()

	cam.End3D()
end

local PotentialWeaponName = ""
local PotentialWeaponLerp = 0
local colBG = Color(0, 0, 0, 0)
function GM:Draw3DPotentialWeapon()
	local pwep = MySelf:GetPotentialCarry()
	local wep = MySelf:GetCarry()
	if not IsValid(wep) and pwep and pwep:IsValid() and pwep.GetCarrier and not pwep:GetCarrier():IsValid() and pwep.Name then
		PotentialWeaponName = string.upper(pwep.Name)
		PotentialWeaponLerp = math.Approach(PotentialWeaponLerp, 1, FrameTime() * self.LerpRateOn)
	else
		PotentialWeaponLerp = math.Approach(PotentialWeaponLerp, 0, FrameTime() * self.LerpRateOff)
	end

	if PotentialWeaponLerp == 0 then return end

	colBG.a = PotentialWeaponLerp * 90

	local col = Color(HSVtoRGB((CurTime() * 180) % 360))
	col.a = PotentialWeaponLerp * 255

	--local w, h = 460, 40

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), self.CameraYawLerp / 3)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(0, -300), camang, SCALE3D2D_LARGEI)

		--draw.RoundedBox(16, w * -0.5, 0, w, h, color_black_alpha90)
		draw.SimpleTextBlurBG("["..(input.LookupBinding("+use") or "USE").."] PICK UP "..PotentialWeaponName, "eft_3dweapon", 0, 0 --[[h / 2]], col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

local WeaponName = ""
local WeaponLerp = 0
function GM:Draw3DWeapon()
	local wep = MySelf:GetCarry()
	if wep and wep:IsValid() and wep.Name then
		WeaponName = string.upper(wep.Name)
		WeaponLerp = math.Approach(WeaponLerp, 1, FrameTime() * self.LerpRateOn)
	else
		WeaponLerp = math.Approach(WeaponLerp, 0, FrameTime() * self.LerpRateOff)
	end

	if WeaponLerp == 0 then return end

	colBG.a = WeaponLerp * 90

	local col = Color(HSVtoRGB((CurTime() * 180) % 360))
	col.a = WeaponLerp * 255

	--local w, h = 300, 40

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), 30 + self.CameraYawLerp / 3)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(400, -450), camang, SCALE3D2D_LARGEI)

		--draw.RoundedBox(16, w * -0.5, 0, w, h, color_black_alpha90)
		draw.SimpleTextBlurBG(WeaponName.."!", "eft_3dweapon", 0, 0 --[[h / 2]], col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

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
	cam.Start3D2D(EyePos3D2DScreen(0, 250), camang, SCALE3D2D_LARGEI)

		draw.SimpleTextBlurBG("GO >>>", "eft_3dteamscore", 0, 0, Color(HSVtoRGB((CurTime() * 180) % 360)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

net.Receive("eft_nearestgoal", function(length)
	GAMEMODE.NearestGoal = net.ReadVector()
end)

function GM:CreateFonts()
	local blursize = 8 * SCALE3D2D
	local blursize_large = 8 * SCALE3D2D_LARGE

	local function create(name, size, face)
		face = face or "coolvetica"

		surface.CreateFont(name, {font = face, size = size * SCALE3D2D, weight = 0, antialias = true, shadow = false, outline = false})
		surface.CreateFont(name.."_shd", {font = face, size = size * SCALE3D2D, weight = 0, antialias = true, shadow = false, outline = false, blursize = blursize})
	end

	local function create_large(name, size, face)
		face = face or "coolvetica"

		surface.CreateFont(name, {font = face, size = size * SCALE3D2D_LARGE, weight = 0, antialias = true, shadow = false, outline = false})
		surface.CreateFont(name.."_shd", {font = face, size = size * SCALE3D2D_LARGE, weight = 0, antialias = true, shadow = false, outline = false, blursize = blursize_large})
	end

	surface.CreateFont("eft_3dstruggleicon", {font = "coolvetica", size = 48, weight = 1000, antialias = true, shadow = false, outline = false})
	surface.CreateFont("eft_3dstruggleicon_shd", {font = "coolvetica", size = 48, weight = 1000, antialias = true, shadow = false, outline = false, blursize = 8})

	surface.CreateFont("eft_3dstruggletext", {font = "coolvetica", size = 24, weight = 0, antialias = true, shadow = false, outline = false})
	surface.CreateFont("eft_3dpowertext", {font = "coolvetica", size = 40, weight = 0, antialias = true, shadow = false, outline = false})
	surface.CreateFont("eft_3dheadertext", {font = "coolvetica", size = 72, weight = 500, antialias = true, shadow = false, outline = false})

	create("eft_3dhealthbar", 28)
	create("eft_3dothernametext", 48)
	create_large("eft_3dpoweruptext", 64)
	create_large("eft_3dpoweruptimetext",  48)
	create_large("eft_3dweapon", 48)
	create("eft_3dteamname", 32)
	create("eft_3dteamscore", 40)
	create("eft_3dpity", 28)
	create("eft_3dballtext", 32)
	create("eft_3dballtextsmall", 24)
	create("eft_3dnotice", 40)

	surface.CreateFont("eft_3dwinnertext", {font = "coolvetica", size = 128, weight = 500, antialias = true, shadow = false, outline = false})
	surface.CreateFont("eft_3djerseytext", {font = "coolvetica", size = 64, weight = 500, antialias = true, shadow = false, outline = false})
end

function GM:Initialize()
	self.BaseClass.Initialize(self)

	hook.Remove("PrePlayerDraw", "DrawPlayerRing")

	tempColRed = table.Copy(team.GetColor(TEAM_RED))
	tempColBlue = table.Copy(team.GetColor(TEAM_BLUE))

	self:RegisterWeapons()
	self:CreateFonts()
	self:PrecacheResources()
end

function GM:Draw3DBallPowerup()
	local ball = self:GetBall()
	if not ball:IsValid() then return end

	if ball:GetState() == BALL_STATE_NONE then return end

	local time = CurTime()
	local statetable = ball:GetStateTable()
	local col = table.Copy(ball:CallStateFunction("GetBallColor", ball:GetCarrier()) or color_white)
	local timeleft = ball:GetStateEnd() == 0 and -1 or math_max(0, ball:GetStateEnd() - time)
	local fadein
	if timeleft == -1 then
		fadein = math.Clamp((time - ball:GetStateStart()) / 0.5, 0, 1)
	else
		fadein = math.Clamp(math_min(timeleft, time - ball:GetStateStart()) / 0.5, 0, 1)
	end

	col.a = 255 * fadein * (1 - math.abs(math.sin(time * math.pi * 4)) * 0.25)

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), self.CameraYawLerp / 3)
	camang:RotateAroundAxis(camang:Forward(), 15)
	camang:RotateAroundAxis(camang:Up(), (1 - fadein) * 720)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(0, 400), camang, (1 + math.abs(math.sin(time * math.pi * 2)) ^ 4 * 0.25) * SCALE3D2D_LARGEI)

		if statetable.Name then
			draw.SimpleTextBlurBG(string.upper(statetable.Name), "eft_3dpoweruptext", 0, -2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
		if timeleft ~= -1 then
			col.r = 255 col.g = 255 col.b = 255
			draw.SimpleTextBlurBG(util.ToMinutesSecondsMilliseconds(timeleft), "eft_3dpoweruptimetext", 0, 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
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
			draw.SimpleText("V I C T O R Y", "eft_3dwinnertext", 0, -16 - rfadein * 1000, Color(HSVtoRGB((time * 180) % 360)), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			draw.SimpleText(team.GetName(winner), "eft_3dwinnertext", 0, 16 + rfadein * 1000, team.GetColor(winner), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
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

		draw.SimpleText(self.RoundHomeRun and "HOME RUN!!" or "TOUCH DOWN!!", "eft_3dwinnertext", 0, 0, barcol, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

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

		draw.SimpleText(string.upper(team.GetName(winner)), "eft_3dwinnertext", 0, 2, col, TEXT_ALIGN_CENTER)

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

	if self.RoundEndScrollOT then
		self:Draw3DOvertime()
	elseif self:IsWarmUp() then
		self:Draw3DWarmUp()
	end
end

function GM:Draw3DWarmUp()
	local realtime = RealTime()

	local barcol = Color(HSVtoRGB(math.abs(math.sin(realtime * 6)) * 60))

	local ang = EyeAngles3D2D()
	ang:RotateAroundAxis(ang:Forward(), 30)
	ang:RotateAroundAxis(ang:Right(), self.CameraYawLerp / 3)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(0, 256), ang, 0.9)

		draw.SimpleText("WARM UP: "..math.ceil(self.WarmUpLength - CurTime()), "eft_3dwinnertext", 0, 0, barcol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

function GM:Draw3DOvertime()
	if self.RoundEndScrollOT >= 1 then return end

	local realtime = RealTime()

	self.RoundEndScrollOT = self.RoundEndScrollOT + RealFrameTime() * (math.abs(self.RoundEndScrollOT - 0.5) <= 0.1 and 0.03 or 0.5)

	local distfromcenter = math.abs(self.RoundEndScrollOT - 0.5) * 2
	local size = 1.25 - distfromcenter * 0.5
	local barcol = Color(HSVtoRGB((realtime * 400) % 360))

	local ang = EyeAngles3D2D()
	ang:RotateAroundAxis(ang:Forward(), -30)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(1200 - self.RoundEndScrollOT * 2400, 0), ang, size)

		draw.SimpleText("OVER TIME!", "eft_3dwinnertext", 0, 0, barcol, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

local W_TEAMSCORES = 128 * SCALE3D2D
local H_TEAMSCORES = 80 * SCALE3D2D
--local X_TEAMSCORES = W_TEAMSCORES * -0.5
local Y_TEAMSCORES = 4 * SCALE3D2D
function GM:Draw3DTeamScores()
	local carryteam = self.Ball:IsValid() and self.Ball:GetCarrier():IsValid() and self.Ball:GetCarrier():Team()

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), -30 + self.CameraYawLerp / 3)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(-400, 500), camang, SCALE3D2DI)
		--draw.RoundedBox(16 * SCALE3D2D, X_TEAMSCORES, 0, W_TEAMSCORES, H_TEAMSCORES, color_black_alpha90)
		if carryteam == TEAM_RED then
			draw.SimpleTextBlurBG("▼", "eft_3dteamname", 0, math.sin(RealTime() * 3) ^ 2 * -8 * SCALE3D2D, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
		draw.SimpleTextBlurBG(team.GetName(TEAM_RED), "eft_3dteamname", 0, Y_TEAMSCORES, team.GetColor(TEAM_RED), TEXT_ALIGN_CENTER)
		draw.SimpleTextBlurBG(team.GetScore(TEAM_RED).." / "..self.ScoreLimit, "eft_3dteamscore", 0, H_TEAMSCORES, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		if team.HasPity(TEAM_RED) then
			draw.SimpleTextBlurBG("RAGE!", "eft_3dpity", 0, H_TEAMSCORES + 8, Color(HSVtoRGB(math.abs(math.sin(CurTime() * 4)) * 50)), TEXT_ALIGN_CENTER)
		end

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()

	camang:RotateAroundAxis(camang:Right(), 60)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(400, 500), camang, SCALE3D2DI)
		--draw.RoundedBox(16 * SCALE3D2D, X_TEAMSCORES, 0, W_TEAMSCORES, H_TEAMSCORES, color_black_alpha90)
		if carryteam == TEAM_BLUE then
			draw.SimpleTextBlurBG("▼", "eft_3dteamname", 0, math.sin(RealTime() * 3) ^ 2 * -8 * SCALE3D2D, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
		draw.SimpleTextBlurBG(team.GetName(TEAM_BLUE), "eft_3dteamname", 0, Y_TEAMSCORES, team.GetColor(TEAM_BLUE), TEXT_ALIGN_CENTER)
		draw.SimpleTextBlurBG(team.GetScore(TEAM_BLUE).." / "..self.ScoreLimit, "eft_3dteamscore", 0, H_TEAMSCORES, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		if team.HasPity(TEAM_BLUE) then
			draw.SimpleTextBlurBG("RAGE!", "eft_3dpity", 0, H_TEAMSCORES, Color(HSVtoRGB(math.abs(math.sin(CurTime() * 4)) * 50)), TEXT_ALIGN_CENTER)
		end

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

local Notices = {}
function GM:Draw3DNotices()
	if #Notices == 0 then return end

	local camang = EyeAngles3D2D()
	local time = UnPredictedCurTime()

	--local fwd = camang:Forward()
	camang:RotateAroundAxis(camang:Right(), self.CameraYawLerp / 3)
	--camang:RotateAroundAxis(fwd, 30)
	camang:RotateAroundAxis(camang:Forward(), 30)

	surface.DisableClipping(true)
	DisableClipping(true)

	local done = true

	local y = -300
	local bulge, size, t, x

	for i, notice in pairs(Notices) do
		if notice.Done then continue end

		if time < notice.EndTime then
			size = 1

			-- bulge from certain slot
			bulge = math.Clamp(1 - math.abs(i - 4) / 4, 0, 1)

			t = math.Clamp((time - notice.StartTime) / (notice.EndTime - notice.StartTime), 0, 1)

			size = size + math.Clamp(0.1 - t, 0, 1) ^ 2 * 2
			size = size + bulge * 0.25

			done = false
			cam.IgnoreZ(true)
			cam.Start3D2D(EyePos3D2DScreen(0, -300 + i * 48 + bulge * 12), camang, size * SCALE3D2DI)

			notice.Panel:SetPaintedManually(false)
			notice.Panel:PaintManual()
			notice.Panel:SetPaintedManually(true)

			cam.End3D2D()
			cam.IgnoreZ(false)

			camang:RotateAroundAxis(camang:Forward(), -5)
		else
			notice.Done = true
			notice.Panel:Remove()
		end
	end

	surface.DisableClipping(false)
	DisableClipping(false)

	if done then Notices = {} end
end

function GM:Add3DNotice(...)
	local panel = vgui.Create("DEX3DNotification")
	panel:SetNotification(...)
	panel:SetAlpha(0)
	panel:AlphaTo(255, 0.2)
	panel:AlphaTo(0, 0.2, 4.8)

	if #Notices >= 5 then
		table.remove(Notices, 1)
	end

	table.insert(Notices, {Panel = panel, EndTime = UnPredictedCurTime() + 5, StartTime = UnPredictedCurTime()})
end

local colPlusIcon = Color(255, 255, 255)
-- And now presenting, the most expensive health bar in the world!
local numbox = 25
local step = 100 / numbox
local healthw, healthh = 320 * SCALE3D2D, 52 * SCALE3D2D
local boxw = healthw * 0.1
local hpr_1 = healthh * 0.45
local hpr_2 = healthw * 0.75
local hpr_3 = healthh * 0.1
local hpr_4 = healthw * 0.05
local hpr_5 = healthh * 0.5
local hpr_6 = healthh * 0.01
function GM:Draw3DHealthBar()
	local time = CurTime()
	local health = OldHealth
	local lp = LocalPlayer()
	local realhealth = lp:Health()
	local d

	if health ~= realhealth then
		d = math.Clamp(1 - (time - LastHealthLoss) * 2, 0, 1)
	end

	if realhealth <= 25 then
		colPlusIcon.a = 10 + math.abs(math.sin(time * 10) * 245)
	else
		colPlusIcon.a = 255
	end

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), -30 + self.CameraYawLerp / 3)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(-512, -512), camang, SCALE3D2DI)

		--draw.RoundedBoxEx(16, 0, 0, boxw, healthh, color_black_alpha160, true, false, true, false)
		surface.SetDrawColor(0, 0, 0, 160)
		surface.DrawRect(boxw, hpr_1, hpr_2, hpr_3)

		draw.SimpleText("HP", "eft_3dhealthbar", hpr_4, hpr_5, colPlusIcon, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if lp:Alive() and health > 0 then
			local bw = (healthw - boxw) / numbox * (0.75 + math.sin(time * 2) * 0.01)
			local space = bw * 1.5
			local hx = boxw
			local r, g, b
			local t60 = time * 60
			local t3 = time * 3
			for i=0, 100, step do
				if health < i then break end

				local bh = healthh * math.abs(math.sin(t3 + i * 0.8)) + i * hpr_6

				if realhealth < i then
					surface.SetDrawColor(255, 255, 255, d * 220)
				else
					r, g, b = HSVtoRGB((t60 + i) % 360)
					surface.SetDrawColor(r, g, b, 220)
				end

				surface.DrawRect(hx, (healthh - bh) / 2, bw, bh)

				hx = hx + space
			end
		end

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end

local extend = 50 * SCALE3D2D
function GM:Draw3DBallIndicator()
	local ball = self:GetBall()
	if not ball:IsValid() then return end

	local eyepos = EyePos()
	local ballpos = ball:GetPos()

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
	cam.Start3D2D(ballpos, ang, SCALE3D2DI)

		local ang2d = Angle(0, 0, math.sin(CurTime() * math.pi * 0.5) * 45 + 315)

		local carrier = ball:GetCarrier()
		local col = table.Copy(carrier:IsValid() and team.GetColor(carrier:Team()) or color_white)
		col.a = 200

		local autoreturn = ball:GetAutoReturn()
		if not carrier:IsValid() and autoreturn > 0 then
			local delta = autoreturn - CurTime()
			if delta <= 5 then
				--draw.SimpleText(string.ToMinutesSecondsMilliseconds(math_max(0, delta)), "eft_3dballtextsmall", 0, -42, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				draw.SimpleTextBlurBG(string.format("%.2f", math_max(0, delta)), "eft_3dballtextsmall", 0, -42 * SCALE3D2D, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
		end

		local dist = eyepos:Distance(ballpos)
		if dist > 256 and (dist > 2048 or util.TraceLine({start = ballpos, endpos = eyepos, mask = MASK_SOLID_BRUSHONLY}).Hit) then
			local up = extend * ang2d:Up()
			draw.SimpleTextBlurBG("L", "eft_3dballtext", up.y, up.z, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			ang2d:RotateAroundAxis(ang2d:Forward(), 30)
			up = extend * ang2d:Up()
			draw.SimpleTextBlurBG("L", "eft_3dballtext", up.y, up.z, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			ang2d:RotateAroundAxis(ang2d:Forward(), 30)
			up = extend * ang2d:Up()
			draw.SimpleTextBlurBG("A", "eft_3dballtext", up.y, up.z, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			ang2d:RotateAroundAxis(ang2d:Forward(), 30)
			up = extend * ang2d:Up()
			draw.SimpleTextBlurBG("B", "eft_3dballtext", up.y, up.z, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			local size = (64 + math.abs(math.cos(CurTime() * math.pi * 2)) ^ 2 * 12) * SCALE3D2D
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

			local carrier = viewent:GetCarrier()
			if carrier and carrier:IsValid() then viewent = carrier end

			origin:Set(viewent:LocalToWorld(viewent:OBBCenter()) * lerp + origin * (1 - lerp))

			local ang = Angle(-25, CurTime() * 25, 0)
			local tr = util.TraceHull({start = origin, endpos = origin + ang:Forward() * lerpdist, mask = MASK_SOLID_BRUSHONLY, filter = player.GetAll(), mins = EyeHullMins, maxs = EyeHullMaxs})
			local hitpos = tr.Hit and tr.HitPos + (tr.HitPos - origin):GetNormalized() * 4 or tr.HitPos

			if tr.Hit then
				lerpdist = math_min(lerpdist, hitpos:Distance(origin))
			else
				lerpdist = math_min(256, lerpdist + FrameTime() * 300)
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
		targetroll = targetroll + vel:GetNormalized():Dot(angles:Right()) * math_min(30, speed / 100)
	end

	roll = math.Approach(roll, targetroll, math_max(0.25, math.sqrt(math.abs(roll))) * 30 * FrameTime())
	angles.roll = angles.roll + roll
	lerpfov = math.Approach(lerpfov or fov, fov, FrameTime() * 60)

	return self.BaseClass.CalcView(self, pl, origin, angles, lerpfov, znear, zfar)
end

function GM:HUDDrawTargetID()
end

GM.CurrentTransition = TRANSITION_SLIDE
function GM:RenderScreenspaceEffects()
	self:DoPostProcessing()

	--[[local curtime = CurTime()
	local starttime = GetGlobalFloat("RoundStartTime", 0)
	if math.abs(curtime - starttime) <= 0.5 then
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, ScrW(), ScrH())
	elseif curtime < starttime then
		if curtime >= starttime - 1.5 then
			local delta = math_min(starttime - (curtime - 0.5), 1)
			if delta > 0 then
				TRANSITIONS[self.CurrentTransition]:In(delta, ScrW(), ScrH())
			end
		end
	elseif curtime < starttime + 1.5 then
		local delta = 1 - math_min((curtime + 0.5) - starttime, 1)
		if delta > 0 then
			TRANSITIONS[self.CurrentTransition]:Out(delta, ScrW(), ScrH())
		end
	end]]
end

local MinimapCamera = {
	drawhud = false,
	drawviewmodel = false,
	fov = 0,
	ortho = true,
	znear = 32,
	zfar = 32000
}

local MinimapRT
local MinimapMaterial

local MinimapCameraUp = Vector(1, 0)
local MinimapCameraRight = Vector(0, 1)
local MinimapCameraScale = 1
local MinimapCameraOffset = vector_origin
local function MinimapWorldToScreen(pos)
	pos = MinimapCamera.origin - pos

	local scrpos = pos.y * MinimapCameraUp - pos.x * MinimapCameraRight
	scrpos = scrpos * MinimapCameraScale
	scrpos = scrpos + MinimapCameraOffset

	scrpos.x = math.Clamp(scrpos.x, MinimapCamera.x, MinimapCamera.x + MinimapCamera.w)
	scrpos.y = math.Clamp(scrpos.y, MinimapCamera.y, MinimapCamera.y + MinimapCamera.h)

	return scrpos
end

function GM:GenerateMinimapMaterial(redgoal, bluegoal)
	MinimapRT = GetRenderTarget("EFTMinimap", 1024, 512, true)
	MinimapMaterial = CreateMaterial("EFTMinimap", "UnlitGeneric", {["$basetexture"] = "EFTMinimap"})

	local screenscale = BetterScreenScale()
	local center = (redgoal + bluegoal) * 0.5
	local extents = (bluegoal:Distance(redgoal) + 600) / 2

	local ang = bluegoal - redgoal
	ang:Normalize()
	ang = ang:Angle()
	ang:RotateAroundAxis(ang:Right(), -90)
	ang:RotateAroundAxis(ang:Forward(), -90)

	MinimapCamera.angles = ang
	MinimapCamera.origin = center + Vector(0, 0, 16000)
	MinimapCamera.x = 0
	MinimapCamera.y = 0
	MinimapCamera.w = 1024
	MinimapCamera.h = 512

	MinimapCamera.ortholeft = -extents * screenscale
	MinimapCamera.orthoright = extents * screenscale
	MinimapCamera.orthotop = MinimapCamera.ortholeft / 2
	MinimapCamera.orthobottom = MinimapCamera.orthoright / 2

	MinimapCameraUp = MinimapCamera.angles:Up()
	MinimapCameraRight = MinimapCamera.angles:Right()

	local old_rt = render.GetRenderTarget()
	local old_w, old_h = ScrW(), ScrH()

	render.SetRenderTarget(MinimapRT)
	render.SetViewPort(0, 0, 1024, 512)
	render.Clear(0, 0, 0, 0)
	cam.Start2D()

	hook.Add("PreDrawSkyBox", "MinimapCamera", function() return true end)
	hook.Add("PostDrawTranslucentRenderables", "MinimapCamera", function() return true end)

	render.RenderView(MinimapCamera)

	hook.Remove("PostDrawTranslucentRenderables", "MinimapCamera")
	hook.Remove("PreDrawSkyBox", "MinimapCamera")

	cam.End2D()
	render.SetViewPort(0, 0, old_w, old_h)
	render.SetRenderTarget(old_rt)
end

function GM:DrawMinimap()
	local redgoal = self:GetGoalCenter(TEAM_RED)
	local bluegoal = self:GetGoalCenter(TEAM_BLUE)

	if redgoal == vector_origin or bluegoal == vector_origin then return end

	if not MinimapRT then
		self:GenerateMinimapMaterial(redgoal, bluegoal)
	end

	local screenscale = BetterScreenScale()

	MinimapCamera.x = 0
	MinimapCamera.y = 0
	MinimapCamera.w = screenscale * 300
	MinimapCamera.h = screenscale * 150
	MinimapCameraScale = MinimapCamera.w / MinimapCamera.orthoright / 2
	MinimapCameraOffset = Vector(MinimapCamera.x + MinimapCamera.w / 2, MinimapCamera.y + MinimapCamera.h / 2)

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(MinimapMaterial)
	surface.DrawTexturedRect(MinimapCamera.x, MinimapCamera.y, MinimapCamera.w, MinimapCamera.h)

	local pos
	local lp = LocalPlayer()
	for _, pl in pairs(player.GetAll()) do
		if pl:Alive() and pl:GetObserverMode() == OBS_MODE_NONE then
			pos = MinimapWorldToScreen(pl:GetPos())
			if pl == lp then
				local c = 200 + math.abs(math.sin(CurTime() * 5)) * 55
				surface.SetDrawColor(c, c, c, 255)
			else
				surface.SetDrawColor(team.GetColor(pl:Team()))
			end
			surface.DrawRect(pos.x - 2, pos.y - 2, 4, 4)
		end
	end

	pos = MinimapWorldToScreen(self:GetGoalCenter(TEAM_RED))
	self:DrawCircle(pos.x, pos.y, 8, team.GetColor(TEAM_RED))

	pos = MinimapWorldToScreen(self:GetGoalCenter(TEAM_BLUE))
	self:DrawCircle(pos.x, pos.y, 8, team.GetColor(TEAM_BLUE))

	local ball = self:GetBall()
	local carrier = ball:GetCarrier()
	pos = MinimapWorldToScreen(ball:GetPos())
	if carrier:IsValid() then
		self:DrawCircle(pos.x, pos.y, 6 + math.sin(CurTime() * 5) * 4, team.GetColor(carrier:Team()))
	else
		self:DrawCircle(pos.x, pos.y, 6, color_white)
	end
end

function GM:DrawCrosshair()
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
end

function GM:DrawAngleFinder()
	local w, h = ScrW(), ScrH()
	local pitch = LocalPlayer():EyeAngles().pitch
	local pitchy = pitch / 180
	local x = w / 2 + math.Clamp(h / 1080, 0.5, 1) * 32 + 16
	local y = h / 2

	h = h / 4

	surface.SetDrawColor(255, 255, 255, 60)
	local on = true
	for i=0, h, 8 do
		if on then
			surface.DrawRect(x, y - h / 2 + i, 2, math_min(8, h - i))
		end
		on = not on
	end

	surface.SetDrawColor(255, 0, 0, 100)
	surface.DrawRect(x - 8, y + pitchy * h - 4, 8, 4)
end

local sort_func = function(ply) return ply:Frags() end
function GM:AddScoreboardKills(ScoreBoard)
	ScoreBoard:AddColumn("Score", 80, sort_func, 0.5, nil, 6, 6)
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
	self:DrawMinimap()
	self:DrawScreenCracks()

	local lp = LocalPlayer()
	if lp:IsValid() then
		lp:CallStateFunction("HUDPaint")
		lp:CallCarryFunction("HUDPaint")
	end
end

function GM:DrawScreenCracks()
	if #ScreenCracks == 0 then return end

	local w, h = ScrW(), ScrH()
	local time = CurTime()

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
	local Bar = vgui.Create( "DHudBar" )
	GAMEMODE:AddHUDItem( Bar, 2 )

	local TeamIndicator = vgui.Create( "DHudUpdater" )
	TeamIndicator:SizeToContents()
	TeamIndicator:SetValueFunction( function() return team.GetName( LocalPlayer():Team() ) end )
	TeamIndicator:SetColorFunction( function() return team.GetColor( LocalPlayer():Team() )	end )
	TeamIndicator:SetFont( "HudSelectionText" )
	Bar:AddItem( TeamIndicator )

	local RoundNumber = vgui.Create( "DHudUpdater" )
	RoundNumber:SizeToContents()
	RoundNumber:SetValueFunction( function() return GetGlobalInt( "RoundNumber", 0 ) end )
	RoundNumber:SetLabel( "ROUND" )
	Bar:AddItem( RoundNumber )

	local RoundTimer = vgui.Create( "DHudCountdown" )
	RoundTimer:SizeToContents()
	RoundTimer:SetValueFunction( function()
		if ( GetGlobalFloat( "RoundStartTime", 0 ) > CurTime() ) then return GetGlobalFloat( "RoundStartTime", 0 )  end
		return GAMEMODE:GetTimeLimit()
	end )
	RoundTimer:SetLabel( "TIME" )
	Bar:AddItem( RoundTimer )
end

function GM:UpdateHUD_Observer( bWaitingToSpawn, InRound, ObserveMode, ObserveTarget )
	local lbl = nil
	local txt = nil
	local col = color_white

	if IsValid( ObserveTarget ) and ObserveTarget:IsPlayer() and ObserveTarget ~= LocalPlayer() and ObserveMode ~= OBS_MODE_ROAMING then
		lbl = "SPECTATING"
		txt = ObserveTarget:Nick()
		col = team.GetColor( ObserveTarget:Team() )
	end

	if ObserveMode == OBS_MODE_DEATHCAM or ObserveMode == OBS_MODE_FREEZECAM then
		txt = "You were knocked out!"
	end

	if txt then
		local txtLabel = vgui.Create( "DHudElement" )
		txtLabel:SetText( txt )
		if ( lbl ) then txtLabel:SetLabel( lbl ) end
		txtLabel:SetTextColor( col )

		GAMEMODE:AddHUDItem( txtLabel, 2 )
	end

	GAMEMODE:UpdateHUD_Dead( bWaitingToSpawn, InRound )
end

function GM:UpdateHUD_Dead( bWaitingToSpawn, InRound )
	if not InRound then
		local RespawnText = vgui.Create( "DHudElement" )
			RespawnText:SizeToContents()
			RespawnText:SetText( "Waiting for round start" )
		GAMEMODE:AddHUDItem( RespawnText, 8 )

		return
	end

	if ( bWaitingToSpawn ) then
		local RespawnTimer = vgui.Create( "DHudCountdown" )
			RespawnTimer:SizeToContents()
			RespawnTimer:SetValueFunction( function() return LocalPlayer():GetNWFloat( "RespawnTime", 0 ) end )
			RespawnTimer:SetLabel( "SPAWN IN" )
		GAMEMODE:AddHUDItem( RespawnTimer, 8 )

		return
	end

	if ( InRound ) then
		local RoundTimer = vgui.Create( "DHudCountdown" )
			RoundTimer:SizeToContents()
			RoundTimer:SetValueFunction( function()
				if ( GetGlobalFloat( "RoundStartTime", 0 ) > CurTime() ) then return GetGlobalFloat( "RoundStartTime", 0 )  end
				return GAMEMODE:GetTimeLimit()
			end )
			RoundTimer:SetLabel( "TIME" )
		GAMEMODE:AddHUDItem( RoundTimer, 8 )

		return
	end

	if Team ~= TEAM_SPECTATOR and not Alive then
		local RespawnText = vgui.Create( "DHudElement" )
			RespawnText:SizeToContents()
			RespawnText:SetText( "Press Fire to Spawn" )
		GAMEMODE:AddHUDItem( RespawnText, 8 )
	end
end

function GM:EndOfGame(winner)
	self.GameWinner = winner
	self.GameEndTime = CurTime()
end

function GM:TeamScored(teamid, hitter, points, homerun)
	self.CurrentTransition = math.random(#TRANSITIONS)

	if not MySelf:IsValid() then return end

	if teamid == MySelf:Team() or not team.Joinable(MySelf:Team()) then
		surface.PlaySound("vo/coast/odessa/male01/nlo_cheer0"..math.random(4)..".wav")
	else
		surface.PlaySound("npc/dog/dog_on_dropship.wav")
	end

	self.RoundWinner = teamid
	self.RoundEndScroll = 0
	self.RoundEndCameraTime = RealTime()
	self.RoundHomeRun = homerun
end
net.Receive("eft_teamscored", function(length)
	local teamid = net.ReadUInt(8)
	local pl = net.ReadEntity()
	local points = net.ReadUInt(8)
	local homerun = net.ReadBit() == 1

	gamemode.Call("TeamScored", teamid, pl, points, homerun)
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

net.Receive("eft_overtime", function(length)
	GAMEMODE.RoundEndScrollOT = 0

	-- TODO: less crappy sound
	surface.PlaySound("ambient/machines/thumper_hit.wav")
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
