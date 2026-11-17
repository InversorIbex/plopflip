extends Node
## Drive the player briefly and save PNGs (run with: godot -- --demo).

var player: CharacterBody2D
var step: int = 0
var timer: float = 0.0
var shots: int = 0
var out_dir: String = ""


func _ready() -> void:
	out_dir = OS.get_user_data_dir().path_join("fase0_demo")
	DirAccess.make_dir_recursive_absolute(out_dir)
	await get_tree().process_frame
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		push_error("DEMO: Player not found")
		get_tree().quit(1)
		return
	print("DEMO: out_dir=", out_dir)
	_save("01_spawn")


func _physics_process(delta: float) -> void:
	if player == null:
		return
	timer += delta
	match step:
		0:
			player.set_touch_axis(1.0)
			if timer > 0.9:
				_save("02_running")
				_advance()
		1:
			player.set_touch_axis(1.0)
			player.press_jump()
			_advance()
		2:
			player.set_touch_axis(1.0)
			if timer > 0.28:
				player.press_jump()
				_save("03_air_stretch")
				_advance()
		3:
			player.set_touch_axis(1.0)
			if timer > 0.7:
				player.set_touch_axis(0.0)
				_advance()
		4:
			player.set_touch_down(true)
			if timer > 0.45:
				_save("04_crouch")
				player.set_touch_down(false)
				_advance()
		5:
			player.set_touch_axis(1.0)
			if timer > 1.0:
				player.press_tongue()
				_save("05_tongue")
				_advance()
		6:
			player.set_touch_axis(1.0)
			if timer > 1.6:
				_save("06_stage_overview")
				_advance()
		7:
			print("DEMO: complete shots=", shots, " dir=", out_dir)
			get_tree().quit(0)


func _advance() -> void:
	step += 1
	timer = 0.0


func _save(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if img == null:
		push_warning("DEMO: no image for " + name)
		return
	var path := out_dir.path_join(name + ".png")
	var err := img.save_png(path)
	print("DEMO: saved ", path, " err=", err)
	shots += 1
