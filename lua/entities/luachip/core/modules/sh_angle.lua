--[[local ANGLE = {}
ANGLE.__metatable = ANGLE

function ANGLE:__index(key)
	if key == "p" then
		return debug_getfenv(self)[1]
	elseif key == "y" then
		return debug_getfenv(self)[2]
	elseif key == "r" then
		return debug_getfenv(self)[3]
	end

	local val = getmetatable(self)[key]
	if not val then
		val = debug_getfenv(self).table[key]
	end

	return val
end

function ANGLE:__newindex(key, val)
	if key == "p" then
		key = 1
	elseif key == "y" then
		key = 2
	elseif key == "r" then
		key = 3
	end

	if key ~= 1 and key ~= 2 and key ~= 3 then
		error("")
	end

	debug_getfenv(self)[key] = val
end

function ANGLE:__gc()
end

luachip.RegisterMetaTable("Angle", ANGLE)

local Angle = Angle
local newproxy = newproxy
local debug_setfenv = debug.setfenv
local debug_setmetatable = debug.setmetatable
local luachip_GetMetaTable = luachip.GetMetaTable]]
luachip.AddFunction("Angle", Angle)