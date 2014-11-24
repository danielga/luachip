local VECTOR = {}
VECTOR.__metatable = VECTOR

local setmetatable = setmetatable
function luachip.Vector(x, y, z)
	return setmetatable({x or 0, y or 0, z or 0}, VECTOR)
end

local newvector = luachip.Vector

function VECTOR:__index(key)
	local val = VECTOR[key]
	if not val then
		if key == "x" then
			key = 1
		elseif key == "y" then
			key = 2
		elseif key == "z" then
			key = 3
		end

		val = self[key]
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
		return
	end

	self[key] = val
end

function VECTOR:__add(vec)
	return newvector(self[1] + vec[1], self[2] + vec[2], self[3] + vec[3])
end

function VECTOR:__sub(vec)
	return newvector(self[1] - vec[1], self[2] - vec[2], self[3] - vec[3])
end

function VECTOR:__mul(a)
	return newvector(self[1] * a, self[2] * a, self[3] * a)
end

function VECTOR:__div(a)
	return newvector(self[1] / a, self[2] / a, self[3] / a)
end

function VECTOR:__unm()
	self[1] = -self[1]
	self[2] = -self[2]
	self[3] = -self[3]
end

function VECTOR:__eq(vec)
	return self[1] == vec[1] and self[2] == vec[2] and self[3] == vec[3]
end

local vecfmt = "%.6f %.6f %.6f"
function VECTOR:__tostring()
	return vecfmt:format(self[1], self[2], self[3])
end

-- assigning values to existent vectors is faster than creating a new one each time
-- assign to indices 1, 2 and 3 instead of x, y and z for even MORE MICROSECOWAGHUGHAWG
-- be very careful with this, only one Lua Vector exists
local vector = Vector()
function VECTOR:ToLua()
	vector[1] = self[1]
	vector[2] = self[2]
	vector[3] = self[3]
	return vector
end

luachip.AddFunction("Vector", newvector)