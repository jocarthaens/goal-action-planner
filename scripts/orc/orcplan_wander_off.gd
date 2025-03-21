extends GOAPAction


var _rand_pos: Vector2 = Vector2.ZERO;
var _wander_dist: int = 128;
var _timer: float = 0.0;
var _wander_off: bool = false;
var _wander_time: float = 5.0;
var _wander_speed: int = 64;

func _ready():
	set_effect("explore_area", false)

# Checks conditions if action can be executed.
func check_procedural_precondition() -> bool:
	return true

# Contains instructions to be performed by agent and returns value if action has finished executing.
func execute_action(actor: Node, delta: float) -> Status:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	var proximity_dist: int = world_state.get("proximity_dist");
	
	if _timer < _wander_time:
		if _wander_off == false || %RayCast2D.is_colliding():
			var start_pos: Vector2 = actor.get_global_position();
			_rand_pos = start_pos + Vector2(randf_range(-_wander_dist, _wander_dist), randf_range(-_wander_dist, _wander_dist));
			var dist: float = _rand_pos.distance_to(start_pos);
			while (dist > _wander_dist && dist < _wander_dist * 0.75):
				randomize();
				_rand_pos = start_pos + Vector2(randi_range(-_wander_dist, _wander_dist), randi_range(-_wander_dist, _wander_dist));
				dist = _rand_pos.distance_to(start_pos);
			_wander_off = true;
		if not actor.is_near(_rand_pos, proximity_dist):
			actor.move_to(_rand_pos, _wander_speed)
		_timer += delta;
	else:
		reset();
		return Status.SUCCESS;
	
	return Status.RUNNING

func reset():
	_timer = 0.0;
	_rand_pos = Vector2.ZERO;
	_wander_off = false;
