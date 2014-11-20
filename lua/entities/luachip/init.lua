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
	if self.Executor then
		local _, _, _, err = self.Executor("kill")
		print(err)
		self.Executor = nil
	end

	local func, err = luachip.CreateExecutor(self, code)
	if not func then
		print(err)
		self:SetState(self.ERRORED)
		self:SetColor(Color(255, 0, 0, 255))
		return false
	end

	self:SetState(self.RUNNING)
	self:SetColor(Color(255, 255, 255, 255))

	self.Code = code
	self.Executor = func

	return true
end

function ENT:GetCode()
	return self.Code
end

function ENT:Reset()
	if self.Executor then
		print(self.Executor("reset"))
		self:SetState(self.RUNNING)
		self:SetColor(Color(255, 255, 255, 255))
	elseif self.Code then
		self:SetCode(self.Code)
	end
end

function ENT:Think()
	if self.Executor and self:GetState() == self.RUNNING then
		local alive, success, time, err = self.Executor()
		if alive then
			self:SetExecutionTime(time)
			self:NextThink(CurTime() + 1 / 66)
			return true
		else
			if success then
				self:SetExecutionTime(0)
				self:SetState(self.FINISHED)
			else
				print(err)
				self:SetExecutionTime(time)
				self:SetState(self.ERRORED)
				self:SetColor(Color(255, 0, 0, 255))
			end

			--self.Executor = nil
		end
	end
end

function ENT:OnRemove()
	if self.Executor and self:GetState() == self.RUNNING then
		local _, _, _, err = self.Executor("kill")
		print(err)
		self.Executor = nil
	end
end