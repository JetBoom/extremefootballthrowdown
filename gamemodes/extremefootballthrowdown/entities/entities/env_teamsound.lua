ENT.Type = "point"

function ENT:AcceptInput(name, activator, caller, args)
	local targets
	name = string.lower(name)
	if name == "playtored" then
		targets = team.GetPlayers(TEAM_RED)
	elseif name == "playtoblue" then
		targets = team.GetPlayers(TEAM_BLUE)
	elseif name == "playtospectators" then
		targets = team.GetPlayers(TEAM_SPECTATOR)
		targets = table.Add(targets, team.GetPlayers(TEAM_UNASSIGNED))
	elseif name == "playtoall" then
		targets = player.GetAll()
	end

	if targets and #targets > 0 then
		local soundfile, pitch, vol = string.match(args, "(.+)%|(%d+)%|(%d+)")
		if soundfile then
			pitch = math.Clamp(tonumber(pitch) or 100, 5, 255)
			vol = math.Clamp(tonumber(vol) or 100, 5, 255) / 255
		else
			soundfile = args
			pitch = 100
			vol = 1
		end

		GAMEMODE:LocalSound(soundfile, targets, pitch, vol)
	end
end
