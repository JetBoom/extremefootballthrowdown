STATE.Time = 3.2

function STATE:Started(pl, oldstate)
	--pl:ResetJumpPower(0)

	if SERVER then
		pl:EmitSound("weapons/physcannon/physcannon_charge.wav", 72, 50, 0.75)
	end
end

function STATE:Ended(pl, newstate)
	if newstate ~= STATE_NONE or not pl:GetCarry():IsValid() or pl:GetCarry():GetClass() ~= "prop_carry_arcanewand" or pl:GetCarry().Canceled then return end

	pl:DoAttackEvent()

	if SERVER then
		pl:EmitSound("weapons/physcannon/energy_sing_flyby"..math.random(2)..".wav")
		pl:GetCarry():SetDTFloat(5, CurTime() + 1.5)

		local ent = ents.Create("projectile_arcanewand")
		if ent:IsValid() then
			ent:SetPos(pl:GetShootPos())
			ent:SetOwner(pl)
			ent:SetColor(team.GetColor(pl:Team()))
			ent.Team = pl:Team()
			ent:Spawn()

			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:Wake()
				phys:SetVelocityInstantaneous(pl:GetAimVector() * 700)
			end
		end
	end
end

function STATE:IsIdle(pl)
	return false
end

--[[function STATE:Move(pl, move)
	move:SetSideSpeed(0)
	move:SetForwardSpeed(0)
	move:SetMaxSpeed(0)
	move:SetMaxClientSpeed(0)

	return MOVE_STOP
end]]

function STATE:Think(pl)
	if not (--[[pl:IsOnGround() and]] pl:WaterLevel() < 2) then
		pl:EndState(true)
	end
end

--[[function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("seq_baton_swing")
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:SetCycle(0.3 * math.Clamp(1 - (pl:GetStateEnd() - CurTime()) / self.Time, 0, 1) ^ 4)
	pl:SetPlaybackRate(0)

	return true
end]]

if not CLIENT then return end

function STATE:HUDPaint(pl)
	GAMEMODE:DrawCrosshair()
end

function STATE:GetCameraPos(pl, camerapos, origin, angles, fov, znear, zfar)
	pl:ThirdPersonCamera(camerapos, origin, angles, fov, znear, zfar, math.Clamp((CurTime() - pl:GetStateStart()) * 4, 0, 1))
end
