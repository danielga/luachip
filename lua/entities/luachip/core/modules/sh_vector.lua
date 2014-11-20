--[[local VECTOR = {}
VECTOR.__metatable = VECTOR

function VECTOR:__index(key)
	if key == "x" then
		return debug_getfenv(self)[1]
	elseif key == "y" then
		return debug_getfenv(self)[2]
	elseif key == "z" then
		return debug_getfenv(self)[3]
	end

	local val = getmetatable(self)[key]
	if not val then
		val = debug_getfenv(self).table[key]
	end

	return val
end

function VECTOR:__newindex(key, val)
	if key == "x" then
		key = 1
	elseif key == "y" then
		key = 2
	elseif key == "z" then
		key = 3
	end

	if key ~= 1 and key ~= 2 and key ~= 3 then
		error("")
	end

	debug_getfenv(self)[key] = val
end

function VECTOR:__gc()
end

luachip.RegisterMetaTable("Vector", VECTOR)

local Vector = Vector
local newproxy = newproxy
local debug_setfenv = debug.setfenv
local debug_setmetatable = debug.setmetatable
local luachip_GetMetaTable = luachip.GetMetaTable]]
luachip.AddFunction("Vector", Vector)