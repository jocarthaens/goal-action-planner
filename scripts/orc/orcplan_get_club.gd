extends GOAPAction

var _timer: float = 0.0;
var _run_timer: bool = false;
var _collect_time: float = 0.5;


func _ready():
	set_condition("found_excali-bonk", true);
	set_condition("has_bonker", false);
	
	set_effect("has_bonker", true);
	set_effect("found_excali-bonk", false);
	#set_effect("is_afraid", false); # not sure




# Checks conditions if action can be executed.
func check_procedural_precondition() -> bool:
	#check for excaliclub nearby and has_bonker
	var world_state: Dictionary = get_planner().get_state_dictionary();
	var excaliclub: Area2D = get_planner().get_state_dictionary().get("nearest_excali-bonk")
	var bonker_hp: int = get_planner().get_state_dictionary().get("bonker_hp")
	
	var condition: bool = true if bonker_hp <= 0 && excaliclub != null else false;
	#print("get bonker: "+str(condition))
	#print("satiation: "+str(world_state["satiation"]))
	return condition;

# Contains instructions to be performed by agent and returns value if action has finished executing.
func execute_action(actor: Node, delta: float) -> Status:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	var excaliclub: Area2D = world_state.get("nearest_excali-bonk")
	var bonker_hp: int = world_state.get("bonker_hp")
	var proximity_dist: int = world_state.get("proximity_dist");
	var move_speed: int = 64;
	
	if (excaliclub == null || bonker_hp > 0):
		print("no club");
		return Status.FAILURE;
	
	if actor.is_near(excaliclub.get_global_position(), proximity_dist) == true:
		if _run_timer == false:
			_timer = _collect_time;
			_run_timer = true;
		_timer -= delta;
		if _timer <= 0 && _run_timer == true:
			actor.collect();
			reset();
			return Status.SUCCESS;
	
	elif actor.is_near(excaliclub.get_global_position(), proximity_dist) == false: 
		actor.move_to(excaliclub.get_global_position(), move_speed)
	
	return Status.RUNNING


func reset():
	_timer = 0.0;
	_run_timer = false;
