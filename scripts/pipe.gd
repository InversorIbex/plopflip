extends Area2D
## Pipe / tube warp stub — hold ↓ (or interact) on entrance to teleport (GDD §3.1).

@export var exit_path: NodePath
@export var suck_duration: float = 0.35

@onready var label: Label = $Hint

var exit_node: Node2D
var busy: bool = false


func _ready() -> void:
	if exit_path:
		exit_node = get_node_or_null(exit_path)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_process(false)
	if label:
		label.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		set_process(true)
		if label:
			label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		set_process(false)
		if label:
			label.visible = false


func _process(_delta: float) -> void:
	if busy or exit_node == null:
		return
	var players := get_overlapping_bodies()
	for p in players:
		if not p.is_in_group("player"):
			continue
		var wants := Input.is_action_pressed("move_down") or Input.is_action_just_pressed("interact")
		if p.has_method("set_touch_down") and p.get("touch_down"):
			wants = true
		if wants:
			_warp(p)
			break


func _warp(player: Node2D) -> void:
	busy = true
	if label:
		label.visible = false
	var tween := create_tween()
	tween.tween_property(player, "scale", Vector2(0.2, 0.2), suck_duration * 0.5)
	tween.tween_callback(func() -> void:
		player.global_position = exit_node.global_position
		player.scale = Vector2(0.2, 0.2)
		if player is CharacterBody2D:
			(player as CharacterBody2D).velocity = Vector2.ZERO
	)
	tween.tween_property(player, "scale", Vector2.ONE, suck_duration * 0.5)
	tween.tween_callback(func() -> void:
		busy = false
	)
