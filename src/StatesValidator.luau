--StatesValidator.luau
local FsmTypes = require(script.Parent.FsmTypes)

local Handler = {}

local function getMethodsMissing(state: { [string]: any }, methods: { string })
	-- return an table of missing methods
	local missing = {}

	for _, method in methods do
		if not state[method] then
			table.insert(missing, method)
		end
	end

	if #missing == 0 then
		return {}
	end

	return missing
end

function Handler.ValidateState(state)
	-- validate states
	assert(state, "state is nil")
	assert(type(state) == "table", string.format("state type should be an table, but got %s", type(state)))

	-- validate requirements to load an state --
	local methodsValidate = { "Update", "Enter", "Exit", "CanEnter", "CanExit" } -- methods that should be implemented in an state
	local formatedMethodsMissing = string.format(table.concat(getMethodsMissing(state, methodsValidate), ", "))
	--print(getMethodsMissing(state, methodsValidate))

	assert(
		#formatedMethodsMissing == 0,
		string.format("the methods: [%s] is missing in state %s", formatedMethodsMissing, state.Name or "unknown")
	)
end

function Handler.validateTransition(stateFrom: FsmTypes.State, stateTo: FsmTypes.State, context: any)
	-- validate if the transition between states is valid
	assert(stateFrom, "stateFrom is nil")
	assert(stateTo, "stateTo is nil")
	assert(type(stateFrom) == "table", string.format("stateFrom type should be an table, but got %s", type(stateFrom)))
	assert(type(stateTo) == "table", string.format("stateTo type should be an table, but got %s", type(stateTo)))

	-- validate requirements to load an state --
	local canExit, reasonExit
	if stateFrom.CanExit then
		canExit, reasonExit = stateFrom:CanExit(stateTo.Name, context)
	end

	local canEnter, reasonEnter
	if stateTo.CanEnter then
		canEnter, reasonEnter = stateTo:CanEnter(stateFrom.Name, context)
	end

	if not canExit then
		warn(string.format("cannot exit state %s: %s", stateFrom.Name, reasonExit or "unknown reason"))
	end

	if not canEnter then
		warn(string.format("cannot enter state %s: %s", stateTo.Name, reasonEnter or "unknown reason"))
	end

	return (canExit and canEnter)
end

function Handler.validatePriorityRequest(X: FsmTypes.transitionRequest, Y: FsmTypes.transitionRequest)
	-- validate if the transition request is valid

	-- validate X
	assert(X, "X is nil")
	assert(X.Priority, "X.Priority is nil")
	assert(X.State, "X.State is nil")
	assert(type(X.State) == "table", string.format("X.State type should be an table, but got %s", type(X.State)))
	assert(type(X) == "table", string.format("X type should be an table, but got %s", type(X)))
	assert(
		type(X.Priority) == "number",
		string.format("X.Priority type should be a number, but got %s", type(X.Priority))
	)

	-- validate Y
	assert(Y, "Y is nil")
	assert(type(Y) == "table", string.format("Y type should be an table, but got %s", type(Y)))
	assert(Y.State, "Y.State is nil")
	assert(type(Y.State) == "table", string.format("Y.State type should be an table, but got %s", type(Y.State)))
	assert(Y.Priority, "Y.Priority is nil")
	assert(
		type(Y.Priority) == "number",
		string.format("Y.Priority type should be a number, but got %s", type(Y.Priority))
	)

	-- logic:

	local valid = X.Priority > Y.Priority
	if not valid then
		return Y
	end

	return X
end

return Handler
