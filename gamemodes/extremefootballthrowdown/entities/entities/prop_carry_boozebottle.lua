AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "prop_carry_base"

ENT.Name = "Booze Bottle"

ENT.IsPropWeapon = true

ENT.Model = Model("models/props_junk/garbage_glassbottle001a.mdl")
ENT.ThrowForce = 1000

ENT.MaxActiveSets = 2

ENT.BoneName = "ValveBiped.Bip01_R_Hand"
ENT.AttachmentOffset = Vector(5, 5, -5)
ENT.AttachmentAngles = Angle(0, 180, 180)

function ENT:Initialize()
	self:SetModelScale(1.75, 0)

	self.BaseClass.Initialize(self)
end

function ENT:SecondaryAttack(pl)
	if pl:CanThrow() then
		pl:SetState(STATE_THROW)
	end

	return true
end

function ENT:Move(pl, move)
	move:SetMaxSpeed(move:GetMaxSpeed() * 0.95)
	move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.95)
end

function ENT:GetImpactSpeed()
	return self:GetLastCarrier():IsValid() and 200 or 450
end

if CLIENT then return end

function ENT:OnThink()
	if self.Exploded then
		self:Remove()
	elseif self.PhysicsData then
		self:Explode(self.PhysicsData.HitPos, self.PhysicsData.HitNormal, self.PhysicsData.HitEntity)
		self:Remove()
	elseif self.TouchedEnemy then
		self:Explode(nil, nil, self.TouchedEnemy)
		self:Remove()
	end
end

function ENT:PhysicsCollide(data, phys)
	if data.Speed >= self:GetImpactSpeed() then
		self.PhysicsData = data
		self:NextThink(CurTime())
	end
end

function ENT:Explode(hitpos, hitnormal, hitent)
	if self.Exploded then return end
	self.Exploded = true
	self.PhysicsData = nil

	self:NextThink(CurTime())

	hitpos = hitpos or self:GetPos()
	hitnormal = hitnormal or Vector(0, 0, 1)

	for _, ent in pairs(ents.FindInSphere(hitpos, 200)) do
		if ent:IsPlayer() and ent:Alive() and ent:GetObserverMode() == OBS_MODE_NONE and (ent:Team() ~= self:GetLastCarrierTeam() or ent == self:GetLastCarrier()) and util.IsVisible(ent:EyePos(), hitpos) then
			local has = false
			for __, ent2 in pairs(ents.FindByClass("status_boozed")) do
				if ent2:GetOwner() == ent then
					has = true
				end
			end

			if not has then
				local status = ents.Create("status_boozed")
				if status:IsValid() then
					status:SetPos(ent:LocalToWorld(ent:OBBCenter()))
					status:SetOwner(ent)
					status:SetParent(ent)
					status:Spawn()
				end
			end
		end
	end

	if IsValid(hitent) and hitent:IsPlayer() and hitent:Team() ~= self:GetLastCarrierTeam() then
		hitent:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav")
		hitent:ThrowFromPosition(hitpos + Vector(0, 0, -24), math.Clamp(self:GetVelocity():Length() * 0.6, 250, 550), true, self:GetLastCarrier())
		hitent:TakeDamage(10, self:GetLastCarrier(), self)
	end

	local ent = ents.Create("prop_physics")
	if ent:IsValid() then
		ent:SetPos(self:GetPos())
		ent:SetAngles(self:GetAngles())
		ent:SetModel(self:GetModel())
		ent:Spawn()

		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			phys:SetVelocityInstantaneous(self:GetVelocity())
		end

		ent:Fire("break", "", 0)
	end
	
	local ball = GAMEMODE:GetBall()
	if ball:IsValid() and ball:GetState() == BALL_STATE_NONE then
		local nearest = ball:NearestPoint(hitpos)
		if nearest:DistToSqr(hitpos) <= 40000 and util.IsVisible(nearest, hitpos) then
			ball:SetState(BALL_STATE_BOOZEBALL, 8)
		end
	end
	
	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
	util.Effect("exp_boozebottle", effectdata)
end

function ENT:OnTouch(ent)
	if ent:IsPlayer() and ent:Alive() and self:GetVelocity():Length() >= self:GetImpactSpeed() and ent:Team() ~= self:GetLastCarrierTeam() then
		self.TouchedEnemy = ent
	end
end
