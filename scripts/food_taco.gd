extends Area2D

@export var food_name: String;
@export_range(0, 20) var food_point: int = 1;
@onready var shape: CollisionShape2D = %TacoShape;

var recover_time: float = 45.0
var _timer: float = 0.0;
var _manifest_taco: bool = true;

func _ready() -> void:
	_manifest_taco = false;
	randomize();
	_timer = randf_range(30, 45);

func _physics_process(delta: float) -> void:
	if (_manifest_taco == false):
		visible = false;
		shape.disabled = true;
		_timer += delta;
		if _timer >= recover_time:
			_manifest_taco = true;
			visible = true;
			shape.disabled = false;
			_timer = 0;


func get_food():
	_manifest_taco = false;
	return food_point;


func get_type() -> String:
	return food_name;


func food_points():
	return food_point
