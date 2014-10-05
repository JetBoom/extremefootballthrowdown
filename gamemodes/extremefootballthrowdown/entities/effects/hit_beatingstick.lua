function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local normal = data:GetNormal()

	self.Pos = pos
	self.Dir = normal

	local ent = data:GetEntity()
	if ent:IsValid() then
		ent:EmitSound("npc/zombie/zombie_hit.wav", 75, math.Rand(70, 120))

		util.Blood(pos, math.random(30, 40), normal * -1, 450)
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
