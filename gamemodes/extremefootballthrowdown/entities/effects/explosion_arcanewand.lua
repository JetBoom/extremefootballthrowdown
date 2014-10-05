EFFECT.LifeTime = 0.5

function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local normal = data:GetNormal() * -1

	self.Pos = pos + normal
	self.Normal = normal
	self.DieTime = CurTime() + self.LifeTime

	sound.Play("weapons/physcannon/energy_sing_explosion2.wav", pos, 75, math.Rand(120, 130))

	local emitter = ParticleEmitter(pos)
	emitter:SetNearClip(24, 32)

	for i=1, math.random(120, 160) do
		local heading = VectorRand()
		heading:Normalize()

		local particle = emitter:Add("effects/spark", pos + heading * 8)
		particle:SetVelocity(420 * heading)
		particle:SetDieTime(math.Rand(0.5, 0.85))
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(255)
		particle:SetStartSize(math.Rand(3, 4))
		particle:SetEndSize(0)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-10, 10))
		particle:SetAirResistance(250)
	end

	emitter:Finish()

	local dlight = DynamicLight(0)
	if dlight then
		dlight.Pos = pos
		dlight.r = 255
		dlight.g = 255
		dlight.b = 255
		dlight.Brightness = 8
		dlight.Size = 300
		dlight.Decay = 1000
		dlight.DieTime = CurTime() + 1
	end
end

function EFFECT:Think()
	return CurTime() < self.DieTime
end

local matRefract = Material("refract_ring")
function EFFECT:Render()
	local delta = (self.DieTime - CurTime()) / self.LifeTime
	local basesize = 72
	basesize = basesize + basesize ^ (1.5 - delta)

	local pos = self.Pos
	matRefract:SetFloat("$refractamount", (0.75 + math.abs(math.sin(CurTime() * 5)) * math.pi * 0.25) * delta)
	render.SetMaterial(matRefract)
	render.UpdateRefractTexture()
	render.DrawSprite(pos, basesize, basesize, color_white)
	render.DrawQuadEasy(pos, self.Normal, basesize, basesize, color_white, 0)
	render.DrawQuadEasy(pos, self.Normal, basesize, basesize, color_white, 0)
end
