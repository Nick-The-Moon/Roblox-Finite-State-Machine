local ServerScriptService = game:GetService("ServerScriptService")
local StateMachine = require(ServerScriptService.Server.stateMachineSystem.StateMachine)
local StatesValidator = require(ServerScriptService.Server.stateMachineSystem.StatesValidator)

local states: { [string]: any } = {
	["idle"] = {
		Name = "idle",
		AlowedTransitions = { "walk", "run" },
		Enter = function(self, context)
			print("entering idle state")
		end,
		Update = function(self, dt, context)
			print("updating idle state")
		end,
		Exit = function(self, context)
			print("exiting idle state")
		end,
		CanEnter = function(self, previousState, context)
			return true
		end,
		CanExit = function(self, nextState, context)
			return true
		end,
	},
	["walk"] = {
		Name = "walk",
		AlowedTransitions = { "idle", "run" },
		Enter = function(self, context)
			print("entering walk state")
		end,
		Update = function(self, dt, context)
			print("updating walk state")
		end,
		Exit = function(self, context)
			print("exiting walk state")
		end,
		CanEnter = function(self, previousState, context)
			if previousState == "idle" then
				return true
			end
			return false, "can only enter walk state from idle state"
		end,
		CanExit = function(self, nextState, context)
			if nextState.Name == "idle" then
				return true
			end
			return false, "can only exit walk state to idle state"
		end,
	},
	["run"] = {
		Name = "run",
		AlowedTransitions = { "idle", "walk" },
		Enter = function(self, context)
			print("entering run state")
		end,
		Update = function(self, dt, context)
			print("updating run state")
		end,
		Exit = function(self, context)
			print("exiting run state")
		end,
		CanEnter = function(self, previousState, context)
			if previousState == "walk" then
				return true
			end
			return false, "can only enter run state from walk state"
		end,
		CanExit = function(self, nextState, context)
			if nextState == "idle" then
				return true
			end
			return false, "can only exit run state to idle state"
		end,
	},
}

local x = StateMachine.new(states, "idle", {})
print(x)
print(states.walk)

local DT = 1 / 2 -- simulates 10 frames per second
x:TransitionTo({
	State = states.run,
	Priority = 2,
	source = script.Name,
	reason = "testing transition to run state",
	LifeTime = 5,
})
x:TransitionTo({
	State = states.walk,
	Priority = 1,
	source = script.Name,
	reason = "testing transition to walk state",
	LifeTime = 5,
})

while true do
	--print(x._queue)
	x:Update(DT)
	task.wait(DT)
end
