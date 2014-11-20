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

luachip.AddFunction("yield", function()
	ENV.BypassTiming(true)
	coroutine.yield()
	ENV.BypassTiming(false)
end)

luachip.AddFunction("GetExecutionTime", function()
	ENV.BypassTiming(true)
	ENV.BypassTiming(false)
	return ENV.TimeTotal
end)

luachip.AddFunction("GetMaxExecutionTime", function()
	return MaxExecutionTime
end)