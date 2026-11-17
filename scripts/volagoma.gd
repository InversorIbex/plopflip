extends CharacterBody2D
## E3 Volagoma — sine-wave flyer; tongue ×1.

@onready var visual: Node2D = $Visual

var base_y: float = 0.0
var phase: float = 0.0
var dir: float = 1.0
var alive: bool = true
const SPEED := 70.0


func _ready() -> void:
	add_to_group("enemies")
	base_y = global_position.y
	phase = randf() * TAU
	collision_layer = 4
	collision_mask = 3


func _physics_process(delta: float) -> void:
	if not alive:
		return
	phase += delta * 2.2
	var spd := SPEED * GameState.enemy_speed_mult()
	velocity.x = dir * spd
	velocity.y = 0.0
	global_position.y = base_y + sin(phase) * 36.0
	move_and_slide()
	if is_on_wall():
		dir *= -1.0
	# Soft bounds turn
	if global_position.x < 40.0:
		dir = 1.0
	visual.rotation = sin(phase) * 0.2


func hit_by_tongue() -> void:
	_defeat()


func stomp() -> void:
	_defeat()


func _defeat() -> void:
	if not alive:
		return
	alive = false
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2(1.5, 0.3), 0.12)
	tween.parallel().tween_property(visual, "modulate:a", 0.0, 0.18)
	tween.tween_callback(queue_free)
	if randf() < 0.6:
		var drop := preload("res://scenes/pickups/caramelo.tscn").instantiate()
		drop.global_position = global_position
		get_parent().call_deferred("add_child", drop)
