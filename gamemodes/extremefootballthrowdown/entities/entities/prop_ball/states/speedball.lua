STATE.Name = "Speed Ball"

if SERVER then
	function STATE:Start(ball, samestate)
		ball:EmitSound("npc/attack_helicopter/aheli_charge_up.wav", 100, 100)
	end

	function STATE:End(ball)
		ball:EmitSound("npc/barnacle/barnacle_die1.wav", 100, 100)
	end
end

function STATE:GetChargeTimeMultiplier(ball, pl)
	return 0.5
end

local colYellow = Color(255, 255, 0)
function STATE:GetBallColor(ball, carrier)
	return colYellow
end

function STATE:PreMove(ball, pl, move)
	move:SetMaxSpeed(move:GetMaxSpeed() * 2)
end

if not CLIENT then return end

local matRefraction	= Material("refract_ring")
function STATE:PostDraw(ball)
	local carrier = ball:GetCarrier()
	if carrier:IsValid() then
		local vel = carrier:GetVelocity()
		local speed = vel:Length()
		if speed > 300 then
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

	local vel = carrier:IsValid() and carrier:GetVelocity() or ball:GetVelocity()
	local pos = ball:GetPos()

	local emitter = ParticleEmitter(pos)
	emitter:SetNearClip(16, 24)

	local particle = emitter:Add("sprites/glow04_noz", ball:GetPos())
	particle:SetDieTime(math.Rand(1.7, 2.5))
	particle:SetStartSize(3)
	particle:SetEndSize(0)
	particle:SetStartAlpha(255)
	particle:SetEndAlpha(255)
	particle:SetVelocity(VectorRand():GetNormalized() * math.Rand(100, 228) + vel * 0.8)
	particle:SetAirResistance(100)
	particle:SetColor(255, 255, 120)
	particle:SetRoll(math.Rand(0, 360))
	particle:SetRollDelta(math.Rand(-15, 15))

	emitter:Finish()
end
