ENT.Type = "anim"

function ENT:Initialize()
	self:DrawShadow(false)
	if CLIENT then
		self:SetRenderBounds(Vector(-48, -48, -48), Vector(48, 48, 48))
	end
	self:SetNotSolid(true)
end

function ENT:SetJerseyName(str)
end

function ENT:GetJerseyName()
	return self:GetDTString(1)
end

function ENT:SetJerseyNumber(id)
	self:SetDTInt(1, id)
end

function ENT:GetJerseyName()
	return self:GetDTInt(1)
end
