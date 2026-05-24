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
			print("starting idle")
		end,
		Exit = function(_self, _context)
			print("exiting idle")
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
			print("starting", self.Name)
			context.isAttacking = true
		end,
		Exit = function(self, context)
			print("exiting", self.Name)
			context.isAttacking = false
		end,
		Update = function(self, dt, context) end,
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
			print("starting", self.Name)
			local stunTimmer = 0.4 * 60
			context.StunTimer = tick() + stunTimmer
		end,
		Exit = function(self, context)
			print("exiting", self.Name)
		end,
		Update = function(self, dt, context)
			if tick() > context.StunTimer then
				context.FSM:TranstionTo({
					State = context.States.Idle,
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
			return previousState == "attack01"
		end,
		CanExit = function(self, nextState, context)
			return true
		end,
		Enter = function(self, context)
			print("starting", self.Name)
		end,
		Exit = function(self, context)
			print("exiting", self.Name)
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
}

function shared.init()
	print("loaded")
	local Statemachine = Finite_state_machine.new(context.States, "idle", context)
	--context.FSM = Statemachine
end

return shared
