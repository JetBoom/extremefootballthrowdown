function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local normal = data:GetNormal()

	self.Pos = pos
	self.Dir = normal

	local ent = data:GetEntity()
	if ent:IsValid() then
		ent:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav")

		--util.Blood(pos, math.random(24, 30), normal * -1, 300)
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
