extends Node2D
## One continuous jelly: same-color overlapping disks along torso + deforming limbs.
## Overlaps erase seams; stretch springs move limb endpoints of the same mass.

@export var jelly_color := Color(1.0, 0.45, 0.7, 1.0)
@export var jelly_deep := Color(0.86, 0.26, 0.52, 1.0)

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

var _disks: Array = []
var _head_cosmetic: String = "none"
var _torso_cosmetic: String = "none"
var _neck_cosmetic: String = "none"


func apply_cosmetics(tint: Color, head_id: String, torso_id: String, neck_id: String) -> void:
	jelly_color = tint
	jelly_deep = Color(tint.r * 0.72, tint.g * 0.55, tint.b * 0.65, 1.0)
	_head_cosmetic = head_id
	_torso_cosmetic = torso_id
	_neck_cosmetic = neck_id
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
	_disks = _build_disks()
	queue_redraw()


func _build_disks() -> Array:
	var d: Array = []
	var fw := fat_w
	var hr := head_r * fw
	var tr := maxf(torso_rx, torso_ry) * fw * 1.12
	var lr := limb_r * fw * 1.28

	# Continuous vertical core (no neck/waist pinch)
	_bone(d, head_c + Vector2(0, -hr * 0.1), hip_c + Vector2(0, 4), tr * 1.08, 12)
	d.append([head_c, hr])
	d.append([torso_c, tr * 1.12])
	d.append([hip_c, tr])
	_bone(d, head_c, torso_c, maxf(hr, tr) * 0.92, 7)
	_bone(d, torso_c, hip_c, tr * 0.95, 6)

	# Limbs = stretch of same mass (thicker at root)
	_limb(d, shoulder_l, hand_l, lr * 1.2, lr * 0.9, 14)
	_limb(d, shoulder_r, hand_r, lr * 1.2, lr * 0.9, 14)
	_limb(d, hip_c + Vector2(-5, 3), foot_l, lr * 1.25, lr * 1.0, 16)
	_limb(d, hip_c + Vector2(5, 3), foot_r, lr * 1.25, lr * 1.0, 16)
	d.append([hand_l, lr * 1.1])
	d.append([hand_r, lr * 1.1])
	d.append([foot_l, lr * 1.2])
	d.append([foot_r, lr * 1.2])
	return d


func _bone(d: Array, a: Vector2, b: Vector2, radius: float, steps: int) -> void:
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		d.append([a.lerp(b, t), radius * (1.0 + 0.1 * sin(t * PI))])


func _limb(d: Array, a: Vector2, b: Vector2, r0: float, r1: float, steps: int) -> void:
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		d.append([a.lerp(b, t), lerpf(r0, r1, t) * (1.0 + 0.06 * sin(t * PI))])


func _draw() -> void:
	if _disks.is_empty():
		_disks = _build_disks()
	var deep := Color(jelly_deep.r, jelly_deep.g, jelly_deep.b, 1.0)
	var fill := Color(jelly_color.r, jelly_color.g, jelly_color.b, 1.0)

	# Soft outer halo (matching color, low alpha) — softens scallops into one mass
	var halo := Color(jelly_color.r, jelly_color.g, jelly_color.b, 0.22)
	for disk in _disks:
		draw_circle(disk[0], disk[1] * 1.14, halo)

	# Deep rim
	for disk in _disks:
		draw_circle(disk[0], disk[1] * 1.05, deep)

	# Opaque gel — identical color ⇒ fused silhouette
	for disk in _disks:
		draw_circle(disk[0], disk[1], fill)

	# Soft volume (few highlights)
	draw_circle(head_c + Vector2(-5, -4), head_r * 0.5, Color(1, 1, 1, 0.26))
	draw_circle(torso_c + Vector2(-3, 1), maxf(torso_rx, torso_ry) * 0.7, Color(1, 0.88, 0.94, 0.15))

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
			draw_circle(torso_c, torso_rx * 1.1, Color(0.85, 0.15, 0.2, 0.55))
			draw_circle(torso_c + Vector2(0, 4), 3.0, Color(1, 1, 1, 0.8))
		"halloween_capa":
			draw_colored_polygon(PackedVector2Array([
				shoulder_l + Vector2(-4, 0), shoulder_r + Vector2(4, 0),
				hip_c + Vector2(14, 18), hip_c + Vector2(-14, 18)
			]), Color(0.2, 0.08, 0.28, 0.75))
		"carnaval_confeti":
			for i in 5:
				var o := Vector2(cos(i * 1.3) * 12, sin(i * 1.7) * 8)
				draw_circle(torso_c + o, 2.2, Color(1, 0.4 + i * 0.1, 0.3, 0.85))
		"verano_flotador":
			draw_arc(hip_c + Vector2(0, 2), 14.0, 0, TAU, 18, Color(1.0, 0.35, 0.25, 0.9), 5.0, true)
	match _head_cosmetic:
		"navidad_gorro":
			draw_colored_polygon(PackedVector2Array([
				head_c + Vector2(-12, -6), head_c + Vector2(10, -8), head_c + Vector2(2, -26)
			]), Color(0.9, 0.15, 0.2))
			draw_circle(head_c + Vector2(2, -26), 3.5, Color(1, 1, 1))
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
	draw_circle(c + Vector2(-7.5, 3), 2.7, Color(1.0, 0.55, 0.7, 0.45))
	draw_circle(c + Vector2(7.5, 3), 2.7, Color(1.0, 0.55, 0.7, 0.45))
	for side in [-1.0, 1.0]:
		var e := c + Vector2(side * 5.6, -0.4)
		draw_circle(e, 4.5, Color(1, 1, 1, 1))
		draw_circle(e + Vector2(0.3, 0.5), 2.65, Color(0.18, 0.12, 0.22, 1))
		draw_circle(e + Vector2(-1.35, -1.2), 1.2, Color(1, 1, 1, 1))
		draw_circle(e + Vector2(1.0, 0.9), 0.6, Color(1, 1, 1, 0.8))
	var smile_c := c + Vector2(0, 6.3)
	draw_arc(smile_c, 3.5, deg_to_rad(28), deg_to_rad(152), 10, Color(0.75, 0.25, 0.45, 1), 1.5, true)
	draw_circle(smile_c + Vector2(0, 2.1), 1.2, Color(1.0, 0.55, 0.7, 0.9))
