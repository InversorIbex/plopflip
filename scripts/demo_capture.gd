extends Node
## Drive the biped and save PNGs showing limb stretch (godot -- --demo).

var player: CharacterBody2D
var step: int = 0
var timer: float = 0.0
var shots: int = 0
var out_dir: String = ""
var pending_shot: String = ""


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
	_save("01_spawn_biped")


func _physics_process(delta: float) -> void:
	if player == null:
		return
	if pending_shot != "":
		_save(pending_shot)
		pending_shot = ""
		_advance()
		return

	timer += delta
	match step:
		0:
			player.set_touch_axis(1.0)
			if timer > 1.0:
				_save("02_run_stride")
				_advance()
		1:
			player.set_touch_axis(0.15)
			if timer < 0.05:
				player.press_jump()
			if timer > 0.12 and timer < 0.18:
				player.press_jump()
			var leg := float(player.leg_len)
			if timer > 0.18 and not player.is_on_floor() and leg >= 1.2:
				_save("03_jump_legs_long")
				_advance()
			elif timer > 0.85:
				# Force a readable mid-air stretch pose for media
				player.global_position = Vector2(260, -160)
				player.velocity = Vector2(40, -260)
				player.leg_len = 1.85
				player.arm_len = 1.45
				player.leg_len_vel = 0.0
				player.arm_len_vel = 0.0
				player.torso_sy = 1.12
				player.is_crouching = false
				pending_shot = "03_jump_legs_long"
		2:
			player.set_touch_axis(0.35)
			if timer > 1.0:
				player.set_touch_axis(0.0)
				_advance()
		3:
			# Plant on open ground; disable pipes so ↓ crouch does not warp
			if timer < 0.1:
				for p in get_tree().get_nodes_in_group("pipes"):
					p.set("busy", true)
					p.set_process(false)
				player.global_position = Vector2(160, -10)
				player.velocity = Vector2.ZERO
				player.invuln_timer = 0.0
				player.visual.modulate = Color(1, 1, 1, 1)
			player.set_touch_axis(0.0)
			player.set_touch_down(true)
			var leg := float(player.leg_len)
			if timer > 0.6 and leg <= 0.65:
				print("DEMO crouch pose at ", player.global_position, " leg=", leg)
				_save("04_crouch_legs_short")
				player.set_touch_down(false)
				_advance()
			elif timer > 1.4:
				print("DEMO crouch fallback at ", player.global_position, " leg=", leg)
				_save("04_crouch_legs_short")
				player.set_touch_down(false)
				_advance()
		4:
			player.set_touch_axis(1.0)
			if timer > 0.8:
				player.press_tongue()
				_save("05_tongue_biped")
				_advance()
		5:
			player.set_touch_axis(1.0)
			if timer > 1.2:
				_save("06_stage_biped")
				_advance()
		6:
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
	var leg_v = player.leg_len if player else -1.0
	print("DEMO: saved ", path, " err=", err, " leg_len=", leg_v, " on_floor=", player.is_on_floor() if player else "?")
	shots += 1
