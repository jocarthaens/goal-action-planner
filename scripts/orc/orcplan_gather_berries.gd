extends GOAPAction

var _timer: float = 0.0;
var _run_timer: bool = false;
var _collect_time: float = 0.5;


func _ready():
	set_condition("found_berry_bush", true);
	
	set_effect("found_food", true);
	#set_effect("is_near_food", true); # not sure
	set_effect("found_berry_bush", false); # not sure
	#set_effect("is_satiated", true); # not sure
	



# Checks conditions if action can be executed.
func check_procedural_precondition() -> bool:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	# check for nearby berry_bush and not is_satiated
	var berry_bush: Area2D = world_state.get("nearest_berry_bush")
	var satiation: int = world_state.get("satiation")
	var max_satiation: int = world_state.get("satiation_max")
	
	var condition: bool = true if satiation < max_satiation && berry_bush != null else false;
	return condition;

# Contains instructions to be performed by agent and returns value if action has finished executing.
func execute_action(actor: Node, delta: float) -> Status:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	var berry_bush: Area2D = world_state.get("nearest_berry_bush")
	var satiation: int = world_state.get("satiation");
	var max_satiation: int = world_state.get("satiation_max");
	
	if (berry_bush == null || satiation >= max_satiation):
		print("no_berries")
		return Status.FAILURE;
	
	if actor.is_near(berry_bush.get_global_position(), 8) == true:
		if _run_timer == false:
			_timer = _collect_time;
			_run_timer = true;
		_timer -= delta;
		if _timer <= 0 && _run_timer == true:
			actor.collect();
			reset();
			return Status.SUCCESS;
	
	elif actor.is_near(berry_bush.get_global_position(), 8) == false: 
		actor.move_to(berry_bush.get_global_position(), 64)
	
	return Status.RUNNING


func reset():
	_timer = 0.0;
	_run_timer = false;
