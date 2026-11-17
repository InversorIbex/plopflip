extends Node
## Full-game demo shots: menus + gameplay (godot -- --demo).

var out_dir: String = ""
var step: int = 0
var timer: float = 0.0
var app: Node


func _ready() -> void:
	out_dir = OS.get_user_data_dir().path_join("full_game_demo")
	DirAccess.make_dir_recursive_absolute(out_dir)
	await get_tree().process_frame
	await get_tree().process_frame
	app = get_tree().get_first_node_in_group("app")
	print("FULLDEMO: out=", out_dir)


func _physics_process(delta: float) -> void:
	if app == null:
		return
	timer += delta
	match step:
		0:
			if timer > 0.4:
				_shot("01_title")
				_advance()
		1:
			if timer > 0.15:
				app.show_difficulty()
				_advance()
		2:
			if timer > 0.35:
				_shot("02_difficulty")
				_advance()
		3:
			if timer > 0.15:
				GameState.difficulty = GameState.Difficulty.MEDIO
				app.show_level_select()
				_advance()
		4:
			if timer > 0.4:
				_shot("03_level_select")
				_advance()
		5:
			if timer > 0.15:
				app.show_cosmetics()
				_advance()
		6:
			if timer > 0.35:
				GameState.set_color("berry")
				GameState.set_cosmetic("head", "verano_gafas")
				GameState.set_cosmetic("torso", "verano_flotador")
				_shot("04_cosmetics")
				_advance()
		7:
			if timer > 0.2:
				GameState.set_color("rosa")
				GameState.set_cosmetic("head", "navidad_gorro")
				GameState.set_cosmetic("torso", "navidad_jersey")
				app.start_stage(0, 0)
				_advance()
		8:
			# Wait for player spawn + idle stretch
			var p := get_tree().get_first_node_in_group("player") as CharacterBody2D
			if p and timer > 0.9:
				_shot("05_factory_idle")
				_advance()
			elif timer > 2.0:
				_shot("05_factory_idle")
				_advance()
		9:
			var p := get_tree().get_first_node_in_group("player") as CharacterBody2D
			if p:
				p.set_touch_axis(1.0)
				if timer < 0.08:
					p.press_jump()
				if timer > 0.2 and not p.is_on_floor():
					_shot("06_factory_jump")
					_advance()
				elif timer > 1.0:
					_shot("06_factory_jump")
					_advance()
		10:
			var p := get_tree().get_first_node_in_group("player") as CharacterBody2D
			if p:
				p.set_touch_axis(0.0)
				p.set_touch_down(true)
				if timer > 0.5:
					_shot("07_factory_crouch")
					p.set_touch_down(false)
					_advance()
		11:
			if timer > 0.2:
				app.start_stage(1, 1)
				_advance()
		12:
			if timer > 1.0:
				_shot("08_garden_stage")
				_advance()
		13:
			if timer > 0.2:
				app.start_stage(2, 2)
				_advance()
		14:
			if timer > 1.1:
				_shot("09_sewer_pipes")
				_advance()
		15:
			var p := get_tree().get_first_node_in_group("player") as CharacterBody2D
			if p and timer > 0.3:
				p.press_tongue()
				if timer > 0.45:
					_shot("10_tongue_combat")
					_advance()
		16:
			# Fake results screen
			app.show_results({"score": 1250, "stars": 2, "time": 54.2, "time_bonus": 80, "no_hit": 0, "caramelos": 12})
			_advance()
		17:
			if timer > 0.5:
				_shot("11_results")
				_advance()
		18:
			print("FULLDEMO: done shots")
			get_tree().quit(0)


func _advance() -> void:
	step += 1
	timer = 0.0


func _shot(name: String) -> void:
	var path := out_dir.path_join(name + ".png")
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("FULLDEMO: saved ", path, " err=", err)
