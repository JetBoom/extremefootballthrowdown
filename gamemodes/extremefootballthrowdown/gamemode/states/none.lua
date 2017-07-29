local ACT_HL2MP_RUN_CHARGING = ACT_HL2MP_RUN_CHARGING
local IN_RELOAD = IN_RELOAD
local math_AngleDifference = math.AngleDifference
local pairs = pairs

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

function STATE:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND, true)
		return ACT_INVALID
	end
end

if SERVER then

local M_Entity = FindMetaTable("Entity")
local M_Player = FindMetaTable("Player")

local COLLISION_PASSTHROUGH = COLLISION_PASSTHROUGH
local COLLISION_NORMAL = COLLISION_NORMAL
local P_Team = M_Player.Team
local P_Alive = M_Player.Alive
local E_IsValid = M_Entity.IsValid

function STATE:Think(pl)
	self:HighJumpThink(pl)

	if not pl:CanCharge() then
		if pl:GetCollisionMode() > COLLISION_NORMAL then
			local myteam = P_Team(pl)
			for _, ent in pairs(ents.FindInBox(pl:WorldSpaceAABB())) do
				if E_IsValid(ent) and ent:IsPlayer() and P_Alive(ent) and P_Team(ent) ~= myteam then
					return
				end
			end

			pl:SetCollisionMode(COLLISION_NORMAL)
		end

		return
	end

	pl:MaxCollisionMode(COLLISION_PASSTHROUGH)

	--[[local comp = pl:ShouldCompensate()
	if comp then
		pl:LagCompensation(true)
	end]]
	local targets = pl:GetTargets()
	--[[if comp then
		pl:LagCompensation(false)
	end]]

	for _, tr in pairs(targets) do
		-- Hitting someone might have changed our ability to charge any more.
		if not pl:CanCharge() then return end

		local hitent = tr.Entity
		if hitent:IsPlayer() and hitent:GetChargeImmunity(pl) <= CurTime() and not hitent:ImmuneToAll() then
			-- Let victim state handle it.
			if hitent:CallStateFunction("OnChargedInto", pl) then
				continue
			end

			-- Victim charging in to us at the same time.
			if hitent:CanCharge() and math.abs(math_AngleDifference(hitent:GetAngles().yaw, (pl:GetPos() - hitent:GetPos()):Angle().yaw)) <= 25 then
				local myspeed = pl:GetVelocity():Length2D()
				local otherspeed = hitent:GetVelocity():Length2D()
				local myground = pl:OnGround()
				local otherground = hitent:OnGround() and not hitent:IsCarrying()
				local closespeed = math.abs(myspeed - otherspeed) < 24

				-- People on the ground always have priority. We're gonna get hit.
				if otherground and not myground then
					hitent:ChargeHit(pl, tr)
					continue
				end

				-- Same thing here.
				if myground and not otherground then
					pl:ChargeHit(hitent, tr)
					continue
				end

				-- Both in the air, hit each other regardless of speed.
				if not myground and not otherground then
					local mid = (hitent:GetPos() + pl:GetPos()) / 2

					hitent:ChargeHit(pl, tr)
					pl:ChargeHit(hitent, tr)

					hitent:SetLocalVelocity(vector_origin)
					pl:SetLocalVelocity(vector_origin)

					hitent:ThrowFromPosition(mid, myspeed, false, pl)
					pl:ThrowFromPosition(mid, otherspeed, false, pl)

					continue
				end

				-- Both on the ground, similar speed.
				if myground and otherground and closespeed then
					pl:SetState(STATE_POWERSTRUGGLE, nil, hitent)
					hitent:SetState(STATE_POWERSTRUGGLE, nil, pl)

					return
				end

				--[[pl:PrintMessage(HUD_PRINTTALK, "HEAD ON! - My speed: "..myspeed.." Their speed: "..otherspeed)
				hitent:PrintMessage(HUD_PRINTTALK, "HEAD ON! - My speed: "..otherspeed.." Their speed: "..myspeed)]]

				-- Punish us if our speed is less.
				if myspeed < otherspeed then
					hitent:ChargeHit(pl, tr)
					continue
				end
			end

			-- Default, just hit the target person.
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
