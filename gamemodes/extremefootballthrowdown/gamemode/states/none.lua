function STATE:IsIdle(pl)
	return true
end

function STATE:CanPickup(pl, ent)
	return true
end

function STATE:Started(pl, oldstate)
	pl:ResetJumpPower()

	--pl:SetStateInteger(pl:KeyDown(IN_ATTACK2) and 1 or pl:KeyDown(IN_RELOAD) and -1 or 0)
	pl:SetStateInteger(pl:KeyDown(IN_RELOAD) and -1 or 0)
	pl:SetStateNumber(0)
end

function STATE:Think(pl)
	self:HighJumpThink(pl)
end

function STATE:HighJumpThink(pl)
	if pl:GetStateNumber() == 0 then
		if pl:Crouching() and pl:IsOnGround() and pl:GetVelocity():LengthSqr() <= 256 and not pl:IsCarrying() then
			pl:SetStateNumber(CurTime() + 1)
		end
	elseif not pl:Crouching() or not pl:OnGround() or pl:GetVelocity():LengthSqr() > 256 or pl:IsCarrying() then
		pl:SetStateNumber(0)
	end
end

if SERVER then
function STATE:Think(pl)
	self:HighJumpThink(pl)

	if not pl:CanCharge() then return end

	--[[local comp = pl:ShouldCompensate()
	if comp then
		pl:LagCompensation(true)
	end]]
	local targets = pl:GetTargets()
	--[[if comp then
		pl:LagCompensation(false)
	end]]

	for _, tr in pairs(targets) do
		if not pl:CanCharge() then return end

		local hitent = tr.Entity
		if hitent:IsPlayer() and hitent:GetChargeImmunity(pl) <= CurTime() and not hitent:ImmuneToAll() then
			if hitent:CallStateFunction("OnChargedInto", pl) then
				continue
			elseif hitent:CanCharge() and math.abs(math.AngleDifference(hitent:GetAngles().yaw, (pl:GetPos() - hitent:GetPos()):Angle().yaw)) <= 25 then
				local myspeed = pl:GetVelocity():LengthSqr()
				local otherspeed = hitent:GetVelocity():LengthSqr()
				if not hitent:IsCarrying() and math.abs(myspeed - otherspeed) < 576 then --24^2
					pl:SetState(STATE_POWERSTRUGGLE, nil, hitent)
					hitent:SetState(STATE_POWERSTRUGGLE, nil, pl)
					return
				else
					pl:PrintMessage(HUD_PRINTTALK, "HEAD ON! - My speed: "..myspeed.." Their speed: "..otherspeed)
					hitent:PrintMessage(HUD_PRINTTALK, "HEAD ON! - My speed: "..otherspeed.." Their speed: "..myspeed)
					if myspeed < otherspeed then
						hitent:ChargeHit(pl, tr)
						continue
					end
				end
			end

			pl:ChargeHit(hitent, tr)
		end
	end
end
end

function STATE:CalcMainActivity(pl, velocity)
	if pl:CanCharge() then
		pl.CalcIdeal = ACT_HL2MP_RUN_CHARGING
		pl.CalcSeqOverride = -1
	end
end

function STATE:KeyPress(pl, key)
	--[[if key == IN_ATTACK2 then
		pl:SetStateInteger(1)
	elseif key == IN_RELOAD then
		pl:SetStateInteger(-1)
	else]]if key == IN_JUMP and self:CanHighJump(pl) then
		pl:SetState(STATE_HIGHJUMP, 5)
	end
end

function STATE:Reload(pl)
	pl:SetStateInteger(-1)
end

function STATE:CanHighJump(pl)
	return pl:Crouching() and pl:OnGround() and CurTime() >= pl:GetStateNumber() and pl:GetStateNumber() > 0 and not pl:IsCarrying()
end

function STATE:KeyRelease(pl, key)
	--if key == IN_ATTACK2 and pl:GetStateInteger() == 1 or key == IN_RELOAD and pl:GetStateInteger() == -1 then
	if key == IN_RELOAD and pl:GetStateInteger() == -1 then
		pl:SetStateInteger(0)
	end
end

local skip = false
local matWhite = Material("models/debug/debugwhite")
function STATE:PostPlayerDraw(pl)
	if not skip and pl:GetStateNumber() > 0 and CurTime() >= pl:GetStateNumber() then
		skip = true
		pl.SkipDrawHooks = true
		render.ModelMaterialOverride(matWhite)
		render.SetBlend(math.abs(math.sin(CurTime() * 14)) * 0.4)
		pl:DrawModel()
		render.SetBlend(1)
		render.ModelMaterialOverride()
		pl.SkipDrawHooks = nil
		skip = false
	end
end
