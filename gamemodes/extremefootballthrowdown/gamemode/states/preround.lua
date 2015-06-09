function STATE:IsIdle(pl)
	return false
end

function STATE:Move(pl, move)
	move:SetForwardSpeed(0)
	move:SetSideSpeed(0)
	move:SetUpSpeed(0)
	move:SetMaxSpeed(0)
	move:SetMaxClientSpeed(0)
end

local FrozenSequences = {
	"pose_standing_01",
	"pose_standing_02",
	"idle_suitcase"
}

function STATE:EntityTakeDamage(dmginfo)
	dmginfo:SetDamage(0)
	dmginfo:ScaleDamage(0)
end

function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence(FrozenSequences[(pl:EntIndex() + pl:Frags()) % #FrozenSequences + 1])
	
	return true
end

if not CLIENT then return end

function STATE:CreateMove(pl, cmd)
	cmd:ClearMovement()
	cmd:ClearButtons()
end
