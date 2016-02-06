EFFECT.LifeTime = 1

function EFFECT:Init(data)
	local pos = data:GetOrigin()
	self.Pos = pos

	self.StartTime = CurTime()
	self.DieTime = CurTime() + self.LifeTime

	self.Entity:SetRenderBounds(Vector(-256, -256, -256), Vector(256, 256, 256))

	sound.Play("weapons/physcannon/energy_sing_flyby2.wav", self.Pos, 80, math.Rand(95, 105))
end

function EFFECT:Think()
	return CurTime() <= self.DieTime
end

local matRefraction	= Material("refract_ring")
function EFFECT:Render()
	local delta = math.Clamp(math.min(CurTime() - self.StartTime, self.DieTime - CurTime()) / self.LifeTime, 0, 1) ^ 2

	matRefraction:SetFloat("$refractamount", delta)
	render.SetMaterial(matRefraction)
	render.UpdateRefractTexture()

	render.DrawSprite(self.Pos, delta * 512, delta * 512, color_white)
end