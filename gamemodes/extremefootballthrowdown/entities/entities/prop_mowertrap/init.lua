AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_c17/trappropeller_engine.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
	end

	local trig = ents.Create("trigger_mowerblade")
	if trig:IsValid() then
		trig:SetPos(self:LocalToWorld(Vector(0, 0, 32)))
		trig:SetAngles(self:GetAngles())
		trig:SetOwner(self)
		trig:SetParent(self)
		trig:Spawn()
	end

	self:SetStartTime(CurTime() + 2)

	self:Fire("kill", "", 15)
end

function ENT:OnRemove()
	local pos = self:WorldSpaceCenter()

	local effectdata = EffectData()
		effectdata:SetOrigin(pos)
		effectdata:SetNormal(self:GetUp())
	util.Effect("barrelexplosion", effectdata)

	util.BlastDamage(self, self:GetPlayer():IsValid() and self:GetPlayer() or self, pos, 300, 30)
	util.ScreenShake(pos, 500, 0.5, 1, 300)

	local ent = ents.Create("prop_physics_multiplayer")
	if ent:IsValid() then
		ent:SetPos(self:GetPos())
		ent:SetAngles(self:GetAngles())
		ent:SetModel(self:GetModel())
		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ent:Spawn()

		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetVelocityInstantaneous((Vector(0, 0, 1) + VectorRand():GetNormalized()):GetNormalized() * math.Rand(600, 1300))
			phys:AddAngleVelocity(VectorRand() * math.Rand(300, 1200))
		end

		ent:Fire("kill", "", math.random(8, 12))

		ent:Ignite(15, 0)
		local fire = ents.Create("env_fire_trail")
		if fire:IsValid() then
			fire:SetPos(ent:GetPos())
			fire:Spawn()
			fire:SetParent(ent)
		end
	end

	ent = ents.Create("prop_physics_multiplayer")
	if ent:IsValid() then
		ent:SetPos(self:LocalToWorld(Vector(0, 0, 24)))
		ent:SetAngles(self:GetAngles())
		ent:SetModel("models/props_c17/trappropeller_blade.mdl")
		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ent:Spawn()

		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetVelocityInstantaneous((Vector(0, 0, 1) + VectorRand():GetNormalized()):GetNormalized() * math.Rand(600, 1300))
			phys:AddAngleVelocity(VectorRand() * math.Rand(300, 1200))
		end

		ent:Fire("kill", "", math.random(8, 12))

		ent:Ignite(15, 0)
		local fire = ents.Create("env_fire_trail")
		if fire:IsValid() then
			fire:SetPos(ent:GetPos())
			fire:Spawn()
			fire:SetParent(ent)
		end
	end
end
