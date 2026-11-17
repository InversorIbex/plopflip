extends Camera2D
## Soft lateral follow with look-ahead (GDD §8.2).

@export var target_path: NodePath
@export var follow_speed: float = 6.0
@export var look_ahead: float = 80.0

var target: Node2D


func _ready() -> void:
	if target_path:
		target = get_node_or_null(target_path)
	make_current()


func bind(t: Node2D) -> void:
	target = t


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var facing := 1.0
	if "facing" in target:
		facing = target.facing
	var desired := target.global_position + Vector2(look_ahead * facing, -40.0)
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))
