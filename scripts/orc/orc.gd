extends CharacterBody2D

@export var world_state: Dictionary;
@export var goal_state: Dictionary;

#var state: String = "idle"; # States: idle, walk, melee
var _face_direction: String = "right"; # face direction: left or right
var _collect_timer: float = 0.0;
var _collect_duration: float = 0.16;

var _hunger_drop_timer: float = 0.0;
var _hunger_drop_tick: float = 5.0;

var _attack_mode: bool = false;
var _attack_hit: bool = false;
#var _attack_finished: bool = false;
#var _attack_list: Dictionary = {};




func _ready():
	_initialize_states();
	%PlannerAI.set_dictionaries(world_state, goal_state);
	%PlannerAI.new_action_selected.connect(_on_new_action_selected);
	%PlannerAI.plan_interrupted.connect(_on_plan_interrupted);
	%PlannerAI.planning_finished.connect(_on_planning_finished);
	%Collector/CollisionShape2D.disabled = true;
	scan_area();
	pass

func _initialize_states(): # add parameters for distance limits of all entities
	world_state["bonker_hp"] = 0;
	world_state["bonker_max_hp"] = 3;
	world_state["satiation"] = 0;
	world_state["satiation_max"] = 10;
	

	
	# detection ranges for each entity
	world_state["detect_dist_satyr"] = 128;
	world_state["detect_dist_taco"] = 160;
	world_state["detect_dist_berry_bush"] = 160;
	world_state["detect_dist_boar"] = 160;
	world_state["detect_dist_excali-bonk"] = 160;
	world_state["detect_dist_hideout"] = 160;
	world_state["detect_dist_food"] = 160;
	
	# stores the nearest entity of a type, if detected
	world_state["nearest_satyr"] = null;
	world_state["nearest_taco"] = null;
	world_state["nearest_berry_bush"] = null;
	world_state["nearest_boar"] = null;
	world_state["nearest_excali-bonk"] = null;
	world_state["nearest_hideout"] = null;
	world_state["nearest_food"] = null;
	
	# tells if specified entity was detected within the entity's detection range
	world_state["found_satyr"] = false;
	world_state["found_taco"] = false;
	world_state["found_berry_bush"] = false;
	world_state["found_boar"] = false;
	world_state["found_excali-bonk"] = false;
	world_state["found_hideout"] = false; # include this condition?
	world_state["found_food"] = false;
	
	# distance where an entity is considered nearby
	world_state["proximity_dist"] = 8;
	# tells if specified entity is within proximity distance
	world_state["is_near_satyr"] = false;
	world_state["is_near_taco"] = false;
	world_state["is_near_berry_bush"] = false;
	world_state["is_near_boar"] = false;
	world_state["is_near_excali-bonk"] = false;
	world_state["is_near_hideout"] = false; # include this condition?
	world_state["is_near_food"] = false;
	
	# alert distance that activates is_afraid
	world_state["alert_dist_satyr"] = 96;
	
	world_state["has_bonker"] = false;
	world_state["is_afraid"] = false;
	world_state["is_satiated"] = false;
	world_state["explore_area"] = false;
	
	goal_state["is_satiated"] = true;
	# goals: hide, satiate, explore











func _physics_process(delta: float) -> void:
	scan_area();
	#check_objects(); # checks the world state for dangling nodes (freed nodes)
	check_bonker_state();
	_behavior(delta)
	
	%PlannerAI.run_action_plan(self, delta);
	
	#%PlannerAI.print_chosen_plan_list(0, true)
	#%PlannerAI.print_action_plan();
	
	_animation()
	
	var action: GOAPAction = %PlannerAI.get_current_action();
	%ActionLabel.text = action.get_name() if action != null else "";
	
	%SatiationBar.value = world_state["satiation"];
	%BonkerHP.value = world_state["bonker_hp"];
	
	if velocity.length() > 0:
		%RayCast2D.set_rotation(velocity.angle());
	
	velocity = Vector2.ZERO;




func _behavior(delta: float): # instead of checking states, it will decide its goal depending on the scanned area
	
	if (_collect_timer >= 0):
		_collect_timer -= delta;
	if _collect_timer <= 0:
		%Collector/CollisionShape2D.disabled = true;
		_collect_timer = 0;
	
	
	if world_state["satiation"] > 0:
		_hunger_drop_timer += delta;
		if _hunger_drop_timer >= _hunger_drop_tick:
			world_state["satiation"] -= 1;
			_hunger_drop_timer = 0;
	
	
	if detect_satyr() == false:
		var find_food: bool = ( is_instance_valid(world_state["nearest_food"]) 
				|| ( is_instance_valid(world_state["nearest_boar"]) 
					&& (is_instance_valid(world_state["nearest_excali-club"]) 
							|| world_state["has_bonker"] == true) ) 
				|| is_instance_valid(world_state["nearest_berry_bush"])
				|| is_instance_valid(world_state["nearest_taco"]) );
		
		if ( find_food == true && world_state["satiation"] < world_state["satiation_max"] 
				&& not goal_state.has("is_satiated") ):
			goal_state.clear()
			world_state["is_satiated"] = false;
			goal_state["is_satiated"] = true;
			%PlannerAI.interrupt_plan();
		elif ( (find_food == false || world_state["satiation"] >= world_state["satiation_max"])
				 && not goal_state.has("explore_area") ):
			goal_state.clear()
			world_state["explore_area"] = true;
			goal_state["explore_area"] = false;
			%PlannerAI.interrupt_plan();


func _animation():
	var spd: float = velocity.length();
	if spd > 0.1:
		_face_direction = "left" if velocity.x < 0 else "right";
	if spd <= 0.1 && _attack_mode == true:
		%AnimationPlayer.play("melee_"+_face_direction);
		return;
	elif spd <= 0.1 && _attack_mode == false:
		%AnimationPlayer.play("idle_"+_face_direction);
		return;
	elif spd > 0.1 && _attack_mode == false:
		%AnimationPlayer.play("walk_"+_face_direction);
		return;







# Orc Actions:

# add idle function
func stay_idle():
	velocity = Vector2.ZERO;
	# play idle animation



func move(direction: Vector2, speed: float = 64.0):
	if _attack_mode == false:
		velocity = direction.normalized() * speed;
		move_and_slide();

func move_to(target_pos: Vector2, speed: float = 64.0):
	move(target_pos - global_position, speed);

func is_near(target_pos: Vector2, min_dist: float = 8.0) -> bool:
	return self.global_position.distance_to(target_pos) <= min_dist;


#Synchronize attack animation, attack states, target states
 
func attack():
	if _attack_mode == false:
		_attack_mode = true;
		#_attack_finished = false;

func is_attacking() -> bool:
	return _attack_mode == true;



func collect():
	if (_collect_timer <= 0 && %Collector/CollisionShape2D.disabled == true):
		%Collector/CollisionShape2D.disabled = false;
		_collect_timer = _collect_duration;

func is_collecting() -> bool:
	return %Collector/CollisionShape2D.disabled == false;














func check_objects():
	for key in world_state:
		#print(key)
		if (key.begins_with("nearest_") && is_instance_valid(world_state[key]) == false):
			world_state[key] = null;


func check_bonker_state():
	if (world_state["bonker_hp"] <= 0 && world_state["has_bonker"] == true):
		world_state["has_bonker"] = false;
	elif (world_state["bonker_hp"] > 0 && world_state["has_bonker"] == false):
		world_state["has_bonker"] = true;
	
	if (world_state["bonker_hp"] <= 0 && world_state["has_bonker"] == false) && %Bonker.visible == true:
		%Bonker.visible = false;
	elif (world_state["bonker_hp"] > 0 && world_state["has_bonker"] == true) && %Bonker.visible == false:
		%Bonker.visible = true;


func detect_satyr() -> bool:
	world_state["nearest_satyr"] = null;
	world_state["found_satyr"] = false;
	world_state["is_near_satyr"] = false;
	
	var objs: Array[CollisionObject2D] = [];
	objs.append_array(%Sensor.get_overlapping_areas());
	
	for obj in objs:
		if (obj.has_method("get_type") && obj.get_type() == "satyr"):
			var detect_dist: int = world_state.get("detect_dist_satyr")
			var other: CollisionObject2D = world_state.get("nearest_satyr") if is_instance_valid(world_state.get("nearest_satyr")) == true else null;
			if ( self.global_position.distance_to(obj.get_global_position()) < detect_dist
					&& (
					( other != null && self.global_position.distance_squared_to(obj.get_global_position()) 
							< self.global_position.distance_squared_to(other.get_global_position())
						)
						|| other == null
					)
			):
				world_state["nearest_satyr"] = obj;
				world_state["found_satyr"] = true;
				
			var near_obj: CollisionObject2D = world_state.get("nearest_satyr");
			var nearby: bool = false;
			if near_obj != null:
				nearby = self.global_position.distance_to(near_obj.get_global_position()) <= world_state["proximity_dist"];
			world_state["is_near_satyr"] = nearby;
	
	
	var bonker_hp: int = world_state.get("bonker_hp");
	var satyr: Area2D = world_state.get("nearest_satyr");
	var satyr_dist: float = -1 if satyr == null else self.global_position.distance_to(satyr.get_global_position());
	var alert_dist: int = world_state.get("alert_dist_satyr");
			
	if world_state["is_afraid"] == false && satyr_dist >= 0 && satyr_dist <= alert_dist && bonker_hp <= 0:
		world_state["is_afraid"] = true;
		goal_state.clear()
		goal_state["is_afraid"] = false;
		%PlannerAI.interrupt_plan();
		print("SATYR!")
	
	#print("is_afraid "+str( world_state["is_afraid"]))
	
	return world_state["is_afraid"];








# checks area for the nearest (excaliclubs, shrubs, hideouts, boars, satyr, foods, taco)
# and add them to dictionary
func scan_area() -> void: # include distance conditions (and food value for foods) for setting the nearest 
	_reset_states();
	var objs: Array[CollisionObject2D] = [];
	objs.append_array(%Sensor.get_overlapping_areas());
	
	for obj in objs:
		if (obj.has_method("get_type")):
			var type: String = obj.get_type();
			if world_state.has("nearest_"+type):
				var detect_dist: int = world_state.get("detect_dist_"+type)
				var other: CollisionObject2D = world_state.get("nearest_"+type)
				if ( self.global_position.distance_to(obj.get_global_position()) < detect_dist
						&& (
						( other != null && self.global_position.distance_squared_to(obj.get_global_position()) 
								< self.global_position.distance_squared_to(other.get_global_position())
							)
							|| other == null
						)
				):
					world_state["nearest_"+type] = obj;
					world_state["found_"+type] = true;
				
				var near_obj: CollisionObject2D = world_state.get("nearest_"+type);
				var nearby: bool = false;
				if near_obj != null:
					nearby = self.global_position.distance_to(near_obj.get_global_position()) <= world_state["proximity_dist"];
				world_state["is_near_"+type] = nearby;
			
			elif type == "meat" || type == "berry": # foods 
				var detect_dist: int = world_state.get("detect_dist_food")
				var other: CollisionObject2D = world_state.get("nearest_food")
				if ( self.global_position.distance_to(obj.get_global_position()) < detect_dist
						
						&& (
						( other != null && self.global_position.distance_squared_to(obj.get_global_position()) 
								< self.global_position.distance_squared_to(other.get_global_position()) 
							&& obj.food_points() >= other.food_points() 
							)
							|| other == null
						)
				):
					world_state["nearest_food"] = obj;
					world_state["found_food"] = true;
				
				var near_food: CollisionObject2D = world_state.get("nearest_food");
				var nearby: bool = false;
				if near_food != null:
					nearby = self.global_position.distance_to(near_food.get_global_position()) <= world_state["proximity_dist"];
				world_state["is_near_food"] = nearby;
	#print("scanning");


func _reset_states():
	world_state["nearest_satyr"] = null;
	world_state["nearest_taco"] = null;
	world_state["nearest_berry_bush"] = null;
	world_state["nearest_boar"] = null;
	world_state["nearest_excali-club"] = null;
	world_state["nearest_hideout"] = null;
	world_state["nearest_food"] = null;
	
	world_state["found_satyr"] = false;
	world_state["found_taco"] = false;
	world_state["found_berry_bush"] = false;
	world_state["found_boar"] = false;
	world_state["found_excali-club"] = false;
	world_state["found_hideout"] = false;
	world_state["found_food"] = false;
	
	world_state["is_near_satyr"] = false;
	world_state["is_near_taco"] = false;
	world_state["is_near_berry_bush"] = false;
	world_state["is_near_boar"] = false;
	world_state["is_near_excali-club"] = false;
	world_state["is_near_hideout"] = false;
	world_state["is_near_food"] = false;



















func _on_collector_area_entered(area: Area2D):
	#print("collect: "+str(area))
	if (area.has_method("get_type")):
		var type: String = area.get_type();
		match type:
			"excali-bonk":
				if ((world_state["bonker_hp"] <= 0 || world_state["has_bonker"] == false) and area.has_bonker() == true):
					world_state["has_bonker"] = area.get_bonker();
					world_state["bonker_hp"] = world_state["bonker_max_hp"];
			"berry_bush":
				if area.has_berry():
					area.drop_berry();
			"meat", "berry", "taco": # foods and taco
				var sat: int = world_state["satiation"];
				var max_sat: int = world_state["satiation_max"];
				var food = world_state["nearest_food"] if type != "taco" else world_state["nearest_taco"]
				if (sat < max_sat && food != null && food == area):
					world_state["satiation"] = clampf(sat + area.get_food(), 0, max_sat);
					if type == "taco":
						world_state["nearest_taco"] = null;
						world_state["found_taco"] = false;
						world_state["is_near_taco"] = false;
					else:
						world_state["nearest_food"] = null;
						world_state["found_food"] = false;
						world_state["is_near_food"] = false;
				
				sat = world_state["satiation"];
			_:
				pass



func _on_bonker_hit(_target: Area2D):
	#print("hit")
	_attack_hit = true;



func _on_animation_finished(anim_name: StringName) -> void:
	if (anim_name.begins_with("melee_")):
		if _attack_mode == true:
			if _attack_hit == true:
				world_state["bonker_hp"] -= 1;
				if (world_state["bonker_hp"] <= 0):
					world_state["has_bonker"] = false;
		#_attack_finished = true;
		_attack_hit = false;
		_attack_mode = false;
		return;
	#_attack_finished = false;
	return;







func _on_new_action_selected(action: GOAPAction):
	print("NEW ACTION SELECTED: "+str(action.get_name()));
	print();
	#print(world_state)

func _on_plan_interrupted():
	print("CURRENT PLAN IS INTERRUPTED!")
	print();

func _on_planning_finished(is_empty: bool):
	if (not is_empty):
		print("NEW PLAN WAS MADE!")
		print("Goal: "+str(goal_state))
		%PlannerAI.print_action_plan();
		print();
