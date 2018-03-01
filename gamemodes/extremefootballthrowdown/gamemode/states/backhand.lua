STATE.Time = 0.9
STATE.HitTime = 0.7

function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(0)	
	
	if SERVER then
		pl:EmitSound("physics/nearmiss/whoosh_large1.wav", 72, math.Rand(200, 211))
		--pl:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 72, math.Rand(68, 72))
	end
end

function STATE:CanPickup(pl, ent)
	return true
end

if SERVER then
function STATE:Ended(pl, newstate)
	if newstate == STATE_NONE then
		for _, tr in ipairs(pl:GetTargets()) do
			local hitent = tr.Entity
			if hitent:IsPlayer() then
				pl:PunchHit(hitent, tr)
				hitent:SetVelocity(Vector(-96, 0, 576))
			end
		end
	end
end

function STATE:OnChargedInto(pl, otherpl)
	if CurTime() >= pl:GetStateEnd() - 0.2 and pl:TargetsContain(otherpl) then
		local vel = otherpl:GetVelocity()
		vel.x = 0
		vel.y = 0
		otherpl:SetLocalVelocity(Vector(vel))

		pl:PunchHit(otherpl)
		otherpl:SetState(STATE_SPINNYKNOCKDOWN, STATES[STATE_SPINNYKNOCKDOWN].Time)
		otherpl:SetVelocity(Vector(-96, 0, 576))

		pl:PrintMessage(HUD_PRINTTALK, "CROSS COUNTER!")
		otherpl:PrintMessage(HUD_PRINTTALK, "CROSS COUNTERED!")

		return true
	end
end
end

function STATE:ThinkCompensatable(pl)
	if not (pl:IsOnGround() and pl:WaterLevel() < 2) then
		pl:EndState(true)
	elseif CurTime() >= pl:GetStateEnd() then
		if SERVER then 
			for _, tr in ipairs(pl:GetTargets()) do
				local hitent = tr.Entity
				if hitent:IsPlayer() and (hitent.CrossCounteredBy ~= pl or CurTime() >= (hitent.CrossCounteredTime or -math.huge) + 1) then
					pl:PunchHit(hitent, tr)
					hitent:SetVelocity(Vector(-96, 0, 576))
				end
			end
		end

		pl:EndState(true)
	end
end

function STATE:GoToNextState()
	return true
end

function STATE:IsIdle(pl)
	return false
end

function STATE:Move(pl, move)
	move:SetSideSpeed(0)
	move:SetForwardSpeed(0)
	move:SetMaxSpeed(0)
	move:SetMaxClientSpeed(0)

	return MOVE_STOP
end

function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("seq_throw")
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:SetCycle(math.Clamp((pl:GetStateEnd() - CurTime()) / self.Time, 0, 1) ^ 0.675 * 0.7 + 0.1)
	pl:SetPlaybackRate(0)

	return true
end