local RunService = game:GetService("RunService")
local exampleFolder = script.Parent.examples

local loaded = false
local ExampleSelected = exampleFolder.combo_buffering
-- load examples

local function loadExamples(_input: {}?)
	if not RunService:IsRunning() then
		return
	end
	local module = require(ExampleSelected)
	module.init()
	return true
end

while not loaded do
	loaded = loadExamples()
	task.wait(0.3)
end
