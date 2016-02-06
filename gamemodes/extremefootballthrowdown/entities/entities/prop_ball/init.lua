AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.LastCarrierTeam = 0
ENT.LastOnGround = 0

function ENT:Initialize()
	self:SetModel("models/Roller.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:SetMass(25)
		phys:EnableMotion(true)
		phys:EnableDrag(false)
		phys:SetDamping(0, 0.25)
		phys:Wake()
	end

	local balltrig = ents.Create("prop_balltrigger")
	if balltrig:IsValid() then
		balltrig:SetPos(self:GetPos())
		balltrig:SetAngles(self:GetAngles())
		balltrig:SetOwner(self)
		balltrig:SetParent(self)
		balltrig:Spawn()
		self.BallTrigger = balltrig
	end

	self.LastCarrierTeam = 0

	gamemode.Call("SetBall", self)
	gamemode.Call("SetBallHome", self:GetPos())
end

local ShuttingDown = false
hook.Add("ShutDown", "nomore", function()
	ShuttingDown = true
end)
if not game.PreBallCleanUpMap then
	game.PreBallCleanUpMap = game.CleanUpMap
	function game.CleanUpMap()
		ShuttingDown = true
		game.PreBallCleanUpMap()
		ShuttingDown = false
	end
end
function ENT:OnRemove()
	if ShuttingDown or GAMEMODE.TieBreaker then return end

	-- craaaaaazzzyyyyy physics
	local ent = ents.Create(self:GetClass())
	if ent:IsValid() then
		ent:SetPos(GAMEMODE:GetBallHome())
		ent:Spawn()
	end
end

function ENT:ReturnHome()
	GAMEMODE.SuppressTimeLimit = nil

	self:SetCarrier(NULL)
	self:SetAutoReturn(0)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:SetVelocityInstantaneous(Vector(0, 0, 0))
	end

	self.LastCarrierTeam = 0
	GAMEMODE:LocalSound("eft/ballreset.ogg")

	local effectdata = EffectData()
	effectdata:SetOrigin(self:GetPos())
	util.Effect("ballreset", effectdata, true, true)

	GAMEMODE:BroadcastAction("Ball", "reset")
	gamemode.Call("ReturnBall")
	self:Input("onreturnhome")
	self:CallStateFunction("Returned")
	self:SetState(0)

	effectdata:SetOrigin(self:GetPos())
	util.Effect("ballreset", effectdata, true, true)
end
ENT.Reset = ENT.ReturnHome

function ENT:Think()
	self:AlignToCarrier()

	local carrier = self:GetCarrier()
	if not carrier:IsValid() or not carrier:Alive() then
		self:SetCarrier(NULL)
	end

	if self:GetAutoReturn() > 0 then
		if carrier:IsValid() then self:SetAutoReturn(0) end
	elseif not carrier:IsValid() then
		self:SetAutoReturn(CurTime() + self.ResetTime)
	end

	if carrier:IsValid() and carrier:OnGround() then
		self.LastOnGround = CurTime()
	end

	if self:OverTimeScoreBall() and self:GetState() ~= BALL_STATE_SCOREBALL then
		local timeleft = GAMEMODE:GetGameTimeLeft() - 0.11
		if timeleft < 0 then
			timeleft = 0
		end
		self:SetState(BALL_STATE_SCOREBALL, timeleft)
	end

	if self:GetAutoReturn() > 0 and CurTime() >= self:GetAutoReturn()
	or self:WaterLevel() > 0 and not self:GetStateTable().NoWaterReturn
	or carrier:IsValid() and (carrier:WaterLevel() >= 2 and not self:GetStateTable().NoWaterReturn or CurTime() >= self.LastOnGround + 20) then -- If a person is in the air 20 seconds or more then they're probably glitching a trigger_push or something.
		self:ReturnHome()
		return
	end

	self:CallStateFunction("Think")

	if self:GetStateEnd() ~= 0 and CurTime() >= self:GetStateEnd() then
		self:SetState(0)
	end

	self:CheckScoring()
	self:UpdateNearestGoal()

	self:NextThink(CurTime())
	return true
end

ENT.NextUpdateNearestGoal = 0
function ENT:UpdateNearestGoal()
	local carrier = self:GetCarrier()
	if not carrier:IsValid() or RealTime() < self.NextUpdateNearestGoal then return end
	self.NextUpdateNearestGoal = RealTime() + 0.5

	local carrierpos = carrier:GetPos()
	local teamid = GAMEMODE:GetOppositeTeam(carrier:Team())

	local thenearest
	local thenearestdist = math.huge
	for _, ent in pairs(ents.FindByClass("trigger_goal")) do
		if ent.Enabled and ent.m_TeamID == teamid and ent.m_ScoreType ~= 0 then
			local nearest = ent:NearestPoint(carrierpos)
			local dist = nearest:Distance(carrierpos)
			if dist < thenearestdist then
				thenearestdist = dist
				thenearest = nearest
			end
		end
	end

	if thenearest then
		net.Start("eft_nearestgoal")
			net.WriteVector(thenearest)
		net.Send(carrier)
	end
end

function ENT:CheckScoring()
	if not GetGlobalBool("InRound", true) or GAMEMODE:IsWarmUp() then return end

	-- Some damn edgy coding incoming.
	local carrier = self:GetCarrier()
	if carrier:IsValid() then
		self:CheckScoringCarrier(carrier)
	else
		self:CheckScoringPhys()
	end
end

function ENT:CheckScoringCarrier(carrier)
	local teamid = GAMEMODE:GetOppositeTeam(carrier:Team())
	local ballpos = self:GetPos()
	local ballvel = carrier:GetVelocity()
	local ballpredictedpos = ballpos + ballvel
	local balldir = ballvel:GetNormalized()

	for _, ent in pairs(ents.FindByClass("trigger_goal")) do
		if ent.Enabled and ent.m_TeamID == teamid and bit.band(ent.m_ScoreType, SCORETYPE_TOUCH) ~= 0 then
			local nearest = ent:NearestPoint(ballpredictedpos)
			local dist = nearest:Distance(ballpos)
			if (dist <= 400 and balldir:Dot((nearest - ballpos):GetNormalized()) >= 0.85 or dist <= 128) and util.IsVisible(nearest, ballpos) then
				GAMEMODE:SlowTime(0.5, 0.75)
				break
			end
		end
	end
end

function ENT:CheckScoringPhys()
	local ballvel = self:GetVelocity()
	if ballvel:Length() <= 100 then return end

	local ballpos = self:GetPos()
	local ballpredictedpos = ballpos + ballvel
	local balldir = ballvel:GetNormalized()

	for _, ent in pairs(ents.FindByClass("trigger_goal")) do
		if ent.Enabled and bit.band(ent.m_ScoreType, SCORETYPE_THROW) ~= 0 then
			local nearest = ent:NearestPoint(ballpredictedpos)
			local dist = nearest:Distance(ballpos)
			if (dist <= 360 and balldir:Dot((nearest - ballpos):GetNormalized()) >= 0.85 or dist <= 92) and util.IsVisible(nearest, ballpos) then
				GAMEMODE:SlowTime(0.5, 0.75)
				break
			end
		end
	end
end

function ENT:PhysicsUpdate(phys, dt)
	phys:Wake()

	self:CallStateFunction("PhysicsUpdate", phys, dt)
end

function ENT:Touch(ent)
	if self:CallStateFunction("PreTouch", ent) then return end

	if ent:IsPlayer() and not self:GetCarrier():IsValid() and ent:Alive() and not ent:IsCarrying() and not GAMEMODE:IsWarmUp()
	and ent:CallStateFunction("CanPickup", self) and (self:GetLastCarrier() ~= ent or CurTime() > (self.m_PickupImmunity or 0))
	and (ent:Team() ~= self:GetLastCarrierTeam() or CurTime() > (self.m_TeamPickupImmunity or 0)) then
		if team.HasPlayers(ent:Team() == TEAM_RED and TEAM_BLUE or TEAM_RED) then
			self:SetCarrier(ent)
			ent:AddFrags(5)

			if util.Probability(3) then
				ent:PlayVoiceSet(VOICESET_TAUNT)
			end
		else
			ent:PrintMessage(HUD_PRINTCENTER, "You can't take the ball with no one on the other team!")
		end
	end

	self:CallStateFunction("Touch", ent)
end

function ENT:StartTouch(ent)
	self:CallStateFunction("StartTouch", ent)
end

function ENT:EndTouch(ent)
	self:CallStateFunction("EndTouch", ent)
end

function ENT:Drop(throwforce, suicide)
	self.m_PickupImmunity = CurTime() + 1

	local carrier = self:GetCarrier()
	if carrier:IsValid() then
		self:SetCarrier(NULL)
		if not throwforce and not suicide then
			local phys = self:GetPhysicsObject()
			if phys:IsValid() then
				phys:Wake()
				phys:SetVelocityInstantaneous(carrier:GetVelocity() * 1.75 + Vector(0, 0, 128))
			end
		end

		if throwforce then
			GAMEMODE:BroadcastAction(carrier:Name(), "threw the ball!")
			self.m_TeamPickupImmunity = CurTime() + 0.25
		else
			GAMEMODE:BroadcastAction(carrier:Name(), "dropped the ball!")
		end
	end

	if throwforce then
		GAMEMODE.SuppressTimeLimit = CurTime() + 5

		self:Input("onthrown", carrier, carrier)

		if carrier:IsValid() then
			if carrier:Team() == TEAM_RED then
				self:Input("onthrownbyred", carrier, carrier)
			elseif carrier:Team() == TEAM_BLUE then
				self:Input("onthrownbyblue", carrier, carrier)
			end
		end
	else
		self:Input("ondropped", carrier, carrier)

		if carrier:IsValid() then
			if carrier:Team() == TEAM_RED then
				self:Input("ondroppedbyred", carrier, carrier)
			elseif carrier:Team() == TEAM_BLUE then
				self:Input("ondroppedbyblue", carrier, carrier)
			end
		end
	end

	self:CallStateFunction("Dropped", throwforce, carrier)
end

util.PrecacheSound("npc/turret_floor/click1.wav")
function ENT:PhysicsCollide(data, phys)
	if data.HitNormal.z <= -0.75 and util.TraceLine({start = data.HitPos - data.HitNormal, endpos = data.HitPos + data.HitNormal, filter = self, mask = MASK_SOLID_BRUSHONLY}).HitSky then
		self:ReturnHome()
	elseif not self:CallStateFunction("PhysicsCollide", data, phys) then
		if 30 < data.Speed and 0.2 < data.DeltaTime then
			self:EmitSound("npc/turret_floor/click1.wav")
		end

		local normal = data.OurOldVelocity:GetNormalized()
		phys:SetVelocityInstantaneous(data.Speed * 0.75 * (2 * data.HitNormal * data.HitNormal:Dot(normal * -1) + normal))
	end
end

function ENT:AcceptInput(name, activator, caller, args)
	name = string.lower(name)
	if string.sub(name, 1, 2) == "on" then
		self:FireOutput(name, activator, caller, args)
	end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if string.sub(key, 1, 2) == "on" then
		self:AddOnOutput(key, value)
	end
end

function ENT:OnTakeDamage(dmginfo)
	self:TakePhysicsDamage(dmginfo)

	if self:GetState() == BALL_STATE_NONE and dmginfo:IsExplosionDamage() and dmginfo:GetDamage() > 10 then
		self:SetState(BALL_STATE_BLITZBALL, 20)
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end
