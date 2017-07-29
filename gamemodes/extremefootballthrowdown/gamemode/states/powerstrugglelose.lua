STATE.Time = 0.4

function STATE:NoSuicide(pl)
	return true
end

function STATE:ImmuneToAll(pl)
	return true
end

function STATE:GetOpponent(pl)
	local opp = pl:GetStateEntity()
	if opp:IsValid() and opp:GetStateEntity() == pl and opp:GetState() == STATE_POWERSTRUGGLEWIN then
		return opp
	end
end

function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(0)
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
	if not opp then return end

	local ang = cmd:GetViewAngles()
	ang.yaw = (opp:GetPos() - pl:GetPos()):Angle().yaw
	cmd:SetViewAngles(ang)
end

function STATE:Think(pl)
	local opp = self:GetOpponent(pl)
	if not opp then
		pl:EndState(true)
	elseif opp:GetPos():Distance(pl:GetPos()) >= 128 then
		opp:EndState(true)
		pl:EndState(true)
	end
end

function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("seq_preskewer")
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:SetCycle(math.Clamp((CurTime() - pl:GetStateStart()) / self.Time, 0, 1))
	pl:SetPlaybackRate(0)

	return true
end
