STATE.Time = 0.9

function STATE:Started(pl, oldstate)
	pl:SetCollisionMode(COLLISION_PASSTHROUGH)

	pl:Freeze(true)
	pl:SetStateBool(math.random(2) == 1)
end

function STATE:Ended(pl, newstate)
	pl:Freeze(false)
end

if SERVER then
function STATE:GoToNextState(pl)
	pl:KnockDown()
	return true
end
end

function STATE:IsIdle(pl)
	return false
end

function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence(pl:GetStateBool() and "death_01" or "death_03")
end

function STATE:GetCycle(pl)
	return math.Clamp(1 - (pl:GetStateEnd() - CurTime()) / self.Time, 0, 1)
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:SetCycle(self:GetCycle(pl))
	pl:SetPlaybackRate(0)

	return true
end

--[[if not CLIENT then return end

function STATE:GetCameraPos(pl, camerapos, origin, angles, fov, znear, zfar)
	angles:RotateAroundAxis(Vector(0, 0, 1), math.min(self:GetCycle(pl) ^ 0.5 * 420, 360))
	camerapos:Set(origin - angles:Forward() * 82)
end]]
