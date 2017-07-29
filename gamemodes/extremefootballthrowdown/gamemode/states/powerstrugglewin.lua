STATE.Time = 0.4

function STATE:NoSuicide(pl)
	return true
end

function STATE:ImmuneToAll(pl)
	return true
end

function STATE:GetOpponent(pl)
	local opp = pl:GetStateEntity()
	if opp:IsValid() and opp:GetStateEntity() == pl and opp:GetState() == STATE_POWERSTRUGGLELOSE then
		return opp
	end

	return NULL
end

function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(0)

	pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND, true)
end

function STATE:Ended(pl, newstate)
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

function STATE:CreateMove(pl, cmd)
	local opp = self:GetOpponent(pl)
	if not opp:IsValid() then return end

	local ang = cmd:GetViewAngles()
	ang.yaw = (opp:GetPos() - pl:GetPos()):Angle().yaw
	cmd:SetViewAngles(ang)
end

function STATE:Think(pl)
	local opp = self:GetOpponent(pl)
	if not opp:IsValid() then
		pl:EndState(true)
	elseif opp:GetPos():Distance(pl:GetPos()) >= 128 then
		opp:EndState(true)
		pl:EndState(true)
	elseif CurTime() >= pl:GetStateStart() + self.Time then
		pl:ViewPunch(VectorRand():Angle() * (math.random(2) == 1 and -1 or 1) * 0.1)

		if SERVER then
			local plpos = pl:GetPos()
			local eyepos = pl:EyePos()
			local fang = pl:GetAngles()
			fang.pitch = 0
			fang = fang:Forward()

			local victims = {opp}
			for _, target in pairs(pl:GetTargets()) do
				if target.Entity ~= opp then
					victims[#victims + 1] = target.Entity
				end
			end

			for _, target in pairs(victims) do
				if target:IsValid() and target:IsPlayer() and (not target:ImmuneToAll() or target == opp) then
					target:SetGravity(0.05)
					timer.Simple(0.6, function() if target:IsValid() then target:SetGravity(1) end end)
					target:SetGroundEntity(NULL)
					local tpos = target:GetPos()
					tpos.z = plpos.z
					target:SetVelocity((tpos - plpos):GetNormalized() * 800 + Vector(0, 0, 64))
					target:KnockDown(nil, pl)
					target:TakeDamage(33, pl)

					local effectdata = EffectData()
						effectdata:SetOrigin(target:NearestPoint(eyepos))
						effectdata:SetNormal(fang)
						effectdata:SetEntity(target)
					util.Effect("punchhit", effectdata, true, true)
				end
			end

			local effectdata = EffectData()
				effectdata:SetOrigin(eyepos + fang * 20)
				effectdata:SetNormal(fang)
			util.Effect("powerstrugglehit", effectdata, true, true)
		end

		pl:EndState()
		--opp:EndState()
	end
end

function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("seq_meleeattack01")
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:SetCycle(math.Clamp((CurTime() - pl:GetStateStart()) / self.Time * 0.8, 0, 1))
	pl:SetPlaybackRate(0)

	return true
end
