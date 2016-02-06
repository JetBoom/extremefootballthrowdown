STATE.Time = 0.45
STATE.AnimTime = STATE.Time * 2.1
STATE.ThrowForce = 1100
STATE.ChargeTime = 1

function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(0)
	pl:SetStateNumber(CurTime())
	pl:SetStateBool(false)

	if SERVER then pl:PlayVoiceSet(VOICESET_THROW) end
end

if SERVER then
function STATE:Ended(pl, newstate)
	if newstate == STATE_NONE then
		local carrying = pl:GetCarry()
		if carrying.Drop then
			local throwforce = self:GetThrowForce(pl)

			local throwpos
			if util.TraceLine({start = pl:GetPos() + Vector(0, 0, 4), endpos = pl:GetPos() + Vector(0, 0, pl:OBBMaxs().z + 4), mask = MASK_SOLID_BRUSHONLY}).Hit then
				throwpos = pl:WorldSpaceCenter()
			else
				throwpos = pl:GetShootPos()
			end

			carrying:Drop(throwforce)
			carrying:EmitSound("weapons/stinger_fire1.wav", 76, 100)
			carrying:SetPos(throwpos)

			local phys = carrying:GetPhysicsObject()
			if phys:IsValid() then
				phys:Wake()
				phys:SetVelocityInstantaneous(pl:GetAimVector() * throwforce)
				phys:AddAngleVelocity(VectorRand() * math.Rand(-450, 450))
			end
		end
	end
end
end

function STATE:GetThrowPower(pl)
	local chargetime = self.ChargeTime
	local carry = pl:GetCarrying()
	if carry:IsValid() and GAMEMODE:GetBall() == carry then
		chargetime = (carry:CallStateFunction("GetChargeTimeMultiplier", pl) or 1) * chargetime
	end

	return math.Clamp((pl:GetStateBool() and pl:GetStateNumber() or (CurTime() - pl:GetStateNumber())) / chargetime, 0, 1)
end

function STATE:GetThrowForce(pl)
	local carry = pl:GetCarry()

	local baseforce = carry.GetThrowForce and carry:GetThrowForce() or carry.ThrowForce or self.ThrowForce
	local chargemul = (1 + self:GetThrowPower(pl)) / 2
	local objectmul = carry.GetThrowForceMultiplier and carry:GetThrowForceMultiplier(pl) or 1

	return baseforce * objectmul * chargemul
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
	if not pl:IsOnGround() and pl:WaterLevel() < 2 then
		pl:EndState(true)
	elseif pl:GetStateEnd() == 0 then
		if pl:KeyDown(IN_ATTACK) then
			pl:EndState(true)
		elseif not pl:KeyDown(IN_ATTACK2) then
			pl:SetStateStart(CurTime())
			pl:SetStateEnd(pl:GetStateStart() + self.Time)
			pl:SetStateNumber(self:GetThrowPower(pl))
			pl:SetStateBool(true)

			if SERVER then
				pl:EmitSound("npc/zombie/claw_miss"..math.random(2)..".wav", 72, math.Rand(77, 83))
			end
		end
	end
end

function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("seq_throw")

	return true
end

function STATE:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	if pl:GetStateEnd() == 0 then
		pl:SetCycle(0.15 + math.sin(CurTime() * math.pi * 2) * 0.05)
		--[[local throwpower = self:GetThrowPower(pl)
		if throwpower == 1 then
			pl:SetCycle(math.sin(CurTime() * math.pi * 2) * 0.05 + throwpower * 0.2)
		else
			pl:SetCycle(throwpower * 0.2)
		end]]
	else
		pl:SetCycle(math.Clamp((CurTime() - pl:GetStateStart()) / self.AnimTime * 0.9, 0, 1))
	end
	pl:SetPlaybackRate(0)

	return true
end

if not CLIENT then return end

function STATE:GetCameraPos(pl, camerapos, origin, angles, fov, znear, zfar)
	pl:ThirdPersonCamera(camerapos, origin, angles, fov, znear, zfar, pl:GetStateEnd() == 0 and math.Clamp((CurTime() - pl:GetStateStart()) / 0.2, 0, 1) or 1)
end

function STATE:ShouldDrawCrosshair()
	return true
end

function STATE:ShouldDrawAngleFinder()
	return true
end

local color_black_alpha160 = Color(0, 0, 0, 160)
function STATE:Draw3DHUD(pl)
	local w, h = 400, 40
	local x, y = w * -0.5, h * -0.5
	local fadein = pl:GetStateEnd() == 0 and math.Clamp((CurTime() - pl:GetStateStart()) * 4, 0, 1) or 1
	local time = CurTime()

	local camang = EyeAngles3D2D()
	camang:RotateAroundAxis(camang:Right(), 30 + GAMEMODE.CameraYawLerp / 3)
	camang:RotateAroundAxis(camang:Up(), 90)

	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	cam.IgnoreZ(true)
	cam.Start3D2D(EyePos3D2DScreen(512, 0), camang, 1)

		draw.SimpleText("POWER", "eft_3dpowertext", x - 8, y, Color(255, 255, 255, 255 * fadein), TEXT_ALIGN_RIGHT)
		surface.SetDrawColor(0, 0, 0, 120 * fadein)
		surface.DrawRect(x, y, w, h)
		surface.SetDrawColor(255, 255, 255, 220 * fadein)
		surface.DrawOutlinedRect(x, y, w, h)
		surface.DrawRect(x + 3, y + 3, (w - 6) * self:GetThrowPower(pl), h - 6)

	cam.End3D2D()
	cam.IgnoreZ(false)
	--render.PopFilterMin()
	--render.PopFilterMag()
end
