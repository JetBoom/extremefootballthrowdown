STATE.CanPickup = false

STATE.Time = 1
STATE.HitTime = 0.6
STATE.Range = 128

function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(0)

	pl:SetStateBool(false)
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

function STATE:OnChargedInto(pl, otherpl)
	if CurTime() >= pl:GetStateStart() + self.HitTime then
		local tr = pl:TargetsContain(otherpl, self.Range)
		if tr then
			self:HitEntity(pl, otherpl, tr)
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

function STATE:HitEntity(pl, hitent, tr)
	local knockdown = CurTime() >= hitent:GetKnockdownImmunity(self)
	hitent:ThrowFromPosition(pl:GetLaunchPos(), 800, knockdown, pl)
	if knockdown then
		hitent:ResetKnockdownImmunity(self)
	end
	if pl:GetState() ~= STATE_SPINNYKNOCKDOWN and pl:GetState() ~= STATE_KNOCKDOWN then
		hitent:SetState(STATE_SPINNYKNOCKDOWN, STATES[STATE_SPINNYKNOCKDOWN].Time)
	end
	hitent:TakeDamage(25, pl)

	pl:ViewPunch(VectorRand():Angle() * (math.random(2) == 1 and -1 or 1) * 0.1)

	local effectdata = EffectData()
		effectdata:SetOrigin(tr.HitPos)
		effectdata:SetNormal(tr.HitNormal)
		effectdata:SetEntity(hitent)
	util.Effect("hit_bigpole", effectdata, true, true)
end

function STATE:Think(pl)
	if not (pl:IsOnGround() and pl:WaterLevel() < 2) then
		pl:EndState(true)
	elseif SERVER and not pl:GetStateBool() and CurTime() >= pl:GetStateStart() + self.HitTime then
		pl:SetStateBool(true)
		if SERVER then
			pl:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 72, math.Rand(35, 45))
		end

		for _, tr in ipairs(pl:GetTargets(self.Range)) do
			local hitent = tr.Entity
			if hitent:IsPlayer() and not hitent:ImmuneToAll() then
				self:HitEntity(pl, hitent, tr)
			end
		end
	end
end

function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("seq_baton_swing")
	return true
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:SetCycle(math.Clamp(1 - (pl:GetStateEnd() - CurTime()) / self.Time, 0, 1) ^ 3.5 * 0.8)
	pl:SetPlaybackRate(0)

	return true
end
