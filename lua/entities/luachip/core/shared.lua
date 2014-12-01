luachip = {
	GetTime = system.IsWindows() and SysTime or os.clock,
	Hooks = {},
	Environment = {},
	MaxExecutionTimeInt = 1000,
	MaxExecutionTime = 1000 / 1000000,
	MaxOps = 1000
}

local MaxExecutionTime = luachip.MaxExecutionTime
CreateConVar("luachip_maxtime", luachip.MaxExecutionTimeInt, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Number of microseconds of execution time for each LuaChip.")
cvars.AddChangeCallback("luachip_maxtime", function(name, old, new)
	local newtime = tonumber(new)
	if newtime and newtime ~= luachip.MaxExecutionTimeInt then
		luachip.MaxExecutionTimeInt = newtime
		local decimal = newtime / 1000000
		MaxExecutionTime = decimal
		luachip.MaxExecutionTime = decimal
		luachip.Call("MaxExecutionTimeChanged", newtime, decimal)
	end
end)

local MaxOps = luachip.MaxOps
CreateConVar("luachip_maxops", luachip.MaxOps, FCVAR_ARCHIVE, "Number of Lua ops to execute before checking a LuaChip's execution time.")
cvars.AddChangeCallback("luachip_maxops", function(name, old, new)
	local newops = tonumber(new)
	if newops and newops ~= luachip.MaxOps then
		MaxOps = newops
		luachip.MaxOps = newops
		luachip.Call("MaxOpsChanged", newops)
	end
end)

local ENTITY = FindMetaTable("Entity")
local CPPIGetFriends = ENTITY.CPPIGetFriends
if not CPPIGetFriends then
	CPPIGetFriends = function()
		return nil
	end
end

local IsValid = IsValid
function luachip.IsFriend(ply1, ply2)
	if not IsValid(ply1) or not ply1:IsPlayer() then
		return false, "not_player1"
	end

	if not IsValid(ply2) or not ply2:IsPlayer() then
		return false, "not_player2"
	end

	if ply1 == ply2 then
		return true
	end

	local friends = CPPIGetFriends(ply1)
	if friends ~= nil and friends ~= CPPI_NOTIMPLEMENTED and friends ~= CPPI_DEFER then
		for _, friend in pairs(friends) do
			if friend == ply2 then
				return true
			end
		end
	end

	return false, "not_friend"
end

local CPPIGetOwner = ENTITY.CPPIGetOwner
if not CPPIGetOwner then
	CPPIGetOwner = function()
		return nil
	end
end

function luachip.GetOwner(entity)
	if not IsValid(entity) then
		return nil, "not_valid"
	end

	if entity:IsPlayer() then
		return entity
	end

	local owner = CPPIGetOwner(entity)
	if owner ~= nil and owner ~= CPPI_NOTIMPLEMENTED and owner ~= CPPI_DEFER and owner:IsValid() then
		return owner
	end

	if entity.GetPlayer then
		local owner = entity:GetPlayer()
		if IsValid(owner) then
			return owner
		end
	end

	local OnDieFunctions = entity.OnDieFunctions
	if OnDieFunctions then
		if OnDieFunctions.GetCountUpdate and OnDieFunctions.GetCountUpdate.Args then
			local owner = OnDieFunctions.GetCountUpdate.Args[1]
			if IsValid(owner) then
				return owner
			end
		end

		if OnDieFunctions.undo1 and OnDieFunctions.undo1.Args then
			local owner = OnDieFunctions.undo1.Args[2]
			if IsValid(owner) then
				return owner
			end
		end
	end

	if entity.GetOwner then
		local owner = entity:GetOwner()
		if IsValid(owner) then
			return owner
		end
	end

	return nil, "no_owner"
end

local luachip_GetOwner, luachip_IsFriend = luachip.GetOwner, luachip.IsFriend
function luachip.IsOwner(ply, entity)
	if ply == entity then
		return true
	end

	local owner, err = luachip_GetOwner(entity)
	if not owner then
		return false, err
	end

	return luachip_IsFriend(ply, owner)
end

function luachip.Hook(name, func)
	local hooks = luachip.Hooks[name]
	if not hooks then
		hooks = {}
		luachip.Hooks[name] = hooks
	end

	table.insert(hooks, func)
end

function luachip.Call(name, ...)
	local hooks = luachip.Hooks[name]
	if hooks then
		for i = 1, #hooks do
			hooks[i](...)
		end
	end
end

local debug_getinfo = debug.getinfo
local function insidec()
	local i = 3
	local info = debug_getinfo(i)
	repeat
		if info.short_src == "[C]" then
			return true
		end

		i = i + 1
		info = debug_getinfo(i)
	until not info

	return false
end

local IsValid, CompileString, file_Append, type = IsValid, CompileString, file.Append, type
local setfenv, error, debug_gethook, debug_sethook, debug_traceback = setfenv, error, debug.gethook, debug.sethook, debug.traceback
local luachip_GetTime, luachip_Call, luachip_Environment = luachip.GetTime, luachip.Call, luachip.Environment
local coroutine_create, coroutine_resume, coroutine_running = coroutine.create, coroutine.resume, coroutine.running
local coroutine_yield, coroutine_status = coroutine.yield, coroutine.status
function luachip.CreateExecutor(chip, code)
	if not IsValid(chip) or chip:GetClass() ~= "luachip" then
		return nil, "not_luachip"
	end

	local owner = chip:GetPlayer()
	if not IsValid(owner) or not owner:IsPlayer() then
		return nil, "invalid_owner"
	end

	if type(code) ~= "string" or #code == 0 then
		return nil, "not_string"
	end

	local res = CompileString(code, "LuaChip|" .. owner:SteamID() .. "|" .. owner:GetName())
	if type(res) ~= "function" then
		return nil, "invalid_code", res
	end

	local env
	local func = setfenv(res, luachip_Environment)
	local co = coroutine_create(function()
		env.TimeStart = luachip_GetTime()
		func()
		env.TimeTotal = luachip_GetTime() - env.TimeStart
	end)
	env = {
		Entity = chip,
		Owner = owner,
		Coroutine = co,
		Function = func,
		TimeStart = 0,
		TimeTotal = 0,
		ShouldDie = false,
		ShouldYield = false,
		CheckTime = function()
			local t = luachip_GetTime() - env.TimeStart
			if t >= MaxExecutionTime then
				env.TimeTotal = t
				coroutine_yield()
				env.TimeStart = luachip_GetTime()
			end
		end,
		DebugHook = function(event, line)
			local time = luachip_GetTime()

			if coroutine_running() ~= co then
				return
			end

			if env.ShouldDie then
				env.TimeTotal = time - env.TimeStart
				error("coroutine kill requested")
			end

			if time - env.TimeStart >= MaxExecutionTime * 2 then
				env.TimeTotal = time - env.TimeStart
				file_Append("luachip.txt", debug_traceback(co, "execution spent more time than allowed", 2) .. "\n\n")
				error("execution spent more time than allowed")
			elseif time - env.TimeStart >= MaxExecutionTime then
				env.ShouldYield = true
			end
		end
	}

	local debughook = env.DebugHook
	return function(command)
		local reset = command == "reset"
		local kill = reset or command == "kill"

		env.ShouldDie = kill
		env.TimeTotal = 0
		env.TimeStart = 0

		luachip_Call("SetupEnvironment", env)

		local f, m, c = debug_gethook(co)
		debug_sethook(co, debughook, "", not kill and MaxOps or 1)
		local res, data = coroutine_resume(co)
		debug_sethook(co, f, m, c)

		luachip_Call("FinishEnvironment", env)

		if reset then
			co = coroutine_create(func)
			env.Coroutine = co
			return true, true, 0
		end

		local total = env.TimeTotal * 1000000

		if res then
			return coroutine_status(co) ~= "dead", true, total
		end

		return false, not data, total, data
	end
end

function luachip.AddFunction(name, func)
	luachip_Environment[name] = func
end

function luachip.GetFunction(name)
	return luachip_Environment[name]
end

local files = file.Find("entities/luachip/core/modules/*.lua", "LUA")
for i = 1, #files do
	local file = files[i]
	local prefix = file:sub(1, 3)
	if SERVER and prefix == "sv_" then
		include("modules/" .. file)
	elseif prefix == "sh_" then
		include("modules/" .. file)
		if SERVER then
			AddCSLuaFile("modules/" .. file)
		end
	elseif prefix == "cl_" then
		if CLIENT then
			include("modules/" .. file)
		else
			AddCSLuaFile("modules/" .. file)
		end
	end
end