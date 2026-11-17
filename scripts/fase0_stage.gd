extends Node2D
## Fase 0 vertical slice wiring — bind UI to player, reset run state.

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var touch: Node = $UI/TouchControls


func _ready() -> void:
	GameState.reset_run()
	if camera and camera.has_method("bind"):
		camera.bind(player)
	if touch and touch.has_method("bind_player"):
		touch.bind_player(player)
	player.add_to_group("player")
	# Optional: godot … -- --demo
	if "--demo" in OS.get_cmdline_user_args():
		var demo := preload("res://scripts/demo_capture.gd").new()
		add_child(demo)
