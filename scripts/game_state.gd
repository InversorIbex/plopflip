extends Node
## Shared run state for Fase 0 (energy, fat stacks, score counters).

signal energy_changed(current: float, maximum: float)
signal fat_changed(stacks: int)
signal caramelos_changed(count: int)
signal lives_changed(lives: int)
signal hp_changed(hp: int)

const ENERGY_MAX := 20.0
const FAT_MAX := 5
const LIVES_DEFAULT := 3
const HP_DEFAULT := 3

## GDD §8.4 energy costs
const COST_JUMP := 1.0
const COST_DOUBLE_JUMP := 1.0
const COST_TONGUE := 3.0
const MOVE_DRAIN_INTERVAL := 2.5
const MOVE_DRAIN_AMOUNT := 1.0

## Fat stack multipliers (GDD §5.3)
const FAT_SPEED := [1.0, 0.94, 0.88, 0.82, 0.76, 0.70]
const FAT_JUMP := [1.0, 0.97, 0.94, 0.90, 0.86, 0.82]
const FAT_WIDTH := [1.0, 1.08, 1.16, 1.24, 1.32, 1.40]

var energy: float = ENERGY_MAX
var fat_stacks: int = 0
var caramelos: int = 0
var lives: int = LIVES_DEFAULT
var hp: int = HP_DEFAULT
var move_drain_timer: float = 0.0


func _ready() -> void:
	reset_run()


func reset_run() -> void:
	energy = ENERGY_MAX
	fat_stacks = 0
	caramelos = 0
	lives = LIVES_DEFAULT
	hp = HP_DEFAULT
	move_drain_timer = 0.0
	_emit_all()


func _emit_all() -> void:
	energy_changed.emit(energy, ENERGY_MAX)
	fat_changed.emit(fat_stacks)
	caramelos_changed.emit(caramelos)
	lives_changed.emit(lives)
	hp_changed.emit(hp)


func has_energy(amount: float) -> bool:
	return energy >= amount


func spend_energy(amount: float) -> bool:
	if energy < amount:
		return false
	energy = maxf(0.0, energy - amount)
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
	caramelos_changed.emit(caramelos)
	add_energy(energy_gain)
	if fat_gain > 0:
		add_fat(fat_gain)


func take_damage(amount: int = 1) -> void:
	hp = maxi(0, hp - amount)
	hp_changed.emit(hp)
	if hp <= 0:
		lives = maxi(0, lives - 1)
		lives_changed.emit(lives)
		if lives > 0:
			hp = HP_DEFAULT
			hp_changed.emit(hp)
