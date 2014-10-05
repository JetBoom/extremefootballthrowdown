function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(0)

	if SERVER then
		pl:GodEnable()
	end
end

function STATE:Ended(pl, newstate)
	if SERVER then
		pl:GodDisable()
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

function STATE:Think(pl)
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	local duration = pl:SequenceDuration()
	local time = CurTime() + pl:EntIndex() * 0.25
	pl:SetCycle((time % duration) / duration)
	pl:SetPlaybackRate(0)

	return true
end

function STATE:GetOpponents(pl)
	local pl1, pl2

	for _, otherpl in pairs(player.GetAll()) do
		if otherpl:GetState() == STATE_FIGHTER2D then
			if pl1 then
				pl2 = otherpl
				break
			else
				pl1 = otherpl
			end
		end
	end

	return pl1, pl2
end

function STATE:GetLookAt(pl)
	local pl1, pl2 = self:GetOpponents(pl)
	if pl1 and pl2 then
		local ang = ((pl1:LocalToWorld(pl2:OBBCenter()) + pl2:LocalToWorld(pl2:OBBCenter())) / 2 - pl:EyePos()):Angle()
		ang.roll = 0
		ang.pitch = 0

		return ang
	end

	return pl:EyeAngles()
end

local Sequences = {
	"seq_wave_smg1",
	"taunt_cheer_base",
	"taunt_cheer_base",
	"pose_standing_01",
	"pose_standing_02",
	"taunt_dance_base",
	"sit_zen"
}
function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence(Sequences[pl:EntIndex() % #Sequences + 1])
end

if SERVER then return end

function STATE:GetCameraPos(pl, camerapos, origin, angles, fov, znear, zfar)
	local pl1, pl2 = self:GetOpponents(pl)
	if pl1 and pl2 then
		camerapos:Set((pl1:GetPos() + pl2:GetPos()) / 2 + Vector(0, -200, 80))
		angles:Set(Angle(0, 90, 0))
	end
end

function STATE:CreateMove(pl, cmd)
	cmd:SetViewAngles(self:GetLookAt(pl))
end
