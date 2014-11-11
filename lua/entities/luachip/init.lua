AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local defaultmaxtime = 1000 -- in microseconds, default may need adjusting
local maxtime = defaultmaxtime
CreateConVar("luachip_maxtime", maxtime)
cvars.AddChangeCallback("luachip_maxtime", function(name, old, new)
	maxtime = tonumber(new)
	if maxtime then
		maxtime = maxtime / 1000000
	else
		maxtime = defaultmaxtime
	end
end)

local defaultmaxops = 100 -- number of ops to execute before checking chip
local maxops = defaultmaxops
CreateConVar("luachip_maxops", maxops)
cvars.AddChangeCallback("luachip_maxops", function(name, old, new)
	maxops = tonumber(new)
	if not maxops then
		maxops = defaultmaxops
	end
end)

ENT.Environment = {
	print = print,
	yield = function()
		coroutine.yield()
	end
}

function AddLuaChipFunction(name, func)
	ENT.Environment[name] = func
end

local files = file.Find("entities/luachip/modules/*.lua", "LUA")
for i = 1, #files do
	include("modules/" .. files[i])
end

AddLuaChipFunction = nil

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetColor(Color(255, 0, 0, 255))
	self.RunStart = 0
	self.BeingRemoved = false
end

function ENT:SetCode(code)
	local owner = self:GetPlayer()
	assert(IsValid(owner) and owner:IsPlayer(), "this LuaChip's owner is invalid or not a player")
	assert(type(code) == "string", "bad argument #1 is not a string")

	local res = CompileString(code, "LuaChip|" .. owner:SteamID() .. "|" .. owner:GetName())
	if type(res) ~= "function" then
		print("LuaChip errored: " .. (res and tostring(res) or "tried to compile empty string?"))
		return false
	end

	self:SetColor(Color(255, 255, 255, 255))

	self.Code = code
	self.Coroutine = coroutine.create(self.Execute)

	local ent = self
	local co = self.Coroutine
	self.DebugHook = function()
		local time = SysTime()
		if coroutine.running() ~= co then
			return
		end

		if coroutine.status(co) == "dead" then
			print("debug hook", co, "be dead")
			debug.sethook(co)
			error("LuaChip coroutine dead", 3)
			return
		end

		if not IsValid(ent) or ent.BeingRemoved then
			print("debug hook", co, "is kill")
			debug.sethook(co)
			error("LuaChip was removed, stopping coroutine", 3)
		end

		ent.TimeSpent = ent.TimeSpent + time - ent.RunStart
		if ent.TimeSpent >= maxtime then
			print("debug hook", co, "is ded")
			debug.sethook(co)
			error("LuaChip has spent more time than allowed", 3)
		end

		ent.RunStart = SysTime()
	end

	return coroutine.resume(self.Coroutine, self, setfenv(res, self.Environment))
end

function ENT:GetCode()
	return self.Code
end

function ENT:Reset()
	self:SetCode(self:GetCode())
end

function ENT:Think()
	if self.Coroutine then
		debug.sethook(self.Coroutine, self.DebugHook, "", not self.BeingRemoved and maxops or 1)
		self.RunStart = SysTime()
		self.TimeSpent = 0
		local res, good, err = coroutine.resume(self.Coroutine)
		self:SetTimeSpent(self.TimeSpent * 1000000)
		debug.sethook(self.Coroutine)

		if good ~= nil then
			if good == true then
				print("LuaChip finished successfully")
			elseif good == false then
				print(err)
			end

			self.Coroutine = nil
			return
		end

		if res then
			self:NextThink(CurTime() + 1 / 33)
			return true
		else
			print("LuaChip coroutine ended")
			self.Coroutine = nil
		end
	end
end

function ENT:OnRemove()
	self.BeingRemoved = true
	self:Think()
end

function ENT:Execute(func)
	coroutine.yield()
	return xpcall(func, debug.traceback)
end