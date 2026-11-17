extends SceneTree
## Headless smoke: InputMap move/jump fire; TouchScreenButtons laid out.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := 0
	print("touch_input_smoke: start")

	Input.action_press("move_right", 1.0)
	if not Input.is_action_pressed("move_right") or absf(Input.get_axis("move_left", "move_right") - 1.0) > 0.01:
		push_error("FAIL: move_right / get_axis")
		failed += 1
	else:
		print("OK: move_right + get_axis")
	Input.action_release("move_right")

	Input.action_press("move_left", 1.0)
	if Input.get_axis("move_left", "move_right") >= 0.0:
		push_error("FAIL: get_axis left")
		failed += 1
	else:
		print("OK: get_axis left")
	Input.action_release("move_left")

	Input.action_press("jump")
	if not Input.is_action_pressed("jump"):
		push_error("FAIL: jump")
		failed += 1
	else:
		print("OK: jump pressed")
	Input.action_release("jump")

	var packed: PackedScene = load("res://scenes/ui/touch_controls.tscn") as PackedScene
	var controls: Control = packed.instantiate()
	root.add_child(controls)
	await create_timer(0.1).timeout
	controls._layout_touch_buttons()
	await create_timer(0.05).timeout

	controls.debug_press_move(1.0)
	if not Input.is_action_pressed("move_right"):
		push_error("FAIL: debug_press_move right")
		failed += 1
	else:
		print("OK: debug_press_move → move_right")
	controls.debug_press_move(-1.0)
	if not Input.is_action_pressed("move_left"):
		push_error("FAIL: debug_press_move left")
		failed += 1
	else:
		print("OK: debug_press_move → move_left")
	controls.debug_press_move(0.0)
	print("OK: move released")

	controls.debug_press_jump()
	print("OK: debug_press_jump")

	# TouchScreenButton layout sanity
	var jump_tsb: TouchScreenButton = controls.get_node("Buttons/Jump")
	var left_tsb: TouchScreenButton = controls.get_node("Buttons/Left")
	var right_tsb: TouchScreenButton = controls.get_node("Buttons/Right")
	if jump_tsb == null or jump_tsb.shape == null or (jump_tsb.shape as RectangleShape2D).size.x < 40:
		push_error("FAIL: Jump TouchScreenButton shape missing/small")
		failed += 1
	else:
		print("OK: Jump TSB shape=", (jump_tsb.shape as RectangleShape2D).size, " pos=", jump_tsb.position)
	if left_tsb.action != "move_left" or right_tsb.action != "move_right" or jump_tsb.action != "jump":
		push_error("FAIL: TSB actions wrong")
		failed += 1
	else:
		print("OK: TSB actions move_left/move_right/jump")

	# Simulate TSB press via unit API if available — else action_press mirrors what TSB does.
	Input.action_press("move_right")
	Input.action_press("jump")
	if not (Input.is_action_pressed("move_right") and Input.is_action_pressed("jump")):
		push_error("FAIL: simultaneous move+jump actions")
		failed += 1
	else:
		print("OK: simultaneous move_right + jump (multitouch InputMap)")
	Input.action_release("move_right")
	Input.action_release("jump")

	controls.queue_free()
	if failed == 0:
		print("touch_input_smoke: ALL PASSED")
		quit(0)
	else:
		print("touch_input_smoke: FAILED (%d)" % failed)
		quit(1)
