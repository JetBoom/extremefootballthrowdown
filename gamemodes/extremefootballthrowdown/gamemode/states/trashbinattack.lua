STATE.Time = 0.75

function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(0)
	
	pl:DoAttackEvent()
	pl:SetStateBool(false)
end

function STATE:Ended(pl, newstate)
	if newstate ~= STATE_NONE or not pl:GetCarry():IsValid() or pl:GetCarry():GetClass() ~= "prop_carry_trashbin" then return end

	pl:DoAttackEvent()
end


--[[if SERVER then
function STATE:Ended(pl, newstate)
	if newstate == STATE_NONE then
		local carry = pl:GetCarry()
		if not carry:IsValid() or carry:GetClass() ~= "prop_carry_trashbin" then return end

		for _, tr in ipairs(pl:GetTargets()) do
			local hitent = tr.Entity
			if hitent:IsPlayer() then
				local ent = ents.Create("prop_trashbin")
				if ent:IsValid() then
					ent:SetPos(hitent:EyePos())
					ent:SetOwner(hitent)
					ent:SetParent(hitent)
					ent:Spawn()
				end

				hitent:TakeDamage(1, pl, carry)

				carry:Remove()

				return
			end
		end
	end
end
end]]

function STATE:IsIdle(pl)
	return false
end

function STATE:Move(pl, move)
	move:SetMaxClientSpeed(SPEED_ATTACK)

	return MOVE_STOP
end

function STATE:ThinkCompensatable(pl)
	if not pl:IsOnGround() and pl:WaterLevel() < 2 then
		pl:EndState(true)
	else
		local carry = pl:GetCarry()
		if not carry:IsValid() or carry:GetClass() ~= "prop_carry_trashbin" then
			pl:EndState(true)
			return
		end

		if CurTime() < pl:GetStateStart() + self.Time then return end

		if SERVER then
			local targets = pl:GetTargets(nil, nil, nil, nil, true)
			for _, tr in ipairs(targets) do
				local hitent = tr.Entity
				if hitent:IsPlayer() then
					local ent = ents.Create("prop_trashbin")
					if ent:IsValid() then
						ent:SetPos(hitent:EyePos())
						ent:SetOwner(hitent)
						ent:SetParent(hitent)
						ent:Spawn()
					end

					hitent:TakeDamage(1, pl, carry)

					carry:Remove()

					break
				end
			end
		end

		pl:EndState(true)
	end
end

--[[function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("seq_preskewer")
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:SetCycle((1 - math.Clamp((CurTime() - pl:GetStateStart()) / self.Time, 0, 1)) ^ 2 * 0.85 + 0.15)
	pl:SetPlaybackRate(0)

	return true
end]]
