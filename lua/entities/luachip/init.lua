AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local defaultmaxops = 100
local maxops = defaultmaxops
CreateConVar("luachip_maxops", defaultmaxops, FCVAR_ARCHIVE, "Number of Lua ops to execute before checking a LuaChip's execution time.")
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

	self.ExecutionStart = 0
	self.ExecutionTime = 0
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

	self:SetErrored(false)
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

		ent.ExecutionTime = ent.ExecutionTime + time - ent.ExecutionStart
		if ent.ExecutionTime >= ent.MaxExecutionTime then
			print("debug hook", co, "is ded")
			debug.sethook(co)
			error("LuaChip has spent more time than allowed", 3)
		end

		ent.ExecutionStart = SysTime()
	end

	local env = table.Copy(self.Environment)
	env.GetMaxExecutionTime = function()
		return ent.MaxExecutionTime
	end
	env.GetExecutionTime = function()
		return ent.ExecutionTime + SysTime() - ent.ExecutionStart
	end
	return coroutine.resume(self.Coroutine, self, setfenv(res, env))
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
		self.ExecutionStart = SysTime()
		self.ExecutionTime = 0
		local res, good, err = coroutine.resume(self.Coroutine)
		debug.sethook(self.Coroutine)

		if good ~= nil then
			if good == true then
				print("LuaChip finished successfully")
				self:SetExecutionTime(0)
			elseif good == false then
				print(err)
				self:SetExecutionTime(self.ExecutionTime * 1000000)
				self:SetErrored(true)
				self:SetColor(Color(255, 0, 0, 255))
			end

			self.Coroutine = nil
			return
		end

		if res then
			self:SetExecutionTime(self.ExecutionTime * 1000000)
			self:NextThink(CurTime() + 1 / 33)
			return true
		else
			-- reminder
			-- is this code needed? i don't think so
			print("LuaChip coroutine ended")
			self:SetExecutionTime(0)
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