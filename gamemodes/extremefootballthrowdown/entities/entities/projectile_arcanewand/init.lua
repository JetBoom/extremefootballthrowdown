AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:DrawShadow(false)
	self:PhysicsInitSphere(4)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	self:SetTrigger(true)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableDrag(false)
		phys:EnableGravity(false)
		phys:Wake()
	end

	self.DieTime = CurTime() + self.LifeTime
end

function ENT:Think()
	if self.Exploded or CurTime() >= self.DieTime then
		self:Remove()
	elseif self.PhysicsData then
		self:Explode(self.PhysicsData.HitPos, self.PhysicsData.HitNormal)
		self:Remove()
	elseif self.TouchedEnemy then
		if self.TouchedEnemy:IsValid() and self.TouchedEnemy:CallStateFunction("OnHitWithArcaneBolt", self) then
			self.TouchedEnemy = nil
			return
		end

		self:Explode()
		self:Remove()
	end
end

function ENT:PhysicsCollide(data, phys)
	self.PhysicsData = data
	self:NextThink(CurTime())
end

function ENT:StartTouch(ent)
	if ent:IsPlayer() and ent:Alive() and ent:Team() ~= self.Team then
		self.TouchedEnemy = ent
	end
end

function ENT:Explode(hitpos, hitnormal)
	if self.Exploded then return end
	self.Exploded = true
	self.PhysicsData = nil

	self:NextThink(CurTime())

	hitpos = hitpos or self:GetPos()
	hitnormal = hitnormal or Vector(0, 0, 1)

	util.ExplosiveDamage(self, self:GetOwner():IsValid() and self:GetOwner() or self, hitpos, 160, 15, DMG_DISSOLVE, nil, 400)
	util.ScreenShake(hitpos, 500, 0.5, 1, 300)

	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetNormal(hitnormal)
	util.Effect("explosion_arcanewand", effectdata)
end
