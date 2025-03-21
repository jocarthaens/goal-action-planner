extends GOAPAction

var _timer: float = 0.0;
var _run_timer: bool = false;
var _attack_time: float = 1.25;

func _ready():
	set_condition("is_near_boar", true);
	set_condition("has_bonker", true);
	
	set_effect("is_near_boar", false);
	set_effect("found_food", true);



# Checks conditions if action can be executed.
func check_procedural_precondition() -> bool:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	#check if boar is within nearby distance
	var boar: Area2D = world_state.get("nearest_boar");
	var bonker_hp: int = world_state.get("bonker_hp");
	
	var condition: bool = true if boar != null else false;
	return condition;

# Contains instructions to be performed by agent and returns value if action has finished executing.
func execute_action(actor: Node, delta: float) -> Status:
	if _run_timer == false:
		_timer = _attack_time;
		_run_timer = true;
		actor.attack();
	_timer -= delta;
	if _timer <= 0 && _run_timer == true:
		reset();
		return Status.SUCCESS;
	
	return Status.RUNNING;



func reset():
	_timer = 0.0;
	_run_timer = false;
