if SERVER then
	AddCSLuaFile()

	local filelist = file.Find(GM.FolderName.."/gamemode/round_transitions/*.lua", "LUA")
	for _, filename in pairs(filelist) do
		AddCSLuaFile("round_transitions/"..filename)
	end

	return
end

TRANSITIONS = {}

local index = 1

local function Register(filename)
	TRANSITION = {}

	local name = string.sub(filename, 1, -5)
	TRANSITIONNAME = name

	local uppername = string.upper(name)

	_G["TRANSITION_"..uppername] = index
	TRANSITION.Index = index

	include("round_transitions/"..filename)
	AddCSLuaFile("round_transitions/"..filename)

	TRANSITION.FileName = name

	TRANSITIONS[TRANSITION.Index or -1] = TRANSITION

	TRANSITIONNAME = nil
	TRANSITION = nil

	index = index + 1
end

local filelist = file.Find(GM.FolderName.."/gamemode/round_transitions/*.lua", "LUA")
table.sort(filelist)
for _, filename in ipairs(filelist) do
	Register(filename)
end

print("registered "..#TRANSITIONS.." transitions.")
