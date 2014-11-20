include("shared.lua")

-- sends entity index because of server/client delay
-- example: create chip in server, takes time to appear on client
-- but might receive request to send code in the meantime
function luachip.SendCode(entoridx)
	local chip = entoridx
	if type(chip) ~= "number" then
		-- you can try bypassing this check but this is for your
		-- own good, the server also checks if you're owner
		local owns, msg = luachip.IsOwner(LocalPlayer(), chip)
		if owns then
			chip = chip:EntIndex()
		else
			return false, "not_owner", msg
		end
	end

	local code
	if IsValid(chatgui) and IsValid(chatgui.Lua) and IsValid(chatgui.Lua.code) then
		code = util.Compress(chatgui.Lua.code:GetCode())
	end

	local codelen = code and #code or 0
	if codelen == 0 then
		return false, "zero_length"
	end

	net.Start("luachip_sendcode")
	net.WriteUInt(chip, 16)
	net.WriteUInt(codelen, 32)
	net.WriteData(code, codelen)
	net.SendToServer()
	return true
end

function luachip.OpenEditor(code) -- Metastruct's chatbox Lua tab
	if type(code) == "string" and IsValid(chatgui) and IsValid(chatgui.Lua) and IsValid(chatgui.Lua.code) then
		chatgui.Lua.code:SetCode(code)
	end

	if chatbox and chatbox.ShowChat2Box then
		chatbox.ShowChat2Box(2)
		return true
	end

	return false, "no_editor"
end

net.Receive("luachip_requestcode", function(len)
	luachip.SendCode(net.ReadUInt(16))
end)

net.Receive("luachip_sendcode", function(len)
	local chip = net.ReadEntity()
	luachip.OpenEditor(util.Decompress(net.ReadData(net.ReadUInt(32))))
end)

net.Receive("luachip_openeditor", function(len)
	luachip.OpenEditor()
end)