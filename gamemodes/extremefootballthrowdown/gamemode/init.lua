AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("sh_globals.lua")

AddCSLuaFile("cl_obj_entity_extend.lua")
AddCSLuaFile("cl_obj_player_extend.lua")

AddCSLuaFile("sh_obj_entity_extend.lua")
AddCSLuaFile("sh_obj_player_extend.lua")

AddCSLuaFile("sh_states.lua")
AddCSLuaFile("sh_voice.lua")
AddCSLuaFile("sh_translate.lua")

AddCSLuaFile("sh_animations.lua")

AddCSLuaFile("cl_postprocess.lua")
AddCSLuaFile("cl_draw.lua")

AddCSLuaFile("vgui/dex3dnotification.lua")

include("sh_globals.lua")

include("shared.lua")

--include("animationsapi/boneanimlib.lua")

include("sv_obj_player_extend.lua")

--[[
effects for ramming in to someone.
Throwdown combo counter. Every time you knock someone down who isn't on the ground already, your combo goes up. If you die or get knocked down it resets. The game will announce people who reach particular combos.
ball powerup: Pounder Ball. The ball is encased in a big bowling ball. The carrier is slightly slower but the ball will create shock waves when it bounces. Hitting other people with the ball will do enhanced damage and knock back.
ball powerup: Gravity Ball. The ball glows purple. The carrier's gravity is reduced and the ball's gravity is dramatically reduced.
ball powerup: Homing Ball. The ball glows pink and has pink contrails encircling it. The ball will, when thrown, home in on to the nearest team member of the last thrower that isn't them.
ball powerup: Ultimate Ball. The ball glows multiple colors. The carrier is immune to everything except trigger_hurts and runs at normal speed. Anyone who comes close to the carrier will be thrown away.
]]

function GM:Think()
	if not self.IsEndOfGame then
		if CurTime() >= self:GetTimeLimit() and (not GAMEMODE.SuppressTimeLimit or CurTime() > GAMEMODE.SuppressTimeLimit) then
			if self:GetOvertime() or team.GetScore(TEAM_RED) ~= team.GetScore(TEAM_BLUE) or self.OvertimeTime < 0 then
				self:EndOfGame(true)
			else
				self:SetOvertime(true)
			end
		elseif self:GetOvertime() and team.GetScore(TEAM_RED) ~= team.GetScore(TEAM_BLUE) then
			self:EndOfGame(true)
		end
	end

	for _, pl in pairs(player.GetAll()) do
		if pl:Alive() and pl:GetObserverMode() == OBS_MODE_NONE then
			if CurTime() >= pl.NextHealthRegen and CurTime() >= pl.LastDamaged + 1 and pl:Health() < pl:GetMaxHealth() then
				pl.NextHealthRegen = CurTime() + 0.25
				pl:SetHealth(math.min(pl:GetMaxHealth(), pl:Health() + 2))
			end

			pl:ThinkSelf()
		end
	end
end

function GM:CanEndRoundBasedGame()
	return true
end

function GM:OnEndOfGame(bGamemodeVote)
	for k,v in pairs(player.GetAll()) do
		if v:ShouldBeFrozen() then
			v:Freeze(true)
		end
	end

	net.Start("eft_endofgame")
		net.WriteUInt(team.GetScore(TEAM_RED) > team.GetScore(TEAM_BLUE) and TEAM_RED or team.GetScore(TEAM_BLUE) > team.GetScore(TEAM_RED) and TEAM_BLUE or 0, 8)
	net.Broadcast()
end

function GM:PreRoundStart(iNum)
	if CurTime() >= GAMEMODE.GetTimeLimit() or GAMEMODE:HasReachedRoundLimit( iNum ) then
		if not self:GetOvertime() and team.GetScore(TEAM_RED) == team.GetScore(TEAM_BLUE) then
			self:SetOvertime(true)
		else
			GAMEMODE:EndOfGame(true)
			return
		end
	end

	if not GAMEMODE:CanStartRound(iNum) then
		timer.Simple(1, function() GAMEMODE:PreRoundStart( iNum ) end)
		return
	end

	timer.Simple(GAMEMODE.RoundPreStartTime, function() GAMEMODE:RoundStart() end)
	SetGlobalInt("RoundNumber", iNum)
	SetGlobalFloat("RoundStartTime", CurTime() + GAMEMODE.RoundPreStartTime)

	GAMEMODE:ClearRoundResult()
	GAMEMODE:OnPreRoundStart(GetGlobalInt("RoundNumber"))
	GAMEMODE:SetInRound(true)
end

function GM:SetOvertime(ot)
	SetGlobalBool("overtime", ot)

	if ot then
		self:StartRoundBasedGame()

		net.Start("eft_overtime")
		net.Broadcast()
	end
end
GM.SetOverTime = GM.SetOvertime

function GM:ReturnBall()
	local ball = self:GetBall()
	if not ball or not ball:IsValid() then return end

	ball:SetPos(self:GetBallHome())
end

function GM:PlayerReady(pl)
end

concommand.Add("initpostentity", function(sender, command, arguments)
	if not sender.DidInitPostEntity then
		sender.DidInitPostEntity = true

		gamemode.Call("PlayerReady", sender)
	end
end)

function GM:HasReachedRoundLimit(iNum)
	return team.GetScore(TEAM_RED) >= self.ScoreLimit or team.GetScore(TEAM_BLUE) >= self.ScoreLimit
end

-- typical network var unreliability causes people to be stuck on the ball camera even after a round starts.
function GM:SetInRound(b)
	local l = "SetGlobalBool(\"InRound\","..tostring(b)..")"
	for _, p in pairs(player.GetAll()) do p:SendLua(l) end

	self.BaseClass.SetInRound(self, b)
end

function GM:AllowPlayerPickup(pl, ent)
	return false
end

function GM:IsSpawnpointSuitable(pl, spawnpointent, bMakeSuitable)
	if bMakeSuitable then
		if pl:Team() == TEAM_SPECTATOR or pl:Team() == TEAM_UNASSIGNED then return true end

		local Pos = spawnpointent:GetPos()
		for k, v in pairs(ents.FindInBox(Pos + Vector(-16, -16, 0), Pos + Vector(16, 16, 72))) do
			if v:IsPlayer() and v:Alive() then
				return false
			end
		end
	end

	return true
end

local function SortSpawnDistToBallSpawn(a, b)
	local home = GAMEMODE:GetBallHome()
	return a:GetPos():DistToSqr(home) > b:GetPos():DistToSqr(home)
end

function GM:PlayerSelectTeamSpawn(teamid, pl)
	local spawns = team.GetSpawnPoints(teamid)
	if not spawns or #spawns == 0 then return pl end

	table.sort(spawns, SortSpawnDistToBallSpawn)

	for _, spawn in pairs(spawns) do
		if self:IsSpawnpointSuitable(pl, spawn, true) then
			return spawn
		end
	end

	return spawns[#spawns]
end

function GM:CanPlayerSuicide(pl)
	if not self:InRound() then return false end

	if self.TieBreaker then
		if pl:Alive() and pl:GetState() == STATE_FIGHTER2D and pl:GetStateInteger() ~= STATE_FIGHTER2D_LOSE then
			pl:SetStateInteger(STATE_FIGHTER2D_LOSE)
			pl:SetHealth(1)
			pl:SetStateFloat(CurTime())
		end

		return false
	end

	local ball = self:GetBall()
	if ball:IsValid() and ball:GetCarrier() == pl then
		return false
	end

	if pl:CallStateFunction("NoSuicide") then return false end

	return self.BaseClass.CanPlayerSuicide(self, pl)
end

function GM:OnRoundResult(result, resulttext)
	team.AddScore(result, 1)
end

function GM:PlayerSpawn(pl)
	self.BaseClass:PlayerSpawn(pl)

	pl:Extinguish()

	pl.m_KnockdownImmunity = {}
	pl.m_ChargeImmunity = {}
	pl.PointsCarry = 0
	pl.NextPainSound = 0
	pl:SetLastAttacker(nil)

	local teamid = pl:Team()

	local modelname = player_manager.TranslatePlayerModel(pl:GetInfo("cl_playermodel"))
	if not self.AllowedPlayerModels[modelname:lower()] then
		modelname = teamid == TEAM_RED and "models/player/barney.mdl" or "models/player/breen.mdl"
	end
	pl:SetModel(modelname)

	if teamid == TEAM_RED then
		--pl:SetModel("models/player/barney.mdl")
		pl:SetPlayerColor(Vector(2, 0, 0))
	else
		--pl:SetModel("models/player/breen.mdl")
		pl:SetPlayerColor(Vector(0, 0, 1))
	end

	if not team.Joinable(teamid) then return end

	if teamid == TEAM_RED or teamid == TEAM_BLUE then
		pl:ShouldDropWeapon(false)
		pl:Give("weapon_eft")
	else
		pl:StripWeapons()
	end

	if CurTime() < GetGlobalFloat("RoundStartTime") and teamid ~= TEAM_SPECTATOR and teamid ~= TEAM_CONNECTING then
		pl:SetState(STATE_PREROUND)
	else
		pl:EndState()
		if pl:ShouldBeFrozen() then
			pl:Freeze(true)
		end
	end

	for bonename, scale in pairs(self.BoneScales) do
		local boneid = pl:LookupBone(bonename)
		if boneid then
			pl:ManipulateBoneScale(boneid, scale)
		end
	end

	if not self.NoFlex then
		pl:SetFlexScale(1.5)
		for i=1, 45 do
			pl:SetFlexWeight(i, math.Rand(0, 2))
		end
	end

	pl:SetGravity(1)
end

function GM:SetupTieBreaker()
	if IsValid(self.TieBreaker) then return end

	for _, ent in pairs(ents.FindByClass("prop_ball")) do ent:Remove() end
	for _, ent in pairs(ents.FindByClass("prop_carry_*")) do ent:Remove() end

	local redpl, bluepl = team.TopPlayer(TEAM_RED), team.TopPlayer(TEAM_BLUE)

	if redpl and bluepl then
		local ballhome = self:GetBallHome()
		local ent = ents.Create("game_tiebreaker_controller")
		if ent:IsValid() then
			ent:SetPos(ballhome + Vector(0, -256, 0))
			ent:SetRedPlayer(redpl)
			ent:SetBluePlayer(bluepl)
			ent:Spawn()
		end

		redpl:SetPos(ballhome + Vector(-72, -256, 128))
		bluepl:SetPos(ballhome + Vector(72, -256, 128))
		redpl:SetState(STATE_FIGHTER2D)
		bluepl:SetState(STATE_FIGHTER2D)
	end
end

function GM:EndTieBreaker(winnerteamid)
	for _, ent in pairs(ents.FindByClass("game_tiebreaker_controller")) do
		ent:Remove()
	end
end

function GM:OnRoundStart(num)
	for _, pl in pairs(player.GetAll()) do
		if pl:GetState() == STATE_PREROUND then
			pl:EndState()
		end
	end

	self.NoFlex = false
end

function GM:PlayerSetModel(pl)
end

function GM:PlayerHurt(victim, attacker, healthremaining, damage)
	victim.LastDamaged = CurTime()

	if attacker ~= victim and attacker:IsValid() and attacker:IsPlayer() then
		victim:SetLastAttacker(attacker)

		attacker.PointsCarry = attacker.PointsCarry + damage * self.PointsForDamage
		if attacker.PointsCarry >= 1 then
			local toadd = math.floor(attacker.PointsCarry)
			attacker:AddFrags(toadd)
			attacker.PointsCarry = attacker.PointsCarry - toadd
		end

		if damage >= 5 then
			net.Start("eft_screencrack")
			net.Send(victim)
		end
	end

	victim:PlayPainSound()

	self.BaseClass.PlayerHurt(self, victim, attacker, healthremaining, damage)
end

function GM:PlayerDeath(victim, inflictor, attacker)
	if attacker == victim or not attacker:IsValid() or not attacker:IsPlayer() then
		local lastattacker = victim:GetLastAttacker()
		if lastattacker and lastattacker:IsValid() and lastattacker:IsPlayer() and lastattacker:Team() ~= victim:Team() then
			inflictor = attacker
			attacker = lastattacker
		end
	end

	self.BaseClass.PlayerDeath(self, victim, inflictor, attacker)
end

function GM:DoPlayerDeath(pl, attacker, dmginfo)
	pl:SetRespawnTime(4)
	pl:Extinguish()
	pl:Freeze(false)

	if attacker == pl or not attacker:IsValid() or not attacker:IsPlayer() then
		local lastattacker = pl:GetLastAttacker()
		if lastattacker and lastattacker:IsValid() and lastattacker:IsPlayer() and lastattacker:Team() ~= pl:Team() then
			attacker = lastattacker
		end
	end

	pl:PlayVoiceSet(VOICESET_DEATH)

	if attacker ~= pl and attacker:IsValid() and attacker:IsPlayer() and attacker:Alive() and util.Probability(2) then
		attacker:PlayVoiceSet(VOICESET_TAUNT)
	end

	local carrying = pl:GetCarrying()
	if carrying:IsValid() and carrying.Drop then carrying:Drop(nil, attacker == pl) end

	if not pl:CallStateFunction("DontCreateRagdoll", dmginfo) then
		pl:CreateRagdoll()
	end

	pl:AddDeaths(1)

	gamemode.Call("OnDoPlayerDeath", pl, attacker, dmginfo)
end

function GM:OnDoPlayerDeath(pl, attacker, dmginfo)
end

function GM:PlayerDeathSound()
	return true
end

function GM:SpawnRandomWeaponAtSpawn(class, teamid, silent)
	local spawn = table.Random(team.GetSpawnPoints(teamid))
	if not spawn then return end

	local ent = ents.Create(class)
	if ent:IsValid() then
		ent:SetPos(spawn:GetPos() + Vector(0, 0, 8))
		ent:Spawn()

		if not silent then
			local effectdata = EffectData()
				effectdata:SetOrigin(ent:LocalToWorld(ent:OBBCenter()))
			util.Effect("ballreset", effectdata, true, true)
		end
	end
end

function GM:SpawnRandomWeapon(silent)
	if self.VeryCompetitive or #ents.FindByClass("logic_norandomweapons") > 0 or self.TieBreaker then return end

	local weps = self:GetWeapons()
	if #weps == 0 then return end

	local overtime = self:IsOverTime()

	-- Pick a random weapon. But also we need to pick based on weight. Some have a higher chance to drop.
	local maxrandom = 0
	local randpick = {}
	for _, wepclass in pairs(weps) do
		local tab = scripted_ents.GetStored(wepclass)
		if tab then
			if (not overtime or tab.t.AllowDuringOverTime) and (not self.Competitive or tab.t.AllowInCompetitive) then
				local currently_in_play = #ents.FindByClass(wepclass)
				local max_in_play = tab.t.MaxActiveSets
				if max_in_play == nil or currently_in_play < max_in_play * 2 then
					local chance = tab.t.DropChance or 1
					randpick[wepclass] = {maxrandom, maxrandom + chance}
					maxrandom = maxrandom + chance
				end
			end
		end
	end

	local rand = math.Rand(0, maxrandom)
	local class

	for wepclass, v in pairs(randpick) do
		if rand >= v[1] and rand <= v[2] then
			class = wepclass
			break
		end
	end

	if class then
		self:SpawnRandomWeaponAtSpawn(class, TEAM_RED, silent)
		self:SpawnRandomWeaponAtSpawn(class, TEAM_BLUE, silent)
	end
end

function GM:EntityTakeDamage(ent, dmginfo)
	if ent:IsPlayer() then
		if ent:CallStateFunction("EntityTakeDamage", dmginfo) then return end

		if dmginfo:IsExplosionDamage() then
			local attacker = dmginfo:GetAttacker()
			if attacker:IsValid() and attacker:IsPlayer() and attacker:Team() == ent:Team() and ent ~= attacker then
				dmginfo:SetDamage(0)
				dmginfo:ScaleDamage(0)
				return
			end

			if dmginfo:GetDamage() >= 16 then
				ent:Ignite(dmginfo:GetDamage() / 20)
				ent:ThrowFromPosition(dmginfo:GetDamagePosition(), dmginfo:GetDamage() * 10, true, attacker)
			end
		end
	end
end

function GM:OnPlayerKnockedDownBy(pl, knocker)
end

function GM:Initialize()
	util.AddNetworkString("PlayableGamemodes")
	util.AddNetworkString("RoundAddedTime")
	util.AddNetworkString("PlayableGamemodes")
	util.AddNetworkString("fretta_teamchange")

	timer.Simple(self.WarmUpLength, function() GAMEMODE:StartRoundBasedGame() GAMEMODE:EndWarmUp() end)

	if self.AutomaticTeamBalance then
		timer.Create("CheckTeamBalance", 30, 0, function() GAMEMODE:CheckTeamBalance() end)
	end

	resource.AddFile("materials/refract_ring.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray1.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray2.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray3.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray4.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray5.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray6.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray7.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray8.vmt")
	resource.AddFile("sound/eft/ballreset.ogg")
	resource.AddFile("sound/eft/bigpole_swing.ogg")
	resource.AddFile("materials/overlays/statuscold.vmt")

	if self.ForceMappackDownload then
		resource.AddWorkshop("244859331")
	end

	util.AddNetworkString("eft_localsound")
	util.AddNetworkString("eft_endofgame")
	util.AddNetworkString("eft_nearestgoal")
	util.AddNetworkString("eft_teamscored")
	util.AddNetworkString("eft_screencrack")
	util.AddNetworkString("eft_overtime")

	self:RegisterWeapons()

	self:PrecacheResources()
end

function GM:EndWarmUp()
	for _, pl in pairs(player.GetAll()) do
		pl:SetDeaths(0)
		pl:SetFrags(0)
	end
end

local function gsub_randomsound(a, b) return math.random(a, b) end
function GM:LocalSound(soundfile, targets, pitch, vol)
	soundfile = string.gsub(soundfile, "%?(%d+)%|(%d+)", gsub_randomsound)

	net.Start("eft_localsound")
		net.WriteString(soundfile)
		net.WriteFloat(pitch or 100)
		net.WriteFloat(vol or 1)
	net.Send(targets or player.GetAll())
end

function GM:TeamSound(soundfile, teamid, pitch, vol)
	local targets
	if not teamid then
		targets = player.GetAll()
	elseif teamid == 0 then
		targets = team.GetPlayers(TEAM_UNASSIGNED)
		targets = table.Add(targets, team.GetPlayers(TEAM_SPECTATOR))
	else
		targets = team.GetPlayers(teamid)
	end

	self:LocalSound(soundfile, targets, pitch, vol)
end

function GM:SlowTimeEase(base, rate)
	local timescale = base or 0.1
	local timerate = rate or 0.5
	timer.Create("SlowTime", 0, 0, function()
		timescale = math.min(1, timescale + FrameTime() * timerate)
		game.SetTimeScale(timescale)
		if timescale == 1 then
			timer.Remove("SlowTime")
		end
	end)
end

function GM:SlowTime(timescale, duration)
	timescale = timescale or 0.1

	game.SetTimeScale(timescale)
	timer.Create("SlowTime", (duration or 1) * timescale, 1, function()
		game.SetTimeScale(1)
	end)
end

function GM:PlayerInitialSpawn(pl)
	self.BaseClass.PlayerInitialSpawn(self, pl)

	pl:SetCanWalk(false)
	pl:SprintDisable()
	pl:SetCustomCollisionCheck(true)
	pl:SetNoCollideWithTeammates(false)
	pl:SetAvoidPlayers(false)
	pl:CollisionRulesChanged()

	pl.NextHealthRegen = 0
	pl.LastDamaged = 0
	pl.m_KnockdownImmunityGlobal = 0
	pl.m_KnockdownImmunityChain = 0
end

function GM:OnPlayerChangedTeam(pl, teamid)
	self.BaseClass.OnPlayerChangedTeam(self, pl, teamid)

	pl:CollisionRulesChanged()
end

local NextSwitchFromTeamToSpec = {}
local NumTeamJoins = {}
function GM:PlayerCanJoinTeam(ply, teamid)
	if ply:Team() == teamid then
		ply:ChatPrint( "You're already on that team" )
		return false
	end

	if ply.AutoJoiningTeam then return true end

	local TimeBetweenSwitches = GAMEMODE.Competitive and 5 or GAMEMODE.SecondsBetweenTeamSwitches or 10
	if ply.LastTeamSwitch and RealTime() - ply.LastTeamSwitch < TimeBetweenSwitches then
		--ply.LastTeamSwitch = ply.LastTeamSwitch + 1
		ply:ChatPrint( Format( "Please wait %i more seconds before trying to change team again", (TimeBetweenSwitches - (RealTime() - ply.LastTeamSwitch)) + 1 ) )
		return false
	end

	if self.Competitive then return true end

	if team.Joinable(teamid) then
		local uid = ply:UniqueID()
		if ply:Team() == TEAM_SPECTATOR then
			if NextSwitchFromTeamToSpec[uid] and RealTime() < NextSwitchFromTeamToSpec[uid] then
				ply:ChatPrint("You have recently started spectating and cannot rejoin the match so easily. Wait "..math.ceil(ply.NextSwitchFromTeamToSpec - RealTime()).." more seconds.")
				return false
			end
		elseif ply:Team() ~= TEAM_UNASSIGNED then
			if (NumTeamJoins[uid] or 0) > 2 then
				ply:ChatPrint("You cannot swap teams anymore this match.")
				return false
			elseif GAMEMODE.AutomaticTeamBalance then
				local nummyteam = team.NumPlayers(ply:Team())
				local numotherteam = team.NumPlayers(teamid)

				if nummyteam <= numotherteam then
					ply:ChatPrint("You cannot swap teams because it would make them uneven.")
					return false
				end
			end
		end
	end

	return true
end

function GM:OnPlayerChangedTeam(pl, oldteam, newteam)
	self.BaseClass.OnPlayerChangedTeam(self, pl, oldteam, newteam)

	if team.Joinable(newteam) then
		local uid = pl:UniqueID()

		NumTeamJoins[uid] = (NumTeamJoins[uid] or 0) + 1

		if oldteam == TEAM_SPECTATOR then
			NextSwitchFromTeamToSpec[pl:UniqueID()] = GAMEMODE.SecondsBetweenTeamSwitchesFromSpec
		end
	end
end

function GM:OnPreRoundStart(num)
	game.CleanUpMap()

	self:RecalculateGoalCenters(TEAM_RED)
	self:RecalculateGoalCenters(TEAM_BLUE)

	UTIL_StripAllPlayers()
	UTIL_SpawnAllPlayers()

	self.NoFlex = true

	game.SetTimeScale(1)

	timer.Create("SpawnRandomWeapon", 10, 0, function() GAMEMODE:SpawnRandomWeapon() end)

	for i=1, math.random(3, 5) do
		self:SpawnRandomWeapon(true)
	end
end

function BroadcastLua(lua)
	for _, pl in pairs(player.GetAll()) do
		pl:SendLua(lua)
	end
end

function GM:BroadcastAction(subject, action)
	if type(subject) == "string" then
		BroadcastLua(string.format("GAMEMODE:AddPlayerAction(%q, %q)", subject, action))
	else
		BroadcastLua(string.format("GAMEMODE:AddPlayerAction(Entity("..subject:EntIndex().."), %q)", action))
	end
end

function GM:OnRoundResult(result, resulttext)
end

function GM:TeamScored(teamid, hitter, points, istouch)
	if not teamid or not self:InRound() or self:IsWarmUp() then return end

	self:SlowTime(0.1, 2.5)

	team.AddScore(teamid, points)

	hitter = hitter or NULL

	local hittername
	if hitter and hitter:IsValid() then
		if hitter:IsPlayer() then
			hittername = hitter:Name()
			hitter:AddFrags(math.ceil(math.Clamp(#player.GetAll() / 10, 0.05, 1) * self.PointsForScoring))
		else
			hittername = hitter:GetClass()
		end
	else
		hittername = "Something"
	end

	gamemode.Call("RoundEndWithResult", teamid, hittername.." from the "..team.GetName(teamid).." scored a "..(istouch and "touch down" or "goal").."!")

	for _, pl in pairs(player.GetAll()) do
		if (hitter == pl or math.random(2) == 1) and pl:GetObserverMode() == OBS_MODE_NONE and pl:Alive() then
			timer.Simple(math.Rand(0, 3), function() if pl:IsValid() then pl:PlayVoiceSet(teamid == pl:Team() and VOICESET_HAPPY or VOICESET_MAD) end end)
		end
	end

	local ball = GAMEMODE:GetBall()

	net.Start("eft_teamscored")
		net.WriteUInt(teamid, 8)
		net.WriteEntity(hitter)
		net.WriteUInt(points, 8)
		if ball:IsValid() and ball.LastBigPoleHit and ball.LastBigPoleHit == hitter and CurTime() < ball.LastBigPoleHitTime + 5 and not istouch then
			net.WriteBit(true)
		else
			net.WriteBit(false)
		end
	net.Broadcast()

	for _, ent in pairs(ents.FindByClass("logic_teamscore")) do
		ent:Input("onscore", hitter, ball)
		if teamid == TEAM_RED then
			ent:Input("onredscore", hitter, ball)
		elseif teamid == TEAM_BLUE then
			ent:Input("onbluescore", hitter, ball)
		end
	end

	gamemode.Call("OnTeamScored", teamid, hitter, points, istouch)
end

function GM:OnTeamScored(teamid, hitter, points, istouch)
end

GM.ForceMappackDownload = CreateConVar("eft_downloadmapaddon", "0", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Make clients download a workshop addon containing most EFT maps."):GetBool()
cvars.AddChangeCallback("eft_downloadmapaddon", function(cvar, oldvalue, newvalue)
	GAMEMODE.ForceMappackDownload = tonumber(newvalue) == 1

	if GAMEMODE.ForceMappackDownload then
		resource.AddWorkshop("244859331")
	end
end)
