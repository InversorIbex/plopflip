extends CharacterBody2D
## E1 Masticón — slow horizontal patrol; tongue ×1 or stomp (GDD §4.2).

const PATROL_SPEED := 55.0

@onready var visual: Node2D = $Visual
@onready var ray_left: RayCast2D = $RayLeft
@onready var ray_right: RayCast2D = $RayRight

var direction: float = -1.0
var alive: bool = true


func _ready() -> void:
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if not alive:
		return
	if not is_on_floor():
		velocity.y += 900.0 * delta
	else:
		velocity.y = 0.0

	# Turn at edges / walls
	var floor_ahead := ray_left.is_colliding() if direction < 0.0 else ray_right.is_colliding()
	if is_on_wall() or (is_on_floor() and not floor_ahead):
		direction *= -1.0
		visual.scale.x = absf(visual.scale.x) * direction

	velocity.x = direction * PATROL_SPEED
	move_and_slide()
	# Gentle wobble
	visual.rotation = sin(Time.get_ticks_msec() * 0.008) * 0.08


func hit_by_tongue() -> void:
	_defeat()


func stomp() -> void:
	_defeat()


func _defeat() -> void:
	if not alive:
		return
	alive = false
	# Soft "sugar poof" — fade and free
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2(1.6, 0.2), 0.12)
	tween.parallel().tween_property(visual, "modulate:a", 0.0, 0.18)
	tween.tween_callback(queue_free)
	# Drop a small caramelo sometimes
	if randf() < 0.7:
		var drop := preload("res://scenes/pickups/caramelo.tscn").instantiate()
		drop.global_position = global_position + Vector2(0, -12)
		get_parent().call_deferred("add_child", drop)
