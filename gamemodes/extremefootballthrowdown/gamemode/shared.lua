DeriveGamemode("fretta13")

GM.Name = "Extreme Football Throwdown"
GM.Author = "William \"JetBoom\" Moodhe"
GM.Email = "williammoodhe@gmail.com"
GM.Website = "http://www.noxiousnet.com"

include("workshopfix.lua")

include("buffthefps.lua")
include("nixthelag.lua")

TEAM_RED = 1
TEAM_BLUE = 2
TEAM_SPECTATE = TEAM_SPECTATOR

MOVE_STOP = 0
MOVE_OVERRIDE = 1

GM.Help	= "Get the ball in to the enemy goal.\n\nYou speed up over time and lose speed for hitting things or changing directions quickly.\n\nHold right click while going fast to ram.\nPress left click for melee attack/diving tackle.\nPress right click with the ball to throw it.\nPress ALT to dive.\nHold R to look behind you.\nHold CTRL + stay still to prepare a high jump."

GM.TeamBased = true
GM.AllowAutoTeam = true
GM.UseAutoJoin = true

GM.AllowSpectating = true
GM.ValidSpectatorModes = {OBS_MODE_CHASE, OBS_MODE_IN_EYE, OBS_MODE_ROAMING}
GM.ValidSpectatorEntities = {"player", "prop_ball"}
GM.CanOnlySpectateOwnTeam = true

GM.SelectClass = false

GM.SecondsBetweenTeamSwitches = 40
GM.SecondsBetweenTeamSwitchesFromSpec = 150

GM.GameLength = CreateConVar("eft_gamelength", "20", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "Time in minutes the map lasts for."):GetInt()
if GM.GameLength < 0 then GM.GameLength = -1 end
cvars.AddChangeCallback("eft_gamelength", function(cvar, oldvalue, newvalue)
	GAMEMODE.GameLength = tonumber(newvalue) or 20
	if GAMEMODE.GameLength < 0 then
		GAMEMODE.GameLength = -1
	end
end)

GM.ScoreLimit = CreateConVar("eft_scorelimit", "7", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "Time in minutes the map lasts for."):GetInt()
if GM.ScoreLimit < 0 then GM.ScoreLimit = -1 end
cvars.AddChangeCallback("eft_scorelimit", function(cvar, oldvalue, newvalue)
	GAMEMODE.ScoreLimit = tonumber(newvalue) or 7
	if GAMEMODE.ScoreLimit < 0 then
		GAMEMODE.ScoreLimit = -1
	end
end)

GM.Pity = CreateConVar("eft_pity", "3", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "If a team is up by this many points, the other team receives speed buffs with the ball."):GetInt()
cvars.AddChangeCallback("eft_pity", function(cvar, oldvalue, newvalue)
	GAMEMODE.Pity = math.max(tonumber(newvalue) or 0, 0)
end)

function team.HasPity(teamid)
	return GAMEMODE.Pity > 0 and team.GetScore(teamid == TEAM_RED and TEAM_BLUE or TEAM_RED) >= team.GetScore(teamid) + GAMEMODE.Pity
end

GM.RoundLimit = -1
GM.RoundLength = 60 * 20
GM.RoundBased = true
GM.RoundEndsWhenOneTeamAlive = false

GM.RealisticFallDamage = true
GM.NoPlayerDamage = false
GM.NoPlayerSelfDamage = false
GM.NoPlayerTeamDamage = true
GM.NoPlayerPlayerDamage = false
GM.NoNonPlayerPlayerDamage = false

GM.SelectModel = false

GM.AutomaticTeamBalance = true

GM.PointsForScoring = 300
GM.PointsForDamage = 0.1

GM.Ball = GM.Ball or NULL
GM.BallTrigger = GM.BallTrigger or NULL

GM.BoneScales = {
	["ValveBiped.Bip01_Spine2"] = Vector(1.000000, 1.250000, 1.250000),
	["ValveBiped.Bip01_R_Thigh"] = Vector(1.000000, 1.250000, 1.250000),
	["ValveBiped.Bip01_R_Clavicle"] = Vector(3.000000, 1.500000, 1.500000),
	--["ValveBiped.Bip01_R_Calf"] = Vector(1.000000, 0.750000, 0.750000),
	--["ValveBiped.Bip01_L_Calf"] = Vector(1.000000, 0.750000, 0.750000),
	["ValveBiped.Bip01_L_Thigh"] = Vector(1.000000, 1.250000, 1.250000),
	["ValveBiped.Bip01_Spine4"] = Vector(1.000000, 1.250000, 2.500000),
	["ValveBiped.Bip01_Pelvis"] = Vector(0.800000, 0.800000, 1.000000),
	["ValveBiped.Bip01_L_Clavicle"]	= Vector(3.000000, 1.500000, 1.500000)
}

include("sh_animations.lua")
include("sh_states.lua")
include("sh_roundtransitions.lua")
include("sh_voice.lua")
include("sh_translate.lua")

include("sh_obj_entity_extend.lua")
include("sh_obj_player_extend.lua")

IncludePlayerClasses()

function GM:EntityEmitSound(snd)
	if game.GetTimeScale() ~= 1 then
		local ent = snd.Entity
		if ent and ent:IsValid() then
			if ent:IsPlayer() or ent:GetMoveType() ~= MOVETYPE_NONE then
				snd.Pitch = math.Clamp(snd.Pitch * math.Clamp(game.GetTimeScale() ^ 0.6, 0.4, 3), 10, 255)
				snd.DSP = 21
				return true
			end
		end
	end
end

function GM:PlayerShouldTaunt(pl, actid)
	return pl:IsIdle() and not pl:IsPlayingTaunt() and pl:Alive() and pl:OnGround() and pl:GetMoveType() == MOVETYPE_WALK
end

function GM:PlayerCanHearPlayersVoice(listener, talker)
	return self.TieBreaker or not self:InRound() or listener:Team() == TEAM_SPECTATOR or listener:Team() == TEAM_UNASSIGNED or listener:Team() == talker:Team(), false
end

function GM:ShouldCollide(enta, entb)
	if enta.ShouldNotCollide and enta:ShouldNotCollide(entb) or entb.ShouldNotCollide and entb:ShouldNotCollide(enta) then
		return false
	end

	return true
end

function GM:RecalculateGoalCenters(teamid)
	local ball = self:GetBall()
	if ball:IsValid() then
		local vec = Vector(0, 0, 0)
		local num = 0
		local goals = ents.FindByClass("prop_goal")
		goals = table.Add(goals, ents.FindByClass("trigger_goal"))
		for _, ent in pairs(goals) do
			if ent:GetTeamID() == teamid then
				vec = vec + ent:LocalToWorld(ent:OBBCenter())
				num = num + 1
			end
		end
		if num > 0 then
			if teamid == TEAM_RED then
				ball:SetRedGoalCenter(vec / num)
			elseif teamid == TEAM_BLUE then
				ball:SetBlueGoalCenter(vec / num)
			end
		end
	end
end

function GM:InitPostEntity()
	self.BaseClass:InitPostEntity()
end

function GM:GetOppositeTeam(teamid)
	return teamid == TEAM_RED and TEAM_BLUE or teamid == TEAM_BLUE and TEAM_RED or teamid
end

function GM:SetBallHome(vec)
	self.BallHome = vec
end

function GM:GetBallHome()
	return self.BallHome or Vector(0, 0, 0)
end

function GM:SetBall(ent)
	self.Ball = ent
	self.BallTrigger = ent.BallTrigger or ents.FindByClass("prop_balltrigger")[1]
end

function GM:GetBall()
	return self.Ball or NULL
end

function GM:ShouldDrawLocalPlayer(pl)
	return pl:Alive() and not IsValid(pl:GetRagdollEntity())
end

function GM:GetFallDamage(pl, speed)
	return 0
end

function GM:Move(pl, move)
	if not pl:Alive() then return end

	local nextvel = pl:GetNextMoveVelocity()
	if nextvel ~= vector_origin then
		pl:SetGroundEntity(NULL)
		move:SetVelocity(nextvel)
		pl:SetNextMoveVelocity(vector_origin)
		return
	end

	local ret = pl:CallStateFunction("Move", move)
	if ret then
		if ret == MOVE_STOP then return end
		if ret == MOVE_OVERRIDE then return true end
	end

	if pl:OnGround() then
		local carry = pl:GetCarry()
		if carry:IsValid() and carry == self:GetBall() then
			if not carry:CallStateFunction("PreMove", pl, move) then
				self:DefaultMove(pl, move)
			end
			carry:CallStateFunction("PostMove", pl, move)
		else
			self:DefaultMove(pl, move)
		end
	elseif pl:IsSwimming() then
		move:SetMaxSpeed(move:GetMaxSpeed() * 0.75)
		move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.75)
	else
		move:SetMaxSpeed(move:GetMaxSpeed() * 0.2)
		move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.2)
	end

	local ret = pl:CallStateFunction("PostMove", move)
	if ret then
		if ret == MOVE_OVERRIDE then return true end
	end
end

GM.m_Weapons = {}
function GM:RegisterWeapon(class)
	table.insert(self.m_Weapons, class)
end

function GM:RegisterWeapons()
	for class, v in pairs(scripted_ents.GetList()) do
		if v and v.t and v.t.IsPropWeapon then
			self:RegisterWeapon(class)
		end
	end
end

function GM:GetWeapons()
	return self.m_Weapons
end

function GM:DefaultMove(pl, move)
	local carry = pl:GetCarry()
	if carry:IsValid() and carry.Move and carry:Move(pl, move) then return end

	if move:GetForwardSpeed() > 0 then
		local curvel = move:GetVelocity()
		local maxspeed = move:GetMaxSpeed()
		local curspeed = math.min(maxspeed, curvel:Length2D())
		local acceleration = carry:IsValid() and carry.GetAcceleration and carry:GetAcceleration() or 1
		local newspeed = math.max(curspeed + FrameTime() * (15 + 0.5 * (400 - curspeed)) * acceleration, 100) * (1 - math.max(0, math.abs(math.AngleDifference(move:GetMoveAngles().yaw, curvel:Angle().yaw)) - 4) / 360)

		move:SetSideSpeed(0)
		move:SetMaxSpeed(newspeed)
		move:SetMaxClientSpeed(newspeed)
	else
		move:SetMaxSpeed(120)
		move:SetMaxClientSpeed(120)
	end
end

function GM:KeyPress(pl, key)
	if not pl:Alive() or pl:GetObserverMode() ~= OBS_MODE_NONE then return end

	if pl:CallStateFunction("KeyPress", key) then return end

	local carry = pl:GetCarry()
	if carry:IsValid() and carry.KeyPress and carry:KeyPress(pl, key) then return end

	if key == IN_ATTACK then
		if pl:CanMelee() then
			local state = STATE_PUNCH1
			--[[for _, tr in pairs(pl:GetTargets()) do
				local hitent = tr.Entity
				if hitent:IsPlayer() and hitent:GetState() == STATE_KNOCKEDDOWN then
					state = STATE_KICK1
					break
				end
			end]]

			pl:SetState(state, STATES[state].Time)
		end
	elseif key == IN_ATTACK2 then
		if pl:CanMelee() then
			local vel = pl:GetVelocity()
			local dir = vel:GetNormalized()
			local speed = vel:Length() * dir:Dot(pl:GetForward())
			if speed >= 290 and CurTime() >= pl:GetLastChargeHit() + 0.4 and pl:GetCarry() ~= self:GetBall() then
				pl:SetState(STATE_DIVETACKLE)
			end
		end
	elseif key == IN_WALK then
		if SERVER and pl:IsIdle() and not pl:IsCarrying() then
			if pl:OnGround() then
				local dir = vector_origin
				if pl:KeyDown(IN_FORWARD) then
					dir	= dir + pl:GetForward()
				end
				if pl:KeyDown(IN_BACK) then
					dir = dir - pl:GetForward()
				end
				if pl:KeyDown(IN_MOVERIGHT) then
					dir = dir + pl:GetRight()
				end
				if pl:KeyDown(IN_MOVELEFT) then
					dir = dir - pl:GetRight()
				end

				pl:KnockDown()
				dir:Normalize()
				dir = dir * 300
				dir.z = 300
				pl:SetNextMoveVelocity(dir)
			else
				pl:KnockDown()
			end
		end
	elseif key == IN_SPEED then
		if pl:IsIdle() and not pl:IsCarrying() and pl:OnGround() and pl:WaterLevel() <= 1 then
			pl:SetState(STATE_WAVE, STATES[STATE_WAVE].Time)
		end
	end
end

function GM:OnPowerStruggleWin(pl, other)
end

function GM:OnPowerStruggleLose(pl, other)
end

function GM:KeyRelease(pl, key)
	if pl:CallStateFunction("KeyRelease", key) then return end

	local carry = pl:GetCarry()
	if carry:IsValid() and carry.KeyRelease and carry:KeyRelease(pl, key) then return end
end

function GM:OnPlayerHitGround(pl, inwater, hitfloater, speed)
	if CurTime() ~= pl.LastHitGround then
		pl.LastHitGround = CurTime()

		local ret = pl:CallStateFunction("OnPlayerHitGround", inwater, hitfloater, speed)
		if ret ~= nil then return ret end
	end

	if inwater then return true end

	if SERVER then
		local damage = (0.1 * (speed - 650)) ^ 1.2

		if hitfloater then damage = damage / 2 end

		if math.floor(damage) > 0 then
			if damage >= 20 then
				pl:KnockDown()
			end
			pl:TakeSpecialDamage(damage, DMG_FALL, game.GetWorld(), game.GetWorld(), pl:GetPos())
			pl:EmitSound("player/pl_fallpain"..(math.random(0, 1) == 1 and 3 or 1)..".wav")
		end
	end

	return true
end

function GM:CreateTeams()
	if not GAMEMODE.TeamBased then return end

	team.SetUp(TEAM_RED, "Red Rhinos", Color(255, 20, 20))
	team.SetSpawnPoint(TEAM_RED, {"info_player_red"}, true)

	team.SetUp(TEAM_BLUE, "Blue Bulls", Color(20, 20, 255))
	team.SetSpawnPoint(TEAM_BLUE, {"info_player_blue"}, true)

	team.SetUp(TEAM_SPECTATOR, "Spectators", Color(200, 200, 200), true)
	team.SetSpawnPoint(TEAM_SPECTATOR, {"info_player_blue", "info_player_red", "prop_ball"})
	team.SetClass(TEAM_SPECTATOR, {"Spectator"})

	team.SetSpawnPoint(TEAM_UNASSIGNED, {"info_player_blue", "info_player_red", "prop_ball"})
end

function util.Blood(pos, amount, dir, force, noprediction)
	local effectdata = EffectData()
		effectdata:SetOrigin(pos)
		effectdata:SetMagnitude(amount)
		effectdata:SetNormal(dir)
		effectdata:SetScale(math.max(128, force))
	util.Effect("bloodstream", effectdata, nil, noprediction)
end

function util.Chance(chance)
	return chance <= math.random(100)
end

function util.Probability(prob)
	return prob <= 1 or math.random(prob) == prob
end

function util.ToMinutesSeconds(seconds)
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60

    return string.format("%02d:%02d", minutes, math.floor(seconds))
end

function util.ExplosiveDamage(inflictor, attacker, pos, range, damage, damagetype, forcemultiplier, forceoverride)
	damagetype = damagetype or DMGTYPE_FIRE

	local teamid = attacker:IsValid() and attacker:IsPlayer() and attacker:Team() or 0

	for _, ent in pairs(ents.FindInSphere(pos, range)) do
		if ent:IsPlayer() and ent:Team() == teamid and ent ~= attacker then continue end

		local entpos = ent:NearestPoint(pos)
		if util.IsVisible(entpos, pos) then
			local dmg = math.Clamp(1 - entpos:Distance(pos) / range, 0, 1) ^ 0.5 * damage
			local force = (ent:IsPlayer() and 1 or 0.3) * (forceoverride or dmg * 15 * (forcemultiplier or 1))
			ent:ThrowFromPosition(pos + Vector(0, 0, -24), force, force >= 150, attacker)
			ent:TakeSpecialDamage(damage, damagetype, attacker, inflictor, pos)
		end
	end
end

function util.IsVisible(posa, posb)
	if posa == posb then return true end

	local trace = {start = posa, endpos = posb, mask = MASK_SOLID_BRUSHONLY}

	if not trace.Hit then return true end

	trace.start = posb
	trace.endpos = posa

	return not trace.Hit
end

function util.ToMinutesSecondsMilliseconds(seconds)
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60

	local milliseconds = math.floor(seconds % 1 * 100)

    return string.format("%02d:%02d.%02d", minutes, math.floor(seconds), milliseconds)
end

function team.HasPlayers(teamid)
	for _, pl in pairs(player.GetAll()) do
		if pl:Team() == teamid then return true end
	end

	return false
end

function team.TopPlayer(teamid)
	local ret

	local topscore = -math.huge
	for _, pl in pairs(team.GetPlayers(teamid)) do
		if pl:Frags() > topscore then
			ret = pl
			topscore = pl:Frags()
		end
	end

	return ret
end

function timer.SimpleEx(delay, action, ...)
	if ... == nil then
		timer.Simple(delay, action)
	else
		local a, b, c, d, e, f, g, h, i, j, k = ...
		timer.Simple(delay, function() action(a, b, c, d, e, f, g, h, i, j, k) end)
	end
end

function timer.CreateEx(timername, delay, repeats, action, ...)
	if ... == nil then
		timer.Create(timername, delay, repeats, action)
	else
		local a, b, c, d, e, f, g, h, i, j, k = ...
		timer.Create(timername, delay, repeats, function() action(a, b, c, d, e, f, g, h, i, j, k) end)
	end
end

function util.LimitTurning(oldangles, newangles, angle_per_dt, dt)
	dt = dt or FrameTime()

	local maxdiff = dt * angle_per_dt
	local mindiff = -maxdiff

	local diff = math.AngleDifference(newangles.yaw, oldangles.yaw)
	if diff > maxdiff or diff < mindiff then
		newangles.yaw = math.NormalizeAngle(oldangles.yaw + math.Clamp(diff, mindiff, maxdiff))
	end

	diff = math.AngleDifference(newangles.pitch, oldangles.pitch)
	if diff > maxdiff or diff < mindiff then
		newangles.pitch = math.NormalizeAngle(oldangles.pitch + math.Clamp(diff, mindiff, maxdiff))
	end

	return newangles
end

function AccessorFuncDT(tab, membername, type, id)
	local emeta = FindMetaTable("Entity")
	local setter = emeta["SetDT"..type]
	local getter = emeta["GetDT"..type]

	tab["Set"..membername] = function(me, val)
		setter(me, id, val)
	end

	tab["Get"..membername] = function(me)
		return getter(me, id)
	end
end