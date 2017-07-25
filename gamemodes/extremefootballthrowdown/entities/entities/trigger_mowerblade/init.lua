AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
	self:DrawShadow(false)
	self:SetCustomCollisionCheck(true)
	self:CollisionRulesChanged()

	self:PhysicsInitBox(Vector(-54, -54, -16), Vector(54, 54, 4))
	self:SetCollisionBounds(Vector(-54, -54, -16), Vector(54, 54, 4))
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetTrigger(true)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableCollisions(false)
	end

	self.NextTouch = {}
end

function ENT:Touch(ent)
	if not ent:IsPlayer() then return end

	local parent = self:GetParent()
	if parent:IsValid() and CurTime() >= parent:GetStartTime() and (parent:GetTeam() ~= ent:Team() or parent:GetPlayer() == ent) and (not self.NextTouch[ent] or CurTime() >= self.NextTouch[ent]) then
		self.NextTouch[ent] = CurTime() + 0.25

		util.Blood(ent:NearestPoint(self:GetPos()), math.random(40, 60), Vector(0, 0, 1), 250)
		ent:EmitSound("ambient/machines/slicer"..math.random(4)..".wav")
		ent:ThrowFromPosition((parent:GetPos() + (ent:GetPos() + Vector(0, 0, -16)) * 2) / 3, 400, true, parent:GetPlayer())
		ent:TakeDamage(18, parent:GetPlayer(), parent)
	end
end
