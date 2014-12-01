local ENV, luachip_Vector, luachip_Angle
local luachip_IsOwner, luachip_GetTime, luachip_GetFunction = luachip.IsOwner, luachip.GetTime, luachip.GetFunction
local getmetatable, debug_getfenv = getmetatable, debug.getfenv
local ent_index = "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"

luachip.Hook("SetupEnvironment", function(env)
	ENV = env

	if not luachip_Vector then
		luachip_Vector = luachip.Vector
	end

	if not luachip_Angle then
		luachip_Angle = luachip.Angle
	end
end)

local function GetEntity(self)
	return debug_getfenv(self)[ent_index]
end

local function CheckEntity(self)
	return luachip_IsOwner(ENV.Owner, GetEntity(self)) and ent or nil
end

local ENTITY = {}
ENTITY.__metatable = ENTITY

function ENTITY:__index(key)
	if key == ent_index then
		return
	end

	local val = getmetatable(self)[key]
	if not val then
		val = debug_getfenv(self)[key]
	end

	return val
end

function ENTITY:__newindex(key, val)
	if key == ent_index then
		return
	end

	debug_getfenv(self)[key] = val
end

function ENTITY:__gc()
end

function ENTITY:GetPos()
	--ENV.CheckTime()
	local vec = GetEntity(self):GetPos()
	return luachip_Vector(vec[1], vec[2], vec[3])
end

function ENTITY:SetPos(vec)
	--ENV.CheckTime()
	--local ent = CheckEntity(self)
	local ent = GetEntity(self)
	if ent then
		ent:SetPos(vec:ToLua())
	end
end

function ENTITY:Kill()
	--ENV.CheckTime()
	--local ent = CheckEntity(self)
	local ent = GetEntity(self)
	if ent then
		ent:Kill()
	end
end

local Entity = Entity
local newproxy = newproxy
local debug_setfenv = debug.setfenv
local debug_setmetatable = debug.setmetatable
luachip.AddFunction("Entity", function(idx)
	local ent = ENV.Entity
	if idx then
		ent = Entity(idx)
	end

	local obj = newproxy(false)
	debug_setfenv(obj, {[ent_index] = ent})
	debug_setmetatable(obj, ENTITY)
	return obj
end)

local Player = Player
luachip.AddFunction("Player", function(uid)
	local ply = ENV.Owner
	if uid then
		ply = Player(uid)
	end

	local obj = newproxy(false)
	debug_setfenv(obj, {[ent_index] = ply})
	debug_setmetatable(obj, ENTITY)
	return obj
end)

luachip.AddFunction("IsValid", IsValid)