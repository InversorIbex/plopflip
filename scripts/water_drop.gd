extends Area2D
## Water drop — −1 fat stack (GDD §5.2).

@onready var visual: Node2D = $Visual

var collected: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if collected:
		return
	visual.position.y = sin(Time.get_ticks_msec() * 0.005) * 3.0


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect()


func collect() -> void:
	if collected:
		return
	collected = true
	GameState.remove_fat(1)
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2(0.2, 1.8), 0.12)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(queue_free)
