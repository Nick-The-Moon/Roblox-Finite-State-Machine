local RunService = game:GetService("RunService")
local exampleFolder = script.Parent.examples

local loaded = false
local ExampleSelected = exampleFolder.combo_buffering
-- load examples

local module = require(exampleFolder.combo_buffering)

module.init()
