extends GOAPAction


func _ready():
	set_condition("found_boar", true);
	#set_condition("is_near_boar", false);
	set_condition("has_bonker", true);
	
	set_effect("is_near_boar", true);
	#set_effect("is_near_food", true); # not sure
	#set_effect("is_satiated", true); # not sure



# Checks conditions if action can be executed.
func check_procedural_precondition() -> bool:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	#check if boar is within nearby distance
	var boar: Area2D = world_state.get("nearest_boar")
	#var bonker_hp: int = world_state.get("bonker_hp")
	
	
	var condition: bool = true if boar != null else false;
	return condition;

# Contains instructions to be performed by agent and returns value if action has finished executing.
func execute_action(actor: Node, delta: float) -> Status:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	var boar: Area2D = world_state.get("nearest_boar");
	var bonker_hp: int = world_state.get("bonker_hp");
	var proximity_dist: int = world_state.get("proximity_dist");
	var chase_speed: int = 96
	
	if (boar == null || bonker_hp <= 0):
		return Status.FAILURE;
	if actor.is_near(boar.get_global_position(), proximity_dist) == true:# && boar.get_state() == "idle":
		return Status.SUCCESS
	elif actor.is_near(boar.get_global_position(), proximity_dist) == false: 
		actor.move_to(boar.get_global_position(), chase_speed)
	return Status.RUNNING;
