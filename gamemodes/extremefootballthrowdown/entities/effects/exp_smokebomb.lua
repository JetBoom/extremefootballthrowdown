function EFFECT:Init(data)
	local normal = data:GetNormal()
	local pos = data:GetOrigin()

	sound.Play("weapons/smokegrenade/sg_explode.wav", pos, 90, math.random(80, 90))

	pos = pos + normal * 2

	local emitter = ParticleEmitter(pos)
	emitter:SetNearClip(24, 64)

	local particle, lum, dir

	for i=1, 80 do
		dir = (VectorRand():GetNormalized() + normal) / 2
		lum = math.random(140, 200)

		particle = emitter:Add("particle/smokestack", pos + dir * 48)
		particle:SetVelocity(VectorRand() * math.Rand(2080, 3536))
		particle:SetDieTime(math.Rand(18, 23))
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(0)
		particle:SetStartSize(math.Rand(200, 300))
		particle:SetEndSize(math.Rand(5, 90))
		particle:SetColor(lum, lum, lum)
		particle:SetRoll(math.random(0, 360))
		particle:SetRollDelta(math.Rand(-0.1, 0.1))
		particle:SetAirResistance(600)

		particle:SetCollide(true)
		particle:SetBounce(0.4)

		particle:SetLighting(true)
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
