STATE.Velocity = 600

function STATE:Started(pl, oldstate)
	pl:SetNextMoveVelocity(Vector(0, 0, self.Velocity))

	if SERVER then
		pl:SetCollisionMode(COLLISION_PASSTHROUGH)
	end
end

function STATE:Ended(pl, newstate)
end

function STATE:CanPickup(pl, ent)
	return true
end

if SERVER then
function STATE:Think(pl)
	if pl:GetVelocity().z <= 350 and not pl:IsCarrying() then
		pl:KnockDown(3)
	end
end
end

function STATE:IsIdle(pl)
	return false
end

function STATE:OnPlayerHitGround(pl)
	pl:EndState()
end

function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("taunt_cheer_base")

	return true
end

function STATE:GetCycle(pl)
	return 0.5 + math.sin(CurTime() * 2) * 0.2
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:SetCycle(self:GetCycle(pl))
	pl:SetPlaybackRate(0)

	return true
end
