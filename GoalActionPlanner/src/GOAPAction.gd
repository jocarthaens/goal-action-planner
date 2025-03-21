@icon("res://GoalActionPlanner/icons/goapaction.svg")
extends Node
class_name GOAPAction

@export var action_cost: int = 1
@export var preconditions: Dictionary
@export var effects: Dictionary

enum Status {FAILURE, SUCCESS, RUNNING}

var _parent_planner: GOAPPlanner

@onready var _default_action_cost: int = action_cost
@onready var _is_cost_modified: bool = false



# OVERRIDABLE FUNCTIONS START HERE

# Checks conditions if action can be executed during plan execution. Also used for checking complex preconditions on the planning phase.
func check_procedural_precondition() -> bool:
	return true

# Contains instructions to be performed by actor and returns value if action has finished executing.
func execute_action(actor: Node, delta: float) -> Status:
	return Status.SUCCESS

# Function that supposedly resets the state of the GOAPAction node.
func reset():
	pass

# OVERRIDABLE FUNCTIONS ENDS HERE





# Methods used to set action cost

func set_action_cost(value: int) -> void:
	_is_cost_modified = true
	action_cost = value

func set_default_action_cost(value: int) -> void:
	_default_action_cost = value
	action_cost = value

func get_action_cost() -> int:
	return action_cost

func reset_action_cost() -> void:
	_is_cost_modified = false
	action_cost = _default_action_cost







# Methods used to set and modify preconditions

func set_condition(key, value) -> void:
	preconditions[key] = value

func get_condition(key) -> Variant:
	return preconditions[key] if has_condition(key) else null

func has_condition(key) -> bool:
	return preconditions.has(key)

func remove_condition(key) -> void:
	preconditions.erase(key)








# Methods used to set and modify effects

func set_effect(key, value) -> void:
	effects[key] = value

func get_effect(key) -> Variant:
	return effects[key] if has_effect(key) else null

func has_effect(key) -> bool:
	return effects[key].has(key)

func remove_effect(key) -> void:
	effects.erase(key)






# Method that returns the GOAPPlanner parent of the GOAPAction node instance
func get_planner() -> GOAPPlanner:
	return _parent_planner






# These functions will update their parent GOAPPlanner node when they enter/exit the scene tree

func _enter_tree():
	var _parent = get_parent()
	if (_parent is GOAPPlanner):
		_parent_planner = _parent
		_parent_planner._update_actions(self, true)
	else:
		_parent_planner = null

func _exit_tree():
	if (_parent_planner is GOAPPlanner):
		_parent_planner._update_actions(self, false)
		_parent_planner = null
