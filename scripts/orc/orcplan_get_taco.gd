extends GOAPAction


func _ready():
	set_condition("found_taco", true);
	set_condition("found_satyr", false);
	set_effect("is_satiated", false);
	
	set_effect("is_satiated", true);
	#set_effect("is_near_taco", false);




# Checks conditions if action can be executed.
func check_procedural_precondition() -> bool:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	#check satyr distance and hunger
	var satyr: Area2D = world_state.get("nearest_satyr")
	var taco: Area2D = world_state.get("nearest_taco")
	var satiation: int = world_state.get("satiation")
	var max_satiation: int = world_state.get("satiation_max")
	
	# add additional condition for satyr distance if satyr is present?
	var condition: bool = true if satiation < max_satiation && taco != null else false;
	#print(world_state["is_near_taco"])
	return condition;

# Contains instructions to be performed by agent and returns value if action has finished executing.
func execute_action(actor: Node, delta: float) -> Status:
	var world_state: Dictionary = get_planner().get_state_dictionary();
	
	var satyr: Area2D = world_state.get("nearest_satyr")
	var orc: CharacterBody2D = actor;
	var alert_dist: float = world_state.get("alert_dist_satyr")
	var dist: float = (satyr.global_position - orc.global_position).length() if satyr != null else -1;
	var bonker_hp: int = world_state.get("bonker_hp")
	
	var taco: Area2D = world_state.get("nearest_taco")
	var satiation: int = world_state.get("satiation")
	var max_satiation: int = world_state.get("satiation_max")
	
	var proximity_dist: int = world_state.get("proximity_dist");
	var move_speed: int = 32;
	
	if (taco == null || satiation >= max_satiation || dist >= 0 && dist <= alert_dist && bonker_hp <= 0):
		return Status.FAILURE;
	if actor.is_near(taco.get_global_position(), proximity_dist) == true:
		actor.collect();
		return Status.SUCCESS;
	elif actor.is_near(taco.get_global_position(), proximity_dist) == false: 
		actor.move_to(taco.get_global_position(), move_speed)
	
	return Status.RUNNING
