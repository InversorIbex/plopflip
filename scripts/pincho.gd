extends StaticBody2D
## E2 Pincho-dulce — spikes open/close; tongue only when retracted; no stomp.

@onready var visual: Node2D = $Visual

var spikes_out: bool = true
var timer: float = 0.0
var alive: bool = true


func _ready() -> void:
	add_to_group("enemies")
	timer = randf() * 1.2


func _process(delta: float) -> void:
	if not alive:
		return
	timer += delta
	if timer >= 1.4:
		timer = 0.0
		spikes_out = not spikes_out
		_update_visual()


func _update_visual() -> void:
	if visual:
		visual.modulate = Color(1.0, 0.35, 0.45) if spikes_out else Color(0.95, 0.7, 0.75)
		visual.scale = Vector2(1.1, 1.15) if spikes_out else Vector2(0.95, 0.85)


func hit_by_tongue() -> void:
	if spikes_out:
		return
	_defeat()


func stomp() -> void:
	# No stomp — hurts player instead (handled by contact)
	pass


func damages_on_contact() -> bool:
	return spikes_out


func _defeat() -> void:
	if not alive:
		return
	alive = false
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
