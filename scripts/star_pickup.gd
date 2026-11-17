extends Area2D
## Cute candy star pickup.

@export var star_index: int = 0

var collected: bool = false
var _spin: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body)
	collision_layer = 8
	collision_mask = 2
	monitoring = true
	var glow := Polygon2D.new()
	glow.name = "Glow"
	glow.color = Color(1.0, 0.9, 0.35, 0.28)
	glow.polygon = _star_pts(20.0)
	add_child(glow)
	var poly := Polygon2D.new()
	poly.name = "StarPoly"
	poly.color = Color(1.0, 0.86, 0.2)
	poly.polygon = _star_pts(14.0)
	add_child(poly)
	var shine := Polygon2D.new()
	shine.color = Color(1, 1, 1, 0.55)
	shine.polygon = _star_pts(6.0)
	shine.position = Vector2(-2, -3)
	add_child(shine)
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 15.0
	shape.shape = c
	add_child(shape)


func _process(delta: float) -> void:
	if collected:
		return
	_spin += delta * 1.8
	rotation = sin(_spin) * 0.25
	position.y += sin(Time.get_ticks_msec() * 0.005 + star_index) * 0.18


func _star_pts(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI * 0.5 + i * PI * 0.2
		var rr := r if i % 2 == 0 else r * 0.42
		pts.append(Vector2(cos(ang), sin(ang)) * rr)
	return pts


func _on_body(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	GameState.collect_star(star_index)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.9, 1.9), 0.12)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
