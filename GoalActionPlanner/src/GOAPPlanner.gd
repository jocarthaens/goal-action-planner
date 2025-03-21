@icon("res://GoalActionPlanner/icons/goapplanner.svg")
extends Node
class_name GOAPPlanner

@export var actor: NodePath 
@export var use_current_plan: bool = false ## Uses current action plan if action planner cannot generate a new plan.

@export_group("Cost Selection")
@export var select_max_cost: bool = false
@export var shuffle_if_same_cost: bool = false ## Randomizes selection if multiple actions has max/min values satisfied. This is to ensure that all possible options are chosen even if their values are equal.

@export_group("State Dictionaries")
@export var current_state: Dictionary
@export var goal_state: Dictionary

var _planner: Planner = Planner.new()

enum Status {FAILURE, SUCCESS, RUNNING} # add SUSPENDED?
var action_list: Array[GOAPAction] # pool of actions that will be chosen during planning phase
var action_plan: Array[GOAPAction] # a sequence of chosen actions to be executed during plan execution phase
var _sorted_plan_list: Array[GOAPNode] # used for debugging purposes
var _new_action_plan: Array[GOAPAction] # used for checking conditions
var _action_index: int = 0;
var _old_action_index: int = -1; # used for action_executed signal, checks current action if it is changed

signal plan_interrupted;
signal planning_finished(is_plan_empty: bool)
signal new_action_selected(action: GOAPAction)
signal plan_execution_finished(is_success: bool);

var _is_next_action: bool = false;
#var _default_idle_action: Callable = func(): pass
#var current_idle_action = _default_idle_action

var _is_initialized: bool = false
var _is_interrupted: bool = false

@onready var actor_node: Node = get_node(actor)




# Methods for setting world and goal state dictionaries

func set_dictionaries(state_dict: Dictionary, goal_dict: Dictionary):
	current_state = state_dict
	goal_state = goal_dict


func get_state_dictionary() -> Dictionary:
	return current_state

func get_goal_dictionary() -> Dictionary:
	return goal_state

func get_actor() -> Node:
	return actor_node




# Methods for modifying the planner's action lists

func add_action(action: GOAPAction):
	add_child(action)

func remove_action(action: GOAPAction, is_permanent: bool = true):
	remove_child(action)
	if is_permanent:
		action.queue_free()

func clear_actions(is_permanent: bool):
	for action in action_list:
		if action is GOAPAction:
			remove_action(action, is_permanent)

func _update_actions(child: GOAPAction, is_entering: bool):
	if is_entering:
		action_list.append(child)
	elif not is_entering:
		action_list.erase(child)
		if action_plan.has(child):
			interrupt_plan()


func get_current_action() -> GOAPAction:
	return action_plan[_action_index] if _action_index >= 0 && _action_index < action_plan.size() else null;






# Methods for setting idle actions

#func set_idle_action(idle_action):
	#if idle_action is GOAPAction or idle_action is Callable:
		#current_idle_action = idle_action
	#_check_idle_action(idle_action)
#
#func reset_idle_action():
	#current_idle_action = _default_idle_actionplan_status
#
#func _check_idle_action(idle_action):
	#if not (idle_action is GOAPAction) and not (idle_action is Callable):
		#var errorMessage: String = "Idle Action can only be a GOAPAction instance or a Callable."
		#push_error(errorMessage)
		#assert((idle_action is GOAPAction) or (idle_action is Callable), errorMessage)



# LIST OF CHECKERS CALLED WHEN RUNNING THE INSTANCE THE FIRST TIME

func _initial_checks():
	if not _is_initialized:
		_check_dictionaries()
		_check_action_list()
		_is_initialized = true

func _check_action_list():
	if action_list.size() <= 0:
		var error_message: String = "GOAPInstance doesn't have a list of GOAPAction nodes."
		push_error(error_message)
		assert(action_list.size() > 0,error_message)

func _check_dictionaries(): 
	if current_state.is_empty():
		push_error("State Dictionary is empty.")
	if goal_state.is_empty():
		push_error("Goal Dictionary is empty.")
	assert(not current_state.is_empty() && not goal_state.is_empty(), "Check assigned dictionaries in instantiated GOAPAgent, or Inspector (if GOAPAgent is a node) if empty.")





# MAIN FUNCTION: RUN THIS FUNCTION IN GAME LOOP TO START
func run_action_plan(actor_object, delta: float, pick_max_cost: bool = select_max_cost, jumble_same_cost: bool = shuffle_if_same_cost, current_plan_if_empty: bool = use_current_plan):
	var plan_status: Status = _execute_plan(actor_object, delta, current_plan_if_empty)
	if plan_status != Status.RUNNING:
		var is_success: bool = true if plan_status == Status.SUCCESS else false;
		plan_execution_finished.emit(is_success);
		if plan_status == Status.FAILURE:
			action_plan.clear()
		_find_action_plan(pick_max_cost, jumble_same_cost)

# GENERATES ACTION PLAN
func _find_action_plan(pick_max_cost: bool = select_max_cost, jumble_same_cost: bool = shuffle_if_same_cost):
	for action: GOAPAction in action_list:
		action.reset();
	
	_new_action_plan.clear()
	_action_index = 0
	
	_planner.provide_action_plan(current_state, goal_state, _new_action_plan, action_list, pick_max_cost, jumble_same_cost)
	
	_sorted_plan_list.clear()
	_sorted_plan_list = _planner.get_plan_list().duplicate(true)
	
	if _new_action_plan.size() > 0:
		action_plan.clear()
		action_plan.append_array(_new_action_plan)
	
	planning_finished.emit(action_plan.is_empty());

# EXECUTES THE ACTION PLAN (RETURNS STATUS)
func _execute_plan(actor_object,  delta: float, current_plan_if_empty: bool = use_current_plan) -> Status:
	if _is_initialized == false:
		_old_action_index = -1;
		_initial_checks()
		return Status.FAILURE
	
	if _is_interrupted == true:
		plan_interrupted.emit()
		_old_action_index = -1;
		_is_interrupted = false
		return Status.FAILURE
	
	elif (_new_action_plan.size() > 0 || current_plan_if_empty == true) && action_plan.size() > 0:
		if _action_index > action_plan.size():
			_action_index = 0
		
		if _old_action_index != _action_index:#
			new_action_selected.emit(action_plan[_action_index]);
		_old_action_index = _action_index;
		
		var condition_check: bool = action_plan[_action_index].check_procedural_precondition() and _action_index < action_plan.size()
		var response = action_plan[_action_index].execute_action(actor_object, delta) if condition_check == true else Status.FAILURE
		
		if response == Status.SUCCESS:
			if _action_index < action_plan.size():
				_action_index += 1
			if _action_index >= action_plan.size():
				_old_action_index = -1;
				return Status.SUCCESS
		
		elif response == Status.FAILURE:
			_old_action_index = -1;
			return Status.FAILURE
		#elif response == Status.RUNNING:
		#	pass
	
	elif _new_action_plan.is_empty() && (current_plan_if_empty == false || action_plan.is_empty()):
		#_perform_idle_action(idle_action)
		_old_action_index = -1;
		return Status.FAILURE
	
	
	return Status.RUNNING

#func _perform_idle_action(idle_action):
	#_check_idle_action(idle_action)
	#
	#if idle_action is Callable:
		#idle_action.call()
	#elif idle_action is GOAPAction:
		#idle_action.execute_action()

#CALL THIS TO INTERRUPT CURRENT ACTION PLAN FOR THE PLANNER TO CREATE A NEW ONE
func interrupt_plan():
	_is_interrupted = true








#ALL DEBUGGER FUNCTIONS
func print_action_list(print_action_cost: bool = false, print_precondition: bool = false, print_effects: bool = false):
	if action_list.is_empty():
		print("## Action List is currently empty. ##")
	else:
		print("List of Actions in Action List")
		for action in action_list:
			if action is GOAPAction:
				print("Action Name = ", action.name)
				if print_action_cost:
					print("	Action Cost = ", action.action_cost)
				if print_precondition:
					print("	Preconditions = ", action.preconditions)
				if print_effects:
					print("	Effects = ", action.effects)

func print_plan_list(print_plan_cost: bool = false):
	if _sorted_plan_list.is_empty():
		print("## Plan List is currently empty. ##")
	else:
		var order: String = "ascending order." if select_max_cost else "descending order."
		print("List of Plans in Plan List, arranged in ", order)
		for node:GOAPNode in _sorted_plan_list:
			print("Rear Action = ", node.action.name)
			if print_plan_cost:
				print("	Run Cost = ", node.run_cost)

func print_chosen_plan_list(chosen_plan_index: int = 0, _print_plan_cost: bool = false):
	if _sorted_plan_list.is_empty():
		print("## Plan List is currently empty. ##")
	else:
		var chosen_plan = _sorted_plan_list[chosen_plan_index] if _sorted_plan_list.size() > chosen_plan_index else null
		var order: String = "ascending order." if select_max_cost else "descending order."
		print("Action Plan index ", chosen_plan_index," in Plan List. Plan is arranged in ", order)
		
		while chosen_plan != null && chosen_plan.action != null:
			print(chosen_plan.action.name , ": Current Run Cost = ", chosen_plan.run_cost)
			chosen_plan = chosen_plan.parent

func print_action_plan(print_action_cost: bool = false, print_precondition: bool = false, print_effects: bool = false):
	if action_plan.is_empty():
		print("## Action Plan is currently empty. ##")
	else:
		var num: int = 0
		print("List of Actions in Action Plan, in order")
		for action:GOAPAction in action_plan:
			num += 1
			print(num,". Action Name = ", action.name)
			if print_action_cost:
				print("	Action Cost = ", action.action_cost)
			if print_precondition:
				print("	Preconditions = ", action.preconditions)
			if print_effects:
				print("	Effects = ", action.effects)

#TO ADD: PLANLIST ITERATION FOR OTHER ACTION PLAN EXECUTION (NOT NECESSARY)
#TO ADD: MAKE GOAP FUNCTIONS SELF-CONTAINED AND MODULAR (NEARING BUT ENOUGH FOR NOW)










# PLANNER STARTS HERE
class Planner:
	
	var _plan_list: Array[GOAPNode]
	func get_plan_list(): return _plan_list
	
	# ALL PLANNER ESSENTIAL FUNCTIONS
	
	func provide_action_plan(start_state: Dictionary, goal_state: Dictionary, action_plan_box: Array[GOAPAction], available_actions: Array[GOAPAction], pick_max_cost: bool, jumble_same_cost: bool) -> void:
		var root: GOAPNode = GOAPNode.new(null, 0, start_state, null)
		var usable_actions: Array[GOAPAction] = []
		var plan_list: Array[GOAPNode] = []
		
		for action in available_actions:
			#print(str(action) + " = "+ str(action.check_procedural_precondition()) )
			if action is GOAPAction and action.check_procedural_precondition() == true:
				usable_actions.append(action)
		_build_plans(root, goal_state, plan_list, usable_actions)
		_choose_best_plan(action_plan_box, plan_list, pick_max_cost, jumble_same_cost)
	
	func _build_plans(node_start: GOAPNode, goal_state: Dictionary, plan_list_box: Array[GOAPNode], actions_list: Array[GOAPAction]) -> void:
		#print("next")
		#print(actions_list)
		for action: GOAPAction in actions_list:
			if(_all_match_state(action.preconditions, node_start.state)):
				#print("match")
				var curr_state: Dictionary = node_start.state.duplicate()
				_populate_state(curr_state, action.effects)
				var goap_node: GOAPNode = GOAPNode.new(node_start, node_start.run_cost + action.action_cost, curr_state, action)
				#print("goal_check: ")
				if (_all_match_state(goal_state, curr_state)):
					#print("alrighty!")
					plan_list_box.append(goap_node)
				else:
					#print("! not again !")
					var subset_actions: Array[GOAPAction] = []
					subset_actions.append_array(_action_subset(actions_list, action))
					_build_plans(goap_node, goal_state, plan_list_box, subset_actions)
			#print("* saddened *")
	
	func _choose_best_plan(action_plan_box: Array[GOAPAction], plans_list: Array[GOAPNode], pick_max_cost: bool, jumble_same_cost: bool):
		
		# sorts list of plans by their overall run cost
		_sort_node_by_cost(plans_list, pick_max_cost, jumble_same_cost)
		
		_plan_list.clear()
		_plan_list = plans_list.duplicate(true)
		
		var best_node: GOAPNode = plans_list[0] if not plans_list.is_empty() else null
		var best_node_list: Array[GOAPNode] = []
		while best_node != null:
			best_node_list.append(best_node)
			best_node = best_node.parent
		
		# sorts the list of nodes by their accumulated run cost, with the lowest being the first
		_sort_node_by_cost(best_node_list, false, jumble_same_cost)
		
		for node in best_node_list:
			var action = node.action
			if action != null:
				action_plan_box.append(action)
	
	
	
	
	# ALL PLANNER HELPER FUNCTIONS
	
	static func _all_match_state(test_state: Dictionary, check_state: Dictionary) -> bool:
		var all_match = false
		var key_matches: int = 0

		for key1 in test_state:
			for key2 in check_state:
				if (key1 == key2 && test_state[key1] == check_state[key2]):
					key_matches += 1
		if key_matches == test_state.size():
			all_match = true
		
		#print("test "+str(test_state))
		#print("check "+str(check_state))
		#print("all_match: "+str(all_match))
		return all_match
	
	static func _populate_state(current_state: Dictionary, change_state: Dictionary) -> void:
		for key in change_state:
			current_state[key] = change_state[key]
	
	static func _action_subset(actions_list: Array[GOAPAction], unwanted_action: GOAPAction) -> Array[GOAPAction]:
		var sub_array: Array[GOAPAction] = actions_list.duplicate()
		sub_array.erase(unwanted_action)
		return sub_array
	
	static func _sort_node_by_cost(node_list: Array[GOAPNode], pick_max_cost: bool, jumble_same_cost: bool):
		if jumble_same_cost == true:
			randomize()
			node_list.shuffle()
		if pick_max_cost == false:
			node_list.sort_custom(func(a: GOAPNode, b: GOAPNode): return a.run_cost < b.run_cost)
		elif pick_max_cost == true:
			node_list.sort_custom(func(a: GOAPNode, b: GOAPNode): return a.run_cost > b.run_cost)




# This inner class stores the whole plan by referencing its precedent/parent GOAPNode instances, 
# up until the last precedent references a null instance

class GOAPNode:
	var parent: GOAPNode
	var run_cost: int
	var state: Dictionary
	var action: GOAPAction
	
	func _init(_parent: GOAPNode, _cost: int, _state: Dictionary, _action: GOAPAction):
		parent = _parent
		run_cost = _cost
		state = _state.duplicate()
		action = _action
