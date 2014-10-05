function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local normal = data:GetNormal()

	self.Pos = pos
	self.Dir = normal

	local ent = data:GetEntity()
	if ent:IsValid() then
		ent:EmitSound("npc/zombie/zombie_hit.wav", 80, math.Rand(60, 80))
		ent:EmitSound("vehicles/v8/vehicle_impact_medium"..math.random(4)..".wav", 80, math.Rand(110, 120))

		util.Blood(pos, math.random(30, 40), normal * -1, 450)
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
