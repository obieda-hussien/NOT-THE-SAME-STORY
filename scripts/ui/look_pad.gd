extends Control
## Screen-relative swipe area independent of movement stick and contextual buttons.
signal look_changed(delta_pixels: Vector2)
var active_finger := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and active_finger == -1:
			active_finger = touch.index
			accept_event()
		elif not touch.pressed and touch.index == active_finger:
			active_finger = -1
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == active_finger:
			look_changed.emit(drag.relative)
			accept_event()

func _exit_tree() -> void:
	active_finger = -1
