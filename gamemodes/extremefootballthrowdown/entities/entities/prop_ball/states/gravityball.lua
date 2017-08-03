STATE.Name = "Gravity Ball"

if SERVER then
	local function AddEffect(carrier)
		carrier:SetGravity(0.5)
	end

	local function RemoveEffect(carrier)
		carrier:SetGravity(1)
	end

	function STATE:Start(ball, samestate)
		ball:EmitSound("buttons/button1.wav", 100, 40)

		local carrier = ball:GetCarrier()
		if carrier:IsValid() then
			AddEffect(carrier)
		end
	end

	function STATE:End(ball)
		ball:EmitSound("ambient/machines/machine1_hit2.wav", 100, 100)

		local carrier = ball:GetCarrier()
		if carrier:IsValid() then
			RemoveEffect(carrier)
		end
	end

	function STATE:CarrierChanged(ball, newcarrier, oldcarrier)
		if newcarrier:IsValid() and newcarrier:IsPlayer() then
			AddEffect(newcarrier)
		end

		if oldcarrier:IsValid() and oldcarrier:IsPlayer() then
			RemoveEffect(oldcarrier)
		end
	end
end

local colBall = Color(100, 0, 205)
function STATE:GetBallColor(ball, carrier)
	return colBall
end

if not CLIENT then return end

local vecGravity = Vector(0, 0, 300)
local matRefraction	= Material("refract_ring")
function STATE:PostDraw(ball)
	local carrier = ball:GetCarrier()
	if carrier:IsValid() then
		local vel = carrier:GetVelocity()
		local speed = vel:Length()
		if speed > 170 then
			local dir = vel:GetNormalized() * -1
			local intensity = math.Clamp((speed - 300) / 125, 0, 1) ^ 2

			matRefraction:SetFloat("$refractamount", intensity * 0.05 + math.abs(math.sin(CurTime())) * 0.05)
			render.SetMaterial(matRefraction)
			render.UpdateRefractTexture()

			local baserot = (CurTime() * 600) % 360
			for i=1, 8 do
				local pos = carrier:GetPos() + carrier:GetUp() * carrier:OBBCenter().z + 16 * i * dir
				local rot = baserot + i * 90
				local size = 72 - i * 2
				render.DrawQuadEasy(pos, dir, size, size, color_white, rot)
				render.DrawQuadEasy(pos, dir * -1, size, size, color_white, rot)
			end
		end
	end
	if CurTime() < ball.NextStateEmit then return end
	ball.NextStateEmit = CurTime() + 0.01

	local carrier = ball:GetCarrier()
	local vel = carrier:IsValid() and carrier:GetVelocity() or ball:GetVelocity()
	local pos = ball:GetPos()

	local emitter = ParticleEmitter(pos)
	emitter:SetNearClip(16, 24)

	local particle = emitter:Add("Effects/yellowflare", ball:GetPos())
	particle:SetDieTime(math.Rand(1.7, 2.5))
	particle:SetStartSize(8)
	particle:SetEndSize(4)
	particle:SetStartAlpha(255)
	particle:SetEndAlpha(0)
	local v = VectorRand()
	v.z = 0
	v:Normalize()
	particle:SetVelocity(v * math.Rand(100, 228) + vel * 0.8)
	particle:SetAirResistance(64)
	particle:SetRoll(math.Rand(0, 360))
	particle:SetRollDelta(math.Rand(-15, 15))
	particle:SetGravity(vecGravity)
	particle:SetColor(100, 0, 205)

	emitter:Finish()
end
