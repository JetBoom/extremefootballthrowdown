include("shared.lua")

function ENT:Think()
	self:AlignToCarrier()

	self:OnThink()

	self:NextThink(CurTime())
	return true
end

function ENT:OnThink()
end

function ENT:Draw()
	self:AlignToCarrier()

	self:DrawModel()
end
ENT.DrawTranslucent = ENT.Draw
