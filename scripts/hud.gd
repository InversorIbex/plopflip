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
		hint_label.text = "MOVE pad · JUMP · TONGUE · CROUCH"
	var title: Label = get_node_or_null("Root/Title")
	if title:
		title.text = "gomFlip"
		title.add_theme_color_override("font_color", Color(0.95, 0.45, 0.7))
		title.add_theme_font_size_override("font_size", 20)
	# Soft HUD panel behind stats
	var panel := PanelContainer.new()
	panel.position = Vector2(8, 6)
	panel.custom_minimum_size = Vector2(230, 168)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.12, 0.08, 0.18, 0.45)
	st.corner_radius_top_left = 14
	st.corner_radius_top_right = 14
	st.corner_radius_bottom_left = 14
	st.corner_radius_bottom_right = 14
	st.content_margin_left = 10
	st.content_margin_top = 8
	panel.add_theme_stylebox_override("panel", st)
	$Root.add_child(panel)
	$Root.move_child(panel, 0)
	# Style energy bar
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.55, 0.75)
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_left = 6
	fill.corner_radius_bottom_right = 6
	energy_bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.15, 0.25, 0.7)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	energy_bar.add_theme_stylebox_override("background", bg)


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
