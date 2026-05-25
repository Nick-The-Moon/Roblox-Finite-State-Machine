export type State = {
	Name: string,
	--priority: number,
	--
	Enter: (self: State, context: any) -> (),
	Update: (self: State, dt: number, context: any) -> (),
	Exit: (self: State, context: any) -> (),
	--
	CanExit: (self: State, nextState: string, context: any) -> (boolean, string?),
	CanEnter: (self: State, previousState: string?, context: any) -> (boolean, string?),
	-- functions for state behavior
	GetnextState: (self: State, context: any) -> string?,
}
export type transitionRequest = {
	State: State,
	Priority: number,
	source: string,
	LifeTime: number,
	--debug:
	reason: string?,
}

export type transtitionFormated = {
	State: State,
	Priority: number,
	source: string,
	LifeTime: number,
	--debug:
	reason: string?,
	_runtime: {
		Status: string,
		LastFailureReason: string?,
		LastFailureState: string?,
	},
}

export type ForceTranstionFlags = {
	ClearQueue: boolean,
	SkipExit: boolean,
	reason: string?,
}

-- state machine types
local FsmTypes = {}
return FsmTypes
