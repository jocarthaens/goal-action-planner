extends GOAPAction

var _timer: float = 0.0;
var _run_timer: bool = false;
var _collect_time: float = 0.25;


func _ready():
	set_condition("found_food", true);
	set_condition("is_satiated", false);
	
	set_effect("is_satiated", true);
	set_effect("found_food", false);
	#set_effect("is_near_food", false); # not sure




# Checks conditions if action can be executed.
func check_procedural_precondition() -> bool:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	#check satiation
	#var food: Area2D = world_state.get("nearest_food");
	var satiation: int = world_state.get("satiation");
	var max_satiation: int = world_state.get("satiation_max");
	
	var condition: bool = true if satiation < max_satiation else false; # && food != null else false;
	#print("okay "+ str(world_state.get("found_food")) ) if condition == true else null;
	return condition;

# Contains instructions to be performed by agent and returns value if action has finished executing.
func execute_action(actor: Node, delta: float) -> Status:
	
	if actor.is_collecting() == true:
		return Status.RUNNING;
	
	var world_state: Dictionary = get_planner().get_state_dictionary();
	var food: Area2D = world_state.get("nearest_food");
	var satiation: int = world_state.get("satiation");
	var max_satiation: int = world_state.get("satiation_max");
	
	if (food == null || satiation >= max_satiation):
		print("no_food")
		return Status.FAILURE;
	
	if _run_timer == false:
		_timer = _collect_time;
		_run_timer = true;
	_timer -= delta;
	if _timer <= 0 && _run_timer == true:
		if actor.is_near(food.get_global_position(), 8) == true && actor.is_collecting() == false:
			actor.collect();
			reset();
			return Status.SUCCESS;
	
	if actor.is_near(food.get_global_position(), 8) == false: 
		actor.move_to(food.get_global_position(), 64)
		return Status.RUNNING
	return Status.RUNNING


func reset():
	_timer = 0.0;
	_run_timer = false;
