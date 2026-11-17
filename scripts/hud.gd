extends Control
## Landscape HUD — energy, fat, caramelos, lives, stars, score (GDD §8.3).

@onready var energy_bar: ProgressBar = $Root/TopLeft/EnergyBar
@onready var energy_label: Label = $Root/TopLeft/EnergyLabel
@onready var fat_label: Label = $Root/TopLeft/FatLabel
@onready var caramelos_label: Label = $Root/TopLeft/CaramelosLabel
@onready var lives_label: Label = $Root/TopLeft/LivesLabel
@onready var hint_label: Label = $Root/Hint

var stars_label: Label
var score_label: Label


func _ready() -> void:
	GameState.energy_changed.connect(_on_energy)
	GameState.fat_changed.connect(_on_fat)
	GameState.caramelos_changed.connect(_on_caramelos)
	GameState.lives_changed.connect(_on_lives)
	GameState.stars_changed.connect(_on_stars)
	GameState.score_changed.connect(_on_score)
	_on_energy(GameState.energy, GameState.ENERGY_MAX)
	_on_fat(GameState.fat_stacks)
	_on_caramelos(GameState.caramelos)
	_on_lives(GameState.lives)
	# Extra labels
	var root: Control = $Root/TopLeft
	stars_label = Label.new()
	stars_label.name = "StarsLabel"
	stars_label.add_theme_font_size_override("font_size", 18)
	root.add_child(stars_label)
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.add_theme_font_size_override("font_size", 18)
	root.add_child(score_label)
	_on_stars(GameState.stars_mask)
	_on_score(GameState.stage_score)
	if hint_label:
		hint_label.text = "Pad · A salto · B lengua · ↓ tubo  |  Teclado: A/D S Space J"


func _on_energy(current: float, maximum: float) -> void:
	energy_bar.max_value = maximum
	energy_bar.value = current
	energy_label.text = "Energy %d/%d" % [int(current), int(maximum)]
	energy_bar.modulate = Color(1.0, 0.4, 0.35) if current < 3.0 else Color(1, 1, 1)


func _on_fat(stacks: int) -> void:
	fat_label.text = "Fat %d/5" % stacks


func _on_caramelos(count: int) -> void:
	caramelos_label.text = "Caramelos %d" % count


func _on_lives(lives: int) -> void:
	lives_label.text = "Lives ×%d" % lives


func _on_stars(mask: int) -> void:
	if stars_label == null:
		return
	var filled := ""
	for i in 3:
		filled += "★" if (mask & (1 << i)) else "☆"
	stars_label.text = "Stars %s" % filled


func _on_score(score: int) -> void:
	if score_label:
		score_label.text = "Score %d" % score
