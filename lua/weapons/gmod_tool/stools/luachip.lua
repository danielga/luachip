TOOL.Category = "Construction"
TOOL.Name = "#tool.luachip.name"

TOOL.RequiresTraceHit = true

TOOL.DefaultModel = "models/beer/wiremod/gate_e2.mdl"
TOOL.ClientConVar = {
	model = TOOL.DefaultModel
}

cleanup.Register("luachips")

if SERVER then
	util.AddNetworkString("luachip_requestcode")
	util.AddNetworkString("luachip_sendcode")
	util.AddNetworkString("luachip_openeditor")

	CreateConVar("sbox_maxluachips", 5)

	function TOOL:LeftClick(trace)
		if not util.IsValidPhysicsObject(trace.Entity, trace.PhysicsBone) then
			return false
		end

		local owner = self:GetOwner()
		if IsValid(trace.Entity) and trace.Entity:GetClass() == "luachip" and trace.Entity:GetPlayer() == owner then
			net.Start("luachip_requestcode")
			net.WriteEntity(trace.Entity)
			net.Send(owner)
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

		net.Start("luachip_requestcode")
		net.WriteUInt(entity:EntIndex(), 16)
		net.Send(owner)
		return true
	end

	function TOOL:RightClick(trace)
		local owner = self:GetOwner()
		if IsValid(trace.Entity) and trace.Entity:GetClass() == "luachip" and trace.Entity:GetPlayer() == owner then
			net.Start("luachip_sendcode")
			net.WriteEntity(trace.Entity)
			net.WriteString(trace.Entity:GetCode() or "")
			net.Send(owner)
			return true
		end

		net.Start("luachip_openeditor")
		net.Send(owner)
		return false
	end

	function TOOL:Reload(trace)
		local owner = self:GetOwner()
		if IsValid(trace.Entity) and trace.Entity:GetClass() == "luachip" and trace.Entity:GetPlayer() == owner then
			trace.Entity:Reset()
			return true
		end

		return false
	end

	net.Receive("luachip_sendcode", function(len, ply)
		local chip = Entity(net.ReadUInt(16))
		local success = net.ReadBit() == 1
		if success and IsValid(chip) and chip:GetClass() == "luachip" and chip:GetPlayer() == ply then
			chip:SetCode(net.ReadString())
		end
	end)
else
	language.Add("tool.luachip.name", "LuaChip")
	language.Add("tool.luachip.desc", "Creates LuaChips that allow you to execute Lua on the server")
	language.Add("tool.luachip.0", "Left click to spawn/update LuaChips. Right click to edit LuaChips or open the editor. Reload to reset LuaChips.")

	function TOOL.BuildCPanel(CPanel, FaceEntity)
		CPanel:AddControl("Header", {Description = "#tool.luachip.desc"})
	end

	net.Receive("luachip_requestcode", function(len)
		net.Start("luachip_sendcode")
		net.WriteUInt(net.ReadUInt(16), 16)

		if IsValid(chatgui) and IsValid(chatgui.Lua) and IsValid(chatgui.Lua.code) then
			net.WriteBit(true)
			net.WriteString(chatgui.Lua.code:GetCode())
		else
			net.WriteBit(false)
		end

		net.SendToServer()
	end)

	local function OpenEditor(code)
		if type(code) == "string" and IsValid(chatgui) and IsValid(chatgui.Lua) and IsValid(chatgui.Lua.code) then
			chatgui.Lua.code:SetCode(code)
		end

		if chatbox and chatbox.ShowChat2Box then
			chatbox.ShowChat2Box(2)
		end
	end

	net.Receive("luachip_sendcode", function(len)
		local chip = net.ReadEntity()
		OpenEditor(net.ReadString())
	end)

	net.Receive("luachip_openeditor", function(len)
		OpenEditor()
	end)
end