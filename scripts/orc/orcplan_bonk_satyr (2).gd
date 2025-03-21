extends GOAPAction


var _target_id: int = 0;

func _ready():
	set_condition("is_near_satyr", true);
	set_condition("has_bonker", true);
	
	set_effect("is_near_satyr", false);
	#set_effect("is_near_food", true); # not sure
	#set_effect("is_afraid", false); # not sure



# Checks conditions if action can be executed.
func check_procedural_precondition() -> bool:
	#check if satyr is within neaby distance and bonker hp > 0
	var world_state: Dictionary = get_planner().get_state_dictionary();
	var satyr: Area2D = world_state.get("nearest_satyr")
	var bonker_hp: int = world_state.get("bonker_hp")
	
	var condition: bool = true if bonker_hp > 0 && satyr != null else false;
	return condition;

# Contains instructions to be performed by agent and returns value if action has finished executing.
func execute_action(actor: Node, delta: float) -> Status:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	var satyr: Area2D = world_state.get("nearest_satyr");
	var bonker_hp: int = world_state.get("bonker_hp");
	if _target_id == 0 && satyr != null:
		_target_id = satyr.get_instance_id();
	
	if (satyr == null || bonker_hp <= 0 || (satyr != null && satyr.get_instance_id() != _target_id)):
		_target_id = 0;
		return Status.FAILURE;
	if actor.is_near(satyr.get_global_position(), 8) == true:
		#if (actor.is_attack_finished() == true):
		#	return Status.SUCCESS
		actor.attack();
		return Status.SUCCESS
	elif actor.is_near(satyr.get_global_position(), 8) == false: 
		actor.move_to(satyr.get_global_position(), 64)
	return Status.RUNNING;
