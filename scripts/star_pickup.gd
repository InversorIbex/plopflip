extends Area2D
## Route star — 3 per stage (GDD §5.1).

@export var star_index: int = 0

var collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body)
	# Visual
	var poly := Polygon2D.new()
	poly.name = "StarPoly"
	poly.color = Color(1.0, 0.88, 0.25)
	poly.polygon = _star_pts(14.0)
	add_child(poly)
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 14.0
	shape.shape = c
	add_child(shape)
	collision_layer = 8
	collision_mask = 2
	monitoring = true


func _process(delta: float) -> void:
	if collected:
		return
	rotation += delta * 1.5
	position.y += sin(Time.get_ticks_msec() * 0.005 + star_index) * 0.15


func _star_pts(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI * 0.5 + i * PI * 0.2
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(Vector2(cos(ang), sin(ang)) * rr)
	return pts


func _on_body(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	GameState.collect_star(star_index)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.12)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
