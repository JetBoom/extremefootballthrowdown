STATE.Name = "Booze Ball"

if SERVER then
	
	function STATE:Start(ball, samestate)
		ball:EmitSound("vehicles/Airboat/pontoon_splash2.wav", 100, 110)
		
		local carrier = ball:GetCarrier()
	end

	function STATE:End(ball)
		ball:EmitSound("vehicles/Airboat/pontoon_impact_hard2.wav", 100, 170)
		
		local carrier = ball:GetCarrier()
	end
	
	function STATE:PhysicsCollide(ball, hitdata, phys)
		self.HitData = hitdata
		phys:SetVelocityInstantaneous(Vector(hitdata.OurOldVelocity.x*0.87,hitdata.OurOldVelocity.y*0.87,hitdata.OurOldVelocity.z*-0.27))
		return true
	end
	
	function STATE:Think(ball)
		local hitdata = self.HitData
		if hitdata then
			self.HitData = nil

			if hitdata.Speed >= 250 then

				local ent = ents.Create("effect_boozeballimpact")

				ang = hitdata.HitNormal:Angle()
			
				if ent:IsValid() then
					ent:SetPos(ball:GetPos())
					ent:SetAngles(Angle(ang.p-90,ang.y,ang.r))
					ent:SetModelScale(hitdata.Speed / 225)
					ent:Spawn()
				end
	
				local effectdata = EffectData()
					effectdata:SetOrigin(ball:GetPos())
				util.Effect("exp_boozebottle", effectdata)
			end
		end
	end
end

--[[function STATE:StartTouch(ball, ent)
	if self:ShouldHit(ball, ent) then
		ent:ThrowFromPosition(ball:GetPos() + Vector(0, 0, -64), 500, true, ball:GetLastCarrier())
		local has = false
		for __, ent2 in pairs(ents.FindByClass("status_boozed")) do
			if ent2:GetOwner() == ent then
				has = true
			end
		end

		if not has then
			local status = ents.Create("status_boozed")
			if status:IsValid() then
				status:SetPos(ent:LocalToWorld(ent:OBBCenter()))
				status:SetOwner(ent)
				status:SetParent(ent)
				status:Spawn()
			end
		end
		if ent:Health() > 5 then
		end
		ent:TakeDamage(5, ball:GetLastCarrier(), ball)
		GAMEMODE:SlowTime(0.5, 0.75)
	end
end]]

function STATE:ShouldHit(ball, ent)
	return ent:IsPlayer() and not ball:GetCarrier():IsValid() and ent:Alive() and ent:Team() ~= ball:GetLastCarrierTeam() and ball:GetVelocity():Length() >= 250
end

local colBall = Color(100, 50, 50)
function STATE:GetBallColor(ball, carrier)
	return colBall
end

if not CLIENT then return end

local vecGravity = Vector(0, 0, 300)
function STATE:PostDraw(ball)
	if CurTime() < ball.NextStateEmit then return end
	ball.NextStateEmit = CurTime() + 0.01

	local carrier = ball:GetCarrier()
	local vel = carrier:IsValid() and carrier:GetVelocity() or ball:GetVelocity()
	local pos = ball:GetPos()

	local emitter = ParticleEmitter(pos)
	emitter:SetNearClip(16, 24)

	local particle = emitter:Add("Effects/bubble", ball:GetPos())
	particle:SetDieTime(math.Rand(1.7, 2.5))
	particle:SetStartSize(math.Rand(0.5, 1) ^ 2 * 10)
	particle:SetEndSize(0)
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
	particle:SetColor(100, 50, 50)

	emitter:Finish()
end
