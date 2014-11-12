luachip.AddFunction("print", print)

luachip.AddFunction("yield", function()
	coroutine.yield()
end)

luachip.AddFunction("Entity", Entity)