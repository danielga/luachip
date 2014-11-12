TOOL.Category = "Construction"
TOOL.Name = "#tool.luachip.name"

TOOL.RequiresTraceHit = true

TOOL.DefaultModel = "models/beer/wiremod/gate_e2.mdl"
TOOL.ClientConVar = {
	model = TOOL.DefaultModel
}

cleanup.Register("luachips")

if SERVER then
	CreateConVar("sbox_maxluachips", 5)

	function TOOL:LeftClick(trace)
		local owner = self:GetOwner()
		if not owner:IsAdmin() then -- for now only allow admins to use this
			return false
		end

		if not util.IsValidPhysicsObject(trace.Entity, trace.PhysicsBone) then
			return false
		end

		if luachip.RequestCode(owner, trace.Entity) then
			return true
		end

		if not owner:CheckLimit("luachips") then
			return false
		end

		local entity = ents.Create("luachip")
		if not IsValid(entity) then
			return false
		end

		local model = self:GetClientInfo("model")
		if not util.IsValidModel(model) then
			model = self.DefaultModel
		end

		entity:SetModel(model)
		local ang = trace.HitNormal:Angle()
		ang.pitch = ang.pitch + 90
		entity:SetAngles(ang)
		entity:SetPos(trace.HitPos)
		entity:SetPlayer(owner)
		entity:Spawn()

		entity:SetPos(trace.HitPos - trace.HitNormal * entity:OBBMins().z)

		local weld = constraint.Weld(entity, trace.Entity, 0, trace.PhysicsBone, 0, true, false)
		undo.Create("luachip")
			undo.AddEntity(entity)
			undo.AddEntity(weld)
			undo.SetPlayer(owner)
		undo.Finish()

		owner:AddCount("luachips", entity)
		owner:AddCleanup("luachips", entity)

		return luachip.RequestCode(owner, entity)
	end

	function TOOL:RightClick(trace)
		local owner = self:GetOwner()
		if not owner:IsAdmin() then -- for now only allow admins to use this
			return false
		end

		if luachip.SendCode(owner, trace.Entity) then
			return true
		end

		return luachip.OpenEditor(owner)
	end

	function TOOL:Reload(trace)
		local owner = self:GetOwner()
		if not owner:IsAdmin() then -- for now only allow admins to use this
			return false
		end

		if luachip.Reset(owner, trace.Entity) then
			return true
		end

		return false
	end
else
	language.Add("tool.luachip.name", "LuaChip")
	language.Add("tool.luachip.desc", "Creates LuaChips that allow you to execute Lua on the server")
	language.Add("tool.luachip.0", "Left click to spawn/update LuaChips. Right click to edit LuaChips or open the editor. Reload to reset LuaChips.")

	function TOOL.BuildCPanel(CPanel, FaceEntity)
		CPanel:AddControl("Header", {Description = "#tool.luachip.desc"})
	end
end