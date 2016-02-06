STATE_FIGHTER2D_NONE = 0
STATE_FIGHTER2D_PUNCHING = 1
STATE_FIGHTER2D_SHOVING = 2
STATE_FIGHTER2D_GUARDBREAK = 3
STATE_FIGHTER2D_GUARDKNOCKBACK = 4
STATE_FIGHTER2D_LOSE = 5

STATE.WalkSpeed = 120

STATE.PunchTime = 0.1
STATE.PunchDelay = 0.35
STATE.ShoveTime = 0.75
STATE.MaxRange = 256
STATE.GuardKnockbackDuration = 1

function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(320)
	pl:SetHealth(100)
	pl:SetStateNumber(0)
	pl:SetStateInteger(0)
	pl:SetStateBool(false)
end

function STATE:IsIdle(pl)
	return false
end

function STATE:Move(pl, move)
	if pl:GetStateInteger() == STATE_FIGHTER2D_SHOVING or pl:GetStateInteger() == STATE_FIGHTER2D_LOSE or pl:GetStateInteger() == STATE_FIGHTER2D_GUARDBREAK
		or not pl:OnGround() then
		move:SetMaxSpeed(0)
		move:SetMaxClientSpeed(0)
		return MOVE_STOP
	end

	local opponent = self:GetOpponent(pl)
	if opponent then
		if opponent:EntIndex() < pl:EntIndex() then
			local opppos = opponent:GetPos()
			local origin = move:GetOrigin()
			if opppos.y ~= origin.y then
				origin.y = opppos.y
				move:SetOrigin(origin)
			end
		end

		if pl:GetStateInteger() == STATE_FIGHTER2D_GUARDKNOCKBACK then
			local opppos = opponent:GetPos()
			local mypos = move:GetOrigin()
			local dir = opppos.x < mypos.x and 1 or -1

			move:SetVelocity(Vector(dir * 300 * math.Clamp((pl:GetStateNumber() - CurTime()) / self.GuardKnockbackDuration, 0, 1) ^ 0.5, 0, 0))
			pl:SetGroundEntity(NULL)
			return MOVE_STOP
		end
	end

	local forceleft, forceright
	local tiebreaker = GAMEMODE.TieBreaker
	if tiebreaker then
		local origin = move:GetOrigin()
		local tiebreakerx = tiebreaker:GetPos().x
		if origin.x < tiebreakerx - self.MaxRange then
			--origin.x = tiebreakerx - self.MaxRange
			--move:SetOrigin(origin)
			forceleft = true
		elseif origin.x > tiebreakerx + self.MaxRange then
			--origin.x = tiebreakerx + self.MaxRange
			--move:SetOrigin(origin)
			forceright = true
		end
	end

	local onright = self:GetOpponentOnRight(pl)

	local speed = 0
	if forceleft then
		speed = speed + (onright and -1000 or 1000)
	elseif forceright then
		speed = speed + (onright and 1000 or -1000)
	else
		if pl:KeyDown(onright and IN_MOVELEFT or IN_MOVERIGHT) then
			speed = speed - 1000
		end
		if pl:KeyDown(onright and IN_MOVERIGHT or IN_MOVELEFT) then
			speed = speed + 1000
		end
	end

	--[[if onright then
		if noleft then
			speed = math.max(0, speed)
		elseif noright then
			speed = math.min(0, speed)
		end
	elseif noleft then
		speed = math.min(0, speed)
	elseif noright then
		speed = math.max(0, speed)
	end]]

	move:SetSideSpeed(0)
	move:SetForwardSpeed(speed)

	if pl:Crouching() or pl:GetStateBool() then
		move:SetMaxSpeed(self.WalkSpeed * 0.4)
		move:SetMaxClientSpeed(self.WalkSpeed * 0.4)
	elseif pl:GetStateInteger() == STATE_FIGHTER2D_PUNCHING then
		move:SetMaxSpeed(self.WalkSpeed * 0.6)
		move:SetMaxClientSpeed(self.WalkSpeed * 0.6)
	elseif onright and speed < 0 then
		move:SetMaxSpeed(self.WalkSpeed * 0.75)
		move:SetMaxClientSpeed(self.WalkSpeed * 0.75)
	else
		move:SetMaxSpeed(self.WalkSpeed)
		move:SetMaxClientSpeed(self.WalkSpeed)
	end

	return MOVE_STOP
end

function STATE:Think(pl)
	if pl:GetStateInteger() == STATE_FIGHTER2D_PUNCHING then
		if CurTime() >= pl:GetStateNumber() then
			pl:SetStateNumber(0)
			pl:SetStateInteger(STATE_FIGHTER2D_NONE)
			pl.Punch = false
		elseif pl.Punch and CurTime() >= pl:GetStateNumber() - self.PunchDelay + self.PunchTime then
			pl.Punch = false

			if CLIENT then return end

			for _, tr in ipairs(pl:GetTargets()) do
				local hitent = tr.Entity
				if hitent:IsPlayer() then
					if hitent:GetStateBool() then
						pl:SetStateInteger(STATE_FIGHTER2D_GUARDKNOCKBACK)
						pl:SetStateNumber(CurTime() + self.GuardKnockbackDuration)
					elseif not hitent:ImmuneToAll() then
						hitent:TakeDamage(3, pl)

						local effectdata = EffectData()
						if tr then
							effectdata:SetOrigin(tr.HitPos)
							effectdata:SetNormal(tr.HitNormal)
						else
							effectdata:SetOrigin(hitent:NearestPoint(pl:EyePos()))
							effectdata:SetNormal(pl:GetForward() * -1)
						end
						effectdata:SetEntity(hitent)
						util.Effect("punchhit", effectdata, true, true)
					end
				end
			end
		end
	elseif pl:GetStateInteger() == STATE_FIGHTER2D_SHOVING then
		if CurTime() >= pl:GetStateNumber() then
			pl:SetStateNumber(0)
			pl:SetStateInteger(STATE_FIGHTER2D_NONE)

			if CLIENT then return end

			for _, tr in ipairs(pl:GetTargets()) do
				local hitent = tr.Entity
				if hitent:IsPlayer() then
					if hitent:ImmuneToAll() then return end

					if hitent:GetStateBool() then
						hitent:SetStateBool(false)
						hitent:SetStateInteger(STATE_FIGHTER2D_GUARDBREAK)
						hitent:SetStateNumber(CurTime() + 1)
					else
						hitent:ThrowFromPosition(pl:GetPos(), 175)
						hitent:TakeDamage(2, pl)

						local effectdata = EffectData()
						if tr then
							effectdata:SetOrigin(tr.HitPos)
							effectdata:SetNormal(tr.HitNormal)
						else
							effectdata:SetOrigin(hitent:NearestPoint(pl:EyePos()))
							effectdata:SetNormal(pl:GetForward() * -1)
						end
						effectdata:SetEntity(hitent)
						util.Effect("punchhit", effectdata, true, true)
					end
				end
			end
		end
	elseif pl:GetStateInteger() == STATE_FIGHTER2D_GUARDBREAK then
		if CurTime() >= pl:GetStateNumber() then
			pl:SetStateNumber(0)
			pl:SetStateInteger(STATE_FIGHTER2D_NONE)
		end
	elseif pl:GetStateInteger() == STATE_FIGHTER2D_GUARDKNOCKBACK then
		if CurTime() >= pl:GetStateNumber() then
			pl:SetStateNumber(0)
			pl:SetStateInteger(STATE_FIGHTER2D_NONE)
		end
	end
end

function STATE:PrimaryAttack(pl)
	if pl:GetStateInteger() == STATE_FIGHTER2D_NONE and not pl:GetStateBool() then
		pl:DoAttackEvent()
		pl:SetStateInteger(STATE_FIGHTER2D_PUNCHING)
		pl:SetStateNumber(CurTime() + self.PunchDelay)
		pl.Punch = true

		return true
	end
end

function STATE:SecondaryAttack(pl)
	if pl:GetStateInteger() == STATE_FIGHTER2D_NONE and pl:OnGround() and not pl:GetStateBool() then
		--pl:DoAnimationEvent(ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND)
		pl:SetStateInteger(STATE_FIGHTER2D_SHOVING)
		pl:SetStateNumber(CurTime() + self.ShoveTime)

		return true
	end
end

function STATE:Reload(pl)
	if pl:GetStateInteger() == STATE_FIGHTER2D_NONE and pl:OnGround() and not pl:GetStateBool() then
		pl:SetStateBool(true)

		return true
	end
end

function STATE:KeyRelease(pl, key)
	if key == IN_RELOAD then
		pl:SetStateBool(false)
	end
end

function STATE:CalcMainActivity(pl, velocity)
	if pl:GetStateInteger() == STATE_FIGHTER2D_LOSE then
		pl.CalcSeqOverride = pl:LookupSequence("death_04")
		return
	end

	if pl:GetStateInteger() == STATE_FIGHTER2D_GUARDBREAK then
		pl.CalcSeqOverride = pl:LookupSequence("seq_preskewer")
		return
	end

	if pl:GetStateInteger() == STATE_FIGHTER2D_SHOVING then
		pl.CalcSeqOverride = pl:LookupSequence("seq_meleeattack01")
		return
	end

	pl.CalcIdeal = ACT_HL2MP_IDLE_FIST
	pl.CalcSeqOverride = -1

	GAMEMODE:HandlePlayerLanding(pl, velocity, pl.m_bWasOnGround)

	if GAMEMODE:HandlePlayerJumping(pl, velocity) or
		GAMEMODE:HandlePlayerDucking(pl, velocity) or
		GAMEMODE:HandlePlayerSwimming(pl, velocity) then
	else
		local len2d = velocity:Length2D()
		if len2d > 150 then
			pl.CalcIdeal = ACT_HL2MP_RUN_FIST
		elseif len2d > 0.5 then
			pl.CalcIdeal = ACT_HL2MP_WALK_FIST
		end
	end

	pl.m_bWasOnGround = pl:IsOnGround()
	pl.m_bWasNoclipping = pl:GetMoveType() == MOVETYPE_NOCLIP && !pl:InVehicle()

	return pl.CalcIdeal, pl.CalcSeqOverride
end

function STATE:GetOpponent(pl)
	for _, otherpl in pairs(player.GetAll()) do
		if otherpl:GetState() == self.Index and otherpl:Team() ~= pl:Team() then
			return otherpl
		end
	end
end

function STATE:GetOpponentOnRight(pl)
	local opponent = self:GetOpponent(pl)
	if opponent then
		return opponent:GetPos().x >= pl:GetPos().x
	end

	return true
end

function STATE:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST, true)

		return ACT_INVALID
	--[[elseif event == PLAYERANIMEVENT_CUSTOM_GESTURE and data == ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND, true)

		return ACT_INVALID]]
	end
end

if SERVER then return end

function STATE:CreateMove(pl, cmd)
	if pl:GetStateInteger() == STATE_FIGHTER2D_LOSE or pl:GetStateInteger() == STATE_FIGHTER2D_GUARDBREAK then
		cmd:ClearButtons()
		return true
	end

	cmd:SetViewAngles(Angle(0, self:GetOpponentOnRight(pl) and 0 or 180, 0))

	if bit.band(cmd:GetButtons(), IN_FORWARD) > 0 then
		cmd:SetButtons(bit.bor(cmd:GetButtons() - IN_FORWARD, IN_JUMP))
	end

	if bit.band(cmd:GetButtons(), IN_BACK) > 0 then
		cmd:SetButtons(bit.bor(cmd:GetButtons() - IN_BACK, IN_DUCK))
	end

	if (pl:Crouching() or pl:GetStateBool()) and bit.band(cmd:GetButtons(), IN_JUMP) > 0 then
		cmd:SetButtons(cmd:GetButtons() - IN_JUMP)
	end

	if not pl:OnGround() and bit.band(cmd:GetButtons(), IN_DUCK) > 0 then
		cmd:SetButtons(cmd:GetButtons() - IN_DUCK)
	end
end

function STATE:GetCameraPos(pl, camerapos, origin, angles, fov, znear, zfar)
	camerapos:Set(pl:GetPos() + Vector(0, -200, 80))
	angles:Set(Angle(0, 90, 0))
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	if pl:GetStateInteger() == STATE_FIGHTER2D_LOSE then
		pl:SetCycle(math.Clamp((CurTime() - pl:GetStateNumber()) * 0.25, 0, 0.75))
		pl:SetPlaybackRate(0)
		return true
	end

	if pl:GetStateInteger() == STATE_FIGHTER2D_GUARDBREAK then
		pl:SetCycle(1 - math.Clamp(pl:GetStateNumber() - CurTime(), 0, 1))
		pl:SetPlaybackRate(0)
		return true
	end

	if pl:GetStateInteger() == STATE_FIGHTER2D_GUARDKNOCKBACK then
		pl:SetCycle(1 - math.Clamp(pl:GetStateNumber() - CurTime(), 0, 1) / self.GuardKnockbackDuration)
		pl:SetPlaybackRate(0)
		return true
	end

	if pl:GetStateInteger() == STATE_FIGHTER2D_SHOVING then
		pl:SetCycle(0.7 * math.Clamp(1 - (pl:GetStateNumber() - CurTime()) / self.ShoveTime, 0, 1) ^ 2.5)
		pl:SetPlaybackRate(0)
		return true
	end

	pl.FistBlockWeight = math.Approach(pl.FistBlockWeight or 0, pl:GetStateBool() and 1 or 0, FrameTime() * 8)

	if pl.FistBlockWeight > 0 then
		pl:AnimRestartGesture(GESTURE_SLOT_VCD, ACT_HL2MP_FIST_BLOCK, true)
		pl:AnimSetGestureWeight(GESTURE_SLOT_VCD, pl.FistBlockWeight)
	end
end
