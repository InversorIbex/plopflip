extends Node2D
## Builds Fase 0 collision platforms from a simple rect list (feel prototype).

func _ready() -> void:
	_add_platform(Rect2(-40, 0, 2200, 48), Color(0.45, 0.32, 0.55))  # ground
	_add_platform(Rect2(220, -120, 180, 24), Color(0.95, 0.55, 0.7))
	_add_platform(Rect2(480, -220, 160, 24), Color(0.95, 0.55, 0.7))
	_add_platform(Rect2(720, -140, 200, 24), Color(0.95, 0.55, 0.7))
	_add_platform(Rect2(1000, -260, 140, 24), Color(0.95, 0.55, 0.7))
	_add_platform(Rect2(1180, -160, 220, 24), Color(0.95, 0.55, 0.7))
	_add_platform(Rect2(1500, -80, 160, 24), Color(0.95, 0.55, 0.7))
	# Low crawl gap ledge
	_add_platform(Rect2(860, -48, 120, 24), Color(0.75, 0.45, 0.85))
	_add_platform(Rect2(860, -100, 120, 16), Color(0.55, 0.3, 0.65))  # ceiling for crouch
	# Soft backdrop hills (visual only)
	_add_deco()


func _add_platform(rect: Rect2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = rect.size
	shape.shape = rect_shape
	body.add_child(shape)
	var poly := Polygon2D.new()
	var hx := rect.size.x * 0.5
	var hy := rect.size.y * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	poly.color = color
	body.add_child(poly)
	# Candy stripe top
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, -hy + 6), Vector2(-hx, -hy + 6)
	])
	top.color = color.lightened(0.25)
	body.add_child(top)
	add_child(body)


func _add_deco() -> void:
	var bg := Polygon2D.new()
	bg.z_index = -10
	bg.color = Color(0.62, 0.84, 0.95, 1)
	bg.polygon = PackedVector2Array([
		Vector2(-200, -800), Vector2(2400, -800), Vector2(2400, 200), Vector2(-200, 200)
	])
	add_child(bg)
	for i in 6:
		var hill := Polygon2D.new()
		hill.z_index = -9
		var x := i * 380.0 - 80.0
		hill.color = Color(0.7, 0.9, 0.75, 0.55)
		hill.polygon = PackedVector2Array([
			Vector2(x, 20), Vector2(x + 220, -90 - (i % 3) * 20), Vector2(x + 420, 20)
		])
		add_child(hill)
