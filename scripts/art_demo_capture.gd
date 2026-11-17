extends Node
## Art-pass screenshots → user://art_pass_demo (copied to media/art-pass/).

var out_dir: String = ""
var step: int = 0
var timer: float = 0.0
var app: Node


func _ready() -> void:
	out_dir = OS.get_user_data_dir().path_join("art_pass_demo")
	DirAccess.make_dir_recursive_absolute(out_dir)
	await get_tree().process_frame
	await get_tree().process_frame
	app = get_tree().get_first_node_in_group("app")
	# Clean default look for hero shots
	GameState.set_color("rosa")
	GameState.set_cosmetic("head", "none")
	GameState.set_cosmetic("torso", "none")
	GameState.set_cosmetic("neck", "none")
	print("ARTDEMO: out=", out_dir)


func _physics_process(delta: float) -> void:
	if app == null:
		return
	timer += delta
	match step:
		0:
			if timer > 0.5:
				_shot("01_title")
				_advance()
		1:
			if timer > 0.1:
				app.show_cosmetics()
				_advance()
		2:
			if timer > 0.35:
				_shot("02_cosmetics")
				_advance()
		3:
			if timer > 0.1:
				app.show_level_select()
				_advance()
		4:
			if timer > 0.4:
				_shot("03_world_map")
				_advance()
		5:
			if timer > 0.15:
				app.start_stage(0, 0)
				_advance()
		6:
			var p := _player()
			if p and timer > 1.0:
				_shot("04_jelly_idle")
				_advance()
			elif timer > 2.2:
				_shot("04_jelly_idle")
				_advance()
		7:
			var p := _player()
			if p:
				p.set_touch_axis(0.2)
				if timer < 0.06:
					p.press_jump()
				if timer > 0.18 and not p.is_on_floor():
					_shot("05_jelly_jump")
					_advance()
				elif timer > 1.0:
					_shot("05_jelly_jump")
					_advance()
		8:
			var p := _player()
			if p:
				p.set_touch_axis(0.0)
				p.set_touch_down(true)
				if timer > 0.55:
					_shot("06_jelly_crouch")
					p.set_touch_down(false)
					_advance()
		9:
			if timer > 0.15:
				GameState.set_cosmetic("head", "navidad_gorro")
				app.start_stage(0, 1)
				_advance()
		10:
			if timer > 1.0:
				_shot("07_factory_world")
				_advance()
		11:
			if timer > 0.15:
				app.start_stage(1, 1)
				_advance()
		12:
			if timer > 1.05:
				_shot("08_garden_world")
				_advance()
		13:
			if timer > 0.15:
				app.start_stage(2, 2)
				_advance()
		14:
			if timer > 1.1:
				_shot("09_sewer_world")
				_advance()
		15:
			var p := _player()
			if p and timer > 0.25:
				p.press_tongue()
				if timer > 0.42:
					_shot("10_candy_combat")
					_advance()
		16:
			app.show_results({"score": 1680, "stars": 3, "time": 48.0, "time_bonus": 150, "no_hit": 100, "caramelos": 18})
			_advance()
		17:
			if timer > 0.45:
				_shot("11_results")
				_advance()
		18:
			print("ARTDEMO: done")
			get_tree().quit(0)


func _player() -> CharacterBody2D:
	return get_tree().get_first_node_in_group("player") as CharacterBody2D


func _advance() -> void:
	step += 1
	timer = 0.0


func _shot(name: String) -> void:
	var path := out_dir.path_join(name + ".png")
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("ARTDEMO: saved ", path, " err=", err)
