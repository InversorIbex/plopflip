extends Node
## App root — title, difficulty, level select, cosmetics, play, results.

const LevelCatalog = preload("res://scripts/level_catalog.gd")

var stage_node: Node2D
var ui: CanvasLayer
var screen: Control


func _ready() -> void:
	add_to_group("app")
	ui = CanvasLayer.new()
	ui.layer = 50
	add_child(ui)
	if "--demo" in OS.get_cmdline_user_args():
		GameState.color_id = "rosa"
		GameState.cosmetic_head = "none"
		GameState.cosmetic_torso = "none"
		GameState.cosmetic_neck = "none"
	show_title()
	if "--demo" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		_run_demo()


func _clear_ui() -> void:
	for c in ui.get_children():
		c.queue_free()
	screen = null


func _clear_stage() -> void:
	if stage_node and is_instance_valid(stage_node):
		stage_node.queue_free()
		stage_node = null


func _panel(size: Vector2 = Vector2(900, 560)) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = size
	p.anchor_left = 0.5
	p.anchor_top = 0.5
	p.anchor_right = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -size.x * 0.5
	p.offset_top = -size.y * 0.5
	p.offset_right = size.x * 0.5
	p.offset_bottom = size.y * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.1, 0.2, 0.92)
	style.border_color = Color(1.0, 0.65, 0.85, 0.35)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	style.shadow_color = Color(0.9, 0.4, 0.65, 0.25)
	style.shadow_size = 10
	p.add_theme_stylebox_override("panel", style)
	return p


func _title_label(text: String, size: int = 36) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 0.62, 0.82))
	l.add_theme_color_override("font_outline_color", Color(0.35, 0.1, 0.25, 0.55))
	l.add_theme_constant_override("outline_size", 3)
	return l


func _btn(text: String, cb: Callable, min_h: float = 48.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_h)
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.95, 0.45, 0.7, 0.95)
	n.corner_radius_top_left = 12
	n.corner_radius_top_right = 12
	n.corner_radius_bottom_left = 12
	n.corner_radius_bottom_right = 12
	n.content_margin_left = 12
	n.content_margin_right = 12
	b.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = Color(1.0, 0.55, 0.78, 1.0)
	b.add_theme_stylebox_override("hover", h)
	var p := n.duplicate()
	p.bg_color = Color(0.8, 0.35, 0.58, 1.0)
	b.add_theme_stylebox_override("pressed", p)
	var d := n.duplicate()
	d.bg_color = Color(0.35, 0.3, 0.4, 0.7)
	b.add_theme_stylebox_override("disabled", d)
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", Color(1, 0.95, 0.98))
	b.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.75))
	b.pressed.connect(cb)
	return b


func show_title() -> void:
	_clear_stage()
	_clear_ui()
	get_tree().paused = false
	var bg := ColorRect.new()
	bg.color = Color(0.62, 0.84, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	# Soft candy hills as Polygon2D via draw host
	var hills := Control.new()
	hills.set_anchors_preset(Control.PRESET_FULL_RECT)
	hills.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hills)
	for i in 5:
		var poly := Polygon2D.new()
		var x := i * 280.0 - 60.0
		poly.color = Color(0.72, 0.92, 0.8, 0.55)
		poly.polygon = PackedVector2Array([
			Vector2(x, 720), Vector2(x + 140, 470 - (i % 3) * 30), Vector2(x + 300, 720)
		])
		hills.add_child(poly)
	# Floating caramelos deco
	for i in 4:
		var c := Polygon2D.new()
		c.position = Vector2(700 + i * 90, 120 + (i % 2) * 40)
		c.color = Color(1.0, 0.55, 0.75, 0.7)
		c.polygon = PackedVector2Array([0, -10, 8, -3, 8, 3, 0, 10, -8, 3, -8, -3])
		hills.add_child(c)
	# Jelly mascot preview
	var preview := Node2D.new()
	preview.position = Vector2(320, 400)
	preview.scale = Vector2(2.2, 2.2)
	var jelly := Node2D.new()
	jelly.set_script(preload("res://scripts/jelly_body.gd"))
	preview.add_child(jelly)
	ui.add_child(preview)
	# Defer pose so script ready
	jelly.call_deferred("set_pose",
		Vector2(0, -38), Vector2(0, -24), Vector2(0, -12),
		Vector2(-12, -26), Vector2(12, -26),
		Vector2(-28, -2), Vector2(28, -2),
		Vector2(-10, 10), Vector2(10, 10),
		13.0, 10.0, 9.5, 6.8, 1.0)
	jelly.call_deferred("apply_cosmetics", GameState.jelly_tint(), GameState.cosmetic_head, GameState.cosmetic_torso, GameState.cosmetic_neck)

	var p := _panel(Vector2(520, 400))
	ui.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(_title_label("gomFlip", 52))
	var sub := Label.new()
	sub.text = "Gominola elástica · landscape"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))
	v.add_child(sub)
	v.add_child(_btn("Jugar", show_difficulty, 56))
	v.add_child(_btn("Cosméticos", show_cosmetics))
	v.add_child(_btn("Salir", func() -> void: get_tree().quit()))


func show_difficulty() -> void:
	_clear_ui()
	var bg := ColorRect.new()
	bg.color = Color(0.45, 0.7, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var p := _panel(Vector2(640, 420))
	ui.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(_title_label("Dificultad", 32))
	for i in 3:
		var idx := i
		var b := _btn(GameState.DIFF_NAMES[i], func() -> void:
			GameState.difficulty = idx
			GameState.save_progress()
			show_level_select()
		, 52)
		if i == GameState.difficulty:
			b.text += "  ✓"
		v.add_child(b)
	v.add_child(_btn("Atrás", show_title))


func show_level_select() -> void:
	_clear_stage()
	_clear_ui()
	get_tree().paused = false
	var bg := ColorRect.new()
	bg.color = Color(0.5, 0.75, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var p := _panel(Vector2(1080, 640))
	ui.add_child(p)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.add_child(root)
	root.add_child(_title_label("Mundos · %s" % GameState.DIFF_NAMES[GameState.difficulty], 28))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1000, 480)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)

	for w in LevelCatalog.world_count():
		var world_unlocked := GameState.is_world_unlocked(GameState.difficulty, w)
		var wbox := VBoxContainer.new()
		var wt := Label.new()
		var wtitle: String = LevelCatalog.WORLDS[w]["title"]
		wt.text = wtitle if world_unlocked else "%s  (bloqueado)" % wtitle
		wt.add_theme_font_size_override("font_size", 22)
		wt.add_theme_color_override("font_color", Color(1, 0.85, 0.95) if world_unlocked else Color(0.5, 0.5, 0.55))
		wbox.add_child(wt)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		wbox.add_child(row)
		for s in LevelCatalog.stage_count():
			var unlocked := GameState.is_stage_unlocked(GameState.difficulty, w, s)
			var stars := GameState.get_stage_stars(GameState.difficulty, w, s)
			var label := "S%d" % (s + 1)
			if stars > 0:
				label += " " + "★".repeat(stars)
			var ww: int = w
			var ss: int = s
			var b := _btn(label, func() -> void:
				if GameState.is_stage_unlocked(GameState.difficulty, ww, ss):
					start_stage(ww, ss)
			, 64)
			b.custom_minimum_size = Vector2(140, 64)
			b.disabled = not unlocked
			row.add_child(b)
		list.add_child(wbox)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 12)
	root.add_child(nav)
	nav.add_child(_btn("Cosméticos", show_cosmetics))
	nav.add_child(_btn("Dificultad", show_difficulty))
	nav.add_child(_btn("Título", show_title))


func show_cosmetics() -> void:
	_clear_ui()
	var bg := ColorRect.new()
	bg.color = Color(0.58, 0.7, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var p := _panel(Vector2(1040, 620))
	ui.add_child(p)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	p.add_child(root)
	root.add_child(_title_label("Color y temporada", 28))
	var hint := Label.new()
	hint.text = "Adornos de temporada siempre disponibles"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.8, 0.75, 0.9))
	root.add_child(hint)

	var color_row := HBoxContainer.new()
	color_row.add_theme_constant_override("separation", 8)
	root.add_child(color_row)
	for id in GameState.COLORS.keys():
		var cid: String = id
		var b := Button.new()
		b.text = cid.capitalize()
		b.custom_minimum_size = Vector2(100, 44)
		b.modulate = GameState.COLORS[cid]
		b.pressed.connect(func() -> void: GameState.set_color(cid))
		color_row.add_child(b)

	var slots := [["head", "Cabeza"], ["torso", "Torso"], ["neck", "Cuello"]]
	for slot_pair in slots:
		var slot: String = slot_pair[0]
		var slot_name: String = slot_pair[1]
		var lab := Label.new()
		lab.text = slot_name
		lab.add_theme_font_size_override("font_size", 18)
		root.add_child(lab)
		var row := HFlowContainer.new()
		root.add_child(row)
		var none_b := _btn("Ninguno", func() -> void: GameState.set_cosmetic(slot, "none"), 40)
		row.add_child(none_b)
		for cid in GameState.COSMETICS.keys():
			if cid == "none":
				continue
			var info: Dictionary = GameState.COSMETICS[cid]
			if str(info.get("slot", "")) != slot:
				continue
			var id2: String = cid
			var b2 := _btn("%s (%s)" % [info["name"], info["season"]], func() -> void:
				GameState.set_cosmetic(slot, id2)
			, 40)
			row.add_child(b2)

	root.add_child(_btn("Volver al mapa", show_level_select))


func start_stage(world: int, stage: int) -> void:
	_clear_ui()
	_clear_stage()
	stage_node = Node2D.new()
	stage_node.set_script(preload("res://scripts/stage_runtime.gd"))
	add_child(stage_node)
	stage_node.setup(world, stage)
	stage_node.stage_finished.connect(_on_stage_finished)
	stage_node.player_died.connect(_on_player_died)


func _on_stage_finished(result: Dictionary) -> void:
	show_results(result)


func _on_player_died() -> void:
	show_results({"score": 0, "stars": 0, "time": GameState.stage_time, "time_bonus": 0, "no_hit": 0, "caramelos": GameState.caramelos, "failed": true})


func show_results(result: Dictionary) -> void:
	_clear_ui()
	var failed: bool = bool(result.get("failed", false))
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.15, 0.28, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var p := _panel(Vector2(560, 420))
	ui.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(_title_label("Game Over" if failed else "¡Meta!", 34))
	var lines := [
		"Score: %d" % int(result.get("score", 0)),
		"Estrellas: %d/3" % int(result.get("stars", 0)),
		"Caramelos: %d" % int(result.get("caramelos", 0)),
		"Tiempo: %.1fs" % float(result.get("time", 0.0)),
	]
	for line in lines:
		var l := Label.new()
		l.text = line
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 20)
		v.add_child(l)
	if not failed:
		v.add_child(_btn("Siguiente", func() -> void:
			var ns := GameState.current_stage + 1
			if ns < 4 and GameState.is_stage_unlocked(GameState.difficulty, GameState.current_world, ns):
				start_stage(GameState.current_world, ns)
			elif GameState.current_world + 1 < 3 and GameState.is_world_unlocked(GameState.difficulty, GameState.current_world + 1):
				start_stage(GameState.current_world + 1, 0)
			else:
				show_level_select()
		))
	v.add_child(_btn("Reintentar", func() -> void:
		start_stage(GameState.current_world, GameState.current_stage)
	))
	v.add_child(_btn("Mapa", show_level_select))


func _run_demo() -> void:
	# Art-pass showcase (also covers menus + worlds)
	var demo := preload("res://scripts/art_demo_capture.gd").new()
	add_child(demo)
