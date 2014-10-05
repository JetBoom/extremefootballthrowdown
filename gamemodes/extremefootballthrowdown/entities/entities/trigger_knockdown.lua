ENT.Type = "brush"

AccessorFunc(ENT, "m_StartTouchOnly", "StartTouchOnly", FORCE_BOOL)
AccessorFunc(ENT, "m_Enabled", "Enabled", FORCE_BOOL)
AccessorFunc(ENT, "m_KnockdownTime", "KnockdownTime", FORCE_NUMBER)

function ENT:Initialize()
	if self:GetEnabled() == nil then self:SetEnabled(true) end
	if self:GetStartTouchOnly() == nil then self:SetStartTouchOnly(true) end
	if self:GetKnockdownTime() == nil then self:SetKnockdownTime(2.5) end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "starttouchonly" then
		self:SetStartTouchOnly((tonumber(value) or 0) == 1)
	elseif key == "enabled" then
		self:SetEnabled((tonumber(value) or 0) == 1)
	elseif key == "knockdowntime" then
		self:SetKnockdownTime(tonumber(value) or 2.5)
	end
end

function ENT:AcceptInput(name, activator, caller, args)
	name = string.lower(name)
	if string.sub(name, 1, 3) == "set" then
		self:SetKeyValue(string.sub(name, 4), args)
		return true
	end
end

function ENT:Touch(ent)
	if not self:GetStartTouchOnly() and self:GetEnabled() then
		self:KnockDown(ent)
	end
end

function ENT:StartTouch(ent)
	if self:GetStartTouchOnly() and self:GetEnabled() then
		self:KnockDown(ent)
	end
end

function ENT:KnockDown(ent)
	if not ent:IsValid() or not ent:IsPlayer() or ent:GetState() == STATE_KNOCKEDDOWN then return end

	ent:KnockDown(self:GetKnockdownTime())
end
