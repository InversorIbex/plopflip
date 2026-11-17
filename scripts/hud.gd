extends Control
## Landscape HUD stub — energy, fat, caramelos, lives (GDD §8.3).

@onready var energy_bar: ProgressBar = $Root/TopLeft/EnergyBar
@onready var energy_label: Label = $Root/TopLeft/EnergyLabel
@onready var fat_label: Label = $Root/TopLeft/FatLabel
@onready var caramelos_label: Label = $Root/TopLeft/CaramelosLabel
@onready var lives_label: Label = $Root/TopLeft/LivesLabel
@onready var hint_label: Label = $Root/Hint


func _ready() -> void:
	GameState.energy_changed.connect(_on_energy)
	GameState.fat_changed.connect(_on_fat)
	GameState.caramelos_changed.connect(_on_caramelos)
	GameState.lives_changed.connect(_on_lives)
	_on_energy(GameState.energy, GameState.ENERGY_MAX)
	_on_fat(GameState.fat_stacks)
	_on_caramelos(GameState.caramelos)
	_on_lives(GameState.lives)
	if hint_label:
		hint_label.text = "A/D move · S crouch/pipe · Space jump · J tongue  |  Touch: pad + A/B"


func _on_energy(current: float, maximum: float) -> void:
	energy_bar.max_value = maximum
	energy_bar.value = current
	energy_label.text = "Energy %d/%d" % [int(current), int(maximum)]
	if current < 3.0:
		energy_bar.modulate = Color(1.0, 0.4, 0.35)
	else:
		energy_bar.modulate = Color(1, 1, 1)


func _on_fat(stacks: int) -> void:
	fat_label.text = "Fat %d/5" % stacks


func _on_caramelos(count: int) -> void:
	caramelos_label.text = "Caramelos %d" % count


func _on_lives(lives: int) -> void:
	lives_label.text = "Lives ×%d" % lives
