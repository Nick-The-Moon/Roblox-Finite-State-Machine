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
	self._queue = {} :: { FsmTypes.transitionRequest } -- FIFO queue for state transitions
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

	for index, request in ipairs(self._queue) do
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

-- debuging:

function StateMachine:_DebugRequestBlocked(request: FsmTypes.transtitionFormated, reason: string)
	if request._runtime.LastFailureReason == reason then
		return
	end

	request._runtime.LastFailureReason = reason
	request._runtime.Status = "Blocked"

	print(string.format("[FSM] request to %s blocked: %s", request.State.Name, reason))
end

-- resolving transitions:

function StateMachine:_CanProcessRequest(request: FsmTypes.transtitionFormated)
	local stateFrom = self._currentState
	local stateTo = request.State

	if stateFrom.CanExit then
		local canExit, reason = stateFrom:CanExit(stateTo.Name, self.context)

		if not canExit then
			self:_DebugRequestBlocked(request, reason)
			return false
		end
	end

	if stateTo.CanEnter then
		local canEnter, reason = stateTo:CanEnter(stateFrom.Name, self.context)

		if not canEnter then
			self:_DebugRequestBlocked(request, reason)
			return false
		end
	end

	return true
end

function StateMachine:_ResolveRequest(index, request)
	local previousState = self._currentState
	local nextState = request.State

	previousState:Exit(self.context)

	self._currentState = nextState

	nextState:Enter(self.context)

	request._runtime.Status = "Resolved"

	table.remove(self._queue, index)

	print(string.format("[FSM] resolved transition %s -> %s", previousState.Name, nextState.Name))
end

function StateMachine:_ExpireTransition(request: FsmTypes.transtitionFormated)
	request._runtime.Status = "Expired"
	print(
		string.format(
			"[FSM] request to %s expired: source: %s, reason: %s",
			request.State.Name,
			request.source,
			request.reason or "no reason provided"
		)
	)
end

function StateMachine:ResolveTransition()
	if #self._queue == 0 then
		return
	end

	for index, request in ipairs(self._queue) do
		if not self:_CanProcessRequest(request) then
			continue
		end

		self:_ResolveRequest(index, request)
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
	request["_runtime"] = {
		Status = "Pending",
		LastFailureReason = nil,
		LastFailureState = nil,
	}

	table.insert(self._queue, request)

	if #self._queue > 1 then
		table.sort(self._queue, function(a, b)
			return a.Priority > b.Priority -- types: ignore
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
