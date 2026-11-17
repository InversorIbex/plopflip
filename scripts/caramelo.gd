extends Area2D
## Caramelo pickup — normal or engordante via export.

enum Kind { NORMAL, ENGORDANTE, GRANDE }

@export var kind: Kind = Kind.NORMAL

@onready var visual: Node2D = $Visual

var collected: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	match kind:
		Kind.NORMAL:
			visual.modulate = Color(1.0, 0.55, 0.75)
		Kind.ENGORDANTE:
			visual.modulate = Color(1.0, 0.75, 0.2)
			visual.scale = Vector2(1.25, 1.25)
		Kind.GRANDE:
			visual.modulate = Color(0.95, 0.35, 0.85)
			visual.scale = Vector2(1.4, 1.4)


func _process(delta: float) -> void:
	if collected:
		return
	visual.position.y = sin(Time.get_ticks_msec() * 0.006 + global_position.x * 0.01) * 4.0
	visual.rotation += delta * 1.2


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect()


func collect() -> void:
	if collected:
		return
	collected = true
	match kind:
		Kind.NORMAL:
			GameState.collect_caramelo(10, 1.0, 0)
		Kind.ENGORDANTE:
			GameState.collect_caramelo(30, 2.0, 1)
		Kind.GRANDE:
			GameState.collect_caramelo(50, 3.0, 0)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.08)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)
