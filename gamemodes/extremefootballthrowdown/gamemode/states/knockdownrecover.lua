function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(0)
end

function STATE:Ended(pl, newstate)
	if newstate == STATE_NONE then
		pl:SetNextMoveVelocity(pl:GetVelocity() + pl:GetStateVector())
	end
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
