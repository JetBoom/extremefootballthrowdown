STATE.Name = "Feather Ball"

if SERVER then
	local function AddEffect(carrier)
		carrier:SetGravity(0.25)

		for _, ent in pairs(ents.FindByClass("status_featherballwings")) do
			if ent:GetOwner() == carrier then return end
		end
		local ent = ents.Create("status_featherballwings")
		if ent:IsValid() then
			ent:SetPos(carrier:WorldSpaceCenter())
			ent:SetOwner(carrier)
			ent:SetParent(carrier)
			ent:Spawn()
		end
	end

	local function RemoveEffect(carrier)
		carrier:SetGravity(1)

		for _, ent in pairs(ents.FindByClass("status_featherballwings")) do
			if ent:GetOwner() == carrier then
				ent:Remove()
			end
		end
	end

	function STATE:Start(ball, samestate)
		ball:EmitSound("npc/attack_helicopter/aheli_charge_up.wav", 90, 100)

		local carrier = ball:GetCarrier()
		if carrier:IsValid() then
			AddEffect(carrier)
		end
	end

	function STATE:End(ball)
		ball:EmitSound("npc/barnacle/barnacle_die1.wav", 90, 100)

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

function STATE:GetBallColor(ball, carrier)
	return color_white
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

	local particle = emitter:Add("sprites/glow04_noz", ball:GetPos())
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

	emitter:Finish()
end
