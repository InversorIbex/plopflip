extends Node
## Relays _input to parent TouchControls — Control._input is unreliable.


func _ready() -> void:
	set_process_input(true)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	var parent := get_parent()
	if parent and parent.has_method("handle_input_event"):
		parent.handle_input_event(event)
