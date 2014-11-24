local ANGLE = {}
ANGLE.__metatable = ANGLE

local setmetatable = setmetatable
function luachip.Angle(p, y, r)
	return setmetatable({p or 0, y or 0, r or 0}, ANGLE)
end

local newangle = luachip.Angle

function ANGLE:__index(key)
	local val = ANGLE[key]
	if not val then
		if key == "p" then
			key = 1
		elseif key == "y" then
			key = 2
		elseif key == "r" then
			key = 3
		end

		val = self[key]
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
		return
	end

	self[key] = val
end

function ANGLE:__add(ang)
	return newangle(self[1] + ang[1], self[2] + ang[2], self[3] + ang[3])
end

function ANGLE:__sub(ang)
	return newangle(self[1] - ang[1], self[2] - ang[2], self[3] - ang[3])
end

function ANGLE:__mul(a)
	return newangle(self[1] * a, self[2] * a, self[3] * a)
end

function ANGLE:__unm()
	self[1] = -self[1]
	self[2] = -self[2]
	self[3] = -self[3]
end

function ANGLE:__eq(ang)
	return self[1] == ang[1] and self[2] == ang[2] and self[3] == ang[3]
end

local angfmt = "%.6f %.6f %.6f"
function ANGLE:__tostring()
	return angfmt:format(self[1], self[2], self[3])
end

-- assigning values to existent angles is faster than creating a new one each time
-- assign to indices 1, 2 and 3 instead of p, y and r for even MORE MICROSECOWAGHUGHAWG
-- be very careful with this, only one Lua Angle exists
local angle = Angle()
function ANGLE:ToLua()
	angle[1] = self[1]
	angle[2] = self[2]
	angle[3] = self[3]
	return angle
end

luachip.AddFunction("Angle", newangle)