extends Node2D
## Builds and runs one stage from LevelCatalog data.

const LevelCatalog = preload("res://scripts/level_catalog.gd")

signal stage_finished(result: Dictionary)
signal player_died()

var level: Dictionary = {}
var player: CharacterBody2D
var camera: Camera2D
var touch: Control
var hud: Control
var finished: bool = false
var _entities: Node2D


func setup(world: int, stage: int) -> void:
	level = LevelCatalog.get_level(world, stage)
	GameState.current_world = world
	GameState.current_stage = stage
	GameState.reset_run()
	_clear_children()
	_entities = Node2D.new()
	_entities.name = "Entities"
	add_child(_entities)
	_build_backdrop()
	_build_geometry()
	_spawn_pickups()
	_spawn_enemies()
	_spawn_goal()
	_spawn_player()
	_spawn_ui()
	finished = false


func _clear_children() -> void:
	for c in get_children():
		c.queue_free()


func _process(delta: float) -> void:
	if finished or player == null:
		return
	GameState.stage_time += delta
	if GameState.lives <= 0:
		finished = true
		player_died.emit()
		return
	# Fall death
	if player.global_position.y > 420.0:
		GameState.take_damage(99)
		if GameState.lives > 0:
			player.global_position = level["spawn"]
			player.velocity = Vector2.ZERO
			GameState.hp = GameState.HP_DEFAULT
			GameState.hp_changed.emit(GameState.hp)


func _build_backdrop() -> void:
	var sky_c: Color = level.get("sky", Color(0.6, 0.8, 0.95))
	var bg := Polygon2D.new()
	bg.z_index = -20
	bg.color = sky_c
	var length: float = level.get("length", 2400.0)
	bg.polygon = PackedVector2Array([
		Vector2(-300, -900), Vector2(length + 400, -900),
		Vector2(length + 400, 500), Vector2(-300, 500)
	])
	add_child(bg)
	var theme: String = level.get("theme", "factory")
	for i in 7:
		var hill := Polygon2D.new()
		hill.z_index = -18
		var x := i * 360.0 - 100.0
		match theme:
			"sewer":
				hill.color = Color(0.18, 0.22, 0.3, 0.8)
			"garden":
				hill.color = Color(0.4, 0.75, 0.45, 0.5)
			_:
				hill.color = Color(0.7, 0.9, 0.75, 0.5)
		hill.polygon = PackedVector2Array([
			Vector2(x, 40), Vector2(x + 200, -70 - (i % 3) * 25), Vector2(x + 400, 40)
		])
		add_child(hill)
	# Title banner
	var label := Label.new()
	label.text = str(level.get("title", "Stage"))
	label.position = Vector2(40, -360)
	label.add_theme_font_size_override("font_size", 22)
	label.modulate = Color(0.15, 0.12, 0.2, 0.85) if theme != "sewer" else Color(0.9, 0.95, 1.0, 0.8)
	add_child(label)


func _build_geometry() -> void:
	var ground_c: Color = level.get("ground", Color(0.4, 0.3, 0.5))
	var plat_c: Color = level.get("plat", Color(0.95, 0.55, 0.7))
	var plats: Array = level.get("platforms", [])
	for i in plats.size():
		var r: Rect2 = plats[i]
		var c := ground_c if i == 0 or r.size.y >= 40 else plat_c
		_add_platform(r, c)
	for crawl in level.get("crawl", []):
		_add_platform(crawl, plat_c.darkened(0.15))
	for stair in level.get("stairs", []):
		_add_stairs(stair, plat_c)
	for t in level.get("trampolines", []):
		_add_trampoline(t)
	for w in level.get("water", []):
		_add_water(w)
	for p in level.get("pipes", []):
		_add_pipe(p["from"], p["to"])


func _add_platform(rect: Rect2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)
	var poly := Polygon2D.new()
	var hx := rect.size.x * 0.5
	var hy := rect.size.y * 0.5
	poly.polygon = PackedVector2Array([Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)])
	poly.color = color
	body.add_child(poly)
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, -hy + 5), Vector2(-hx, -hy + 5)])
	top.color = color.lightened(0.28)
	body.add_child(top)
	add_child(body)


func _add_stairs(data: Dictionary, color: Color) -> void:
	var x: float = data["x"]
	var y: float = data["y"]
	var steps: int = data["steps"]
	var w: float = data["w"]
	var h: float = data["h"]
	for i in steps:
		_add_platform(Rect2(x + i * w, y - (i + 1) * h, w + 4, h), color.lightened(0.05 * (i % 2)))


func _add_trampoline(rect: Rect2) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	area.add_child(shape)
	var poly := Polygon2D.new()
	var hx := rect.size.x * 0.5
	var hy := rect.size.y * 0.5
	poly.polygon = PackedVector2Array([Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)])
	poly.color = Color(0.4, 0.95, 0.7)
	area.add_child(poly)
	area.body_entered.connect(func(b: Node2D) -> void:
		if b.is_in_group("player") and b.velocity.y >= 0.0:
			b.velocity.y = -560.0
			if b.has_method("boost_stretch"):
				b.boost_stretch()
	)
	add_child(area)


func _add_water(rect: Rect2) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	area.add_child(shape)
	var poly := Polygon2D.new()
	var hx := rect.size.x * 0.5
	var hy := rect.size.y * 0.5
	poly.polygon = PackedVector2Array([Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)])
	poly.color = Color(0.35, 0.7, 0.95, 0.55)
	area.add_child(poly)
	var cooled := {}
	area.body_entered.connect(func(b: Node2D) -> void:
		if b.is_in_group("player"):
			var id := b.get_instance_id()
			if cooled.get(id, false):
				return
			cooled[id] = true
			GameState.remove_fat(2)
	)
	add_child(area)


func _add_pipe(from: Vector2, to: Vector2) -> void:
	var pipe := preload("res://scenes/level/pipe.tscn").instantiate()
	pipe.position = from
	pipe.warp_target = to
	pipe.use_warp_target = true
	add_child(pipe)
	var exit_v := Polygon2D.new()
	exit_v.position = to
	exit_v.color = Color(0.2, 0.55, 0.35)
	exit_v.polygon = PackedVector2Array([
		Vector2(-18, -28), Vector2(18, -28), Vector2(18, 8), Vector2(-18, 8)
	])
	exit_v.z_index = -1
	add_child(exit_v)


func _spawn_pickups() -> void:
	for p in level.get("pickups", []):
		var kind: String = p["kind"]
		var pos: Vector2 = p["pos"]
		match kind:
			"water":
				var drop := preload("res://scenes/pickups/water_drop.tscn").instantiate()
				drop.position = pos
				_entities.add_child(drop)
			_:
				var c := preload("res://scenes/pickups/caramelo.tscn").instantiate()
				c.position = pos
				match kind:
					"engordante":
						c.set("kind", 1)  # Kind.ENGORDANTE
					"grande":
						c.set("kind", 2)  # Kind.GRANDE
					_:
						c.set("kind", 0)
				_entities.add_child(c)
	var si := 0
	for sp in level.get("stars", []):
		var star := preload("res://scenes/pickups/star.tscn").instantiate()
		star.position = sp
		star.star_index = si
		si += 1
		_entities.add_child(star)


func _spawn_enemies() -> void:
	for e in level.get("enemies", []):
		var t: String = e["type"]
		var pos: Vector2 = e["pos"]
		var node: Node2D
		match t:
			"pincho":
				node = preload("res://scenes/enemies/pincho.tscn").instantiate()
			"volagoma":
				node = preload("res://scenes/enemies/volagoma.tscn").instantiate()
			_:
				node = preload("res://scenes/enemies/masticon.tscn").instantiate()
		node.position = pos
		_entities.add_child(node)


func _spawn_goal() -> void:
	var goal := Area2D.new()
	goal.collision_layer = 0
	goal.collision_mask = 2
	goal.position = level["goal"]
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(40, 64)
	shape.shape = rs
	goal.add_child(shape)
	var pole := Polygon2D.new()
	pole.polygon = PackedVector2Array([Vector2(-4, -56), Vector2(4, -56), Vector2(4, 20), Vector2(-4, 20)])
	pole.color = Color(0.9, 0.9, 0.95)
	goal.add_child(pole)
	var flag := Polygon2D.new()
	flag.polygon = PackedVector2Array([Vector2(4, -54), Vector2(36, -40), Vector2(4, -26)])
	flag.color = Color(1.0, 0.85, 0.2)
	goal.add_child(flag)
	goal.body_entered.connect(_on_goal)
	add_child(goal)


func _on_goal(body: Node2D) -> void:
	if finished or not body.is_in_group("player"):
		return
	finished = true
	var result := GameState.finish_stage(float(level.get("par_time", 90.0)))
	stage_finished.emit(result)


func _spawn_player() -> void:
	player = preload("res://scenes/player/player.tscn").instantiate()
	player.position = level["spawn"]
	player.add_to_group("player")
	add_child(player)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = -100
	camera.limit_right = int(level.get("length", 2400)) + 100
	camera.limit_top = -600
	camera.limit_bottom = 360
	player.add_child(camera)
	camera.make_current()
	# Apply cosmetics tint
	if player.has_method("apply_cosmetics"):
		player.apply_cosmetics()


func _spawn_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	hud = preload("res://scenes/ui/hud.tscn").instantiate()
	canvas.add_child(hud)
	touch = preload("res://scenes/ui/touch_controls.tscn").instantiate()
	canvas.add_child(touch)
	if touch.has_method("bind_player"):
		touch.bind_player(player)
	# Pause button
	var pause_btn := Button.new()
	pause_btn.text = "II"
	pause_btn.position = Vector2(1180, 16)
	pause_btn.custom_minimum_size = Vector2(56, 48)
	pause_btn.pressed.connect(func() -> void: get_tree().paused = true; _show_pause())
	canvas.add_child(pause_btn)
	pause_btn.process_mode = Node.PROCESS_MODE_ALWAYS


var _pause_layer: CanvasLayer


func _show_pause() -> void:
	if _pause_layer and is_instance_valid(_pause_layer):
		return
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 40
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(420, 180)
	panel.custom_minimum_size = Vector2(440, 280)
	_pause_layer.add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var title := Label.new()
	title.text = "Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	v.add_child(title)
	for item in [["Continuar", _resume], ["Reintentar", _retry], ["Salir al mapa", _quit_map]]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(0, 48)
		b.pressed.connect(item[1])
		v.add_child(b)


func _resume() -> void:
	if _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null
	get_tree().paused = false


func _retry() -> void:
	_resume()
	setup(GameState.current_world, GameState.current_stage)


func _quit_map() -> void:
	_resume()
	var app := get_tree().get_first_node_in_group("app")
	if app and app.has_method("show_level_select"):
		app.show_level_select()
