STATE.CanPickup = true

function STATE:IsIdle(pl)
	return true
end

function STATE:Started(pl, oldstate)
	pl:ResetJumpPower()

	pl:SetStateInteger(pl:KeyDown(IN_ATTACK2) and 1 or pl:KeyDown(IN_RELOAD) and -1 or 0)
end

if SERVER then
function STATE:Think(pl)
	if not pl:CanCharge() then return end

	for _, tr in pairs(pl:GetTargets()) do
		if not pl:CanCharge() then return end

		local hitent = tr.Entity
		if hitent:IsPlayer() and hitent:GetChargeImmunity(pl) <= CurTime() and not hitent:ImmuneToAll() then
			if hitent:CallStateFunction("OnChargedInto", pl) then
				continue
			elseif hitent:CanCharge() and math.abs(math.AngleDifference(hitent:GetAngles().yaw, (pl:GetPos() - hitent:GetPos()):Angle().yaw)) <= 25 and not hitent:IsCarrying() then
				local myspeed = pl:GetVelocity():Length2D()
				local otherspeed = hitent:GetVelocity():Length2D()
				if math.abs(myspeed - otherspeed) < 24 then
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
	if key == IN_ATTACK2 then
		pl:SetStateInteger(1)
	elseif key == IN_RELOAD then
		pl:SetStateInteger(-1)
	end
end

function STATE:KeyRelease(pl, key)
	if key == IN_ATTACK2 and pl:GetStateInteger() == 1 or key == IN_RELOAD and pl:GetStateInteger() == -1 then
		pl:SetStateInteger(0)
	end
end
