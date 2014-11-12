AddCSLuaFile("shared.lua")
AddCSLuaFile("client.lua")

include("shared.lua")

util.AddNetworkString("luachip_requestcode")
util.AddNetworkString("luachip_sendcode")
util.AddNetworkString("luachip_openeditor")

local defaultmaxops = 100
luachip.MaxOps = defaultmaxops
CreateConVar("luachip_maxops", defaultmaxops, FCVAR_ARCHIVE, "Number of Lua ops to execute before checking a LuaChip's execution time.")
cvars.AddChangeCallback("luachip_maxops", function(name, old, new)
	luachip.MaxOps = tonumber(new)
	if not luachip.MaxOps then
		luachip.MaxOps = defaultmaxops
	end
end)

luachip.Environment = {}

function luachip.AddFunction(name, func)
	luachip.Environment[name] = func
end

function luachip.RequestCode(ply, chip)
	local owns, msg = luachip.IsOwner(chip, ply)
	if not owns then
		return false, "not_owner", msg
	end

	net.Start("luachip_requestcode")
	net.WriteUInt(chip:EntIndex(), 16)
	net.Send(ply)
	return true
end

function luachip.SendCode(ply, chip)
	local owns, msg = luachip.IsOwner(chip, ply)
	if not owns then
		return false, "not_owner", msg
	end

	net.Start("luachip_sendcode")
	net.WriteEntity(chip)
	net.WriteString(chip:GetCode() or "")
	net.Send(ply)
	return true
end

function luachip.Reset(ply, chip)
	local owns, msg = luachip.IsOwner(chip, ply)
	if not owns then
		return false, "not_owner", msg
	end

	chip:Reset()
	return true
end

function luachip.CreateExecutor(name, code)
	assert(type(name) == "string" and #name > 0, "bad argument #1 is not a string or is an empty string")
	assert(type(code) == "string" and #code > 0, "bad argument #2 is not a string or is an empty string")

	local res = CompileString(code, name)
	if type(res) ~= "function" then
		return nil, res
	end

	local luachip = luachip
	local start = 0
	local total = 0
	local die = false
	local env = table.Copy(luachip.Environment)

	env.GetMaxExecutionTime = function()
		return luachip.MaxExecutionTime
	end

	env.GetExecutionTime = function()
		return total + SysTime() - start
	end

	local func = setfenv(res, env)
	local co = coroutine.create(function()
		return xpcall(func, debug.traceback)
	end)

	local function debug_hook()
		local time = SysTime()

		if coroutine.running() ~= co then
			return
		end

		if die then
			debug.sethook(co)
			error("coroutine kill requested")
		end

		total = total + time - start
		if total >= luachip.MaxExecutionTime then
			debug.sethook(co)
			error("execution spent more time than allowed")
		end

		start = SysTime()
	end

	return function(kill)
		debug.sethook(co, debug_hook, "", not kill and luachip.MaxOps or 1)
		die = kill
		total = 0
		start = SysTime()
		local res, good, err = coroutine.resume(co)
		total = (total + time - start) * 1000000
		debug.sethook(co)

		if good == true then
			return false, true, total
		elseif good == false then
			return false, false, total, err
		end

		if res then
			return true, true, total
		end
	end
end

function luachip.OpenEditor(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return false, "not_player"
	end

	net.Start("luachip_openeditor")
	net.Send(ply)
	return true
end

net.Receive("luachip_sendcode", function(len, ply)
	local chip = Entity(net.ReadUInt(16))
	local success = net.ReadBit() == 1
	if success and luachip.IsOwner(chip, ply) then
		chip:SetCode(net.ReadString())
	end
end)

local files = file.Find("entities/luachip/core/modules/*.lua", "LUA")
for i = 1, #files do
	include("modules/" .. files[i])
end