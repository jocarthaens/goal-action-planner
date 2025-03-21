extends GOAPAction


var _panic_timer: float = 0.0;
var _panic_duration: float = 2.0;
var _rand_pos: Vector2 = Vector2.ZERO;
var _set_panic_area: bool = false;
var _panic_speed: int = 128
var _panic_dist: int = 128;


func _ready():
	set_condition("found_satyr", true);
	set_condition("has_bonker", false);
	set_condition("is_afraid", true); # not sure to add
	#set_condition("found_hideout", false); # include this condition?
	
	set_effect("found_satyr", false);
	set_effect("is_afraid", false);


# Checks conditions if action can be executed.
func check_procedural_precondition() -> bool:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	
	var is_afraid: bool = world_state.get("is_afraid");
	var hideout: Area2D = world_state.get("nearest_hideout")
	
	var condition: bool = true if is_afraid == true else false;
	return condition;


# Contains instructions to be performed by agent and returns value if action has finished executing.
func execute_action(actor: Node, delta: float) -> Status:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	
	var satyr: Area2D = world_state.get("nearest_satyr");
	var satyr_pos: Vector2 = Vector2.ZERO if satyr == null else satyr.global_position
	var alert_dist: int = world_state.get("alert_dist_satyr");
	var satyr_dist: float = -1 if satyr == null else actor.global_position.distance_to(satyr_pos);
	
	
	if _panic_timer < _panic_duration:
		if ( _set_panic_area == false || %RayCast2D.is_colliding() 
				|| (_set_panic_area == true && satyr != null 
						&& (_rand_pos - satyr_pos).length() <= alert_dist) ):
			var start_pos: Vector2 = actor.global_position;
			randomize();
			_rand_pos = start_pos + Vector2(randf_range(-_panic_dist, _panic_dist), randf_range(-_panic_dist, _panic_dist));
			var dist: float = _rand_pos.distance_to(start_pos);
			while (_rand_pos.distance_to(start_pos) < _panic_dist * 0.75):
				_rand_pos = start_pos + Vector2(randi_range(-_panic_dist, _panic_dist), randi_range(-_panic_dist, _panic_dist));
				dist = _rand_pos.distance_to(start_pos);
			_set_panic_area = true;
		if not actor.is_near(_rand_pos, 8):
			actor.move_to(_rand_pos, _panic_speed)
		_panic_timer += delta;
	else:
		if satyr_dist >= 0 && satyr_dist <= alert_dist:
			print("nooo")
			reset();
			return Status.FAILURE;
		print("yeah")
		reset();
		world_state["is_afraid"] = false;
		return Status.SUCCESS;
	
	return Status.RUNNING;


func reset():
	_panic_timer = 0.0;
	_set_panic_area = false;
	_rand_pos = Vector2.ZERO;
