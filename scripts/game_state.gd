extends Node
## Full run + meta progress for gomFlip (GDD §5–8).

signal energy_changed(current: float, maximum: float)
signal fat_changed(stacks: int)
signal caramelos_changed(count: int)
signal lives_changed(lives: int)
signal hp_changed(hp: int)
signal stars_changed(mask: int)
signal score_changed(score: int)
signal cosmetics_changed()
signal progress_changed()

const ENERGY_MAX := 20.0
const FAT_MAX := 5
const LIVES_DEFAULT := 3
const HP_DEFAULT := 3

const COST_JUMP := 1.0
const COST_DOUBLE_JUMP := 1.0
const COST_TONGUE := 3.0
const MOVE_DRAIN_INTERVAL := 2.5
const MOVE_DRAIN_AMOUNT := 1.0

const FAT_SPEED := [1.0, 0.94, 0.88, 0.82, 0.76, 0.70]
const FAT_JUMP := [1.0, 0.97, 0.94, 0.90, 0.86, 0.82]
const FAT_WIDTH := [1.0, 1.08, 1.16, 1.24, 1.32, 1.40]

enum Difficulty { FACIL, MEDIO, DIFICIL }

const DIFF_NAMES := ["Fácil", "Medio", "Difícil"]
const DIFF_MULT := [1.0, 1.25, 1.5]
const DIFF_DAMAGE := [0.5, 1.0, 1.5]
const DIFF_ENERGY_COST := [0.8, 1.0, 1.15]
const DIFF_ENEMY_SPEED := [0.85, 1.0, 1.2]

const COLORS := {
	"rosa": Color(1.0, 0.45, 0.7),
	"rojo": Color(0.95, 0.28, 0.35),
	"lima": Color(0.55, 0.92, 0.35),
	"berry": Color(0.35, 0.55, 0.98),
	"limon": Color(1.0, 0.88, 0.25),
	"uva": Color(0.62, 0.35, 0.9),
	"naranja": Color(1.0, 0.55, 0.2),
}

## Seasonal cosmetics — always available (GDD §7.2)
const COSMETICS := {
	"none": {"name": "Ninguno", "season": "", "slot": "head"},
	"navidad_gorro": {"name": "Gorro Navidad", "season": "Navidad", "slot": "head"},
	"halloween_bruja": {"name": "Sombrero bruja", "season": "Halloween", "slot": "head"},
	"patricio_sombrero": {"name": "Sombrero verde", "season": "San Patricio", "slot": "head"},
	"carnaval_antifaz": {"name": "Antifaz", "season": "Carnaval", "slot": "head"},
	"verano_gafas": {"name": "Gafas de sol", "season": "Verano", "slot": "head"},
	"otono_bellota": {"name": "Gorro bellota", "season": "Otoño", "slot": "head"},
	"invierno_orejeras": {"name": "Orejeras", "season": "Invierno", "slot": "head"},
	"primavera_corona": {"name": "Corona flores", "season": "Primavera", "slot": "head"},
	"navidad_jersey": {"name": "Jersey Navidad", "season": "Navidad", "slot": "torso"},
	"halloween_capa": {"name": "Capa murciélago", "season": "Halloween", "slot": "torso"},
	"carnaval_confeti": {"name": "Confeti", "season": "Carnaval", "slot": "torso"},
	"verano_flotador": {"name": "Flotador", "season": "Verano", "slot": "torso"},
	"otono_bufanda": {"name": "Bufanda hojas", "season": "Otoño", "slot": "neck"},
	"invierno_bufanda": {"name": "Bufanda nieve", "season": "Invierno", "slot": "neck"},
}

var energy: float = ENERGY_MAX
var fat_stacks: int = 0
var caramelos: int = 0
var caramelos_points: int = 0
var lives: int = LIVES_DEFAULT
var hp: int = HP_DEFAULT
var move_drain_timer: float = 0.0
var stars_mask: int = 0  # bit0..2
var stage_score: int = 0
var stage_time: float = 0.0
var hits_taken: int = 0

var difficulty: int = Difficulty.MEDIO
var color_id: String = "rosa"
var cosmetic_head: String = "none"
var cosmetic_torso: String = "none"
var cosmetic_neck: String = "none"

## Progress: "diff_world_stage" -> {cleared, stars, best_score}
var stage_progress: Dictionary = {}
var total_caramelos: int = 0
var total_stars: int = 0
var unlocked_worlds: Dictionary = {}  # "diff_world" -> true

var current_world: int = 0
var current_stage: int = 0

const SAVE_PATH := "user://gomflip_save.cfg"


func _ready() -> void:
	load_progress()
	reset_run()


func reset_run() -> void:
	energy = ENERGY_MAX
	fat_stacks = 0
	caramelos = 0
	caramelos_points = 0
	lives = LIVES_DEFAULT
	hp = HP_DEFAULT
	move_drain_timer = 0.0
	stars_mask = 0
	stage_score = 0
	stage_time = 0.0
	hits_taken = 0
	_emit_all()


func _emit_all() -> void:
	energy_changed.emit(energy, ENERGY_MAX)
	fat_changed.emit(fat_stacks)
	caramelos_changed.emit(caramelos)
	lives_changed.emit(lives)
	hp_changed.emit(hp)
	stars_changed.emit(stars_mask)
	score_changed.emit(stage_score)


func energy_cost_mult() -> float:
	return DIFF_ENERGY_COST[clampi(difficulty, 0, 2)]


func damage_mult() -> float:
	return DIFF_DAMAGE[clampi(difficulty, 0, 2)]


func enemy_speed_mult() -> float:
	return DIFF_ENEMY_SPEED[clampi(difficulty, 0, 2)]


func score_mult() -> float:
	return DIFF_MULT[clampi(difficulty, 0, 2)]


func has_energy(amount: float) -> bool:
	return energy >= amount * energy_cost_mult()


func spend_energy(amount: float) -> bool:
	var cost := amount * energy_cost_mult()
	if energy < cost:
		return false
	energy = maxf(0.0, energy - cost)
	energy_changed.emit(energy, ENERGY_MAX)
	return true


func add_energy(amount: float) -> void:
	energy = minf(ENERGY_MAX, energy + amount)
	energy_changed.emit(energy, ENERGY_MAX)


func tick_move_drain(delta: float, is_moving: bool) -> void:
	if not is_moving:
		move_drain_timer = 0.0
		return
	move_drain_timer += delta
	if move_drain_timer >= MOVE_DRAIN_INTERVAL:
		move_drain_timer = 0.0
		spend_energy(MOVE_DRAIN_AMOUNT)


func is_low_energy() -> bool:
	return energy < 1.0


func speed_mult() -> float:
	var m: float = FAT_SPEED[clampi(fat_stacks, 0, FAT_MAX)]
	if is_low_energy():
		m *= 0.5
	return m


func jump_mult() -> float:
	return FAT_JUMP[clampi(fat_stacks, 0, FAT_MAX)]


func width_mult() -> float:
	return FAT_WIDTH[clampi(fat_stacks, 0, FAT_MAX)]


func add_fat(amount: int = 1) -> void:
	fat_stacks = mini(FAT_MAX, fat_stacks + amount)
	fat_changed.emit(fat_stacks)


func remove_fat(amount: int = 1) -> void:
	fat_stacks = maxi(0, fat_stacks - amount)
	fat_changed.emit(fat_stacks)


func collect_caramelo(points: int, energy_gain: float, fat_gain: int = 0) -> void:
	caramelos += 1
	caramelos_points += points
	total_caramelos += 1
	caramelos_changed.emit(caramelos)
	add_energy(energy_gain)
	if fat_gain > 0:
		add_fat(fat_gain)
	_recalc_score()


func collect_star(index: int) -> void:
	var bit := 1 << clampi(index, 0, 2)
	if stars_mask & bit:
		return
	stars_mask |= bit
	caramelos_points += 100
	stars_changed.emit(stars_mask)
	_recalc_score()


func _recalc_score() -> void:
	var star_count := _popcount(stars_mask)
	var time_bonus := 0
	# Applied at finish with par; live preview without time
	stage_score = int((caramelos_points + star_count * 0) * score_mult())
	score_changed.emit(stage_score)


func finish_stage(par_time: float) -> Dictionary:
	var star_count := _popcount(stars_mask)
	var time_bonus := 0
	if stage_time <= par_time * 0.7:
		time_bonus = 150
	elif stage_time <= par_time:
		time_bonus = 80
	elif stage_time <= par_time * 1.4:
		time_bonus = 30
	var no_hit := 100 if hits_taken == 0 else 0
	stage_score = int((caramelos_points + star_count * 100 + time_bonus + no_hit) * score_mult())
	score_changed.emit(stage_score)

	var key := stage_key(difficulty, current_world, current_stage)
	var prev: Dictionary = stage_progress.get(key, {"cleared": false, "stars": 0, "best_score": 0})
	var best_stars: int = maxi(int(prev.get("stars", 0)), star_count)
	var best_score: int = maxi(int(prev.get("best_score", 0)), stage_score)
	stage_progress[key] = {"cleared": true, "stars": best_stars, "best_score": best_score}
	total_stars = _count_all_stars()
	_unlock_next(key)
	save_progress()
	progress_changed.emit()
	return {
		"score": stage_score,
		"stars": star_count,
		"time": stage_time,
		"time_bonus": time_bonus,
		"no_hit": no_hit,
		"caramelos": caramelos,
	}


func _unlock_next(_key: String) -> void:
	# Unlock next stage in world
	var next_stage := current_stage + 1
	if next_stage < 4:
		unlocked_worlds[_world_key(difficulty, current_world)] = true
	else:
		# World cleared → next world
		var nw := current_world + 1
		if nw < 3:
			unlocked_worlds[_world_key(difficulty, nw)] = true
	# Ensure current world unlocked
	unlocked_worlds[_world_key(difficulty, current_world)] = true


func is_stage_unlocked(diff: int, world: int, stage: int) -> bool:
	if world == 0 and stage == 0:
		return true
	if not unlocked_worlds.get(_world_key(diff, world), world == 0):
		# World 0 always unlocked; others need flag
		if world > 0 and not unlocked_worlds.get(_world_key(diff, world), false):
			return false
	if stage == 0:
		return unlocked_worlds.get(_world_key(diff, world), world == 0)
	var prev := stage_key(diff, world, stage - 1)
	return bool(stage_progress.get(prev, {}).get("cleared", false))


func is_world_unlocked(diff: int, world: int) -> bool:
	if world == 0:
		return true
	return bool(unlocked_worlds.get(_world_key(diff, world), false))


func stage_key(diff: int, world: int, stage: int) -> String:
	return "%d_%d_%d" % [diff, world, stage]


func _world_key(diff: int, world: int) -> String:
	return "%d_%d" % [diff, world]


func get_stage_stars(diff: int, world: int, stage: int) -> int:
	return int(stage_progress.get(stage_key(diff, world, stage), {}).get("stars", 0))


func _count_all_stars() -> int:
	var n := 0
	for k in stage_progress:
		n += int(stage_progress[k].get("stars", 0))
	return n


func _popcount(x: int) -> int:
	var n := 0
	while x > 0:
		n += x & 1
		x >>= 1
	return n


func take_damage(amount: int = 1) -> void:
	var dmg := maxi(1, int(round(float(amount) * damage_mult())))
	# Fácil: half damage rounded — already in mult; ensure at least chance
	if difficulty == Difficulty.FACIL and amount == 1:
		# Effective +1 HP feel: 50% chance to ignore? Use ceil of 0.5 = still 1 sometimes
		dmg = 1 if randf() < 0.5 else 0
		if dmg == 0:
			hits_taken += 0
			return
	hp = maxi(0, hp - dmg)
	hits_taken += 1
	hp_changed.emit(hp)
	if hp <= 0:
		lives = maxi(0, lives - 1)
		lives_changed.emit(lives)
		if lives > 0:
			hp = HP_DEFAULT
			hp_changed.emit(hp)


func set_color(id: String) -> void:
	if COLORS.has(id):
		color_id = id
		cosmetics_changed.emit()
		save_progress()


func set_cosmetic(slot: String, id: String) -> void:
	if not COSMETICS.has(id) and id != "none":
		return
	match slot:
		"head":
			cosmetic_head = id
		"torso":
			cosmetic_torso = id
		"neck":
			cosmetic_neck = id
	cosmetics_changed.emit()
	save_progress()


func jelly_tint() -> Color:
	return COLORS.get(color_id, COLORS["rosa"])


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "difficulty", difficulty)
	cfg.set_value("meta", "color_id", color_id)
	cfg.set_value("meta", "cosmetic_head", cosmetic_head)
	cfg.set_value("meta", "cosmetic_torso", cosmetic_torso)
	cfg.set_value("meta", "cosmetic_neck", cosmetic_neck)
	cfg.set_value("meta", "total_caramelos", total_caramelos)
	cfg.set_value("meta", "unlocked_worlds", unlocked_worlds)
	cfg.set_value("meta", "stage_progress", stage_progress)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		unlocked_worlds["0_0"] = true
		unlocked_worlds["1_0"] = true
		unlocked_worlds["2_0"] = true
		return
	difficulty = int(cfg.get_value("meta", "difficulty", Difficulty.MEDIO))
	color_id = str(cfg.get_value("meta", "color_id", "rosa"))
	cosmetic_head = str(cfg.get_value("meta", "cosmetic_head", "none"))
	cosmetic_torso = str(cfg.get_value("meta", "cosmetic_torso", "none"))
	cosmetic_neck = str(cfg.get_value("meta", "cosmetic_neck", "none"))
	total_caramelos = int(cfg.get_value("meta", "total_caramelos", 0))
	unlocked_worlds = cfg.get_value("meta", "unlocked_worlds", {})
	stage_progress = cfg.get_value("meta", "stage_progress", {})
	if unlocked_worlds.is_empty():
		unlocked_worlds["0_0"] = true
		unlocked_worlds["1_0"] = true
		unlocked_worlds["2_0"] = true
