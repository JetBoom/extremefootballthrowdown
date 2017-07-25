ENT.Type = "brush"

ENT.m_Enabled = true
ENT.m_Powerup = "speedball"
ENT.m_PowerupTime = 0

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "enabled" then
		self:SetEnabled(tonumber(value) == 1)
	elseif key == "poweruptime" then
		self.m_PowerupTime = tonumber(value) or self.m_PowerupTime or 0
	elseif key == "powerup" then
		self.m_Powerup = tostring(value)
	end
end

function ENT:AcceptInput(name, activator, caller, args)
	name = string.lower(name)
	if name == "setenabled" then
		self:SetKeyValue("enabled", args)
		return true
	elseif name == "setpoweruptime" then
		self:SetKeyValue("poweruptime", args)
	elseif name == "setpowerup" then
		self:SetKeyValue("powerup", args)
	end
end

function ENT:Touch(ent)
	if self:GetEnabled() then
		if ent:IsPlayer() and ent:Alive() and ent:IsCarrying() and ent:GetCarry() == GAMEMODE:GetBall() then ent = GAMEMODE:GetBall() end

		if ent == GAMEMODE:GetBall() and ent:GetState() ~= BALL_STATE_SCOREBALL then
			local desstate = _G["BALL_STATE_"..string.upper(self.m_Powerup)] or 0
			if ent:GetState() ~= desstate then
				ent:SetState(desstate, self.m_PowerupTime)
			end
		end
	end
end

function ENT:SetEnabled(enabled)
	self.m_Enabled = enabled
end

function ENT:GetEnabled()
	return self.m_Enabled
end
