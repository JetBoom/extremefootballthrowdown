STATE.Name = "Water Ball"

STATE.NoWaterReturn = true

if SERVER then
	function STATE:Start(ball, samestate)
		ball:EmitSound("vehicles/Airboat/pontoon_splash2.wav", 100, 100)

		local phys = ball:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetBuoyancyRatio(2)
		end
	end

	function STATE:End(ball)
		ball:EmitSound("vehicles/Airboat/pontoon_impact_hard2.wav", 100, 150)

		local phys = ball:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetBuoyancyRatio(0.05)
		end

		self:RemoveWaterPlatform(ball)
	end

	function STATE:Think(ball)
		local carrier = ball:GetCarrier()
		if carrier:IsValid() then
			self:SpawnWaterPlatform(ball, carrier)
		else
			self:RemoveWaterPlatform(ball)
		end
	end

	function STATE:SpawnWaterPlatform(ball, carrier)
		if IsValid(ball._WaterBallPlatform) then return end

		local ent = ents.Create("prop_waterballplatform")
		if ent:IsValid() then
			ent:SetPos(ball:GetPos())
			ent:SetOwner(ball)
			ent:Spawn()
			ent:SetPlayer(carrier)
			ent:AlignToCarrier()
			ball._WaterBallPlatform = ent
		end
	end

	function STATE:RemoveWaterPlatform(ball)
		if IsValid(ball._WaterBallPlatform) then
			ball._WaterBallPlatform:Remove()
			ball._WaterBallPlatform = nil
		end
	end
end

local colBall = Color(0, 120, 255)
function STATE:GetBallColor(ball, carrier)
	return colBall
end

if not CLIENT then return end

local vecGrav = Vector(0, 0, -400)
function STATE:PostDraw(ball)
	if CurTime() < ball.NextStateEmit then return end
	ball.NextStateEmit = CurTime() + 0.01

	local carrier = ball:GetCarrier()
	local vel = carrier:IsValid() and carrier:GetVelocity() or ball:GetVelocity()
	local pos = ball:GetPos()

	local emitter = ParticleEmitter(pos)
	emitter:SetNearClip(16, 24)

	local particle = emitter:Add("Effects/splash"..math.random(4), ball:GetPos())
	particle:SetDieTime(math.Rand(1.7, 2.5))
	particle:SetStartSize(3)
	particle:SetEndSize(0)
	particle:SetStartAlpha(255)
	particle:SetEndAlpha(255)
	particle:SetVelocity(VectorRand():GetNormalized() * math.Rand(100, 228) + vel * 0.8)
	particle:SetAirResistance(100)
	particle:SetGravity(vecGrav)
	particle:SetCollide(true)
	particle:SetBounce(0.1)
	particle:SetRoll(math.Rand(0, 360))
	particle:SetRollDelta(math.Rand(-15, 15))

	emitter:Finish()
end
