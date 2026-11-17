extends Node2D
## Builds and runs one stage from LevelCatalog data.

const LevelCatalog = preload("res://scripts/level_catalog.gd")
const CandyDraw = preload("res://scripts/candy_draw.gd")

signal stage_finished(result: Dictionary)
signal player_died()

var level: Dictionary = {}
var player: CharacterBody2D
var camera: Camera2D
var touch: Node
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
	var length: float = level.get("length", 2400.0)
	var theme: String = level.get("theme", "factory")

	# Gradient sky bands
	var bands := 5
	for b in bands:
		var band := Polygon2D.new()
		band.z_index = -22
		var t := float(b) / float(bands)
		var c := sky_c.lerp(sky_c.darkened(0.18), t * 0.55)
		if theme == "sewer":
			c = Color(0.16, 0.2, 0.3).lerp(Color(0.28, 0.34, 0.42), 1.0 - t)
		elif theme == "garden":
			c = Color(0.55, 0.88, 0.95).lerp(Color(0.7, 0.92, 0.75), t)
		band.color = c
		var y0 := -900.0 + t * 1200.0
		var y1 := -900.0 + (t + 1.0 / bands) * 1200.0
		band.polygon = PackedVector2Array([
			Vector2(-300, y0), Vector2(length + 400, y0),
			Vector2(length + 400, y1), Vector2(-300, y1)
		])
		add_child(band)

	match theme:
		"factory":
			_deco_factory(length)
		"garden":
			_deco_garden(length)
		"sewer":
			_deco_sewer(length)

	var label := Label.new()
	label.text = str(level.get("title", "Stage"))
	label.position = Vector2(48, -380)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.7))
	label.add_theme_constant_override("outline_size", 4)
	label.modulate = Color(0.2, 0.12, 0.25, 0.95) if theme != "sewer" else Color(0.95, 0.9, 1.0, 0.9)
	add_child(label)


func _deco_factory(length: float) -> void:
	for i in 8:
		var hill := Polygon2D.new()
		hill.z_index = -18
		var x := i * 340.0 - 80.0
		hill.color = Color(0.78, 0.9, 0.82, 0.55)
		hill.polygon = PackedVector2Array([
			Vector2(x, 50), Vector2(x + 180, -60 - (i % 3) * 22), Vector2(x + 360, 50)
		])
		add_child(hill)
	# Candy molds / conveyors silhouettes
	for i in 5:
		var mold := Polygon2D.new()
		mold.z_index = -12
		var x := 180.0 + i * 420.0
		mold.color = Color(0.95, 0.7, 0.8, 0.35)
		mold.polygon = PackedVector2Array([
			Vector2(x, -320), Vector2(x + 90, -320), Vector2(x + 90, -200), Vector2(x, -200)
		])
		add_child(mold)
		var gear := Polygon2D.new()
		gear.z_index = -11
		gear.position = Vector2(x + 45, -260)
		gear.color = Color(1.0, 0.85, 0.4, 0.4)
		var pts := PackedVector2Array()
		for k in 8:
			var a := k * TAU / 8.0
			pts.append(Vector2(cos(a), sin(a)) * (18.0 if k % 2 == 0 else 12.0))
		gear.polygon = pts
		add_child(gear)
	# Soft sun
	var sun := Polygon2D.new()
	sun.z_index = -19
	sun.position = Vector2(length * 0.7, -520)
	sun.color = Color(1.0, 0.92, 0.55, 0.55)
	var sp := PackedVector2Array()
	for k in 16:
		sp.append(Vector2(cos(k * TAU / 16.0), sin(k * TAU / 16.0)) * 70.0)
	sun.polygon = sp
	add_child(sun)


func _deco_garden(length: float) -> void:
	for i in 9:
		var hill := Polygon2D.new()
		hill.z_index = -18
		var x := i * 300.0 - 60.0
		hill.color = Color(0.45, 0.82, 0.55, 0.5)
		hill.polygon = PackedVector2Array([
			Vector2(x, 40), Vector2(x + 150, -90 - (i % 4) * 18), Vector2(x + 300, 40)
		])
		add_child(hill)
	# Jelly bushes / flowers
	for i in 12:
		var bush := Polygon2D.new()
		bush.z_index = -10
		var x := 100.0 + i * 190.0
		bush.position = Vector2(x, -8)
		bush.color = Color(0.55, 0.9, 0.65, 0.75)
		bush.polygon = PackedVector2Array([
			Vector2(-22, 8), Vector2(-18, -18), Vector2(0, -28), Vector2(18, -18), Vector2(22, 8)
		])
		add_child(bush)
		var flower := Polygon2D.new()
		flower.z_index = -9
		flower.position = Vector2(x, -36)
		flower.color = Color(1.0, 0.55, 0.75, 0.85)
		var fp := PackedVector2Array()
		for k in 6:
			fp.append(Vector2(cos(k * TAU / 6.0), sin(k * TAU / 6.0)) * 8.0)
		flower.polygon = fp
		add_child(flower)


func _deco_sewer(length: float) -> void:
	# Brick wall bands
	for i in 6:
		var wall := Polygon2D.new()
		wall.z_index = -18
		var x := i * 420.0 - 100.0
		wall.color = Color(0.28, 0.32, 0.4, 0.85)
		wall.polygon = PackedVector2Array([
			Vector2(x, -500), Vector2(x + 380, -500), Vector2(x + 380, 80), Vector2(x, 80)
		])
		add_child(wall)
		for row in 8:
			for col in 4:
				var brick := Polygon2D.new()
				brick.z_index = -17
				brick.color = Color(0.32, 0.36, 0.45, 0.5)
				var bx := x + 20 + col * 90.0 + (20 if row % 2 == 0 else 0)
				var by := -460 + row * 55.0
				brick.polygon = PackedVector2Array([
					Vector2(bx, by), Vector2(bx + 70, by), Vector2(bx + 70, by + 28), Vector2(bx, by + 28)
				])
				add_child(brick)
	# Dripping slime accents
	for i in 7:
		var drip := Polygon2D.new()
		drip.z_index = -8
		var x := 220.0 + i * 320.0
		drip.color = Color(0.45, 0.85, 0.55, 0.55)
		drip.polygon = PackedVector2Array([
			Vector2(x, -200), Vector2(x + 24, -200), Vector2(x + 18, -140), Vector2(x + 6, -140)
		])
		add_child(drip)


func _build_geometry() -> void:
	var ground_c: Color = level.get("ground", Color(0.4, 0.3, 0.5))
	var plat_c: Color = level.get("plat", Color(0.95, 0.55, 0.7))
	var icing := plat_c.lightened(0.35)
	var theme: String = level.get("theme", "factory")
	match theme:
		"garden":
			icing = Color(0.85, 0.98, 0.9)
		"sewer":
			icing = Color(0.55, 0.75, 0.6)
	var plats: Array = level.get("platforms", [])
	for i in plats.size():
		var r: Rect2 = plats[i]
		var is_ground := i == 0 or r.size.y >= 40
		var c := ground_c if is_ground else plat_c
		CandyDraw.add_candy_platform(self, r, c, icing if not is_ground else c.lightened(0.2), is_ground)
	for crawl in level.get("crawl", []):
		CandyDraw.add_candy_platform(self, crawl, plat_c.darkened(0.12), icing.darkened(0.05), false)
	for stair in level.get("stairs", []):
		_add_stairs(stair, plat_c, icing)
	for t in level.get("trampolines", []):
		_add_trampoline(t)
	for w in level.get("water", []):
		_add_water(w)
	for p in level.get("pipes", []):
		_add_pipe(p["from"], p["to"])


func _add_stairs(data: Dictionary, color: Color, icing: Color) -> void:
	var x: float = data["x"]
	var y: float = data["y"]
	var steps: int = data["steps"]
	var w: float = data["w"]
	var h: float = data["h"]
	for i in steps:
		CandyDraw.add_candy_platform(
			self,
			Rect2(x + i * w, y - (i + 1) * h, w + 4, h),
			color.lightened(0.04 * (i % 2)),
			icing,
			false
		)


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
	var hx := rect.size.x * 0.5
	var hy := rect.size.y * 0.5
	var base := Polygon2D.new()
	base.polygon = CandyDraw.rounded_rect_poly(hx + 4, hy + 2, 6.0)
	base.color = Color(0.25, 0.75, 0.55)
	area.add_child(base)
	var pad := Polygon2D.new()
	pad.polygon = CandyDraw.rounded_rect_poly(hx, hy, 5.0)
	pad.color = Color(0.55, 1.0, 0.75)
	area.add_child(pad)
	var shine := Polygon2D.new()
	shine.polygon = PackedVector2Array([Vector2(-hx + 4, -hy + 2), Vector2(hx - 8, -hy + 2), Vector2(hx - 10, -hy + hy), Vector2(-hx + 6, -hy + hy)])
	shine.color = Color(1, 1, 1, 0.35)
	area.add_child(shine)
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
	var hx := rect.size.x * 0.5
	var hy := rect.size.y * 0.5
	var pool := Polygon2D.new()
	pool.polygon = CandyDraw.rounded_rect_poly(hx, hy, 8.0)
	pool.color = Color(0.35, 0.72, 0.98, 0.55)
	area.add_child(pool)
	var surface := Polygon2D.new()
	surface.polygon = PackedVector2Array([
		Vector2(-hx + 2, -hy), Vector2(hx - 2, -hy),
		Vector2(hx - 6, -hy + 6), Vector2(-hx + 6, -hy + 6)
	])
	surface.color = Color(0.75, 0.95, 1.0, 0.65)
	area.add_child(surface)
	# Bubbles
	for i in 3:
		var bub := Polygon2D.new()
		bub.position = Vector2(-hx * 0.4 + i * hx * 0.4, 0)
		bub.color = Color(1, 1, 1, 0.35)
		bub.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(0, -3), Vector2(3, 0), Vector2(0, 3)
		])
		area.add_child(bub)
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
	# Cute exit pipe twin
	var exit := Node2D.new()
	exit.position = to
	exit.z_index = -1
	var tube := Polygon2D.new()
	tube.color = Color(0.3, 0.78, 0.48)
	tube.polygon = PackedVector2Array([-20, -44, 20, -44, 20, 4, -20, 4])
	exit.add_child(tube)
	var rim := Polygon2D.new()
	rim.color = Color(0.2, 0.58, 0.35)
	rim.polygon = PackedVector2Array([-24, -6, 24, -6, 24, 6, -24, 6])
	exit.add_child(rim)
	var hole := Polygon2D.new()
	hole.color = Color(0.06, 0.14, 0.1)
	hole.polygon = PackedVector2Array([-12, -36, 12, -36, 12, -8, -12, -8])
	exit.add_child(hole)
	add_child(exit)


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
	var base := Polygon2D.new()
	base.polygon = CandyDraw.rounded_rect_poly(14, 6, 4.0)
	base.position = Vector2(0, 14)
	base.color = Color(0.85, 0.55, 0.75)
	goal.add_child(base)
	var pole := Polygon2D.new()
	pole.polygon = PackedVector2Array([Vector2(-3, -58), Vector2(3, -58), Vector2(3, 14), Vector2(-3, 14)])
	pole.color = Color(0.95, 0.92, 0.98)
	goal.add_child(pole)
	var flag := Polygon2D.new()
	flag.polygon = PackedVector2Array([Vector2(3, -56), Vector2(40, -40), Vector2(3, -24)])
	flag.color = Color(1.0, 0.78, 0.25)
	goal.add_child(flag)
	var star := Polygon2D.new()
	star.position = Vector2(18, -40)
	star.color = Color(1, 1, 1, 0.85)
	var sp := PackedVector2Array()
	for k in 10:
		var a := -PI * 0.5 + k * PI * 0.2
		sp.append(Vector2(cos(a), sin(a)) * (5.0 if k % 2 == 0 else 2.2))
	star.polygon = sp
	goal.add_child(star)
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
	# HUD must not steal touches from virtual controls.
	if hud is Control:
		(hud as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud)
	# Touch on its own higher layer so controls stay above HUD/hints.
	var touch_layer := CanvasLayer.new()
	touch_layer.layer = 30
	add_child(touch_layer)
	touch = preload("res://scenes/ui/touch_controls.tscn").instantiate()
	touch_layer.add_child(touch)
	if touch.has_method("bind_player"):
		touch.bind_player(player)
	# Pause button (small, top-right — does not cover action buttons)
	var pause_btn := Button.new()
	pause_btn.text = "II"
	pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.offset_left = -72.0
	pause_btn.offset_top = 12.0
	pause_btn.offset_right = -12.0
	pause_btn.offset_bottom = 60.0
	pause_btn.focus_mode = Control.FOCUS_NONE
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
