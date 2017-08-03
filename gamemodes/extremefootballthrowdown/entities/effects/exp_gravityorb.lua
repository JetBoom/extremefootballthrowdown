EFFECT.LifeTime = 0.5

function EFFECT:Init(data)
	local normal = data:GetNormal()
	local pos = data:GetOrigin()
	self.DieTime = CurTime() + 0.75
	pos = pos + normal * 2
	self.Pos = pos
	self.Norm = normal
	self.Entity:SetRenderBoundsWS(pos + Vector(-1000, -1000, -1000), pos + Vector(1000, 1000, 1000))

	sound.Play("weapons/mortar/mortar_explode"..math.random(3)..".wav", pos, 90, math.Rand(80, 90))
	--sound.Play("physics/glass/glass_largesheet_break1.wav", pos, 75, math.Rand(120, 130))

	local emitter = ParticleEmitter(pos)
	emitter:SetNearClip(24, 64)

	local vecGrav = Vector(0, 0, 100)
	for i=1, math.random(260, 360) do
		local heading = VectorRand()
		heading:Normalize()

		local particle = emitter:Add("Effects/yellowflare", pos + heading * 8)
		particle:SetVelocity(math.Rand(100, 520) * heading)
		particle:SetDieTime(math.Rand(2, 5))
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(255)
		particle:SetStartSize(math.Rand(0.5, 1) ^ 2 * 10)
		particle:SetEndSize(0)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-2, 2))
		particle:SetAirResistance(100)
		particle:SetColor(205, 150, 205)
		particle:SetGravity(vecGrav)
	end

	for i=1, 10 do
		local dir = (VectorRand():GetNormalized() + normal) / 2

		local particle = emitter:Add("particle/smokestack", pos + dir * 32)
		particle:SetVelocity(dir * math.Rand(180, 300))
		particle:SetDieTime(math.Rand(2, 2.4))
		particle:SetStartAlpha(240)
		particle:SetEndAlpha(0)
		particle:SetStartSize(math.Rand(20, 30))
		particle:SetEndSize(math.Rand(200, 240))
		particle:SetColor(100, 0, 255)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-2, 2))
		particle:SetAirResistance(math.Rand(60, 80))
	end

	local ang = normal:Angle()
	local fwd = ang:Forward()

	for i=1, math.random(90, 120) do
		local dir = (VectorRand() * 1.5 + normal):GetNormalized()
		local particle = emitter:Add("effects/fire_cloud1", pos + dir * 16)
		particle:SetVelocity(dir * math.Rand(200, 450))
		particle:SetDieTime(math.Rand(1, 1.6))
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(0)
		particle:SetStartSize(12)
		particle:SetEndSize(math.Rand(60, 100))
		particle:SetColor(50, 0, 255)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-3, 3))
		particle:SetAirResistance(200)
	end

	for i=1, math.random(30, 40) do
		local dir = (VectorRand() + normal):GetNormalized()
		local particle = emitter:Add("effects/fire_embers"..math.random(3), pos + dir * 16)
		particle:SetVelocity(dir * math.Rand(200, 400))
		particle:SetDieTime(math.Rand(1, 1.2))
		particle:SetStartAlpha(240)
		particle:SetEndAlpha(0)
		particle:SetStartSize(8)
		particle:SetEndSize(math.Rand(60, 100))
		particle:SetColor(50, 0, 255)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-3, 3))
		particle:SetAirResistance(150)
	end

	local dlight = DynamicLight(0)
	if dlight then
		dlight.Pos = pos
		dlight.r = 105
		dlight.g = 0
		dlight.b = 105
		dlight.Brightness = 8
		dlight.Size = 300
		dlight.Decay = 1000
		dlight.DieTime = CurTime() + 3
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()

end
