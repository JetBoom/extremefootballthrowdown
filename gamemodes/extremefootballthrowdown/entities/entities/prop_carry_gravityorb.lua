AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "prop_carry_base"

ENT.Name = "Gravity Orb"

ENT.IsPropWeapon = true

ENT.Model = Model("models/maxofs2d/hover_rings.mdl")
ENT.ThrowForce = 1000

ENT.MaxActiveSets = 1
ENT.DropChance = 0.6

ENT.BoneName = "ValveBiped.Bip01_R_Hand"
ENT.AttachmentOffset = Vector(5, 5, -5)
ENT.AttachmentAngles = Angle(0, 180, 180)

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
			for __, ent2 in pairs(ents.FindByClass("status_gravity")) do
				if ent2:GetOwner() == ent then
					has = true
					break
				end
			end

			if not has then
				local status = ents.Create("status_gravity")
				if status:IsValid() then
					status:SetPos(ent:LocalToWorld(ent:OBBCenter()))
					status:SetOwner(ent)
					status:SetParent(ent)
					status:Spawn()
				end
			end

			ent:TakeDamage(5, self:GetLastCarrier(), self)
			ent:ThrowFromPosition(hitpos, 250)
		end
	end

	local ball = GAMEMODE:GetBall()
	if ball:IsValid() and ball:GetState() == BALL_STATE_NONE then
		local nearest = ball:NearestPoint(hitpos)
		if nearest:DistToSqr(hitpos) <= 40000 and util.IsVisible(nearest, hitpos) then
			ball:SetState(BALL_STATE_GRAVITYBALL, 6)
		end
	end

	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetNormal(hitnormal)
	util.Effect("exp_gravityorb", effectdata)
end

function ENT:OnTouch(ent)
	if ent:IsPlayer() and ent:Alive() and self:GetVelocity():Length() >= self:GetImpactSpeed() and ent:Team() ~= self:GetLastCarrierTeam() then
		self.TouchedEnemy = ent
	end
end
