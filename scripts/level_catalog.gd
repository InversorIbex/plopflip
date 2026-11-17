extends RefCounted
## 3 worlds × 4 stages — hand-authored layouts, themed (GDD §6.2).
## Use as LevelCatalog via preload("res://scripts/level_catalog.gd").

const WORLDS := [
	{"title": "Fábrica de caramelos", "theme": "factory", "sky": Color(0.62, 0.84, 0.95), "plat": Color(0.95, 0.55, 0.7), "ground": Color(0.45, 0.32, 0.55)},
	{"title": "Jardín de gelatina", "theme": "garden", "sky": Color(0.55, 0.9, 0.7), "plat": Color(0.55, 0.85, 0.95), "ground": Color(0.35, 0.55, 0.4)},
	{"title": "Alcantarillas dulces", "theme": "sewer", "sky": Color(0.22, 0.28, 0.38), "plat": Color(0.45, 0.7, 0.55), "ground": Color(0.25, 0.3, 0.35)},
]


static func world_count() -> int:
	return WORLDS.size()


static func stage_count() -> int:
	return 4


static func get_level(world: int, stage: int) -> Dictionary:
	world = clampi(world, 0, 2)
	stage = clampi(stage, 0, 3)
	var w: Dictionary = WORLDS[world]
	var layouts := [
		_layout_intro(world),
		_layout_heights(world),
		_layout_pipes(world),
		_layout_gauntlet(world),
	]
	var L: Dictionary = layouts[stage].duplicate(true)
	L["world"] = world
	L["stage"] = stage
	L["title"] = "%s — Stage %d" % [w["title"], stage + 1]
	L["theme"] = w["theme"]
	L["sky"] = w["sky"]
	L["plat"] = w["plat"]
	L["ground"] = w["ground"]
	L["par_time"] = [70.0, 85.0, 95.0, 110.0][stage]
	return L


static func _base(spawn: Vector2, goal: Vector2, length: float) -> Dictionary:
	return {
		"spawn": spawn,
		"goal": goal,
		"length": length,
		"platforms": [],
		"stairs": [],
		"pipes": [],
		"water": [],
		"trampolines": [],
		"enemies": [],
		"pickups": [],
		"stars": [],
		"crawl": [],
	}


static func _layout_intro(world: int) -> Dictionary:
	var L := _base(Vector2(80, -40), Vector2(2100, -40), 2300.0)
	L["platforms"] = [
		Rect2(-40, 0, 2400, 48),
		Rect2(260, -110, 160, 22),
		Rect2(520, -200, 150, 22),
		Rect2(780, -130, 180, 22),
		Rect2(1100, -240, 140, 22),
		Rect2(1400, -150, 200, 22),
		Rect2(1750, -90, 160, 22),
	]
	L["stairs"] = [
		{"x": 940, "y": 0, "steps": 5, "w": 36, "h": 18},
	]
	L["crawl"] = [Rect2(1580, -48, 110, 22), Rect2(1580, -100, 110, 14)]
	L["pickups"] = [
		{"kind": "normal", "pos": Vector2(300, -150)},
		{"kind": "normal", "pos": Vector2(560, -240)},
		{"kind": "engordante", "pos": Vector2(820, -180)},
		{"kind": "normal", "pos": Vector2(1140, -280)},
		{"kind": "grande", "pos": Vector2(1480, -200)},
		{"kind": "water", "pos": Vector2(1680, -40)},
	]
	L["stars"] = [Vector2(540, -260), Vector2(1120, -300), Vector2(1900, -40)]
	L["enemies"] = [
		{"type": "masticon", "pos": Vector2(400, -20)},
		{"type": "masticon", "pos": Vector2(1300, -20)},
	]
	if world >= 1:
		L["trampolines"] = [Rect2(650, -24, 70, 16)]
		L["enemies"].append({"type": "volagoma", "pos": Vector2(1000, -180)})
	if world >= 2:
		L["pipes"] = [{"from": Vector2(1600, -8), "to": Vector2(1850, -8)}]
		L["water"] = [Rect2(700, -20, 90, 28)]
	return L


static func _layout_heights(world: int) -> Dictionary:
	var L := _base(Vector2(60, -40), Vector2(2200, -280), 2400.0)
	L["platforms"] = [
		Rect2(-40, 0, 500, 48),
		Rect2(200, -140, 120, 20),
		Rect2(400, -260, 120, 20),
		Rect2(620, -160, 140, 20),
		Rect2(850, -300, 130, 20),
		Rect2(1100, -180, 150, 20),
		Rect2(1350, -320, 140, 20),
		Rect2(1600, -200, 160, 20),
		Rect2(1850, -280, 280, 24),
		Rect2(1850, 0, 400, 48),
	]
	L["trampolines"] = [Rect2(980, -24, 80, 16), Rect2(1500, -24, 80, 16)]
	L["stairs"] = [{"x": 1720, "y": 0, "steps": 8, "w": 32, "h": 20}]
	L["pickups"] = [
		{"kind": "normal", "pos": Vector2(240, -180)},
		{"kind": "normal", "pos": Vector2(440, -300)},
		{"kind": "engordante", "pos": Vector2(680, -210)},
		{"kind": "normal", "pos": Vector2(890, -340)},
		{"kind": "grande", "pos": Vector2(1380, -360)},
		{"kind": "water", "pos": Vector2(1200, -40)},
		{"kind": "normal", "pos": Vector2(1950, -320)},
	]
	L["stars"] = [Vector2(420, -320), Vector2(870, -360), Vector2(2000, -320)]
	L["enemies"] = [
		{"type": "masticon", "pos": Vector2(300, -20)},
		{"type": "pincho", "pos": Vector2(640, -180)},
		{"type": "volagoma", "pos": Vector2(1200, -260)},
		{"type": "masticon", "pos": Vector2(1700, -20)},
	]
	if world == 2:
		L["water"].append(Rect2(500, -18, 120, 30))
	return L


static func _layout_pipes(world: int) -> Dictionary:
	var L := _base(Vector2(70, -40), Vector2(2300, -40), 2500.0)
	L["platforms"] = [
		Rect2(-40, 0, 900, 48),
		Rect2(300, -120, 140, 20),
		Rect2(560, -220, 120, 20),
		# Sewer pocket
		Rect2(1000, 180, 700, 40),
		Rect2(1000, 80, 120, 20),
		Rect2(1200, 40, 140, 20),
		Rect2(1450, 100, 160, 20),
		Rect2(1700, 0, 900, 48),
		Rect2(1900, -140, 180, 22),
		Rect2(2150, -80, 140, 22),
	]
	L["pipes"] = [
		{"from": Vector2(820, -8), "to": Vector2(1050, 160)},
		{"from": Vector2(1600, 160), "to": Vector2(1750, -8)},
	]
	L["water"] = [Rect2(1280, 160, 140, 36)]
	L["crawl"] = [Rect2(2050, -48, 100, 22), Rect2(2050, -95, 100, 14)]
	L["pickups"] = [
		{"kind": "normal", "pos": Vector2(340, -160)},
		{"kind": "engordante", "pos": Vector2(600, -260)},
		{"kind": "grande", "pos": Vector2(1250, 20)},
		{"kind": "water", "pos": Vector2(1480, 70)},
		{"kind": "normal", "pos": Vector2(1520, 70)},
		{"kind": "normal", "pos": Vector2(1960, -180)},
	]
	L["stars"] = [Vector2(580, -280), Vector2(1320, 20), Vector2(2200, -40)]
	L["enemies"] = [
		{"type": "masticon", "pos": Vector2(450, -20)},
		{"type": "pincho", "pos": Vector2(1180, 160)},
		{"type": "volagoma", "pos": Vector2(1400, 0)},
		{"type": "masticon", "pos": Vector2(2000, -20)},
	]
	if world == 0:
		L["trampolines"] = [Rect2(200, -24, 60, 14)]
	return L


static func _layout_gauntlet(world: int) -> Dictionary:
	var L := _base(Vector2(60, -40), Vector2(2450, -40), 2600.0)
	L["platforms"] = [
		Rect2(-40, 0, 400, 48),
		Rect2(280, -130, 100, 18),
		Rect2(480, -240, 100, 18),
		Rect2(700, -140, 120, 18),
		Rect2(920, -280, 110, 18),
		Rect2(1150, -160, 130, 18),
		Rect2(1400, -300, 120, 18),
		Rect2(1650, -120, 150, 18),
		Rect2(1900, -220, 140, 18),
		Rect2(2150, 0, 500, 48),
		Rect2(2200, -100, 160, 18),
	]
	L["trampolines"] = [Rect2(600, -24, 70, 14), Rect2(1300, -24, 70, 14)]
	L["stairs"] = [{"x": 2050, "y": 0, "steps": 6, "w": 34, "h": 18}]
	L["pipes"] = [{"from": Vector2(1000, -8), "to": Vector2(1550, -8)}]
	L["water"] = [Rect2(1750, -18, 100, 28)]
	L["crawl"] = [Rect2(800, -48, 100, 20), Rect2(800, -96, 100, 14)]
	L["pickups"] = [
		{"kind": "normal", "pos": Vector2(300, -170)},
		{"kind": "engordante", "pos": Vector2(500, -280)},
		{"kind": "grande", "pos": Vector2(940, -320)},
		{"kind": "normal", "pos": Vector2(1180, -200)},
		{"kind": "engordante", "pos": Vector2(1420, -340)},
		{"kind": "water", "pos": Vector2(1680, -160)},
		{"kind": "normal", "pos": Vector2(1950, -260)},
		{"kind": "grande", "pos": Vector2(2280, -140)},
	]
	L["stars"] = [Vector2(500, -300), Vector2(1420, -360), Vector2(2300, -140)]
	L["enemies"] = [
		{"type": "masticon", "pos": Vector2(200, -20)},
		{"type": "pincho", "pos": Vector2(720, -160)},
		{"type": "volagoma", "pos": Vector2(1100, -240)},
		{"type": "masticon", "pos": Vector2(1500, -20)},
		{"type": "pincho", "pos": Vector2(1920, -240)},
		{"type": "volagoma", "pos": Vector2(2100, -160)},
	]
	if world == 2:
		L["enemies"].append({"type": "masticon", "pos": Vector2(2300, -20)})
	return L
