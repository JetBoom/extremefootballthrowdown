AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "prop_carry_base"

ENT.Name = "Nitro Barrel"

ENT.IsPropWeapon = true

ENT.Model = Model("models/props_c17/oildrum001_explosive.mdl")
ENT.ThrowForce = 750

ENT.MaxActiveSets = 2

ENT.BoneName = "ValveBiped.Bip01_R_Hand"
ENT.AttachmentOffset = Vector(4, 7, 4)
ENT.AttachmentAngles = Angle(0, 0, 180)

function ENT:Initialize()
	self:SetModelScale(0.5, 0)

	self.BaseClass.Initialize(self)
end

function ENT:SecondaryAttack(pl)
	if pl:CanThrow() then
		pl:SetState(STATE_THROW)
	end

	return true
end

function ENT:Move(pl, move)
	move:SetMaxSpeed(move:GetMaxSpeed() * 0.8)
	move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.8)
end

function ENT:GetImpactSpeed()
	return self:GetLastCarrier():IsValid() and 200 or 450
end

if CLIENT then return end

function ENT:OnThink()
	if self.Exploded then
		self:Remove()
	elseif self.PhysicsData then
		self:Explode(self.PhysicsData.HitPos, self.PhysicsData.HitNormal)
		self:Remove()
	elseif self.TouchedEnemy then
		self:Explode()
		self:Remove()
	end
end

function ENT:PhysicsCollide(data, phys)
	if data.Speed >= self:GetImpactSpeed() then
		self.PhysicsData = data
		self:NextThink(CurTime())
	end
end

function ENT:Explode(hitpos, hitnormal)
	if self.Exploded then return end
	self.Exploded = true
	self.PhysicsData = nil

	self:NextThink(CurTime())

	hitpos = hitpos or self:GetPos()
	hitnormal = (hitnormal or Vector(0, 0, -1)) * -1

	util.BlastDamage(self, self:GetLastCarrier():IsValid() and self:GetLastCarrier() or self, hitpos, 420, 70)
	util.ScreenShake(hitpos, 500, 0.5, 1, 300)

	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetNormal(hitnormal)
	util.Effect("barrelexplosion", effectdata)
end

function ENT:OnTouch(ent)
	if ent:IsPlayer() and ent:Alive() and self:GetVelocity():Length() >= self:GetImpactSpeed() and ent:Team() ~= self:GetLastCarrierTeam() then
		self.TouchedEnemy = true
	end
end
