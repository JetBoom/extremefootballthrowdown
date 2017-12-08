AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "prop_carry_base"

ENT.Name = "Smoke Bomb"

ENT.IsPropWeapon = true

ENT.Model = Model("models/weapons/w_grenade.mdl")
ENT.ThrowForce = 1000

ENT.MaxActiveSets = 2
ENT.DropChance = 0.75

ENT.Mass = 50

ENT.BoneName = "ValveBiped.Bip01_R_Hand"
ENT.AttachmentOffset = Vector(4, 4, 4)
ENT.AttachmentAngles = Angle(0, 0, 180)

ENT.AllowInCompetitive = true

function ENT:Initialize()
	self:SetModelScale(2, 0)

	self.BaseClass.Initialize(self)
end

function ENT:SecondaryAttack(pl)
	if pl:CanThrow() then
		pl:SetState(STATE_THROW)
	end

	return true
end

function ENT:Move(pl, move)
	move:SetMaxSpeed(move:GetMaxSpeed() * 0.9)
	move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.9)
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

	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetNormal(hitnormal)
	util.Effect("exp_smokebomb", effectdata)
	
	local ball = GAMEMODE:GetBall()
	if ball:IsValid() and ball:GetState() == BALL_STATE_BLITZBALL then
		local nearest = ball:NearestPoint(hitpos)
		if nearest:DistToSqr(hitpos) <= 40000 and util.IsVisible(nearest, hitpos) then
			ball:SetState(BALL_STATE_NONE)
		end
	end
end

function ENT:OnTouch(ent)
	if ent:IsPlayer() and ent:Alive() and self:GetVelocity():Length() >= self:GetImpactSpeed() and ent:Team() ~= self:GetLastCarrierTeam() then
		self.TouchedEnemy = true
	end
end
