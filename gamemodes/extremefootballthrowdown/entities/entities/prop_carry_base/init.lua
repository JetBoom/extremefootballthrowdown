AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.LastCarrierTeam = 0

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	self:SetTrigger(true)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(true)
		phys:EnableDrag(false)
		phys:SetDamping(0, 0.25)
		if self.Mass then
			phys:SetMass(self.Mass)
		end

		phys:Wake()
	end

	self.LastCarrierTeam = 0
	self.DieTime = CurTime() + self.LifeTime
end

function ENT:Think()
	self:AlignToCarrier()

	local carrier = self:GetCarrier()
	if not carrier:IsValid() or not carrier:Alive() then
		self:SetCarrier(NULL)
	end

	self:OnThink()

	if not carrier:IsValid() and CurTime() >= self.DieTime then
		local effectdata = EffectData()
			effectdata:SetOrigin(self:LocalToWorld(self:OBBCenter()))
		util.Effect("ballreset", effectdata, true, true)

		self:Remove()
	end

	self:NextThink(CurTime())
	return true
end

function ENT:PhysicsUpdate(phys)
	phys:Wake()
end

function ENT:OnThink()
end

function ENT:Touch(ent)
	if ent:IsPlayer() and not self:GetCarrier():IsValid() and ent:Alive() and not ent:IsCarrying() and self:GetVelocity():Length() < 200
	and ent:CallStateFunction("CanPickup", self) and (self:GetLastCarrier() ~= ent or CurTime() > (self.m_PickupImmunity or 0))
	and (ent:Team() ~= self:GetLastCarrierTeam() or CurTime() > (self.m_TeamPickupImmunity or 0)) then
		if ent:KeyDown(IN_USE) then
			self:SetCarrier(ent)
		elseif ent:GetPotentialCarry() ~= self then
			ent:SetPotentialCarry(self)
		end
	end

	self:OnTouch(ent)
end

function ENT:EndTouch(ent)
	if ent:IsPlayer() and ent:GetPotentialCarry() == self then
		ent:SetPotentialCarry(NULL)
	end
end

function ENT:OnTouch(ent)
end

function ENT:Drop(thrown)
	self.m_PickupImmunity = CurTime() + 1

	local carrier = self:GetCarrier()
	if carrier:IsValid() then
		self:SetCarrier(NULL)
		if not thrown then
			local phys = self:GetPhysicsObject()
			if phys:IsValid() then
				phys:Wake()
				phys:SetVelocityInstantaneous(carrier:GetVelocity() * 1.75 + Vector(0, 0, 128))
			end
		end

		if thrown then
			self.m_TeamPickupImmunity = CurTime() + 0.25
		end
	end

	if thrown then
		self:OnThrown(carrier)

		self:Input("onthrown", carrier, carrier)

		if carrier:IsValid() then
			if carrier:Team() == TEAM_RED then
				self:Input("onthrownbyred", carrier, carrier)
			elseif carrier:Team() == TEAM_BLUE then
				self:Input("onthrownbyblue", carrier, carrier)
			end
		end
	else
		self:Input("ondropped", carrier, carrier)

		if carrier:IsValid() then
			if carrier:Team() == TEAM_RED then
				self:Input("ondroppedbyred", carrier, carrier)
			elseif carrier:Team() == TEAM_BLUE then
				self:Input("ondroppedbyblue", carrier, carrier)
			end
		end
	end
end

function ENT:OnThrown(carrier)
end

function ENT:AcceptInput(name, activator, caller, args)
	name = string.lower(name)
	if string.sub(name, 1, 2) == "on" then
		self:FireOutput(name, activator, caller, args)
	end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if string.sub(key, 1, 2) == "on" then
		self:AddOnOutput(key, value)
	end
end
