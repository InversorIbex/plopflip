extends CharacterBody2D
## Stretchy unified jelly — continuous silhouette, limb length springs (GDD §2, §8.4).

const SPEED := 220.0
const JUMP_VELOCITY := -420.0
const DOUBLE_JUMP_VELOCITY := -380.0
const GRAVITY := 1100.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.09
const TONGUE_REACH := 72.0
const TONGUE_DURATION := 0.32
const INVULN_TIME := 1.0

@onready var visual: Node2D = $Visual
@onready var jelly: Node2D = $Visual/JellyBody
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var crouch_shape: CollisionShape2D = $CrouchShape
@onready var tongue: Area2D = $Tongue
@onready var tongue_visual: Line2D = $Tongue/TongueLine
@onready var tongue_tip: CollisionShape2D = $Tongue/Tip

const VISUAL_SIZE := 1.2

var facing: float = 1.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var can_double_jump: bool = true
var is_crouching: bool = false
var tongue_timer: float = 0.0
var tongue_active: bool = false
var invuln_timer: float = 0.0
var was_on_floor: bool = false
var land_squash: float = 0.0
var run_phase: float = 0.0

## Limb springs (length scale). 1.0 = rest.
var leg_len: float = 1.0
var leg_len_vel: float = 0.0
var arm_len: float = 1.0
var arm_len_vel: float = 0.0
var torso_sy: float = 1.0
var torso_sy_vel: float = 0.0
var torso_sx: float = 1.0
var torso_sx_vel: float = 0.0
var hip_y_offset: float = 0.0
var arm_swing: float = 0.0
var leg_swing: float = 0.0
var leg_l_y: float = 1.0
var leg_r_y: float = 1.0

var touch_axis: float = 0.0
var touch_down: bool = false
var touch_jump_pressed: bool = false
var touch_tongue_pressed: bool = false


func _ready() -> void:
	tongue.monitoring = false
	tongue_tip.disabled = true
	tongue_visual.visible = false
	crouch_shape.disabled = true
	_apply_fat_width()
	GameState.fat_changed.connect(func(_s: int) -> void: _apply_fat_width())


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_handle_gravity(delta)
	_handle_crouch()
	_handle_move(delta)
	_handle_jump()
	_handle_tongue(delta)
	_update_limb_feel(delta)
	move_and_slide()
	_post_move_feedback()
	_check_enemy_contact()


func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		can_double_jump = true
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	invuln_timer = maxf(0.0, invuln_timer - delta)
	land_squash = move_toward(land_squash, 0.0, delta * 3.5)


func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta


func _input_axis() -> float:
	var axis := Input.get_axis("move_left", "move_right")
	if absf(touch_axis) > absf(axis):
		axis = touch_axis
	return axis


func _wants_down() -> bool:
	return Input.is_action_pressed("move_down") or touch_down


func _jump_just() -> bool:
	return Input.is_action_just_pressed("jump") or touch_jump_pressed


func _tongue_just() -> bool:
	return Input.is_action_just_pressed("tongue") or touch_tongue_pressed


func _handle_crouch() -> void:
	var want := _wants_down() and is_on_floor() and not tongue_active
	if want == is_crouching:
		return
	is_crouching = want
	body_shape.disabled = is_crouching
	crouch_shape.disabled = not is_crouching


func _handle_move(delta: float) -> void:
	var axis := _input_axis()
	if is_crouching:
		axis = 0.0
	var speed := SPEED * GameState.speed_mult()
	if axis != 0.0:
		facing = signf(axis)
		velocity.x = axis * speed
		GameState.tick_move_drain(delta, true)
		if is_on_floor():
			run_phase += delta * 10.0 * absf(axis)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		GameState.tick_move_drain(delta, false)
		if is_on_floor():
			run_phase = move_toward(run_phase, 0.0, delta * 6.0)


func _handle_jump() -> void:
	if _jump_just():
		jump_buffer_timer = JUMP_BUFFER
	touch_jump_pressed = false
	if jump_buffer_timer <= 0.0:
		return
	if coyote_timer > 0.0 and not is_crouching:
		if GameState.spend_energy(GameState.COST_JUMP):
			velocity.y = JUMP_VELOCITY * GameState.jump_mult()
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			can_double_jump = true
			leg_len = 0.55
			leg_len_vel = 4.5
			torso_sy = 0.85
			torso_sx = 1.2
		return
	if can_double_jump and not is_on_floor() and not GameState.is_low_energy():
		if GameState.spend_energy(GameState.COST_DOUBLE_JUMP):
			velocity.y = DOUBLE_JUMP_VELOCITY * GameState.jump_mult()
			can_double_jump = false
			jump_buffer_timer = 0.0
			leg_len = 1.55
			leg_len_vel = 2.0
			arm_len = 1.25
			torso_sy = 1.2


func _handle_tongue(delta: float) -> void:
	if tongue_active:
		tongue_timer -= delta
		var t := 1.0 - (tongue_timer / TONGUE_DURATION)
		var reach := TONGUE_REACH
		if t < 0.35:
			reach *= t / 0.35
		elif t > 0.7:
			reach *= (1.0 - t) / 0.3
		tongue_visual.points = PackedVector2Array([Vector2.ZERO, Vector2(reach * facing, 0)])
		tongue_tip.position = Vector2(reach * facing, 0)
		if tongue_timer <= 0.0:
			_end_tongue()
		return
	if _tongue_just():
		touch_tongue_pressed = false
		if GameState.spend_energy(GameState.COST_TONGUE):
			_start_tongue()


func _start_tongue() -> void:
	tongue_active = true
	tongue_timer = TONGUE_DURATION
	tongue.monitoring = true
	tongue_tip.disabled = false
	tongue_visual.visible = true
	tongue_visual.points = PackedVector2Array([Vector2.ZERO, Vector2(8 * facing, 0)])


func _end_tongue() -> void:
	tongue_active = false
	tongue.monitoring = false
	tongue_tip.disabled = true
	tongue_visual.visible = false


func _spring_toward(current: float, velocity: float, target: float, stiffness: float, damping: float, delta: float) -> Vector2:
	var force := (target - current) * stiffness - velocity * damping
	velocity += force * delta
	current += velocity * delta
	return Vector2(current, velocity)


func _update_limb_feel(delta: float) -> void:
	var target_leg := 1.0
	var target_arm := 1.0
	var target_torso_y := 1.0
	var target_torso_x := 1.0
	var target_hip_y := 0.0
	arm_swing = 0.0
	leg_swing = 0.0

	if is_crouching:
		target_leg = 0.42
		target_arm = 0.78
		target_torso_y = 0.86
		target_torso_x = 1.2
		target_hip_y = 10.0
		arm_swing = 0.75
	elif not is_on_floor():
		var up := clampf(-velocity.y / 380.0, 0.0, 1.0)
		var fall := clampf(velocity.y / 480.0, 0.0, 1.0)
		target_leg = 1.05 + up * 0.95 + fall * 0.7
		target_arm = 1.0 + up * 0.55 + fall * 0.2
		target_torso_y = 1.0 + up * 0.18 - fall * 0.06
		target_torso_x = 1.0 - up * 0.1 + fall * 0.06
		arm_swing = -0.85 - up * 0.25
		leg_swing = 0.12
	else:
		var moving := absf(velocity.x) > 20.0
		if moving:
			var stride := sin(run_phase)
			leg_swing = stride * 0.55
			arm_swing = -stride * 0.7
			target_leg = 1.0 + absf(stride) * 0.22
			target_arm = 1.0 + absf(stride) * 0.12
			target_torso_y = 1.0 - absf(stride) * 0.04
		if land_squash > 0.05:
			target_leg = lerpf(target_leg, 0.45, land_squash)
			target_torso_y = lerpf(target_torso_y, 0.78, land_squash)
			target_torso_x = lerpf(target_torso_x, 1.25, land_squash)
			target_hip_y = land_squash * 8.0

	var leg_s := _spring_toward(leg_len, leg_len_vel, target_leg, 95.0, 12.0, delta)
	leg_len = clampf(leg_s.x, 0.28, 2.0)
	leg_len_vel = leg_s.y
	var arm_s := _spring_toward(arm_len, arm_len_vel, target_arm, 80.0, 11.0, delta)
	arm_len = clampf(arm_s.x, 0.45, 1.65)
	arm_len_vel = arm_s.y
	var ty := _spring_toward(torso_sy, torso_sy_vel, target_torso_y, 65.0, 11.0, delta)
	torso_sy = clampf(ty.x, 0.55, 1.4)
	torso_sy_vel = ty.y
	var tx := _spring_toward(torso_sx, torso_sx_vel, target_torso_x, 65.0, 11.0, delta)
	torso_sx = clampf(tx.x, 0.7, 1.45)
	torso_sx_vel = tx.y
	hip_y_offset = move_toward(hip_y_offset, target_hip_y, delta * 80.0)

	leg_l_y = leg_len
	leg_r_y = leg_len
	if is_on_floor() and not is_crouching and absf(velocity.x) > 20.0:
		var stride := sin(run_phase)
		leg_l_y = clampf(leg_len * (1.0 + stride * 0.38), 0.35, 2.0)
		leg_r_y = clampf(leg_len * (1.0 - stride * 0.38), 0.35, 2.0)

	var fat_w := GameState.width_mult()
	visual.scale = Vector2(facing * fat_w * VISUAL_SIZE, VISUAL_SIZE)
	_push_jelly_pose(fat_w)
	_apply_fat_width()


func _push_jelly_pose(fat_w: float) -> void:
	# Rest proportions in Visual local space (feet ~ y=0)
	var hip := Vector2(0, -16 + hip_y_offset)
	var torso := Vector2(0, -30 + hip_y_offset * 0.35)
	var head := Vector2(0, torso.y - 16.0 * torso_sy)

	var sh_l := torso + Vector2(-11.0 * torso_sx, -1.0)
	var sh_r := torso + Vector2(11.0 * torso_sx, -1.0)
	# Long thin limbs so metaball grows clear arm/leg lobes of the same mass
	var arm_rest := 38.0
	var leg_rest := 34.0

	# Angles from down (+Y); strong outward bias for arm lobes
	var arm_ang_l := 1.05 + arm_swing
	var arm_ang_r := -1.05 - arm_swing
	var hand_l := sh_l + Vector2(sin(arm_ang_l), cos(arm_ang_l)) * arm_rest * arm_len
	var hand_r := sh_r + Vector2(sin(arm_ang_r), cos(arm_ang_r)) * arm_rest * arm_len

	var hip_l := hip + Vector2(-5, 1)
	var hip_r := hip + Vector2(5, 1)
	var leg_ang_l := 0.0
	var leg_ang_r := 0.0
	if is_crouching:
		leg_ang_l = 0.55
		leg_ang_r = -0.55
	elif is_on_floor() and absf(velocity.x) > 20.0:
		leg_ang_l = leg_swing
		leg_ang_r = -leg_swing
	else:
		leg_ang_l = leg_swing * 0.2
		leg_ang_r = -leg_swing * 0.2

	var foot_l := hip_l + Vector2(sin(leg_ang_l), cos(leg_ang_l)) * leg_rest * leg_l_y
	var foot_r := hip_r + Vector2(sin(leg_ang_r), cos(leg_ang_r)) * leg_rest * leg_r_y

	if jelly and jelly.has_method("set_pose"):
		jelly.set_pose(
			head,
			torso,
			hip,
			sh_l,
			sh_r,
			hand_l,
			hand_r,
			foot_l,
			foot_r,
			13.5,
			10.0 * torso_sx,
			10.0 * torso_sy,
			4.6,
			1.0
		)

	tongue.position = Vector2(0, head.y - 2.0)


func _apply_fat_width() -> void:
	var w := GameState.width_mult()
	if body_shape.shape is RectangleShape2D:
		var h := 32.0 if is_crouching else 56.0
		(body_shape.shape as RectangleShape2D).size = Vector2(30.0 * w, h)
	if crouch_shape.shape is RectangleShape2D:
		(crouch_shape.shape as RectangleShape2D).size = Vector2(36.0 * w, 32.0)


func _post_move_feedback() -> void:
	if is_on_floor() and not was_on_floor and velocity.y >= 0.0:
		land_squash = 1.0
		leg_len = 0.4
		leg_len_vel = 0.0
		torso_sy = 0.7
		torso_sx = 1.35
	was_on_floor = is_on_floor()


func _check_enemy_contact() -> void:
	if invuln_timer > 0.0:
		visual.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
		return
	visual.modulate.a = 1.0
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider and collider.is_in_group("enemies"):
			if velocity.y > 0.0 and col.get_normal().y < -0.5:
				if collider.has_method("stomp"):
					collider.stomp()
				velocity.y = JUMP_VELOCITY * 0.55
				leg_len = 1.35
			else:
				_hurt()


func _hurt() -> void:
	if invuln_timer > 0.0:
		return
	GameState.take_damage(1)
	invuln_timer = INVULN_TIME
	velocity = Vector2(-facing * 180.0, -220.0)


func _on_tongue_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("hit_by_tongue"):
		body.hit_by_tongue()
	elif body.is_in_group("pickups") and body.has_method("collect"):
		body.collect()


func set_touch_axis(axis: float) -> void:
	touch_axis = clampf(axis, -1.0, 1.0)


func set_touch_down(pressed: bool) -> void:
	touch_down = pressed


func press_jump() -> void:
	touch_jump_pressed = true


func press_tongue() -> void:
	touch_tongue_pressed = true
