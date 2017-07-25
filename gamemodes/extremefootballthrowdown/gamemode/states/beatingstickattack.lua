STATE.Time = 0.55
STATE.HitTime = 0.18
STATE.Range = 64
STATE.FOV = 90

function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(0)

	pl:DoAttackEvent()
	pl:SetStateBool(false)

	if SERVER then
		pl:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 72, math.Rand(65, 75))
	end
end

function STATE:IsIdle(pl)
	return false
end

function STATE:Move(pl, move)
	move:SetMaxClientSpeed(SPEED_ATTACK)

	return MOVE_STOP
end

function STATE:OnChargedInto(pl, otherpl)
	if CurTime() >= pl:GetStateStart() + self.HitTime then
		local tr = pl:TargetsContain(otherpl, self.Range)
		if tr then
			self:HitEntity(pl, otherpl, tr, true)
			return true
		end
	end
end

function STATE:OnHitWithArcaneBolt(pl, ent)
	if CurTime() >= pl:GetStateStart() + self.HitTime and ent:GetOwner():IsValid() and ent:GetOwner():IsPlayer() and ent:GetOwner():Team() ~= pl:Team() then
		local tr = pl:TargetsContain(ent, self.Range)
		if tr then
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				local vel = phys:GetVelocity()
				local aim = pl:GetAimVector()
				if vel:GetNormalized():Dot(aim) <= -0.8 then
					phys:SetVelocityInstantaneous(vel * -1.4)
				else
					phys:SetVelocityInstantaneous(vel:Length() * 1.4 * aim)
				end
			end

			ent:SetOwner(pl)
			ent:SetColor(team.GetColor(pl:Team()))
			ent.Team = pl:Team()
			ent:EmitSound("npc/manhack/bat_away.wav")

			return true
		end
	end
end

function STATE:HitEntity(pl, hitent, tr, spinny)
	if hitent:ThrowFromPosition(pl:GetLaunchPos(), 450, true, pl) and spinny then
		hitent:SetState(STATE_SPINNYKNOCKDOWN, STATES[STATE_SPINNYKNOCKDOWN].Time)
	end
	hitent:TakeDamage(12, pl)

	pl:ViewPunch(VectorRand():Angle() * (math.random(2) == 1 and -1 or 1) * 0.1)

	local effectdata = EffectData()
		effectdata:SetOrigin(tr.HitPos)
		effectdata:SetNormal(tr.HitNormal)
		effectdata:SetEntity(hitent)
	util.Effect("hit_beatingstick", effectdata, true, true)
end

function STATE:ThinkCompensatable(pl)
	if not pl:IsOnGround() and not pl:IsSwimming() then
		pl:EndState(true)
	elseif not pl:GetStateBool() and CurTime() >= pl:GetStateStart() + self.HitTime then
		pl:SetStateBool(true)

		if SERVER then
			local targets = pl:GetSweepTargets(self.Range, self.FOV, nil, nil, nil, true)
			for _, tr in ipairs(targets) do
				local hitent = tr.Entity
				if hitent:IsPlayer() and not hitent:ImmuneToAll() then
					self:HitEntity(pl, hitent, tr)
				end
			end

			local ball = GAMEMODE:GetBall()
			if not ball:GetCarrier():IsValid() then
				local ballpos = ball:GetPos()
				local eyepos = pl:EyePos()
				if ballpos:Distance(eyepos) <= self.Range and util.IsVisible(ballpos, eyepos) then
					local eyevector = pl:EyeAngles()
					eyevector.pitch = 0
					eyevector = eyevector:Forward()

					local dir = ballpos - eyepos
					dir:Normalize()
					if eyevector:Dot(dir) >= 0.4 then
						if CurTime() >= (NEXTHOMERUN or 0) then
							NEXTHOMERUN = CurTime() + 5
						end

						ball.LastBigPoleHit = pl
						ball.LastBigPoleHitTime = CurTime()
						ball:SetLastCarrier(pl)
						ball:SetAutoReturn(0)
						ball:EmitSound("npc/zombie/zombie_hit.wav", 90, math.Rand(95, 105))
						local phys = ball:GetPhysicsObject()
						if phys:IsValid() then
							local ang = dir:Angle()
							ang.pitch = -35
							phys:SetVelocityInstantaneous(ang:Forward() * 731)
						end
					end
				end
			end
		end
	end
end

--[[function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("seq_baton_swing")
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:SetCycle(math.Clamp(1 - (pl:GetStateEnd() - CurTime()) / self.Time, 0, 1) * 0.8)
	pl:SetPlaybackRate(0)

	return true
end]]
