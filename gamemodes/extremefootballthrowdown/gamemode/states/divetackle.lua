STATE.ExtraSpeed = 100
STATE.UpwardBoost = 300

function STATE:IsIdle(pl)
	return false
end

function STATE:Started(pl, oldstate)
	pl:Freeze(true)
	pl:SetStateEntity(NULL)

	local ang = pl:EyeAngles()
	ang[1] = 0
	ang[3] = 0

	pl:SetGroundEntity(NULL)
	pl:SetLocalVelocity((pl:GetVelocity():Length() + self.ExtraSpeed) * ang:Forward() + Vector(0, 0, self.UpwardBoost))

	if SERVER then
		local ent = ents.Create("point_divetackletrigger")
		if ent:IsValid() then
			ent:SetOwner(pl)
			ent:SetParent(pl)
			ent:SetPos(pl:GetPos() + pl:GetForward() * 24)
			ent:Spawn()
		end

		pl:SetCollisionMode(COLLISION_PASSTHROUGH)
	end
end

function STATE:Ended(pl, newstate)
	pl:Freeze(false)

	if SERVER then
		for _, ent in pairs(ents.FindByClass("point_divetackletrigger")) do
			if ent:GetOwner() == pl then
				ent:Remove()
			end
		end
	end

	pl:SetStateEntity(NULL)
end

function STATE:CanPickup(pl, ent)
	return ent == GAMEMODE.Ball and pl:GetStateEntity() == NULL
end

if SERVER then
function STATE:Think(pl)
	if pl:OnGround() or pl:IsSwimming() then
		if pl:IsCarryingBall() then
			pl:EndState()
			pl:SetLocalVelocity(pl:GetVelocity() * 0.5)
		else
			for _, ent in pairs(ents.FindByClass("point_divetackletrigger")) do
				if ent:GetOwner() == pl then
					ent:ProcessTackles()
					return
				end
			end
		--[[else
			local heading = pl:GetVelocity()
			local speed = heading:Length()
			if 200 <= speed then
				heading:Normalize()
				local startpos = pl:GetPos()
				local tr = util.TraceHull({start = startpos, endpos = startpos + speed * FrameTime() * 2 * heading, mask = MASK_PLAYERSOLID, filter = pl:GetTraceFilter(), mins = pl:OBBMins(), maxs = pl:OBBMaxs()})
				if tr.Hit and tr.HitNormal.z < 0.65 and 0 < tr.HitNormal:Length() and not (tr.Entity:IsValid() and tr.Entity:IsPlayer()) then
					pl:KnockDown(3)
				end
			end]]
		end
	end
end
end

function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("zombie_leap_mid")

	return true
end

function STATE:UpdateAnimation(pl)
	pl:SetPlaybackRate(0)
	pl:SetCycle(CurTime() - pl:GetStateStart())

	return true
end
