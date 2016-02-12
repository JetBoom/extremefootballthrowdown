local meta = FindMetaTable("Player")
if not meta then return end

function meta:EndState(nocallended)
	self:SetState(STATE_NONE, nil, nil, nocallended)
end

local IN_FORWARD = IN_FORWARD
function meta:CanCharge()
	return self:GetState() == STATE_NONE and self:GetStateInteger() == 0
	and self:OnGround() and not self:Crouching() and self:WaterLevel() <= 1
	and self:KeyDown(IN_FORWARD)
	and self:GetVelocity():LengthSqr() >= 84100
end

function meta:FixModelAngles(velocity)
	local eye = self:EyeAngles()
	self:SetLocalAngles(eye)
	self:SetPoseParameter("move_yaw", math.NormalizeAngle(velocity:Angle().yaw - eye.y))
end

function meta:RemoveAllStatus(bSilent, bInstant)
	if bInstant then
		for _, ent in pairs(ents.FindByClass("status_*")) do
			if not ent.NoRemoveOnDeath and ent:GetOwner() == self then
				ent:Remove()
			end
		end
	else
		for _, ent in pairs(ents.FindByClass("status_*")) do
			if not ent.NoRemoveOnDeath and ent:GetOwner() == self then
				ent.SilentRemove = bSilent
				ent:SetDie()
			end
		end
	end
end

function meta:RemoveStatus(sType, bSilent, bInstant)
	local removed
	for _, ent in pairs(ents.FindByClass("status_"..sType)) do
		if ent:GetOwner() == self then
			if bInstant then
				ent:Remove()
			else
				ent.SilentRemove = bSilent
				ent:SetDie()
			end
			removed = true
		end
	end
	return removed
end

function meta:GetStatus(sType)
	local ent = self["status_"..sType]
	if ent and ent:IsValid() and ent.Owner == self then return ent end
end

function meta:GiveStatus(sType, fDie)
	local cur = self:GetStatus(sType)
	if cur then
		if fDie then
			cur:SetDie(fDie)
		end
		cur:SetPlayer(self, true)
		return cur
	else
		local ent = ents.Create("status_"..sType)
		if ent:IsValid() then
			ent:Spawn()
			if fDie then
				ent:SetDie(fDie)
			end
			ent:SetPlayer(self)
			return ent
		end
	end
end

function meta:KnockDown(time, knocker)
	if not self:Alive() or self:InVehicle() or self:GetState() == STATE_PREROUND then return end

	time = time or 2.75
	self:SetState(STATE_KNOCKEDDOWN, time)

	if knocker and knocker:IsValid() and knocker:IsPlayer() then
		gamemode.Call("OnPlayerKnockedDownBy", self, knocker)
	end

	local carry = self:GetCarrying()
	if carry:IsValid() and carry.Drop then
		carry:Drop()
	end
end

function meta:ResetKnockdownImmunity(pl, time)
	self:SetKnockdownImmunity(pl, CurTime() + 3.75)
end

function meta:SetKnockdownImmunity(pl, time)
	self.m_KnockdownImmunity[pl] = time
end

function meta:GetKnockdownImmunity(pl)
	return self.m_KnockdownImmunity[pl] or 0
end

function meta:ResetChargeImmunity(pl, time)
	self:SetChargeImmunity(pl, CurTime() + 0.45)
end

function meta:SetChargeImmunity(pl, time)
	self.m_ChargeImmunity[pl] = time
end

function meta:GetChargeImmunity(pl)
	return self.m_ChargeImmunity[pl] or 0
end

function meta:SetDiveTackleThrowAwayTime(time)
	self.m_DiveTackleThrowAwayTime = time
end

function meta:GetDiveTackleThrowAwayTime()
	return self.m_DiveTackleThrowAwayTime or 0
end

function meta:ChargeLaunch(hitent, knockdown)
	hitent:ThrowFromPosition(self:GetLaunchPos(), self:GetVelocity():Length() * 1.65, knockdown, self)
end

function meta:ChargeHit(hitent, tr)
	if hitent:ImmuneToAll() then return end

	self:SetLastChargeHit(CurTime())

	local knockdown = CurTime() >= hitent:GetKnockdownImmunity(self)
	self:ChargeLaunch(hitent, knockdown)
	hitent:ResetChargeImmunity(self)
	if knockdown then
		hitent:ResetKnockdownImmunity(self)
	end
	hitent:TakeDamage(5, self)

	self:SetVelocity(self:GetVelocity() * -0.03)
	self:ViewPunch(VectorRand():Angle() * (math.random(0, 1) == 0 and -1 or 1) * 0.15)

	local effectdata = EffectData()
		if tr then
			effectdata:SetOrigin(tr.HitPos)
		else
			effectdata:SetOrigin(hitent:NearestPoint(self:EyePos()))
		end
		effectdata:SetNormal(self:GetVelocity():GetNormalized())
		effectdata:SetEntity(hitent)
	util.Effect("chargehit", effectdata, true, true)
end

function meta:PunchHit(hitent, tr)
	if hitent:ImmuneToAll() then return end

	local knockdown = CurTime() >= hitent:GetKnockdownImmunity(self)
	hitent:ThrowFromPosition(self:GetLaunchPos(), 360, knockdown, self)
	if knockdown then
		hitent:ResetKnockdownImmunity(self)
	end
	hitent:TakeDamage(10, self)

	self:ViewPunch(VectorRand():Angle() * (math.random(2) == 1 and -1 or 1) * 0.1)

	local effectdata = EffectData()
		if tr then
			effectdata:SetOrigin(tr.HitPos)
			effectdata:SetNormal(tr.HitNormal)
		else
			effectdata:SetOrigin(hitent:NearestPoint(self:EyePos()))
			effectdata:SetNormal(self:GetForward() * -1)
		end
		effectdata:SetEntity(hitent)
	util.Effect("punchhit", effectdata, true, true)
end

local oldrag = meta.CreateRagdoll
function meta:CreateRagdoll()
	if not IsValid(self:GetRagdollEntity()) then
		oldrag(self)
	end
end
