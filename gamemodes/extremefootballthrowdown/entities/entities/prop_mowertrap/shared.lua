ENT.Type = "anim"

AccessorFuncDT(ENT, "Player", "Entity", 0)
AccessorFuncDT(ENT, "Team", "Int", 0)
AccessorFuncDT(ENT, "StartTime", "Float", 0)

function ENT:ShouldNotCollide(ent)
	return true
end
