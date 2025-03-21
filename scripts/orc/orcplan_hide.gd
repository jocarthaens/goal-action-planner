extends GOAPAction


var _hide_timer: float = 0.0;
var _start_hide: bool = false;
var _hide_duration: float = 5.0;


func _ready():
	set_condition("found_satyr", true);
	set_condition("has_bonker", false);
	set_condition("is_afraid", true); # not sure to add
	set_condition("found_hideout", true); # include this condition?
	
	set_effect("found_satyr", false);
	set_effect("is_afraid", false);
	



# Checks conditions if action can be executed.
func check_procedural_precondition() -> bool:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	
	var is_afraid: bool = world_state.get("is_afraid");
	var hideout: Area2D = world_state.get("nearest_hideout")
	
	var condition: bool = true if is_afraid == true && hideout != null else false;
	return condition;
	
	# # check satyr distance and if orc has bonker
	#var bonker_hp: int = world_state.get("bonker_hp");
	#var satyr: Area2D = world_state.get("nearest_satyr");
	#var actor: CharacterBody2D = get_planner().get_actor();
	#var satyr_dist: float = -1 if satyr == null else actor.get_global_position().distance_to(satyr.get_global_position());
	#var alert_dist: int = world_state.get("alert_dist_satyr");
	#
	# # add additional condition for satyr distance if satyr is present
	#var condition: bool = true if (bonker_hp <= 0 && satyr != null && satyr_dist <= alert_dist) || is_afraid == true else false;
	#return condition;

# Contains instructions to be performed by agent and returns value if action has finished executing.
func execute_action(actor: Node, delta: float) -> Status:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	
	var satyr: Area2D = world_state.get("nearest_satyr");
	var hideout: Area2D = world_state.get("nearest_hideout");
	
	var alert_dist: int = world_state.get("alert_dist_satyr");
	var satyr_dist: float = -1 if satyr == null else actor.get_global_position().distance_to(satyr.get_global_position());
	
	var proximity_dist: int = world_state.get("proximity_dist");
	var move_speed: int = 96;
	
	if hideout == null:
		return Status.FAILURE;
	
	elif hideout != null:
		var near_hideout: bool = actor.is_near(hideout.get_global_position(), proximity_dist);
		if near_hideout:
			if _start_hide == false:
				_start_hide = true;
				_hide_timer = _hide_duration;
		else:
			actor.move_to(hideout.get_global_position(), move_speed);
	if _start_hide == true:
		_hide_timer -= delta;
		if _hide_timer <= 0:
			reset();
			world_state["is_afraid"] = false;
			return Status.SUCCESS;
	
	return Status.RUNNING;


func reset():
	_hide_timer = 0.0;
	_start_hide = false;
