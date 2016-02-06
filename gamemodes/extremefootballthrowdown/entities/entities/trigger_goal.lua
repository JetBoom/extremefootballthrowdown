ENT.Type = "brush"

SCORETYPE_TOUCH = 1
SCORETYPE_THROW = 2

ENT.m_TeamID = TEAM_RED
ENT.m_Points = 1
ENT.m_ScoreType = SCORETYPE_TOUCH
ENT.Enabled = true

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if string.sub(key, 1, 2) == "on" then
		self:AddOnOutput(key, value)
	elseif key == "points" then
		self:SetPoints(tonumber(value) or 1)
	elseif key == "scoretype" then
		self.m_ScoreType = tonumber(value) or SCORETYPE_TOUCH
	elseif key == "teamid" then
		self:SetTeamID(tonumber(value) or TEAM_RED)
	elseif key == "enabled" then
		self.Enabled = tonumber(value) == 1
	end
end

function ENT:AcceptInput(name, activator, caller, args)
	name = string.lower(name)
	if string.sub(name, 1, 2) == "on" then
		self:FireOutput(name, activator, caller, args)
	elseif name == "setscoretype" then
		self:SetKeyValue("scoretype", args)
		return true
	elseif name == "setenabled" then
		self:SetKeyValue("enabled", args)
		return true
	end
end

function ENT:Touch(ent)
	if not self.Enabled or GAMEMODE:IsWarmUp() then return end

	local istouch
	local pl
	if ent:IsPlayer() then
		local carry = ent:GetCarry()
		if carry:IsValid() and GAMEMODE:GetBall() == carry then
			pl = ent
			ent = carry
			istouch = true
		end
	end

	if ent == GAMEMODE:GetBall() and GAMEMODE:InRound() then
		local opposite = GAMEMODE:GetOppositeTeam(self:GetTeamID())
		if ent:GetLastCarrierTeam() == opposite and (istouch and bit.band(self.m_ScoreType, SCORETYPE_TOUCH) == SCORETYPE_TOUCH or not istouch and bit.band(self.m_ScoreType, SCORETYPE_THROW) == SCORETYPE_THROW) then
			local carrier = pl or ent:GetLastCarrier()

			gamemode.Call("TeamScored", opposite, carrier, self:GetPoints(), istouch)

			self:Input("onscore", carrier, ent)
		end
	end
end

function ENT:SetPoints(points)
	self.m_Points = points
end

function ENT:GetPoints()
	return self.m_Points
end

function ENT:SetTeamID(id)
	self.m_TeamID = id
end

function ENT:GetTeamID()
	return self.m_TeamID
end

function ENT:SetScoreType(scoretype)
	self.m_ScoreType = scoretype
end

function ENT:GetScoreType()
	return self.m_ScoreType
end
