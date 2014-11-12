AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("core/server.lua")
include("shared.lua")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetColor(Color(255, 0, 0, 255))
end

function ENT:SetCode(code)
	local owner = self:GetPlayer()
	assert(IsValid(owner) and owner:IsPlayer(), "invalid LuaChip owner")

	if self.Executor then
		self.Executor(true)
		self.Executor = nil
	end

	local func, err = luachip.CreateExecutor("LuaChip|" .. owner:SteamID() .. "|" .. owner:GetName(), code)
	if not func then
		print(err)
		self:SetErrored(true)
		self:SetColor(Color(255, 0, 0, 255))
		return false
	end

	self:SetErrored(false)
	self:SetColor(Color(255, 255, 255, 255))

	self.Code = code
	self.Executor = func

	return true
end

function ENT:GetCode()
	return self.Code
end

function ENT:Reset()
	self:SetCode(self:GetCode())
end

function ENT:Think()
	if self.Executor then
		local alive, success, time, err = self.Executor()
		if alive then
			self:SetExecutionTime(time)
			self:NextThink(CurTime() + 1 / 66)
			return true
		else
			if success then
				self:SetExecutionTime(0)
			else
				print(err)
				self:SetExecutionTime(time)
				self:SetErrored(true)
				self:SetColor(Color(255, 0, 0, 255))
			end

			self.Executor = nil
		end
	end
end

function ENT:OnRemove()
	if self.Executor then
		print(self.Executor(true))
		self.Executor = nil
	end
end