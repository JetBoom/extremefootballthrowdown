ENT.Type = "brush"

AccessorFunc(ENT, "m_Enabled", "Enabled", FORCE_BOOL)
AccessorFunc(ENT, "m_StartTouchOnly", "StartTouchOnly", FORCE_BOOL)
AccessorFunc(ENT, "m_OverrideVelocity", "OverrideVelocity", FORCE_BOOL)
AccessorFunc(ENT, "m_PushFromOrigin", "PushFromOrigin", FORCE_BOOL)
AccessorFunc(ENT, "m_PushPlayers", "PushPlayers", FORCE_BOOL)
AccessorFunc(ENT, "m_PushPhysObjects", "PushPhysObjects", FORCE_BOOL)
AccessorFunc(ENT, "m_PushBall", "PushBall", FORCE_BOOL)
AccessorFunc(ENT, "m_KnockDown", "KnockDown", FORCE_BOOL)
AccessorFunc(ENT, "m_PushVelocity", "PushVelocity")

function ENT:Initialize()
	if self:GetPushVelocity() == nil then self:SetPushVelocity(0) end
	if self:GetEnabled() == nil then self:SetEnabled(true) end
	if self:GetStartTouchOnly() == nil then self:SetStartTouchOnly(true) end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "starttouchonly" then
		self:SetStartTouchOnly((tonumber(value) or 0) == 1)
	elseif key == "overridevelocity" then
		self:SetOverrideVelocity((tonumber(value) or 0) == 1)
	elseif key == "pushfromorigin" then
		self:SetPushFromOrigin((tonumber(value) or 0) == 1)
	elseif key == "pushplayers" then
		self:SetPushPlayers((tonumber(value) or 0) == 1)
	elseif key == "pushball" then
		self:SetPushBall((tonumber(value) or 0) == 1)
	elseif key == "pushphysobjects" then
		self:SetPushPhysObjects((tonumber(value) or 0) == 1)
	elseif key == "knockdown" then
		self:SetKnockDown((tonumber(value) or 0) == 1)
	elseif key == "pushvelocity" then
		self:SetPushVelocity(tonumber(value) or Vector(value or "") or 0)
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
		self:Push(ent)
	end
end

function ENT:StartTouch(ent)
	if self:GetStartTouchOnly() and self:GetEnabled() then
		self:Push(ent)
	end
end

function ENT:Push(ent)
	if not ent:IsValid() then return end

	local passes = false
	local isphys = false
	if ent:IsPlayer() then
		passes = self:GetPushPlayers()
	elseif GAMEMODE:GetBall() == ent then
		passes = self:GetPushBall() or self:GetPushPhysObjects()
		isphys = true
	else
		isphys = ent:GetPhysicsObject():IsValid() and ent:GetPhysicsObject():IsMoveable() and ent:GetMoveType() == MOVETYPE_VPHYSICS
		if isphys then
			passes = self:GetPushPhysObjects()
		end
	end

	if not passes then return end

	local vel
	if self:GetPushFromOrigin() then
		local origin = self:LocalToWorld(self:OBBCenter())
		local nearest = ent:NearestPoint(origin)
		vel = (nearest - origin):GetNormalized() * self:GetPushVelocity()
	else
		vel = self:GetPushVelocity()
	end

	if self:GetOverrideVelocity() then
		if isphys then
			ent:GetPhysicsObject():SetVelocityInstantaneous(vel)
		else
			if ent:IsPlayer() then
				ent:SetGroundEntity(NULL)
				if self:GetKnockDown() then
					ent:KnockDown()
				end
			end
			ent:SetLocalVelocity(vel)
		end
	elseif isphys then
		if self:GetStartTouchOnly() then
			ent:GetPhysicsObject():AddVelocity(vel)
		else
			ent:GetPhysicsObject():AddVelocity(FrameTime() * vel)
		end
	else
		if ent:IsPlayer() then
			ent:SetGroundEntity(NULL)
			if self:GetKnockDown() then
				ent:KnockDown()
			end
		end

		if self:GetStartTouchOnly() then
			ent:SetVelocity(vel)
		else
			ent:SetVelocity(FrameTime() * vel)
		end
	end
end
