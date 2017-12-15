STATE.Time = 0.6

function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(0)
	
	pl:DoAttackEvent()
	pl:SetStateBool(false)
end

if SERVER then
function STATE:Ended(pl, newstate)
	
	if newstate == STATE_NONE then
		local carry = pl:GetCarry()
		if not carry:IsValid() or carry:GetClass() ~= "prop_carry_mowertrap" then return end

		local trace = {}
		trace.start = pl:EyePos()
		trace.endpos = trace.start + pl:GetForward() * 48
		trace.mins = Vector(-16, -16, -16)
		trace.maxs = Vector(16, 16, 16)
		trace.mask = MASK_PLAYERSOLID
		trace.filter = pl

		local tr = util.TraceHull(trace)
		if tr.Hit then
			pl:SendLua("surface.PlaySound(\"buttons/button8.wav\")")
			return
		end

		trace.start = tr.HitPos
		trace.endpos = trace.start + Vector(0, 0, -64)

		tr = util.TraceHull(trace)

		local hitent = tr.Entity
		local attach = hitent and hitent:IsValid() and not hitent:IsPlayer() and hitent:GetMoveType() == MOVETYPE_PUSH
		if (tr.HitWorld or attach) and tr.HitNormal.z >= 0.5 then
			local ang = tr.HitNormal:Angle()
			ang:RotateAroundAxis(ang:Right(), 270)

			local ent = ents.Create("prop_mowertrap")
			if ent:IsValid() then
				ent:SetPos(tr.HitPos)
				ent:SetAngles(ang)
				ent:SetColor(team.GetColor(pl:Team()))
				ent:Spawn()
				ent:SetPlayer(pl)
				ent:SetTeam(pl:Team())
				if attach then
					ent:SetParent(hitent)
				end
			end

			carry:Remove()
		else
			pl:SendLua("surface.PlaySound(\"buttons/button8.wav\")")
		end
	end
end
end

function STATE:IsIdle(pl)
	return false
end

function STATE:Move(pl, move)
	move:SetMaxClientSpeed(SPEED_ATTACK)

	return MOVE_STOP
end

function STATE:Think(pl)
	if not pl:IsOnGround() and pl:WaterLevel() < 2 then
		pl:EndState(true)
	end
end

--[[function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("seq_preskewer")
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:SetCycle(math.Clamp((pl:GetStateEnd() - CurTime()) / self.Time, 0, 1) ^ 2 * 0.85 + 0.15)
	pl:SetPlaybackRate(0)

	return true
end]]
