STATES = {}

local index = 0

local function Register(filename)
	STATE = {}

	local statename = string.sub(filename, 1, -5)
	STATENAME = statename

	local upperstatename = string.upper(statename)

	_G["STATE_"..upperstatename] = index
	STATE.Index = index

	include("states/"..filename)
	AddCSLuaFile("states/"..filename)

	STATE.FileName = statename

	STATES[STATE.Index or -1] = STATE

	STATENAME = nil
	STATE = nil

	index = index + 1
end

Register("none.lua")

local filelist = file.Find(GM.FolderName.."/gamemode/states/*.lua", "LUA")
table.sort(filelist)
for _, filename in ipairs(filelist) do
	if filename ~= "none.lua" then
		Register(filename)
	end
end

print("registered "..#STATES.." states.")
