EFFECT.LifeTime = 0.5

function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local normal = data:GetNormal()
	local ent = data:GetEntity()
	self.Pos = pos
	self.Dir = normal
	self.Ent = ent

	self.DieTime = CurTime() + self.LifeTime

	self.Entity:SetRenderBounds(Vector(-256, -256, -256), Vector(256, 256, 256))

	sound.Play("weapons/physcannon/energy_sing_explosion2.wav", self.Pos, 80, math.Rand(95, 105))

	if ent:IsValid() then
		ent:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav")

		--util.Blood(pos, math.random(50, 70), normal, 500)
	end
end

function EFFECT:Think()
	return CurTime() <= self.DieTime
end

local matRefraction	= Material("refract_ring")
function EFFECT:Render()
	local pos = self.Pos
	local dir = self.Dir
	local rdir = dir * -1
	local delta = math.Clamp((self.DieTime - CurTime()) / self.LifeTime, 0, 1)
	local rdelta = 1 - delta

	local size = rdelta ^ 2
	local size1 = size * 0.5
	local pos2 = pos + dir * 64

	matRefraction:SetFloat("$refractamount", delta ^ 3)
	render.SetMaterial(matRefraction)
	render.UpdateRefractTexture()

	for i=0, 16 do
		local isize = 4 + (i * 24)
		local ipos = pos + i * 16 * rdelta ^ 0.3 * dir
		local irot = CurTime() * 360 + i * 45
		render.DrawQuadEasy(ipos, dir, isize, isize, color_white, irot)
		render.DrawQuadEasy(ipos, rdir, isize, isize, color_white, irot)
	end
end