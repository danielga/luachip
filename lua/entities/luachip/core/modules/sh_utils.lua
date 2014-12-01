local ENV
luachip.Hook("SetupEnvironment", function(env)
	ENV = env
end)

local MaxExecutionTime = luachip.MaxExecutionTime
luachip.Hook("MaxExecutionTimeChanged", function(time, decimal)
	MaxExecutionTime = decimal
end)

luachip.AddFunction("assert", assert)

luachip.AddFunction("error", error)

local luachip_GetTime, coroutine_yield = luachip.GetTime, coroutine.yield
luachip.AddFunction("yield", function()
	ENV.TimeTotal = luachip_GetTime() - ENV.TimeStart
	coroutine_yield()
	ENV.TimeStart = luachip_GetTime()
end)

luachip.AddFunction("GetExecutionTime", function()
	return luachip_GetTime() - ENV.TimeStart
end)

luachip.AddFunction("GetMaxExecutionTime", function()
	return MaxExecutionTime
end)