ENT.Type = "brush"

ENT.m_Enabled = true

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "enabled" then
		self:SetEnabled(tonumber(value) == 1)
	end
end

function ENT:AcceptInput(name, activator, caller, args)
	name = string.lower(name)
	if name == "setenabled" then
		self:SetKeyValue("enabled", args)
		return true
	end
end

function ENT:Touch(ent)
	if self:GetEnabled() then
		if ent == GAMEMODE:GetBall() then
			ent:ReturnHome()
		elseif ent:IsPlayer() and ent:Alive() and ent:IsCarrying() and ent:GetCarry() == GAMEMODE:GetBall() then
			GAMEMODE:GetBall():ReturnHome()
		end
	end
end

function ENT:SetEnabled(enabled)
	self.m_Enabled = enabled
end

function ENT:GetEnabled()
	return self.m_Enabled
end
