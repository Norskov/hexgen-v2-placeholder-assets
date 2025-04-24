extends Camera2D

@onready var sub_viewport_container: SubViewportContainer = $"../.."
@onready var sub_viewport: SubViewport = $".."

var init_done = false

func _process(delta: float) -> void:
	if not init_done:
		var s = sub_viewport_container.size
		offset = s / 2	

func _on_v_slider_value_changed(value: float) -> void:
	#var s = sub_viewport_container.size
	#offset = s / 2
	zoom = Vector2(value, value)
