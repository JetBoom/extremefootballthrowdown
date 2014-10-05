function EFFECT:Init(data)
	local pos = data:GetOrigin()

	sound.Play("physics/glass/glass_largesheet_break1.wav", pos, 75, math.Rand(120, 130))

	local emitter = ParticleEmitter(pos)
	emitter:SetNearClip(24, 32)

	local vecGrav = Vector(0, 0, 100)
	for i=1, math.random(260, 360) do
		local heading = VectorRand()
		heading:Normalize()

		local particle = emitter:Add("Effects/bubble", pos + heading * 8)
		particle:SetVelocity(math.Rand(100, 520) * heading)
		particle:SetDieTime(math.Rand(2, 5))
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(255)
		particle:SetStartSize(math.Rand(0.5, 1) ^ 2 * 10)
		particle:SetEndSize(0)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-2, 2))
		particle:SetAirResistance(100)
		particle:SetColor(100, 50, 50)
		particle:SetGravity(vecGrav)
	end

	vecGrav.z = -600
	for i=1, math.random(26, 32) do
		local heading = VectorRand()
		heading:Normalize()

		local particle = emitter:Add("Effects/splash"..math.random(3), pos + heading * 8)
		particle:SetVelocity(math.Rand(100, 420) * heading)
		particle:SetDieTime(math.Rand(1, 3))
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(255)
		particle:SetStartSize(math.Rand(14, 18))
		particle:SetEndSize(0)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-2, 2))
		particle:SetColor(100, 50, 50)
		particle:SetGravity(vecGrav)
		particle:SetCollide(true)
		particle:SetBounce(0.1)
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
