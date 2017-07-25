
STATE.Time = 0.6 --0.5
STATE.HitTime = 0.4

function STATE:CanPickup(pl, ent)
	return true
end

function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(0)
	pl:SetStateBool(false)

	pl:DoAttackEvent()

	if SERVER then
		pl:EmitSound("npc/zombie/claw_miss"..math.random(2)..".wav", 72, math.Rand(97, 103))
	end
end

if SERVER then
--[[function STATE:Ended(pl, newstate)
	if newstate == STATE_NONE then
		for _, tr in ipairs(pl:GetTargets()) do
			local hitent = tr.Entity
			if hitent:IsPlayer() and (hitent.CrossCounteredBy ~= pl or CurTime() >= (hitent.CrossCounteredTime or -math.huge) + 1) then
				pl:PunchHit(hitent, tr)
			end
		end
	end
end]]

function STATE:OnChargedInto(pl, otherpl)
	if CurTime() >= pl:GetStateEnd() - 0.2 and pl:TargetsContain(otherpl) then
		local vel = otherpl:GetVelocity()
		vel.x = 0
		vel.y = 0
		otherpl:SetLocalVelocity(vel)

		otherpl.CrossCounteredBy = pl
		otherpl.CrossCounteredTime = CurTime()

		pl:PunchHit(otherpl)
		otherpl:SetState(STATE_SPINNYKNOCKDOWN, STATES[STATE_SPINNYKNOCKDOWN].Time)

		--[[pl:PrintMessage(HUD_PRINTTALK, "CROSS COUNTER!")
		otherpl:PrintMessage(HUD_PRINTTALK, "CROSS COUNTERED!")]]

		return true
	end
end
end

function STATE:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND, true)
		return ACT_INVALID
	end
end

function STATE:IsIdle(pl)
	return false
end

function STATE:Move(pl, move)
	move:SetMaxClientSpeed(SPEED_ATTACK)

	return MOVE_STOP
end

function STATE:ThinkCompensatable(pl)
	if not pl:IsOnGround() and not pl:IsSwimming() then
		pl:EndState(true)
	elseif CurTime() >= pl:GetStateStart() + self.HitTime then
		if not pl:GetStateBool() then
			pl:SetStateBool(true)
			if SERVER then
				local targets = pl:GetTargets(nil, nil, nil, nil, true)
				for _, tr in ipairs(targets) do
					local hitent = tr.Entity
					if hitent:IsPlayer() and (hitent.CrossCounteredBy ~= pl or CurTime() >= (hitent.CrossCounteredTime or -math.huge) + 1) then
						pl:PunchHit(hitent, tr)
					end
				end
			end
		end

		if CurTime() >= pl:GetStateEnd() then
			pl:EndState(true)
		end
	end
end

function STATE:GoToNextState()
	return true
end

local Translated = {
	[ACT_MP_RUN] = ACT_HL2MP_RUN_MELEE2,
	[ACT_HL2MP_WALK_SUITCASE] = ACT_HL2MP_WALK_MELEE2,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_MELEE2,
	[ACT_HL2MP_IDLE_MELEE_ANGRY] = ACT_HL2MP_IDLE_MELEE2,
	[ACT_HL2MP_IDLE_ANGRY] = ACT_HL2MP_IDLE_MELEE2
}
function STATE:TranslateActivity(pl)
	pl.CalcIdeal = Translated[pl.CalcIdeal] or pl.CalcIdeal
end

--[[function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:SetCycle(0.7 * math.Clamp(1 - (pl:GetStateEnd() - CurTime()) / self.Time, 0, 1) ^ 2.5)
	pl:SetPlaybackRate(0)

	return true
end]]
