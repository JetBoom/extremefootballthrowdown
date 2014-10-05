STATE.Name = "Blitz Ball"

if SERVER then
	function STATE:Start(ball, samestate)
		ball:EmitSound("ambient/fire/gascan_ignite1.wav", 90, 100)
		ball:Ignite(9999)
	end

	function STATE:End(ball)
		ball:EmitSound("npc/barnacle/barnacle_die1.wav", 90, 100)
		ball:Extinguish()
	end
end

function STATE:PreTouch(ball, ent)
	if self:ShouldHit(ball, ent) then return true end
end

function STATE:StartTouch(ball, ent)
	if self:ShouldHit(ball, ent) then
		ent:ThrowFromPosition(ball:GetPos() + Vector(0, 0, -64), 700, true, ball:GetLastCarrier())
		if ent:Health() > 25 then
			ent:Ignite(3)
		end
		ent:TakeDamage(25, ball:GetLastCarrier(), ball)
		GAMEMODE:SlowTime(0.1, 0.75)

		local effectdata = EffectData()
			effectdata:SetOrigin(ent:NearestPoint(ball:GetPos()))
		util.Effect("blitzballhit", effectdata, true, true)
	end
end

function STATE:ShouldHit(ball, ent)
	return ent:IsPlayer() and not ball:GetCarrier():IsValid() and ent:Alive() and ent:Team() ~= ball:GetLastCarrierTeam() and ball:GetVelocity():Length() >= 200
end

local colBall = Color(255, 120, 10)
function STATE:GetBallColor(ball, carrier)
	return colBall
end

if not CLIENT then return end

function STATE:PreDraw(ball)
	render.SetColorModulation(0.25, 0.2, 0.2)
end

function STATE:PostDraw(ball)
	render.SetColorModulation(1, 1, 1)

	if CurTime() < ball.NextStateEmit then return end
	ball.NextStateEmit = CurTime() + 0.2

	local carrier = ball:GetCarrier()
	local vel = carrier:IsValid() and carrier:GetVelocity() or ball:GetVelocity()

	local size = math.Rand(14, 20)

	for i=1, math.random(10, 12) do
		local particle = ball.Emitter:Add("effects/fire_embers"..math.random(3), ball:GetPos())
		particle:SetVelocity(vel + VectorRand():GetNormalized() * math.Rand(-100, 100))
		particle:SetDieTime(math.Rand(0.5, 0.8))
		particle:SetStartSize(size)
		particle:SetEndSize(size * 0.25)
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(0)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-15, 15))

		local particle = ball.Emitter:Add("particles/smokey", ball:GetPos())
		particle:SetDieTime(math.Rand(1, 1.25))
		particle:SetStartSize(size * 0.25)
		particle:SetEndSize(size)
		particle:SetStartAlpha(80)
		particle:SetEndAlpha(0)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-5, 5))
		particle:SetColor(30, 30, 30)
	end
end
