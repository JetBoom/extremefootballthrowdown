ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Name = "The Ball"

ENT.ResetTime = 20

BALL_STATE_NONE = 0
ENT.States = {}
ENT.States[BALL_STATE_NONE] = {}
local filelist = file.Find(ENT.Folder.."/states/*.lua", "LUA")
table.sort(filelist)
for k, v in ipairs(filelist) do
	local _, __, foldername = string.find(v, "([%w_]*)%.lua")

	STATE = {}
	STATE.FolderName = foldername
	STATE.Index = k

	AddCSLuaFile("states/"..v)
	include("states/"..v)

	ENT.States[k] = STATE
	ENT.States[foldername] = STATE
	_G["BALL_STATE_"..string.upper(foldername)] = STATE.Index

	STATE = nil
end

function ENT:Move(pl, move)
	if pl:HasPity() then
		move:SetMaxSpeed(move:GetMaxSpeed() * 0.95)
		move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.95)
	else
		move:SetMaxSpeed(move:GetMaxSpeed() * 0.7571)
		move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.7571)
	end
end

function ENT:OverTimeScoreBall()
	return not GAMEMODE.IsEndOfGame and GAMEMODE:IsOverTime() and GAMEMODE.OvertimeScoreBall > 0 and GAMEMODE:GetGameTimeLeft() <= GAMEMODE.OvertimeScoreBall and team.GetScore(TEAM_RED) == team.GetScore(TEAM_BLUE)
end

function ENT:GetThrowForceMultiplier(pl)
	return self:CallStateFunction("GetThrowForceMultiplier", pl)
end

function ENT:GetLastCarrier()
	return self:GetDTEntity(3)
end

function ENT:SetLastCarrier(ent)
	self:SetDTEntity(3, ent)
	if ent:IsValid() and ent:IsPlayer() then
		self:SetLastCarrierTeam(ent:Team())
	end
end

function ENT:GetLastCarrierTeam()
	return self:GetDTInt(3)
end

function ENT:SetLastCarrierTeam(teamid)
	self:SetDTInt(3, teamid)
end

function ENT:SetRedGoalCenter(vec)
	self:SetDTVector(0, vec)
end

function ENT:GetRedGoalCenter()
	return self:GetDTVector(0)
end

function ENT:SetBlueGoalCenter(vec)
	self:SetDTVector(1, vec)
end

function ENT:GetBlueGoalCenter()
	return self:GetDTVector(1)
end

function ENT:SetHome(vec)
	self:SetDTVector(3, vec)
end

function ENT:GetHome()
	return self:GetDTVector(3)
end

function ENT:SetStateEnd(time)
	self:SetDTFloat(0, time)
end

function ENT:GetStateEnd()
	return self:GetDTFloat(0)
end

function ENT:SetStateStart(time)
	self:SetDTFloat(1, time)
end

function ENT:GetStateStart()
	return self:GetDTFloat(1)
end

function ENT:SetAutoReturn(time)
	self:SetDTFloat(2, time)
end

function ENT:GetAutoReturn()
	return self:GetDTFloat(2)
end

function ENT:SetStateVector(vec)
	self:SetDTVector(2, vec)
end

function ENT:GetStateVector()
	return self:GetDTVector(2)
end

function ENT:SetStateVector(m)
	self:SetDTVector(2, m)
end

function ENT:GetStateVector()
	return self:GetDTVector(2)
end

function ENT:SetStateEntity(m)
	self:SetDTEntity(2, m)
end

function ENT:GetStateEntity()
	return self:GetDTEntity(2)
end

function ENT:SecondaryAttack(pl)
	if pl:CanThrow() then
		pl:SetState(STATE_THROW)

		return true
	end
end

function ENT:SetState(state, duration)
	if self:OverTimeScoreBall() and state ~= BALL_STATE_SCOREBALL then
		return
	end

	if SERVER then
		local samestate = self:GetState() == state
		if not samestate then
			self:CallStateFunction("End")
		end
		self:SetDTInt(2, state)
		self:CallStateFunction("Start", samestate)
		self:SetStateEnd(duration and CurTime() + duration or 0)
		self:SetStateStart(CurTime())
		self:CollisionRulesChanged()

		if not samestate then
			if state == BALL_STATE_NONE then
				GAMEMODE:BroadcastAction("Ball", "powered down")
			elseif self.States[state].Name then
				GAMEMODE:BroadcastAction("Ball", "powered up to "..string.upper(self.States[state].Name))
			end
		end
	end

	self:SetDTInt(2, state)
end

function ENT:GetState()
	return self:GetDTInt(2)
end

function ENT:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	return self:CallStateFunction("UpdateAnimation", pl, velocity, maxseqgroundspeed)
end

function ENT:GetAcceleration()
	return self:GetStateTable().Acceleration
end

function ENT:CallStateFunction(funcname, ...)
	local statetab = self.States[self:GetState()]
	if statetab and statetab[funcname] then
		return statetab[funcname](statetab, self, ...)
	end
end

function ENT:GetStateTable()
	return self.States[self:GetState()]
end

function ENT:SetCarrier(ent)
	local prevcarrier = self:GetCarrier()

	ent = ent or NULL

	self:SetDTEntity(1, ent)
	self:CollisionRulesChanged()

	if SERVER then
		self.LastOnGround = CurTime()
	end

	if CLIENT then return end

	local phys = self:GetPhysicsObject()
	if ent:IsValid() then
		GAMEMODE.SuppressTimeLimit = nil

		local entteam = ent:Team()

		if entteam ~= self.LastCarrierTeam then
			self.LastCarrierTeam = entteam
		end

		self:Input("onpickedup", ent, ent)
		if entteam == TEAM_RED then
			self:Input("onpickedupbyred", ent, ent)
		elseif entteam == TEAM_BLUE then
			self:Input("onpickedupbyblue", ent, ent)
		end

		self:SetLastCarrier(ent)
		ent:SetCarrying(self)
		self:AlignToCarrier()
		if phys:IsValid() then phys:EnableMotion(false) end
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

		GAMEMODE:BroadcastAction(ent:Name(), "picked up the ball!")

		self:CallStateFunction("PickedUp", ent)

		self.NextUpdateNearestGoal = 0
		self:UpdateNearestGoal()
	else
		if phys:IsValid() then phys:EnableMotion(true) phys:Wake() end
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	end

	for _, p in pairs(player.GetAll()) do
		if p ~= ent and p:GetCarrying() == self then p:SetCarrying(NULL) end
	end

	if prevcarrier ~= ent then
		self:CallStateFunction("CarrierChanged", ent, prevcarrier)
	end
end

function ENT:GetCarrier()
	return self:GetDTEntity(1)
end

function ENT:AlignToCarrier()
	local carrier = self:GetCarrier()
	if carrier:IsValid() then
		local set = false
		local attachid = carrier:LookupAttachment("anim_attachment_rh")
		if attachid and attachid > 0 then
			local attach = carrier:GetAttachment(attachid)
			if attach then
				self:SetPos(attach.Pos)
				self:SetAngles(attach.Ang)
				set = true
			end
		end

		if not set then
			self:SetPos(carrier:LocalToWorld(carrier:OBBCenter()))
		end
	end
end

util.PrecacheSound("npc/turret_floor/click1.wav")
