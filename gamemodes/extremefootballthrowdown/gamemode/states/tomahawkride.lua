STATE.MaxTurningAngle = 34

function STATE:Started(pl, oldstate)
	--pl:SetStateAngles(Angle(0, 0, 0))

	if SERVER then
		pl:CreateRagdoll()

		pl:SetCollisionMode(COLLISION_PASSTHROUGH)
	end
end

function STATE:IsIdle(pl)
	return false
end

function STATE:Move(pl, move)
	local ent = pl:GetStateEntity()
	if ent:IsValid() then
		local pos = ent:LocalToWorld(ent:OBBCenter())
		move:SetVelocity(vector_origin)
		move:SetOrigin(pos)
		pl:SetNetworkOrigin(pos)
	end

	move:SetSideSpeed(0)
	move:SetForwardSpeed(0)
	move:SetMaxSpeed(0)
	move:SetMaxClientSpeed(0)

	return MOVE_STOP
end

if SERVER then
function STATE:Think(pl)
	local ent = pl:GetStateEntity()
	if not (ent:IsValid() and ent:GetClass() == "prop_carry_tomahawk" and ent:GetThrown()) then
		pl:EndState()
	end
end
end

if not CLIENT then return end

function STATE:Think(pl)
	local ent = pl:GetStateEntity()
	if not ent:IsValid() then return end

	local rag = pl:GetRagdollEntity()
	if not rag or not rag:IsValid() then return end

	local phys = rag:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end

	local physnum = rag:LookupBone("ValveBiped.Bip01_R_Hand")
	if not physnum then return end

	physnum = rag:TranslateBoneToPhysBone(physnum)
	if not physnum then return end

	phys = rag:GetPhysicsObjectNum(physnum)
	if phys and phys:IsValid() then
		--phys:ComputeShadowControl({secondstoarrive = 0.01, pos = ent:GetPos(), angle = ent:GetAngles(), maxangular = 2000, maxangulardamp = 10000, maxspeed = 5000, maxspeeddamp = 1000, dampfactor = 0.85, teleportdistance = 1, deltatime = ft})
		local pos = ent:LocalToWorld(ent:OBBCenter())
		phys:SetPos(pos)
		phys:SetVelocityInstantaneous(ent:GetVelocity())
	end
end
STATE.ThinkOther = STATE.Think

function STATE:GetCameraPos(pl, camerapos, origin, angles, fov, znear, zfar)
	local ent = pl:GetStateEntity()
	if ent:IsValid() then
		camerapos:Set(ent:GetPos() - angles:Forward() * 200 + angles:Up() * 32)
	end
end

function STATE:CreateMove(pl, cmd)
	local ent = pl:GetStateEntity()
	if not ent:IsValid() then return end

	--[[if pl:GetStateAngles() ~= angle_zero then
		ent.m_GuideEyeAngles = pl:GetStateAngles()
	end]]

	local viewangle = cmd:GetViewAngles()

	if not ent.m_GuideAngles then
		ent.m_GuideAngles = viewangle
	end

	local newangles = util.LimitTurning(ent.m_GuideAngles, viewangle, ent.MaxTurningAngle, CurTime() - ent.LastThink)

	ent.m_GuideAngles = newangles
	ent.LastThink = CurTime()

	cmd:SetViewAngles(newangles)
end

function STATE:PrePlayerDraw(pl)
	return true
end
