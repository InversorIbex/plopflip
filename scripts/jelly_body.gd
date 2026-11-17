extends Node2D
## Unified jelly: overlapping same-color radial metaball envelopes (no part seams).

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

var _disks_cache: Array = []


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
	_disks_cache = _build_disks()
	queue_redraw()


func _build_disks() -> Array:
	var d: Array = []
	var fw := fat_w
	var hr := head_r * fw
	var tr := maxf(torso_rx, torso_ry) * fw
	var lr := limb_r * fw
	d.append([head_c, hr])
	d.append([torso_c, tr])
	d.append([hip_c, 8.0 * fw])
	_add_bone(d, head_c, torso_c, (hr + tr) * 0.4, 5)
	_add_bone(d, torso_c, hip_c, 9.0 * fw, 5)
	_add_bone(d, shoulder_l, hand_l, lr, 12)
	_add_bone(d, shoulder_r, hand_r, lr, 12)
	_add_bone(d, hip_c + Vector2(-6, 2), foot_l, lr * 1.05, 13)
	_add_bone(d, hip_c + Vector2(6, 2), foot_r, lr * 1.05, 13)
	d.append([hand_l, lr * 1.2])
	d.append([hand_r, lr * 1.2])
	d.append([foot_l, lr * 1.3])
	d.append([foot_r, lr * 1.3])
	return d


func _add_bone(d: Array, a: Vector2, b: Vector2, radius: float, steps: int) -> void:
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		d.append([a.lerp(b, t), radius * (1.0 + 0.1 * sin(t * PI))])


func _envelope(origin: Vector2, disks: Array, bins: int = 40) -> PackedVector2Array:
	# Support-function envelope of disk union (star-shaped from origin)
	var best: PackedFloat32Array
	best.resize(bins)
	for i in bins:
		best[i] = 2.0
	for disk in disks:
		var c: Vector2 = disk[0]
		var r: float = disk[1]
		var to := c - origin
		for i in bins:
			var ang := TAU * float(i) / float(bins)
			var dir := Vector2(cos(ang), sin(ang))
			var s := to.dot(dir) + r
			if s > best[i]:
				best[i] = s
	var pts := PackedVector2Array()
	for i in bins:
		var ang := TAU * float(i) / float(bins)
		pts.append(origin + Vector2(cos(ang), sin(ang)) * best[i])
	return pts


func _draw() -> void:
	if _disks_cache.is_empty():
		_disks_cache = _build_disks()
	var disks := _disks_cache
	var deep := Color(jelly_deep.r, jelly_deep.g, jelly_deep.b, 1.0)
	var fill := Color(jelly_color.r, jelly_color.g, jelly_color.b, 1.0)

	# Multiple envelopes from key anchors, SAME opaque color → visually one fused mass
	# Body+head+arms from torso; each leg from its own foot so crotch can exist via overlap
	var body_e := _envelope(torso_c, disks, 44)
	var leg_l_e := _envelope(foot_l.lerp(hip_c, 0.35), disks, 36)
	var leg_r_e := _envelope(foot_r.lerp(hip_c, 0.35), disks, 36)
	var arm_l_e := _envelope(hand_l.lerp(shoulder_l, 0.4), disks, 32)
	var arm_r_e := _envelope(hand_r.lerp(shoulder_r, 0.4), disks, 32)

	# Deep rim (slight inflate of body)
	var rim := PackedVector2Array()
	for p in body_e:
		rim.append(torso_c + (p - torso_c) * 1.05)
	draw_colored_polygon(rim, deep)
	draw_colored_polygon(leg_l_e, deep)
	draw_colored_polygon(leg_r_e, deep)

	# Main gel fill — identical color erases seams where envelopes overlap
	draw_colored_polygon(body_e, fill)
	draw_colored_polygon(leg_l_e, fill)
	draw_colored_polygon(leg_r_e, fill)
	draw_colored_polygon(arm_l_e, fill)
	draw_colored_polygon(arm_r_e, fill)

	# Soft volume highlights (gradients of the same jelly)
	draw_circle(head_c + Vector2(-4, -3), head_r * 0.42, Color(1, 1, 1, 0.32))
	draw_circle(torso_c + Vector2(-3, -2), torso_rx * 0.4, Color(1, 0.88, 0.94, 0.2))
	draw_circle(hand_l.lerp(shoulder_l, 0.45), limb_r * 0.7, Color(1, 1, 1, 0.14))
	draw_circle(hand_r.lerp(shoulder_r, 0.45), limb_r * 0.7, Color(1, 1, 1, 0.14))
	draw_circle(foot_l.lerp(hip_c, 0.4), limb_r * 0.75, Color(1, 1, 1, 0.12))
	draw_circle(foot_r.lerp(hip_c, 0.4), limb_r * 0.75, Color(1, 1, 1, 0.12))

	_draw_face()


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
