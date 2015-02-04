if SERVER then
	include("animationsapi/boneanimlib.lua")
end

if CLIENT then
	include("animationsapi/cl_boneanimlib.lua")
end

function GM:HandlePlayerSwimming(pl, velocity)
	if not pl:IsSwimming() then return false end
	
	if velocity:Length2D() > 10 then
		pl.CalcIdeal = ACT_HL2MP_SWIM_SLAM
	else
		pl.CalcIdeal = ACT_HL2MP_SWIM_IDLE_SLAM
	end

	return true
end

local FrozenSequences = {
	"pose_standing_01",
	"pose_standing_02",
	"idle_suitcase"
}

function GM:CalcMainActivity(pl, velocity)
	if pl:IsFrozen() and CurTime() < GetGlobalFloat("RoundStartTime", 0) then
		return 1, pl:LookupSequence(FrozenSequences[(pl:EntIndex() + pl:Frags()) % #FrozenSequences + 1])
	end

	pl.CalcIdeal = ACT_MP_STAND_IDLE
	pl.CalcSeqOverride = -1

	self:HandlePlayerLanding( pl, velocity, pl.m_bWasOnGround )
	
	if not ( self:HandlePlayerJumping( pl, velocity ) or self:HandlePlayerDucking( pl, velocity ) or self:HandlePlayerSwimming( pl, velocity ) ) then
		local len2d = velocity:Length()
		if len2d > 290 then
			pl.CalcSeqOverride = pl:LookupSequence("run_all_02")
		elseif len2d > 150 then
			pl.CalcIdeal = ACT_MP_RUN
		elseif len2d > 0.5 then
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
