extends Area2D

var grow_time: float = 10.0
var _is_fruiting: bool = false;
var _timer: float = 4.0;
var _drop_command: bool = false;

@onready var collider_shape: CollisionShape2D = %CollisionShape2D
@onready var sprite: Sprite2D = %Sprites
@onready var berry = preload("res://scenes/food_berry.tscn");

func _ready() -> void:
	_is_fruiting = false;
	randomize();
	_timer = randf_range(0, 10);

func _physics_process(delta: float) -> void:
	if (_drop_command == true):
		drop_item();
	if (_is_fruiting == false):
		sprite.frame = 1;
		collider_shape.disabled = true;
		_timer += delta;
		if (_timer >= grow_time):
			_is_fruiting = true;
			sprite.frame = 0;
			collider_shape.disabled = false
			_timer = 0.0;


func has_berry():
	return _is_fruiting;

func drop_berry():
	if (_is_fruiting == true):
		_drop_command = true;

func drop_item():
	var drop = berry.instantiate();
	#drop.pickup_time = 1.0;
	randomize()
	drop.position = position + Vector2(randi_range(-8, 8), randi_range(-8, 8));
	get_parent().add_child(drop);
	_drop_command = false;
	_is_fruiting = false;

func get_type() -> String:
	return "berry_bush";
