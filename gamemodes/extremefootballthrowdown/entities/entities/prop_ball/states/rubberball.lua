STATE.Name = "Rubber Ball"

if SERVER then
	function STATE:Start(ball, samestate)
		ball:EmitSound("vehicles/Airboat/pontoon_splash2.wav", 100, 110)
	end

	function STATE:End(ball)
		ball:EmitSound("vehicles/Airboat/pontoon_impact_hard2.wav", 100, 170)
	end

	function STATE:PhysicsCollide(ball, hitdata, phys)
		phys:SetVelocityInstantaneous(Vector(hitdata.OurOldVelocity.x*1,hitdata.OurOldVelocity.y*1,hitdata.OurOldVelocity.z*-0.875))
		return true
	end
end

function STATE:PreMove(ball, pl, move)
	move:SetMaxSpeed(move:GetMaxSpeed() * 0.75)
end

local colBall = Color(175, 175, 175)
function STATE:GetBallColor(ball, carrier)
	return colBall
end

if not CLIENT then return end

local matShiny = Material("models/shiny")
function STATE:PreDraw(ball)
	render.ModelMaterialOverride(matShiny)
end

local vecGrav = Vector(0, 0, -400)
function STATE:PostDraw(ball)
	render.ModelMaterialOverride()

	if CurTime() < ball.NextStateEmit then return end
	ball.NextStateEmit = CurTime() + 0.01

	local carrier = ball:GetCarrier()
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
	particle:SetColor(255, 255, 255)
	particle:SetRoll(math.Rand(0, 360))
	particle:SetRollDelta(math.Rand(-15, 15))

	emitter:Finish()
end
