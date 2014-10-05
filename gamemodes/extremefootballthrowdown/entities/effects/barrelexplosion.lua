function EFFECT:Init(data)
	local normal = data:GetNormal()
	local pos = data:GetOrigin()
	self.DieTime = CurTime() + 0.75
	util.Decal("Scorch", pos + normal, pos - normal)
	pos = pos + normal * 2
	self.Pos = pos
	self.Norm = normal
	self.Entity:SetRenderBoundsWS(pos + Vector(-1000, -1000, -1000), pos + Vector(1000, 1000, 1000))

	sound.Play("weapons/mortar/mortar_explode"..math.random(3)..".wav", pos, 90, math.Rand(80, 90))
	sound.Play("ambient/explosions/exp"..math.random(4)..".wav", pos, 90, math.Rand(95, 105))

	local emitter = ParticleEmitter(pos)
	emitter:SetNearClip(24, 64)

	for i=1, 20 do
		local dir = (VectorRand():GetNormalized() + normal) / 2

		local particle = emitter:Add("particle/smokestack", pos + dir * 32)
		particle:SetVelocity(dir * math.Rand(180, 600))
		particle:SetDieTime(math.Rand(2, 5))
		particle:SetStartAlpha(240)
		particle:SetEndAlpha(0)
		particle:SetStartSize(math.Rand(20, 30))
		particle:SetEndSize(math.Rand(200, 240))
		particle:SetColor(40, 40, 40)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-2, 2))
		particle:SetAirResistance(math.Rand(60, 80))
	end

	local ang = normal:Angle()
	local fwd = ang:Forward()
	for i=1, 90 do
		ang:RotateAroundAxis(fwd, 4)
		local dir = ang:Up()

		local particle = emitter:Add("particle/smokestack", pos + dir * 16)
		particle:SetVelocity(dir * 800)
		particle:SetDieTime(math.Rand(1.8, 2))
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(0)
		particle:SetStartSize(16)
		particle:SetEndSize(math.Rand(32, 40))
		particle:SetColor(50, 50, 50)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-4, 4))
		particle:SetAirResistance(100)
	end

	for i=1, math.random(90, 120) do
		local dir = (VectorRand() * 1.5 + normal):GetNormalized()
		local particle = emitter:Add("effects/fire_cloud1", pos + dir * 16)
		particle:SetVelocity(dir * math.Rand(600, 850))
		particle:SetDieTime(math.Rand(1, 2.6))
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(0)
		particle:SetStartSize(12)
		particle:SetEndSize(math.Rand(60, 100))
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-3, 3))
		particle:SetAirResistance(200)
	end

	for i=1, math.random(30, 40) do
		local dir = (VectorRand() + normal):GetNormalized()
		local particle = emitter:Add("effects/fire_embers"..math.random(3), pos + dir * 16)
		particle:SetVelocity(dir * math.Rand(600, 800))
		particle:SetDieTime(math.Rand(2, 3.2))
		particle:SetStartAlpha(240)
		particle:SetEndAlpha(0)
		particle:SetStartSize(8)
		particle:SetEndSize(math.Rand(60, 100))
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-3, 3))
		particle:SetAirResistance(150)
	end

	emitter:Finish()
end

function EFFECT:Think()
	return CurTime() < self.DieTime
end

local matRefraction	= Material("refract_ring")
function EFFECT:Render()
	local ct = CurTime()
	if ct < self.DieTime then
		local delta = math.max(0, self.DieTime - ct)
		matRefraction:SetFloat("$refractamount", math.sin(delta * math.pi) * 0.2)
		render.SetMaterial(matRefraction)
		render.UpdateRefractTexture()
		local qsiz = (0.75 - delta) * 1300
		render.DrawQuadEasy(self.Pos, self.Norm, qsiz, qsiz, color_white, 0)
		render.DrawQuadEasy(self.Pos, self.Norm * -1, qsiz, qsiz, color_white, 0)
	end
end
