local matCrater = Material("Decals/rollermine_crater")
function EFFECT:Init(data)
	self.DieTime = CurTime() + 0.25

	local normal = data:GetNormal() * -1
	local pos = data:GetOrigin()

	for i=1, 2 do
		local tr = util.TraceLine({start = pos, endpos = normal * 1024, mask = MASK_SOLID_BRUSHONLY})
		util.DecalEx(matCrater, Entity(0), tr.HitPos, tr.HitNormal, 32, 32, 0)
	end

	pos = pos + normal * 2
	self.Pos = pos
	self.Normal = normal

	sound.Play("Breakable.MatConcrete", pos, 80, math.Rand(95, 105))

	local vBounds = Vector(6, 6, 6)
	local vNBounds = Vector(-6, -6, -6)
	for i=1, math.random(5, 8) do
		local dir = ((normal * 2 + VectorRand()) * 0.3333333):GetNormalized()
		local ent = ClientsideModel("models/props_junk/Rock001a.mdl", RENDERGROUP_OPAQUE)
		ent:SetPos(pos + dir * 16)
		ent:PhysicsInitBox(vNBounds, vBounds)
		ent:SetCollisionBounds(vNBounds, vBounds)

		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetMaterial("rock")
			phys:SetVelocityInstantaneous(dir * math.Rand(100, 400))
			phys:AddAngleVelocity(VectorRand() * 3000)
		end

		SafeRemoveEntityDelayed(ent, math.Rand(4, 5))
	end
end

function EFFECT:Think()
	return CurTime() < self.DieTime
end

local matRefraction	= Material("refract_ring")
local matRing = Material("effects/select_ring")
function EFFECT:Render()
	render.SetMaterial(matRing)
	local delta = math.max(0.001, self.DieTime - CurTime())
	local rdelta = 0.25 - delta
	local size = rdelta * 2000
	local col = Color(255, 255, 255, delta * 1000)
	render.DrawQuadEasy(self.Pos, self.Normal, size, size, col, 0)
	local negno = self.Normal * -1
	render.DrawQuadEasy(self.Pos, negno, size, size, col, 0)

	matRefraction:SetFloat("$refractamount", math.sin(delta * 2 * math.pi) * 0.2)
	render.SetMaterial(matRefraction)
	render.UpdateRefractTexture()
	render.DrawQuadEasy(self.Pos, self.Normal, size, size, color_white, 0)
	render.DrawQuadEasy(self.Pos, negno, size, size, color_white, 0)
end
