extends CharacterBody2D
## Stretchy gummy player — Fase 0 feel prototype (GDD §2, §8.4).

const SPEED := 220.0
const JUMP_VELOCITY := -420.0
const DOUBLE_JUMP_VELOCITY := -380.0
const GRAVITY := 1100.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.09
const CROUCH_SCALE_Y := 0.55
const TONGUE_REACH := 72.0
const TONGUE_DURATION := 0.32
const INVULN_TIME := 1.0

@onready var visual: Node2D = $Visual
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var crouch_shape: CollisionShape2D = $CrouchShape
@onready var tongue: Area2D = $Tongue
@onready var tongue_visual: Line2D = $Tongue/TongueLine
@onready var tongue_tip: CollisionShape2D = $Tongue/Tip
@onready var anim_squash: Node2D = $Visual

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
var stretch_spring: Vector2 = Vector2.ONE
var stretch_vel: Vector2 = Vector2.ZERO

## Virtual / touch overrides from HUD (−1..1 horizontal, bools)
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
	_update_stretch(delta)
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
	land_squash = move_toward(land_squash, 0.0, delta * 4.0)


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
		visual.scale.x = absf(visual.scale.x) * facing
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		GameState.tick_move_drain(delta, false)


func _handle_jump() -> void:
	if _jump_just():
		jump_buffer_timer = JUMP_BUFFER
	touch_jump_pressed = false

	if jump_buffer_timer <= 0.0:
		return

	# Ground / coyote jump
	if coyote_timer > 0.0 and not is_crouching:
		if GameState.spend_energy(GameState.COST_JUMP):
			velocity.y = JUMP_VELOCITY * GameState.jump_mult()
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			can_double_jump = true
			_impulse_stretch(Vector2(0.75, 1.35))
		return

	# Double jump — always available when airborne + energy (GDD)
	if can_double_jump and not is_on_floor() and not GameState.is_low_energy():
		if GameState.spend_energy(GameState.COST_DOUBLE_JUMP):
			velocity.y = DOUBLE_JUMP_VELOCITY * GameState.jump_mult()
			can_double_jump = false
			jump_buffer_timer = 0.0
			_impulse_stretch(Vector2(0.7, 1.45))


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
		# else: no energy feedback — HUD flashes via energy_changed


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


func _impulse_stretch(target: Vector2) -> void:
	stretch_spring = target
	stretch_vel = Vector2.ZERO


func _update_stretch(delta: float) -> void:
	# Spring toward resting scale with squash on land / crouch
	var rest := Vector2.ONE
	if is_crouching:
		rest = Vector2(1.25, CROUCH_SCALE_Y)
	elif not is_on_floor():
		var air := clampf(absf(velocity.y) / 420.0, 0.0, 0.5)
		rest = Vector2(1.0 - air * 0.45, 1.0 + air * 0.6)
	rest.x *= (1.0 + land_squash * 0.35)
	rest.y *= (1.0 - land_squash * 0.4)

	# Soft spring — readable jelly squash/stretch (Fase 0 feel)
	var stiffness := 55.0
	var damping := 9.0
	var force := (rest - stretch_spring) * stiffness - stretch_vel * damping
	stretch_vel += force * delta
	stretch_spring += stretch_vel * delta
	# Clamp so extreme impulses stay readable, not broken
	stretch_spring.x = clampf(stretch_spring.x, 0.55, 1.55)
	stretch_spring.y = clampf(stretch_spring.y, 0.45, 1.7)

	var w := GameState.width_mult()
	visual.scale = Vector2(stretch_spring.x * w * facing, stretch_spring.y)
	# Keep logical hitbox width growing with fat (GDD: hitbox more stable than mesh, width grows)
	_apply_fat_width()


func _apply_fat_width() -> void:
	var w := GameState.width_mult()
	if body_shape.shape is RectangleShape2D:
		(body_shape.shape as RectangleShape2D).size = Vector2(28.0 * w, 48.0)
	if crouch_shape.shape is RectangleShape2D:
		(crouch_shape.shape as RectangleShape2D).size = Vector2(32.0 * w, 28.0)


func _post_move_feedback() -> void:
	if is_on_floor() and not was_on_floor and velocity.y >= 0.0:
		land_squash = 1.0
		_impulse_stretch(Vector2(1.35, 0.65))
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
			# Stomp if coming from above
			if velocity.y > 0.0 and col.get_normal().y < -0.5:
				if collider.has_method("stomp"):
					collider.stomp()
				velocity.y = JUMP_VELOCITY * 0.55
				_impulse_stretch(Vector2(0.8, 1.2))
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


# --- Touch API for HUD ---
func set_touch_axis(axis: float) -> void:
	touch_axis = clampf(axis, -1.0, 1.0)


func set_touch_down(pressed: bool) -> void:
	touch_down = pressed


func press_jump() -> void:
	touch_jump_pressed = true


func press_tongue() -> void:
	touch_tongue_pressed = true
