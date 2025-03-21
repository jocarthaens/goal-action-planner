extends Area2D

@export var food_name: String;
@export_range(0, 20) var food_point: int = 1;
#@export var pickup_time: float = 5.0
#@export var collider_shape: CollisionShape2D;

var _timer: float = 0.0;

var _free_self: bool = false;

func _ready() -> void:
	#collider_shape.disabled = false;
	pass

func _physics_process(delta: float) -> void:
	#_timer += delta;
	#if (_timer >= pickup_time):
	#	collider_shape.disabled = false;
	if (_free_self == true):
		get_parent().remove_child(self);
		self.queue_free();

func get_food():
	_free_self = true;
	return food_point;



func get_type() -> String:
	return food_name;



func food_points():
	return food_point
