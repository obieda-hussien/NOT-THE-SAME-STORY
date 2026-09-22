extends Control
## Dedicated touch-only analog stick. No keyboard or mouse gameplay mapping.
signal changed(direction: Vector2)
var active_finger := -1
var direction := Vector2.ZERO
const RADIUS := 64.0
const DEAD_ZONE := 0.12

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(172,172)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and active_finger == -1:
			active_finger = touch.index
			_sample(touch.position)
			accept_event()
		elif not touch.pressed and touch.index == active_finger:
			release()
			accept_event()
	elif event is InputEventScreenDrag:
		var swipe := event as InputEventScreenDrag
		if swipe.index == active_finger:
			_sample(swipe.position)
			accept_event()

func _sample(local_position: Vector2) -> void:
	var value := ((local_position - size*0.5)/RADIUS).limit_length(1.0)
	if value.length() < DEAD_ZONE:
		value = Vector2.ZERO
	direction = value
	changed.emit(direction)
	queue_redraw()

func release() -> void:
	active_finger = -1
	direction = Vector2.ZERO
	changed.emit(direction)
	queue_redraw()

func _exit_tree() -> void:
	if active_finger != -1:
		release()

func _draw() -> void:
	var center := size*0.5
	draw_circle(center,RADIUS+7,Color("0e1628",0.53))
	draw_arc(center,RADIUS,0.0,TAU,50,Color("8e8de5",0.72),3.0,true)
	draw_line(center,center+direction*RADIUS,Color("a3a2e5",0.37),3.0,true)
	draw_circle(center+direction*RADIUS,27,Color("8e8de5",0.94))
	draw_arc(center+direction*RADIUS,28,0,TAU,40,Color("e9e6ff",0.9),2.0,true)
