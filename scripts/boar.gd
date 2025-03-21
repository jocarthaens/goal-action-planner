extends Area2D



var idle_time: float = 2.0;
var move_time: float = 5.0;
var sleep_time: float = 30.0;
var _timer: float = 0.0;

var _rand_pos: Vector2 = Vector2();
var _spawn_pos: Vector2;
var dist_from_spawn: int = 96;
var speed: int = 64;

var _face_direction: String = "right";
var _mode: String = "idle"; # Modes: Idle, Moving, Sleep, Awake

@onready var entity = get_parent();
@onready var _collider_box = $"../ColliderBox"
@onready var _hurt_area = $HurtArea
@onready var _ray: RayCast2D = %RayCast2D

@onready var animator = %AnimationPlayer;
var _stop_sleep_anim = false;

@onready var meat = preload("res://scenes/food_meat.tscn");
var _drop_item: bool = false;



func _ready():
	_spawn_pos = entity.position;
	randomize();
	_timer = randf_range(0,100);
	animator.animation_finished.connect(_on_animation_finished);


func _physics_process(delta: float) -> void:
	_timer += delta;
	match _mode:
		"idle":
			if _timer >= idle_time:
				_timer = 0;
				_rand_pos = _spawn_pos + Vector2(randf_range(-dist_from_spawn, dist_from_spawn), randf_range(-dist_from_spawn, dist_from_spawn));
				while (_rand_pos.distance_to(_spawn_pos) > dist_from_spawn):
					randomize();
					_rand_pos = _spawn_pos + Vector2(randi_range(-dist_from_spawn, dist_from_spawn), randi_range(-dist_from_spawn, dist_from_spawn));
				_mode = "moving";
		"moving":
			if _ray.is_colliding():
				_rand_pos = _spawn_pos + Vector2(randf_range(-dist_from_spawn, dist_from_spawn), randf_range(-dist_from_spawn, dist_from_spawn));
				while (_rand_pos.distance_to(_spawn_pos) > dist_from_spawn):
					randomize();
					_rand_pos = _spawn_pos + Vector2(randi_range(-dist_from_spawn, dist_from_spawn), randi_range(-dist_from_spawn, dist_from_spawn));
			var direction: Vector2 = entity.position.direction_to(_rand_pos) * speed;
			entity.velocity = direction;
			_ray.set_rotation(direction.angle())
			entity.move_and_slide();
			if entity.position.distance_to(_rand_pos) <= 1 or _timer >= move_time:
				_timer = 0;
				_mode = "idle";
		"sleep":
			_set_colliders(true);
			if (_stop_sleep_anim == true && _drop_item == true):
				entity.visible = false;
				drop_item();
				#entity.queue_free();###
			if _timer >= sleep_time:
				_timer = 0;
				_mode = "awake";
				_stop_sleep_anim = false;
		"awake":
			entity.visible = true;
			if (_stop_sleep_anim == true):
				_mode = "idle";
				_stop_sleep_anim = false;
				_set_colliders(false);
		_:
			_mode = "idle";
	
	if entity.velocity.x > 0: _face_direction = "right";
	elif entity.velocity.x <0: _face_direction = "left";
	
	animation();

func animation():
	match _mode:
		"idle":
			animator.play("idle_"+_face_direction);
		"moving":
			animator.play("walk_"+_face_direction);
		"sleep":
			if (_stop_sleep_anim == true):
				return
			animator.play("sleep_"+_face_direction);
		"awake":
			if (_stop_sleep_anim == true):
				return
			animator.play_backwards("sleep_"+_face_direction);


func _set_colliders(disable_colliders: bool):
	_collider_box.disabled = disable_colliders;
	_hurt_area.disabled = disable_colliders;







func drop_item():
	var drop = meat.instantiate();
	#drop.pickup_time = 1.0;
	randomize()
	drop.position = entity.position + Vector2(randi_range(-8, 8), randi_range(-8, 8));
	entity.get_parent().add_child(drop);
	_drop_item = false;
	#queue_free();

func hurt():
	_mode = "sleep";
	_drop_item = true;

func get_type() -> String:
	return "boar";

func get_state() -> String:
	return _mode;

func is_despawned() -> bool:
	return not entity.visible;






func _on_hurt_box_area_entered(area: Area2D) -> void:
	hurt()

func _on_animation_finished(anim_name: String):
	if (anim_name.begins_with("sleep")):
		_stop_sleep_anim = true;
		return;
	_stop_sleep_anim = false;
