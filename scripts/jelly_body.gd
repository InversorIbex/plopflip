extends Node2D
## Fluid kawaii jelly: soft metaball field → continuous silhouette with limbs as same mass.

@export var jelly_color := Color(1.0, 0.48, 0.72, 1.0)
@export var jelly_deep := Color(0.82, 0.22, 0.48, 1.0)

var head_c: Vector2 = Vector2(0, -52)
var torso_c: Vector2 = Vector2(0, -34)
var hip_c: Vector2 = Vector2(0, -20)
var shoulder_l: Vector2 = Vector2(-14, -38)
var shoulder_r: Vector2 = Vector2(14, -38)
var hand_l: Vector2 = Vector2(-22, -10)
var hand_r: Vector2 = Vector2(22, -10)
var foot_l: Vector2 = Vector2(-8, 2)
var foot_r: Vector2 = Vector2(8, 2)

var head_r: float = 15.0
var torso_rx: float = 12.0
var torso_ry: float = 12.0
var limb_r: float = 6.0
var fat_w: float = 1.0

var _charges: Array = []
var _tex: ImageTexture
var _tex_origin: Vector2 = Vector2.ZERO
var _tex_scale: float = 1.0
var _head_cosmetic: String = "none"
var _torso_cosmetic: String = "none"
var _neck_cosmetic: String = "none"

const THRESH := 1.0
const PX := 1.15


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func apply_cosmetics(tint: Color, head_id: String, torso_id: String, neck_id: String) -> void:
	jelly_color = tint
	jelly_deep = Color(tint.darkened(0.28))
	_head_cosmetic = head_id
	_torso_cosmetic = torso_id
	_neck_cosmetic = neck_id
	if not _charges.is_empty():
		_rebuild_texture()
	queue_redraw()


func set_pose(
	p_head: Vector2, p_torso: Vector2, p_hip: Vector2,
	p_sh_l: Vector2, p_sh_r: Vector2,
	p_hand_l: Vector2, p_hand_r: Vector2,
	p_foot_l: Vector2, p_foot_r: Vector2,
	p_head_r: float, p_torso_rx: float, p_torso_ry: float,
	p_limb_r: float, p_fat: float
) -> void:
	head_c = p_head
	torso_c = p_torso
	hip_c = p_hip
	shoulder_l = p_sh_l
	shoulder_r = p_sh_r
	hand_l = p_hand_l
	hand_r = p_hand_r
	foot_l = p_foot_l
	foot_r = p_foot_r
	head_r = p_head_r
	torso_rx = p_torso_rx
	torso_ry = p_torso_ry
	limb_r = p_limb_r
	fat_w = p_fat
	_charges = _build_charges()
	_rebuild_texture()
	queue_redraw()


func _build_charges() -> Array:
	var c: Array = []
	var fw := fat_w
	var hr := head_r * fw
	var tr := maxf(torso_rx, torso_ry) * fw * 1.22
	var lr := limb_r * fw * 1.35

	# Soft torso core (slightly leaner so limbs read as lobes)
	_chain(c, head_c + Vector2(0, -hr * 0.02), hip_c + Vector2(0, 4), tr * 0.95, 10)
	c.append([head_c, hr * 0.98])
	c.append([torso_c, tr * 1.02])
	c.append([hip_c, tr * 0.9])
	_chain(c, head_c, torso_c, maxf(hr, tr) * 0.9, 5)

	# Limbs as continuous gel lobes of the same mass
	_limb(c, shoulder_l, hand_l, lr * 1.15, lr * 0.9, 14)
	_limb(c, shoulder_r, hand_r, lr * 1.15, lr * 0.9, 14)
	_limb(c, hip_c + Vector2(-6, 2), foot_l, lr * 1.2, lr * 1.0, 16)
	_limb(c, hip_c + Vector2(6, 2), foot_r, lr * 1.2, lr * 1.0, 16)
	c.append([hand_l, lr * 1.1])
	c.append([hand_r, lr * 1.1])
	c.append([foot_l, lr * 1.2])
	c.append([foot_r, lr * 1.2])
	return c


func _chain(out: Array, a: Vector2, b: Vector2, r: float, steps: int) -> void:
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		out.append([a.lerp(b, t), r * (1.0 + 0.08 * sin(t * PI))])


func _limb(out: Array, a: Vector2, b: Vector2, r0: float, r1: float, steps: int) -> void:
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		out.append([a.lerp(b, t), lerpf(r0, r1, t) * (1.0 + 0.07 * sin(t * PI))])


func _field(p: Vector2) -> float:
	var s := 0.0
	for ch in _charges:
		var d := p.distance_to(ch[0])
		var r: float = maxf(ch[1], 0.4)
		var t := d / r
		if t < 2.5:
			s += 1.0 / (t * t + 0.28)
	return s


func _rebuild_texture() -> void:
	if _charges.is_empty():
		return
	var min_v := Vector2(1e9, 1e9)
	var max_v := Vector2(-1e9, -1e9)
	for ch in _charges:
		var r: float = ch[1] * 2.4
		var p: Vector2 = ch[0]
		min_v = min_v.min(p - Vector2(r, r))
		max_v = max_v.max(p + Vector2(r, r))
	min_v -= Vector2(3, 3)
	max_v += Vector2(3, 3)

	var w := clampi(int(ceil((max_v.x - min_v.x) / PX)), 24, 180)
	var h := clampi(int(ceil((max_v.y - min_v.y) / PX)), 24, 220)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var fill := jelly_color
	var deep := jelly_deep
	var hi := fill.lightened(0.35)
	hi.a = 1.0
	var hl_pos := head_c + Vector2(-5, -5)

	for y in h:
		for x in w:
			var p := min_v + Vector2(x + 0.5, y + 0.5) * PX
			var f := _field(p)
			var edge0 := THRESH * 0.55
			if f < edge0:
				continue
			# Soft translucent rim → solid jelly core with visible volume
			var edge := clampf((f - edge0) / (THRESH - edge0 + 0.001), 0.0, 1.0)
			var core := clampf((f - THRESH) / (THRESH * 0.85), 0.0, 1.0)
			var col := deep.lerp(fill, ease(core, 0.55))
			# Specular highlight (bright jelly shine)
			var hl := clampf(1.0 - p.distance_to(hl_pos) / (head_r * 2.0), 0.0, 1.0)
			col = col.lerp(Color(1, 1, 1, 1), hl * 0.55 * maxf(core, 0.35))
			# Belly / body glow
			var belly := clampf(1.0 - p.distance_to(torso_c + Vector2(-2, 3)) / (tr_safe() * 1.8), 0.0, 1.0)
			col = col.lerp(hi, belly * 0.28 * maxf(core, 0.25))
			# Rim darkening for soft-body read
			col = col.lerp(deep, (1.0 - edge) * 0.35)
			col.a = ease(edge, 0.4)
			img.set_pixel(x, y, col)

	if _tex == null or _tex.get_width() != w or _tex.get_height() != h:
		_tex = ImageTexture.create_from_image(img)
	else:
		_tex.update(img)
	_tex_origin = min_v
	_tex_scale = PX


func tr_safe() -> float:
	return maxf(torso_rx, torso_ry) * fat_w


func _draw() -> void:
	if _charges.is_empty():
		_charges = _build_charges()
		_rebuild_texture()
	if _tex:
		draw_set_transform(_tex_origin, 0.0, Vector2(_tex_scale, _tex_scale))
		draw_texture(_tex, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_cosmetics()
	_draw_face()


func _draw_cosmetics() -> void:
	match _neck_cosmetic:
		"otono_bufanda":
			draw_circle(hip_c + Vector2(0, -6), 10.0, Color(0.85, 0.45, 0.2, 0.9))
			draw_circle(hip_c + Vector2(8, -2), 5.0, Color(0.9, 0.55, 0.2, 0.85))
		"invierno_bufanda":
			draw_circle(hip_c + Vector2(0, -6), 10.0, Color(0.85, 0.92, 1.0, 0.95))
			draw_circle(hip_c + Vector2(10, 0), 4.5, Color(0.75, 0.85, 1.0, 0.9))
	match _torso_cosmetic:
		"navidad_jersey":
			draw_circle(torso_c, torso_rx * 1.15, Color(0.85, 0.15, 0.2, 0.5))
			draw_circle(torso_c + Vector2(0, 4), 3.2, Color(1, 1, 1, 0.85))
		"halloween_capa":
			draw_colored_polygon(PackedVector2Array([
				shoulder_l + Vector2(-4, 0), shoulder_r + Vector2(4, 0),
				hip_c + Vector2(14, 18), hip_c + Vector2(-14, 18)
			]), Color(0.2, 0.08, 0.28, 0.7))
		"carnaval_confeti":
			for i in 5:
				var o := Vector2(cos(i * 1.3) * 12, sin(i * 1.7) * 8)
				draw_circle(torso_c + o, 2.2, Color(1, 0.4 + i * 0.1, 0.3, 0.85))
		"verano_flotador":
			draw_arc(hip_c + Vector2(0, 2), 14.0, 0, TAU, 18, Color(1.0, 0.35, 0.25, 0.9), 5.0, true)
	match _head_cosmetic:
		"navidad_gorro":
			draw_colored_polygon(PackedVector2Array([
				head_c + Vector2(-13, -5), head_c + Vector2(11, -7), head_c + Vector2(2, -27)
			]), Color(0.9, 0.15, 0.2))
			draw_circle(head_c + Vector2(2, -27), 3.8, Color(1, 1, 1))
			draw_circle(head_c + Vector2(0, -6), 8.0, Color(1, 1, 1, 0.95))
		"halloween_bruja":
			draw_colored_polygon(PackedVector2Array([
				head_c + Vector2(-16, -4), head_c + Vector2(16, -4), head_c + Vector2(0, -28)
			]), Color(0.25, 0.12, 0.4))
		"patricio_sombrero":
			draw_circle(head_c + Vector2(0, -10), 9.0, Color(0.2, 0.65, 0.3))
			draw_rect(Rect2(head_c + Vector2(-12, -12), Vector2(24, 5)), Color(0.15, 0.5, 0.22))
		"carnaval_antifaz":
			draw_circle(head_c + Vector2(-6, -1), 5.0, Color(0.55, 0.2, 0.85, 0.85))
			draw_circle(head_c + Vector2(6, -1), 5.0, Color(0.55, 0.2, 0.85, 0.85))
		"verano_gafas":
			draw_circle(head_c + Vector2(-6, 0), 5.5, Color(0.1, 0.1, 0.15, 0.85))
			draw_circle(head_c + Vector2(6, 0), 5.5, Color(0.1, 0.1, 0.15, 0.85))
			draw_line(head_c + Vector2(-1, 0), head_c + Vector2(1, 0), Color(0.1, 0.1, 0.15), 2.0)
		"otono_bellota":
			draw_circle(head_c + Vector2(0, -12), 8.0, Color(0.55, 0.32, 0.12))
			draw_circle(head_c + Vector2(0, -18), 3.0, Color(0.35, 0.55, 0.2))
		"invierno_orejeras":
			draw_circle(head_c + Vector2(-12, 2), 6.0, Color(0.95, 0.95, 1.0))
			draw_circle(head_c + Vector2(12, 2), 6.0, Color(0.95, 0.95, 1.0))
		"primavera_corona":
			for i in 6:
				var a := -PI * 0.5 + i * TAU / 6.0
				draw_circle(head_c + Vector2(cos(a), sin(a)) * 14.0 + Vector2(0, -4), 3.2, Color(1.0, 0.45, 0.7))


func _draw_face() -> void:
	var c := head_c
	# Soft blush
	draw_circle(c + Vector2(-8.0, 3.5), 3.2, Color(1.0, 0.5, 0.65, 0.4))
	draw_circle(c + Vector2(8.0, 3.5), 3.2, Color(1.0, 0.5, 0.65, 0.4))
	for side in [-1.0, 1.0]:
		var e := c + Vector2(side * 5.8, -0.2)
		draw_circle(e, 5.0, Color(1, 1, 1, 1))
		draw_circle(e + Vector2(0.25, 0.55), 2.9, Color(0.16, 0.1, 0.2, 1))
		draw_circle(e + Vector2(-1.5, -1.35), 1.35, Color(1, 1, 1, 1))
		draw_circle(e + Vector2(1.15, 1.0), 0.7, Color(1, 1, 1, 0.85))
	# Tiny smile + tongue nub
	var smile_c := c + Vector2(0, 6.8)
	draw_arc(smile_c, 3.8, deg_to_rad(25), deg_to_rad(155), 12, Color(0.7, 0.22, 0.4, 1), 1.7, true)
	draw_circle(smile_c + Vector2(0, 2.3), 1.35, Color(1.0, 0.5, 0.65, 0.95))
