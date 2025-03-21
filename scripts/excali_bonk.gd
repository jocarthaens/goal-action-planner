extends Area2D

var recover_time: float = 20.0
var contains_bonker: bool = false;
var _timer: float = 15.0;

@onready var collider_shape: CollisionShape2D = %CollisionShape2D
@onready var sprite: Sprite2D = %Sprites

func _ready() -> void:
	contains_bonker = false;
	randomize();
	_timer = randf_range(12, 20);

func _physics_process(delta: float) -> void:
	if (contains_bonker == false):
		sprite.frame = 1;
		collider_shape.disabled = true;
		_timer += delta;
		if (_timer >= recover_time):
			contains_bonker = true;
			sprite.frame = 0;
			collider_shape.disabled = false
			_timer = 0.0;



func get_bonker():
	if (contains_bonker == true):
		contains_bonker = false;
		return true;
	return false;

func has_bonker():
	return contains_bonker;



func get_type() -> String:
	return "excali-bonk";
