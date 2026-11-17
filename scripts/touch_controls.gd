extends Control
## Android multitouch controls.
## Gameplay actions: TouchScreenButton → InputMap (multi-finger safe).
## Visible pad/buttons are cosmetics; hit shapes are laid out over them.

@export var player_path: NodePath
var player: Node

@onready var pad_area: Control = $LeftPad
@onready var pad_knob: Control = $LeftPad/Knob


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if player_path:
		player = get_node_or_null(player_path)
	_setup_ui_filters()
	_reset_pad_visual()
	_layout_touch_buttons()
	get_viewport().size_changed.connect(_layout_touch_buttons)
	call_deferred("_layout_touch_buttons")
	var relay := Node.new()
	relay.name = "StickInputRelay"
	relay.set_script(preload("res://scripts/touch_input_relay.gd"))
	add_child(relay)


func bind_player(p: Node) -> void:
	player = p


func _setup_ui_filters() -> void:
	for path in ["LeftPad", "RightButtons/Jump", "RightButtons/Tongue", "RightButtons/Down"]:
		var node := get_node_or_null(path)
		if node is Control:
			(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		if node is BaseButton:
			(node as BaseButton).focus_mode = Control.FOCUS_NONE
	if pad_area:
		for child in pad_area.get_children():
			if child is Control:
				(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _layout_touch_buttons() -> void:
	_place($Buttons/Jump, $RightButtons/Jump)
	_place($Buttons/Tongue, $RightButtons/Tongue)
	_place($Buttons/Down, $RightButtons/Down)
	if pad_area and pad_area.size.x > 4.0:
		_place($Buttons/Left, pad_area, Rect2(0, 0, 0.5, 1))
		_place($Buttons/Right, pad_area, Rect2(0.5, 0, 0.5, 1))
	else:
		var vp := get_viewport().get_visible_rect().size
		_place_rect($Buttons/Left, Rect2(16, vp.y - 280, 130, 260))
		_place_rect($Buttons/Right, Rect2(150, vp.y - 280, 130, 260))
		_place_rect($Buttons/Jump, Rect2(vp.x - 200, vp.y - 240, 160, 160))
		_place_rect($Buttons/Tongue, Rect2(vp.x - 340, vp.y - 280, 140, 140))
		_place_rect($Buttons/Down, Rect2(vp.x - 180, vp.y - 360, 120, 100))


func _place(tsb: TouchScreenButton, ctrl: Control, sub: Rect2 = Rect2(0, 0, 1, 1)) -> void:
	if tsb == null or ctrl == null:
		return
	var top_left := ctrl.get_global_transform_with_canvas() * (ctrl.size * sub.position)
	var size := ctrl.size * sub.size
	_place_rect(tsb, Rect2(top_left - Vector2(12, 12), size + Vector2(24, 24)))


func _place_rect(tsb: TouchScreenButton, rect: Rect2) -> void:
	if tsb == null:
		return
	tsb.position = rect.position + rect.size * 0.5
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	tsb.shape = shape
	tsb.passby_press = true


func _reset_pad_visual() -> void:
	if pad_area and pad_knob:
		pad_knob.position = pad_area.size * 0.5 - pad_knob.size * 0.5


func handle_input_event(event: InputEvent) -> void:
	# Knob follow only — InputMap comes from TouchScreenButtons.
	var pos := Vector2.ZERO
	var pressed := false
	var tracking := false
	if event is InputEventScreenTouch:
		pos = (event as InputEventScreenTouch).position
		pressed = (event as InputEventScreenTouch).pressed
		tracking = true
	elif event is InputEventScreenDrag:
		pos = (event as InputEventScreenDrag).position
		pressed = true
		tracking = true
	elif not DisplayServer.is_touchscreen_available():
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			pos = (event as InputEventMouseButton).position
			pressed = (event as InputEventMouseButton).pressed
			tracking = true
		elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			pos = (event as InputEventMouseMotion).position
			pressed = true
			tracking = true
	if not tracking:
		return
	if not _point_in_pad(pos):
		if not pressed:
			_reset_pad_visual()
		return
	if pressed:
		_follow_knob(pos)
	else:
		_reset_pad_visual()


func _point_in_pad(screen_pos: Vector2) -> bool:
	if pad_area == null:
		return false
	var local := pad_area.get_global_transform_with_canvas().affine_inverse() * screen_pos
	return Rect2(Vector2(-24, -24), pad_area.size + Vector2(48, 48)).has_point(local)


func _follow_knob(screen_pos: Vector2) -> void:
	if pad_area == null or pad_knob == null:
		return
	var local := pad_area.get_global_transform_with_canvas().affine_inverse() * screen_pos
	var center := pad_area.size * 0.5
	var delta := local - center
	var max_r := minf(pad_area.size.x, pad_area.size.y) * 0.42
	if max_r > 1.0 and delta.length() > max_r:
		delta = delta.normalized() * max_r
	if max_r > 1.0:
		pad_knob.position = center + delta - pad_knob.size * 0.5
		var axis := clampf(delta.x / max_r, -1.0, 1.0)
		if player and player.has_method("set_touch_axis"):
			player.set_touch_axis(axis)
		if player and player.has_method("set_touch_down"):
			player.set_touch_down(delta.y > max_r * 0.55 or Input.is_action_pressed("move_down"))


func debug_press_move(axis: float) -> void:
	if axis < -0.2:
		if Input.is_action_pressed("move_right"):
			Input.action_release("move_right")
		Input.action_press("move_left", absf(axis))
	elif axis > 0.2:
		if Input.is_action_pressed("move_left"):
			Input.action_release("move_left")
		Input.action_press("move_right", absf(axis))
	else:
		if Input.is_action_pressed("move_left"):
			Input.action_release("move_left")
		if Input.is_action_pressed("move_right"):
			Input.action_release("move_right")
	if player and player.has_method("set_touch_axis"):
		player.set_touch_axis(axis)


func debug_press_jump() -> void:
	Input.action_press("jump")
	if player and player.has_method("press_jump"):
		player.press_jump()
	Input.action_release("jump")


func debug_press_tongue() -> void:
	Input.action_press("tongue")
	if player and player.has_method("press_tongue"):
		player.press_tongue()
	Input.action_release("tongue")
