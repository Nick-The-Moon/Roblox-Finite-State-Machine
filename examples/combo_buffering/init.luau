local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Finite_state_machine = require(ServerScriptService.server.Finite_state_machine)
local FsmTypes = require(ServerScriptService.server.Finite_state_machine.FsmTypes)
local shared = {}

local states: { [string]: FsmTypes.State } = {
	["idle"] = {
		Name = "idle",
		CanEnter = function(_self, _previousState, _context)
			return true
		end,
		CanExit = function(_self, _nextState, _context)
			return true
		end,
		Enter = function(_self, _context)
			-- print("starting idle")
		end,
		Exit = function(_self, _context)
			-- print("exiting idle")
		end,
		Update = function(_self, _dt, _context)
			--e.g logic here
		end,
		GetnextState = function(_self, _context)
			return nil
		end,
	},
	["attack01"] = {

		Name = "attack01",

		CanEnter = function(self, previousState, context)
			local blacklist = { ["stunned"] = "stunned" }

			if not blacklist[previousState] then
				return true
			end
			return false
		end,
		CanExit = function(self, nextState, context)
			return nextState == "stunned" or context.isAttacking,
				string.format(
					"can not exit because nextState:[%s] is not stunned or is currentState is attacking",
					nextState
				)
		end,
		Enter = function(self, context)
			-- print("starting", self.Name)
			context.isAttacking = true
			context.loop = 0
			context.loopEnd = 1 -- seconds to timer end
		end,
		Exit = function(self, context)
			-- print("exiting", self.Name)
			context.isAttacking = false
		end,
		Update = function(self, dt, context)
			context.loop = context.loop + dt
			if context.loopEnd <= context.loop then
				-- print("request combo")
				context.FSM:TransitionTo({
					State = context.States.combo,
					Priority = 2,
					LifeTime = 9,
					source = self.Name,
					reason = "Starting combo for debuging",
				})
			end
		end,
		GetnextState = function(self, context)
			return "idle"
		end,
	},
	["stunned"] = {
		Name = "stunned",
		CanEnter = function(self, previousState, context)
			return true
		end,
		CanExit = function(self, nextState, context)
			return tick() > context.StunTimer
		end,
		Enter = function(self, context)
			-- print("starting", self.Name)
			local stunTimmer = 0.3
			context.StunTimer = tick() + stunTimmer
		end,
		Exit = function(self, context)
			-- print("exiting", self.Name)
		end,
		Update = function(self, dt, context)
			if tick() > context.StunTimer then
				context.FSM:TransitionTo({
					State = context.States.idle,
					Priority = 1,
					LifeTime = 0.2,
					source = self.Name,
					reason = "stunned timer ended",
				})
			end
		end,
		GetnextState = function(self, context)
			return nil
		end,
	},
	["combo"] = {
		Name = "combo",
		CanEnter = function(self, previousState, context)
			return previousState == "attack01" or previousState == "idle"
		end,
		CanExit = function(self, nextState, context)
			return true
		end,
		Enter = function(self, context)
			-- print("starting", self.Name)
		end,
		Exit = function(self, context)
			-- print("exiting", self.Name)
		end,
		Update = function(self, dt, context)
			--logic
		end,
		GetnextState = function(self, context)
			--logic
			return
		end,
	},
}

local context = {
	FSM = nil,
	StunTimer = 0,
	States = states,
	loop = 0,
	loopEnd = 0,
}

function shared.init()
	print("loaded")
	local Statemachine = Finite_state_machine.new(context.States, "idle", context)
	context.FSM = Statemachine

	print("hi")

	task.wait(3)
	print("starting Example in 1 second")
	task.wait(1)
	RunService.Heartbeat:Connect(function(dt: number)
		Statemachine:Update(dt)
	end)
	Statemachine:TransitionTo({
		State = states.attack01,
		Priority = 1,
		LifeTime = 1,
		source = "init func",
	})
	task.wait(1)
	Statemachine:TransitionTo({
		State = states.stunned,
		Priority = 4,
		LifeTime = 0.3,
		source = script.Name,
	})
end

return shared
