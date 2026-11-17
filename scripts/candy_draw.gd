extends RefCounted
## Shared candy-style polygon helpers for platforms / props.


static func rounded_rect_poly(hx: float, hy: float, r: float = 6.0) -> PackedVector2Array:
	r = minf(r, minf(hx, hy) * 0.45)
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(hx - r, -hy + r), -PI * 0.5, 0.0],
		[Vector2(hx - r, hy - r), 0.0, PI * 0.5],
		[Vector2(-hx + r, hy - r), PI * 0.5, PI],
		[Vector2(-hx + r, -hy + r), PI, PI * 1.5],
	]
	for corner in corners:
		var center: Vector2 = corner[0]
		var a0: float = corner[1]
		var a1: float = corner[2]
		for i in 5:
			var t := float(i) / 4.0
			var a := lerpf(a0, a1, t)
			pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


static func add_candy_platform(parent: Node, rect: Rect2, base: Color, icing: Color, ground: bool = false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)

	var hx := rect.size.x * 0.5
	var hy := rect.size.y * 0.5
	var rad := 8.0 if ground else 7.0
	if rect.size.y < 28:
		rad = 5.0

	# Soft shadow under
	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.18)
	shadow.position = Vector2(2, 3)
	shadow.polygon = rounded_rect_poly(hx, hy, rad)
	shadow.z_index = -1
	body.add_child(shadow)

	# Body
	var poly := Polygon2D.new()
	poly.polygon = rounded_rect_poly(hx, hy, rad)
	poly.color = base
	body.add_child(poly)

	# Icing stripe on top
	var top_h := mini(8.0, hy * 0.55)
	var icing_poly := Polygon2D.new()
	var ihx := hx - 1.0
	icing_poly.polygon = PackedVector2Array([
		Vector2(-ihx, -hy), Vector2(ihx, -hy),
		Vector2(ihx, -hy + top_h), Vector2(-ihx, -hy + top_h)
	])
	icing_poly.color = icing
	body.add_child(icing_poly)

	# Candy dots / sprinkles
	if not ground and hx > 40:
		for i in int(hx / 28.0):
			var dot := Polygon2D.new()
			var dx := -hx + 18 + i * 28.0
			dot.position = Vector2(dx, -hy + top_h * 0.55)
			dot.color = icing.lightened(0.25)
			dot.polygon = PackedVector2Array([
				Vector2(-2.5, 0), Vector2(0, -2.5), Vector2(2.5, 0), Vector2(0, 2.5)
			])
			body.add_child(dot)
	elif ground:
		# Chocolate wafer lines
		for i in range(int((-hx + 20) / 40.0), int((hx - 10) / 40.0) + 1):
			var line := Polygon2D.new()
			var lx := i * 40.0
			line.color = base.darkened(0.12)
			line.polygon = PackedVector2Array([
				Vector2(lx - 2, -hy + 4), Vector2(lx + 2, -hy + 4),
				Vector2(lx + 2, hy - 4), Vector2(lx - 2, hy - 4)
			])
			body.add_child(line)

	parent.add_child(body)
	return body
