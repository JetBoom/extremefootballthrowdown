--[[EFFECT.RefractLifeTime = 0.5
EFFECT.LifeTime = 0.75]]

function EFFECT:Init(data)
	--self.Entity:SetRenderBounds(Vector(-256, -256, -256), Vector(256, 256, 256))

	local pos = data:GetOrigin()
	local normal = data:GetNormal()
	self.Pos = pos
	self.Dir = normal

	--[[self.DieTime = CurTime() + self.LifeTime
	self.RefractDieTime = CurTime() + self.RefractLifeTime

	self.Sparks = {}
	for i=1, math.random(48, 64) do
		self.Sparks[i] = (normal + VectorRand():GetNormalized() * 2) / 3
	end]]

	sound.Play("npc/antlion_guard/shove1.wav", self.Pos, 80, math.Rand(95, 105))

	local ent = data:GetEntity()
	if ent:IsValid() then
		ent:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav")

		--util.Blood(pos, math.random(50, 70), normal, 500)
	end
end

function EFFECT:Think()
	return false --return CurTime() <= self.DieTime
end

--[[local matRefraction	= Material("refract_ring")
local matSpark = Material("effects/spark")
local colSprite = Color(255, 50, 50, 255)]]
function EFFECT:Render()
	--[[local pos = self.Pos
	local delta = math.max(0, self.RefractDieTime - CurTime()) / self.RefractLifeTime

	local size2 = (1 - delta) ^ 1.2 * 512
	matRefraction:SetFloat("$refractamount", delta)
	render.SetMaterial(matRefraction)
	render.UpdateRefractTexture()
	render.DrawQuadEasy(pos, self.Dir, size2, size2, color_white, 0)
	render.DrawQuadEasy(pos, self.Dir * -1, size2, size2, color_white, 0)

	local delta2 = math.max(0, self.DieTime - CurTime()) / self.LifeTime

	local beamlength = (1 - delta2) * 512
	local beamsize = 8 * delta2

	render.SetMaterial(matSpark)
	for _, dir in pairs(self.Sparks) do
		render.DrawBeam(pos, pos + beamlength * dir, beamsize, 0, 1, math.random(2) == 1 and colSprite or color_white)
	end]]
end
