local FsmTypes = require(script.FsmTypes)
local StatesValidator = require(script.StatesValidator)
local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(states: { ["string"]: FsmTypes.State }, initialState: string, context: any)
	local self = setmetatable({}, StateMachine)
	self._states = states
	self._currentState = states[initialState]
	-- self._verified = false
	self.context = context or {}
	self._queue = {} -- FIFO queue for state transitions
	-- self._transitionTriggers = {} -- table to hold events that trigger state transitions

	for _, state in pairs(states) do
		-- print(state or "state is nil")
		StatesValidator.ValidateState(state)
	end
	self._currentState:Enter(nil, self.context)
	return self
end

function StateMachine:Update(dt: number)
	local currentState = self._currentState
	if currentState and currentState.Update then
		currentState:Update(dt, self.context)
	end

	for index, request in self._queue do
		if tick() > request.expires then
			warn(
				string.format(
					"transition request from state %s to state %s expired",
					request.source,
					request.State.Name
				)
			)
			table.remove(self._queue, index)
		end
	end

	self:ResolveTransition()
end

function StateMachine:ResolveTransition()
	if #self._queue == 0 then
		return
	end

	for index, request in self._queue do
		local stateFrom = self._currentState
		local stateTo = request.State
		print("stateFrom: ", stateFrom)
		StatesValidator.validateTransition(stateFrom, stateTo, self.context)

		if stateFrom.CanExit and not stateFrom:CanExit(stateTo.Name, self.context) then
			continue
		end

		if stateTo.CanEnter and not stateTo:CanEnter(stateFrom.Name, self.context) then
			continue
		end

		self._currentState = stateTo
		stateFrom:Exit(self.context)
		stateTo:Enter(self.context)
		table.remove(self._queue, index) -- clear the queue after processing the transition
		break -- process only one transition per update, remove this if you want to process multiple transitions in a single update
	end
end

function StateMachine:TransitionTo(request: FsmTypes.transitionRequest)
	-- seting up Queue  for state Transitions
	if not request or not request.State then
		warn("invalid transition request: state is nil")
		return
	end
	local expiresIn = tick() + request.LifeTime
	request["expires"] = expiresIn

	table.insert(self._queue, request)

	if #self._queue > 1 then
		table.sort(self._queue, function(a, b)
			return a.Priority > b.Priority
		end)
	end
end

function StateMachine:ForceTransitionTo(state: FsmTypes.State, flags: FsmTypes.ForceTranstionFlags?)
	if not state then
		warn("invalid transition request: state is nil")
		return
	end

	local currentState = self._currentState

	if not flags or not flags.SkipExit then
		if currentState and currentState.Exit then
			currentState:Exit(self.context)
		end
	end

	if flags and flags.ClearQueue then
		self._queue = {}
	end

	if flags and flags.reason then
		print(string.format("force transition to state %s: %s", state.Name, flags.reason))
	end

	self._currentState = state
	state:Enter(self.context)
end

-- principal functions for state machine behavior

return StateMachine
