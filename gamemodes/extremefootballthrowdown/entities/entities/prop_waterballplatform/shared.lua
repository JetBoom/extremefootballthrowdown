ENT.Type = "anim"

AccessorFuncDT(ENT, "Player", "Entity", 0)

function ENT:ShouldNotCollide(ent)
	if ent:IsValid() and ent:IsPlayer() then
		return self:GetPlayer() ~= ent
	end
end

function ENT:SetPlayer(pl)
	self:SetDTEntity(0, pl)
	self:CollisionRulesChanged()
end
