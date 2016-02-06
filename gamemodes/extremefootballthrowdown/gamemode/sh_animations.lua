if SERVER then
	include("animationsapi/boneanimlib.lua")
end

if CLIENT then
	include("animationsapi/cl_boneanimlib.lua")
end

local ACT_MP_STAND_IDLE = ACT_MP_STAND_IDLE
local ACT_HL2MP_SWIM_SLAM = ACT_HL2MP_SWIM_SLAM
local ACT_HL2MP_SWIM_IDLE_SLAM = ACT_HL2MP_SWIM_IDLE_SLAM
local ACT_HL2MP_WALK_SUITCASE = ACT_HL2MP_WALK_SUITCASE
local ACT_MP_WALK = ACT_MP_WALK
local ACT_MP_RUN = ACT_MP_RUN
local ACT_HL2MP_IDLE_MELEE_ANGRY = ACT_HL2MP_IDLE_MELEE_ANGRY
local ACT_HL2MP_IDLE_ANGRY = ACT_HL2MP_IDLE_ANGRY
local ACT_HL2MP_RUN_FAST = ACT_HL2MP_RUN_FAST

function GM:HandlePlayerSwimming(pl, velocity)
	if not pl:IsSwimming() then return false end

	if velocity:LengthSqr() > 100 then
		pl.CalcIdeal = ACT_HL2MP_SWIM_SLAM
	else
		pl.CalcIdeal = ACT_HL2MP_SWIM_IDLE_SLAM
	end

	return true
end

function GM:CalcMainActivity(pl, velocity)
	pl.CalcIdeal = ACT_MP_STAND_IDLE
	pl.CalcSeqOverride = -1

	self:HandlePlayerLanding( pl, velocity, pl.m_bWasOnGround )

	if not ( self:HandlePlayerJumping( pl, velocity ) or self:HandlePlayerDucking( pl, velocity ) or self:HandlePlayerSwimming( pl, velocity ) ) then
		local len2d = velocity:LengthSqr()
		if len2d >= 84100 then --290^2
			pl.CalcIdeal = ACT_HL2MP_RUN_FAST
		elseif len2d >= 22500 then --150^2
			pl.CalcIdeal = ACT_MP_RUN
		elseif len2d >= 1 then
			pl.CalcIdeal = pl:IsCarrying() and ACT_HL2MP_WALK_SUITCASE or ACT_MP_WALK
		else
			pl.CalcIdeal = pl:IsCarrying() and ACT_HL2MP_IDLE_MELEE_ANGRY or ACT_HL2MP_IDLE_ANGRY
		end
	end

	pl.m_bWasOnGround = pl:IsOnGround()

	if not pl:CallStateFunction("CalcMainActivity", velocity) then
		pl:CallCarryFunction("CalcMainActivity", velocity)
	end

	return pl.CalcIdeal, pl.CalcSeqOverride
end

function GM:DoAnimationEvent(pl, event, data)
	return pl:CallStateFunction("DoAnimationEvent", event, data) or pl:CallCarryFunction("DoAnimationEvent", event, data) or self.BaseClass.DoAnimationEvent(self, pl, event, data)
end

function GM:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	return pl:CallStateFunction("UpdateAnimation", velocity, maxseqgroundspeed) or pl:CallCarryFunction("UpdateAnimation", velocity, maxseqgroundspeed) or self.BaseClass.UpdateAnimation(self, pl, velocity, maxseqgroundspeed)
end
