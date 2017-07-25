KD_STATE_NONE = 0
KD_STATE_WALLSLAM = 1
KD_STATE_GETTINGUP = 2
KD_STATE_DIVETACKLED = 3

function STATE:Started(pl, oldstate)
	if SERVER then
		if 1 <= pl:Health() and pl:Alive() then
			pl:CreateRagdoll()
		end

		pl:SetCollisionMode(COLLISION_PASSTHROUGH)
	end

	pl:SetStateInteger(KD_STATE_NONE)
	pl:SetStateBool(math.random(2) == 1)

	pl:ResetJumpPower(0)
end

function STATE:Restarted(pl)
	local rag = pl:GetRagdollEntity()
	if not rag or not rag:IsValid() then
		pl:CreateRagdoll()
	end
end

function STATE:Ended(pl, newstate)
	if SERVER then
		pl.HighJumping = nil

		local rag = pl:GetRagdollEntity()
		if rag and rag:IsValid() then
			rag:Remove()
		end

		pl:SetCollisionMode(COLLISION_AVOID)
	end
end

function STATE:GoToNextState(pl)
	if not pl:OnGround() then return end

	local dir = vector_origin
	if pl:KeyDown(IN_FORWARD) then
		dir = dir + pl:GetForward()
	end
	if pl:KeyDown(IN_BACK) then
		dir = dir - pl:GetForward()
	end
	if pl:KeyDown(IN_MOVERIGHT) then
		dir = dir + pl:GetRight()
	end
	if pl:KeyDown(IN_MOVELEFT) then
		dir = dir - pl:GetRight()
	end

	if dir ~= vector_origin then
		dir:Normalize()
		dir = dir * 220
		dir.z = 128
		pl:SetState(STATE_KNOCKDOWNRECOVER, 0.1)
		pl:SetStateVector(dir)
	end
end

function STATE:IsIdle(pl)
	return false
end

function STATE:CanPickup(pl, ent)
	return pl.HighJumping
end

function STATE:Move(pl, move)
	move:SetSideSpeed(0)
	move:SetForwardSpeed(0)
	move:SetMaxSpeed(0)
	move:SetMaxClientSpeed(0)

	return MOVE_STOP
end

function STATE:CalcMainActivity(pl)
	pl.CalcSeqOverride = pl:LookupSequence(pl:GetStateBool() and "zombie_slump_rise_02_fast" or "zombie_slump_rise_01")

	return true
end

function STATE:UpdateAnimation(pl)
	local delta = 1 - (pl:GetStateEnd() - CurTime())
	pl:SetCycle(delta * 0.5 ^ 0.5 * 0.8 + 0.1)
	pl:SetPlaybackRate(0)

	return true
end

if SERVER then

function STATE:Think(pl)
	local state = pl:GetStateInteger()
	if state == KD_STATE_GETTINGUP then return end

	if state == KD_STATE_DIVETACKLED then
		local tackler = pl:GetStateEntity()
		if tackler:IsValid() and tackler:IsPlayer() and tackler:Alive() and tackler:GetState() == STATE_DIVETACKLE then
			pl:SetLocalVelocity(tackler:GetVelocity() * 1.02)
			return
		else
			state = KD_STATE_NONE
			pl:SetStateInteger(state)
		end
	end

	if state == KD_STATE_WALLSLAM then
		if pl:IsOnGround() or pl:IsOnPlayer() or pl:WaterLevel() >= 2 then
			pl:SetStateInteger(KD_STATE_NONE)
			pl:SetStateEnd(CurTime() + 1)
		elseif pl._KNOCKDOWNWALLFREEZE then
			if pl._KNOCKDOWNWALLFREEZE <= CurTime() then
				pl._KNOCKDOWNWALLFREEZE = nil
			else
				pl:SetLocalVelocity(vector_origin)
			end
		end
	elseif pl:GetStateInteger() == KD_STATE_NONE then
		if pl:GetStateEnd() > 0 and pl:GetStateEnd() < CurTime() + 1 then
			if pl:GetVelocity():Length() >= 100 then
				pl:SetStateEnd(CurTime() + 1)
			else
				pl:SetStateInteger(KD_STATE_GETTINGUP)
				local rag = pl:GetRagdollEntity()
				if rag and rag:IsValid() then
					rag:Remove()
				end
			end
		else
			local heading = pl:GetVelocity()
			local speed = heading:Length()
			if 200 <= speed then
				heading:Normalize()
				local startpos = pl:GetPos()
				local tr = util.TraceHull({start = startpos, endpos = startpos + speed * FrameTime() * 2 * heading, mask = MASK_PLAYERSOLID, filter = pl:GetTraceFilter(), mins = pl:OBBMins(), maxs = pl:OBBMaxs()})
				if tr.Hit and tr.HitNormal.z < 0.65 and 0 < tr.HitNormal:Length() and not (tr.Entity:IsValid() and tr.Entity:IsPlayer()) then
					pl:SetStateInteger(KD_STATE_WALLSLAM)
					pl:SetStateEnd(0)
					pl:SetStateVector(tr.HitNormal)
					pl._KNOCKDOWNWALLFREEZE = CurTime() + 0.9

					local eyeangs = pl:EyeAngles()
					pl:SetEyeAngles(Angle(eyeangs.pitch, tr.HitNormal:Angle().yaw, eyeangs.roll))

					local effectdata = EffectData()
						effectdata:SetOrigin(tr.HitPos)
						effectdata:SetNormal(tr.HitNormal)
						effectdata:SetEntity(pl)
					util.Effect("wallslam", effectdata)

					pl:SetLocalVelocity(vector_origin)
					util.ScreenShake(tr.HitPos, 20, 0.5, 1, 128)

					pl:TakeDamage(10, pl:GetLastAttacker() or pl, pl, tr.HitPos)
				end
			end
		end
	end
end
end

if not CLIENT then return end

local ShadowControlSlam = {maxspeed = 5000, maxspeeddamp = 1000, maxangular = 2000, maxangulardamp = 10000, dampfactor = 0.85, teleportdistance = 160}
function STATE:ComputeShadowControl(pl, rag, pos, ang, bonename, teledist)
	local rphys = rag:GetPhysicsObject()
	if rphys and rphys:IsValid() then
		rphys:Wake()
	end

	local physnum = rag:LookupBone(bonename)
	if not physnum then return end

	physnum = rag:TranslateBoneToPhysBone(physnum)
	if not physnum then return end

	local phys = rag:GetPhysicsObjectNum(physnum)
	if phys and phys:IsValid() then
		ShadowControlSlam.pos = pos or phys:GetPos()
		ShadowControlSlam.angle = ang or phys:GetAngles()
		ShadowControlSlam.teleportdistance = teledist or 160

		phys:Wake()
		phys:ComputeShadowControl(ShadowControlSlam)
	end
end

function STATE:Think(pl)
	local rag = pl:GetRagdollEntity()
	if not rag or not rag:IsValid() then return end

	rag:SetColor(pl:GetColor())
	rag:SetMaterial(pl:GetMaterial())

	local ft = FrameTime()

	if pl:GetStateInteger() == KD_STATE_WALLSLAM then
		self:WallSlamThink(pl, rag)
	elseif pl:GetStateInteger() == KD_STATE_DIVETACKLED then
		local tackler = pl:GetStateEntity()
		if tackler:IsValid() and tackler:IsPlayer() then
			local otherhandid = tackler:LookupBone("ValveBiped.Bip01_R_Hand")
			if otherhandid and otherhandid > 0 then
				local pos = tackler:GetBonePosition(otherhandid)
				if pos then
					self:ComputeShadowControl(pl, rag, pos, nil, "ValveBiped.Bip01_Spine2", 1)
				end
			end
		end
	else
		local endtime = pl:GetStateEnd()
		if endtime > 0 and endtime - 0.65 <= CurTime() then
			local playerpos = pl:GetPos()
			local delta = math.max(0.01, endtime - CurTime())
			for i = 0, rag:GetPhysicsObjectCount() do
				local translate = pl:TranslatePhysBoneToBone(i)
				if translate and 0 < translate then
					local pos, ang = pl:GetBonePosition(translate)
					if pos and ang then
						local phys = rag:GetPhysicsObjectNum(i)
						if phys and phys:IsValid() then
							phys:Wake()
							phys:ComputeShadowControl({secondstoarrive = math.max(delta, delta * pos:Distance(playerpos) * 0.1), pos = pos, angle = ang, maxangular = 1000, maxangulardamp = 10000, maxspeed = 5000, maxspeeddamp = 1000, dampfactor = 0.85, teleportdistance = 200, deltatime = ft})
						end
					end
				end
			end
		else
			local phys = rag:GetPhysicsObject()
			if phys:IsValid() then
				phys:Wake()
				phys:ComputeShadowControl({secondstoarrive = ft * 5, pos = pl:GetPos() + Vector(0, 0, 12), angle = rag:GetPhysicsObject():GetAngles(), maxangular = 2000, maxangulardamp = 10000, maxspeed = 5000, maxspeeddamp = 1000, dampfactor = 0.85, teleportdistance = 200, deltatime = ft})
			end
		end
	end
end
STATE.ThinkOther = STATE.Think

function STATE:WallSlamThink(pl, rag)
	local hitnormal = pl:GetStateVector()
	local hitpos = pl:GetPos() + hitnormal * -8

	local hitang = hitnormal:Angle()
	local up = hitang:Up()
	local right = hitang:Right()
	local torsopos = hitpos + up * 48

	local ft = FrameTime()

	ShadowControlSlam.secondstoarrive = ft * 10
	ShadowControlSlam.deltatime = ft

	local ownerangles = Angle()
	ownerangles:Set(hitang)
	ownerangles:RotateAroundAxis(ownerangles:Up(), 90)

	self:ComputeShadowControl(pl, rag, torsopos, ownerangles, "ValveBiped.Bip01_Spine")
	self:ComputeShadowControl(pl, rag, hitpos + up * 58, nil, "ValveBiped.Bip01_Head1")
	self:ComputeShadowControl(pl, rag, hitpos + right * 24 + up * 8, nil, "ValveBiped.Bip01_R_Foot")
	self:ComputeShadowControl(pl, rag, hitpos + right * -24 + up * 8, nil, "ValveBiped.Bip01_L_Foot")
	self:ComputeShadowControl(pl, rag, torsopos + right * 35, nil, "ValveBiped.Bip01_R_Hand")
	self:ComputeShadowControl(pl, rag, torsopos + right * -35, nil, "ValveBiped.Bip01_L_Hand")
end

function STATE:PrePlayerDraw(pl)
	local rag = pl:GetRagdollEntity()
	if rag and rag:IsValid() then
		return true
	end
end
