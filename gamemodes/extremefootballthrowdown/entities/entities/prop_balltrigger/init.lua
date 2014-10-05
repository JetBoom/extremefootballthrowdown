AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetNoDraw(true)
	self:DrawShadow(false)
	self:SetModel("models/Roller_Spikes.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	self:SetTrigger(true)
end

function ENT:Touch(ent)
	local parent = self:GetParent()
	if parent:IsValid() then
		parent:Touch(ent)
	end
end

function ENT:StartTouch(ent)
	local parent = self:GetParent()
	if parent:IsValid() then
		parent:StartTouch(ent)
	end
end

function ENT:EndTouch(ent)
	local parent = self:GetParent()
	if parent:IsValid() then
		parent:EndTouch(ent)
	end
end
