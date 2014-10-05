STATE.Name = "Hold the ball to score!!"

if SERVER then
	function STATE:Start(ball, samestate)
		ball:EmitSound("npc/attack_helicopter/aheli_charge_up.wav", 90, 100)
	end

	function STATE:End(ball)
		ball:EmitSound("npc/barnacle/barnacle_die1.wav", 90, 100)

		local carrier = ball:GetCarrier()
		if carrier:IsValid() then
			gamemode.Call("TeamScored", carrier:Team(), carrier, 1, true)
		end
	end
end

function STATE:GetBallColor(ball, carrier)
	return Color(HSVtoRGB((CurTime() * 180) % 360))
end

if not CLIENT then return end

local vecGrav = Vector(0, 0, 300)
function STATE:PostDraw(ball)
	if CurTime() < ball.NextStateEmit then return end
	ball.NextStateEmit = CurTime() + 0.01

	local carrier = ball:GetCarrier()
	local vel = carrier:IsValid() and carrier:GetVelocity() or ball:GetVelocity()

	local col = self:GetBallColor(ball)
	for i=1, 2 do
	local particle = ball.Emitter:Add("sprites/glow04_noz", ball:GetPos())
		particle:SetDieTime(math.Rand(2.3, 2.5))
		particle:SetStartSize(math.Rand(6, 8))
		particle:SetEndSize(0)
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(255)
		particle:SetVelocity(Angle(0, math.Rand(0, 360), 0):Forward() * math.Rand(8, 92) + vel * 0.8)
		particle:SetAirResistance(100)
		particle:SetGravity(vecGrav)
		particle:SetCollide(true)
		particle:SetBounce(1)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-32, 32))
		particle:SetColor(col.r, col.g, col.b)
	end
end
