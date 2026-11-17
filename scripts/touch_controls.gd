extends Control
## Virtual landscape controls — left pad, jump + tongue on the right (GDD §8.1).

@export var player_path: NodePath

var player: Node
var pad_touch_index: int = -1
var pad_origin: Vector2 = Vector2.ZERO

@onready var pad_area: Control = $LeftPad
@onready var pad_knob: Control = $LeftPad/Knob
@onready var btn_jump: Button = $RightButtons/Jump
@onready var btn_tongue: Button = $RightButtons/Tongue
@onready var btn_down: Button = $RightButtons/Down


func _ready() -> void:
	if player_path:
		player = get_node_or_null(player_path)
	btn_jump.button_down.connect(func() -> void:
		if player and player.has_method("press_jump"):
			player.press_jump()
	)
	btn_tongue.button_down.connect(func() -> void:
		if player and player.has_method("press_tongue"):
			player.press_tongue()
	)
	btn_down.button_down.connect(func() -> void:
		if player and player.has_method("set_touch_down"):
			player.set_touch_down(true)
	)
	btn_down.button_up.connect(func() -> void:
		if player and player.has_method("set_touch_down"):
			player.set_touch_down(false)
	)


func bind_player(p: Node) -> void:
	player = p


func _gui_input(event: InputEvent) -> void:
	# Fallback — pad handled in LeftPad
	pass


func _on_left_pad_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			pad_touch_index = st.index
			pad_origin = pad_area.size * 0.5
			_update_pad(st.position)
		elif st.index == pad_touch_index:
			pad_touch_index = -1
			_reset_pad()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == pad_touch_index:
			_update_pad(sd.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				pad_touch_index = 0
				_update_pad(mb.position)
			else:
				pad_touch_index = -1
				_reset_pad()
	elif event is InputEventMouseMotion and pad_touch_index == 0:
		_update_pad((event as InputEventMouseMotion).position)


func _update_pad(local_pos: Vector2) -> void:
	var center := pad_area.size * 0.5
	var delta := local_pos - center
	var max_r := minf(pad_area.size.x, pad_area.size.y) * 0.35
	if delta.length() > max_r:
		delta = delta.normalized() * max_r
	pad_knob.position = center + delta - pad_knob.size * 0.5
	var axis := clampf(delta.x / max_r, -1.0, 1.0)
	var down := delta.y > max_r * 0.55
	if player:
		if player.has_method("set_touch_axis"):
			player.set_touch_axis(axis)
		if player.has_method("set_touch_down"):
			player.set_touch_down(down)


func _reset_pad() -> void:
	pad_knob.position = pad_area.size * 0.5 - pad_knob.size * 0.5
	if player:
		if player.has_method("set_touch_axis"):
			player.set_touch_axis(0.0)
		if player.has_method("set_touch_down"):
			player.set_touch_down(false)
