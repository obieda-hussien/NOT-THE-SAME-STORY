extends Control
# Mobile-readable first graph board: drag cards; tap two to propose a causal link.
signal clue_selected(id: String)
const CARD_WIDTH := 219.0
const CARD_HEIGHT := 142.0
const PADDING := 15.0
var cards: Dictionary = {}
var dragging := ""
var pointer_start := Vector2.ZERO
var original := Vector2.ZERO
var moved := false

func _ready() -> void:
	custom_minimum_size = Vector2(950, 362)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()

func _build() -> void:
	var i := 0
	for item in Case.definition.get("evidence", []):
		var id: String = item["id"]
		if not Case.found.has(id):
			continue
		var card := Button.new()
		card.text = Loc.t("ev.name."+id)
		card.text_direction = Control.TEXT_DIRECTION_RTL if Loc.language == "ar_EG" else Control.TEXT_DIRECTION_LTR
		var portrait := ""
		match id:
			"witness_coat": portrait = "amina"
			"camera_frame","roof_marks": portrait = "mariam"
			"clock_note","power_log","glass": portrait = "fared"
			"shop_receipt": portrait = "nabil"
		if not portrait.is_empty():
			card.icon = load("res://assets/portraits/"+portrait+".svg")
			card.expand_icon = true
			card.add_theme_constant_override("icon_max_width",68)
			card.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT if Loc.language == "ar_EG" else HORIZONTAL_ALIGNMENT_LEFT
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card.add_theme_font_size_override("font_size", 16)
		card.add_theme_color_override("font_color", Color("242337"))
		var style := StyleBoxFlat.new()
		style.bg_color = _type_color(item["type"])
		style.border_color = Color("e7d1a0")
		style.set_border_width_all(2)
		style.set_corner_radius_all(13)
		style.set_content_margin_all(10)
		card.add_theme_stylebox_override("normal", style)
		var saved: Variant = Case.board_positions.get(id, null)
		if saved is Array and saved.size() == 2:
			card.position = Vector2(float(saved[0]),float(saved[1]))
		else:
			card.position = Vector2(5.0 + float(i%4)*(CARD_WIDTH+PADDING),5.0 + float(floori(float(i)/4.0))*(CARD_HEIGHT+PADDING))
		cards[id] = card
		var selected_id: String = id
		card.pressed.connect(func():
			if not moved:
				clue_selected.emit(selected_id))
		card.gui_input.connect(func(event: InputEvent): _handle_card(event,selected_id))
		add_child(card)
		i += 1
	queue_redraw()

func _type_color(type: String) -> Color:
	match type:
		"testimony": return Color("e6c4d6")
		"physical": return Color("d1cfec")
		"digital": return Color("b9d9e8")
		"document": return Color("f1e4c5")
	return Color("ddd6cf")

func _handle_card(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index != MOUSE_BUTTON_LEFT:
			return
		if e.pressed:
			dragging = id
			pointer_start = get_local_mouse_position()
			original = cards[id].position
			moved = false
		else:
			_finalize_drag(id)
	elif event is InputEventMouseMotion and dragging == id:
		var motion := event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_drag(id,get_local_mouse_position() - pointer_start)
	elif event is InputEventScreenDrag and dragging == id:
		var touch := event as InputEventScreenDrag
		_drag(id,touch.position - pointer_start)
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			dragging = id
			pointer_start = t.position
			original = cards[id].position
			moved = false
		else:
			_finalize_drag(id)

func _drag(id: String, delta: Vector2) -> void:
	if delta.length() < 8.0 and not moved:
		return
	moved = true
	cards[id].position = Vector2(clampf(original.x+delta.x,0.0,size.x-CARD_WIDTH),clampf(original.y+delta.y,0.0,size.y-CARD_HEIGHT))
	queue_redraw()

func _finalize_drag(id: String) -> void:
	if dragging != id:
		return
	dragging = ""
	if moved:
		Case.board_positions[id] = [cards[id].position.x, cards[id].position.y]
		# Mouse click following the drag must not create a clue connection.
		get_viewport().set_input_as_handled()

func _draw() -> void:
	# Original corkboard presentation inspired by the supplied broad detective mood,
	# not a reproduction of its characters or exact layout.
	draw_rect(Rect2(Vector2.ZERO,size),Color("50443b"),true)
	for i in range(0,int(size.x),28):
		for j in range(0,int(size.y),28):
			draw_circle(Vector2(i,j),1.4,Color("dbc7a2",0.17))
	for pair in Case.links:
		var ids: PackedStringArray = pair.split("|")
		if ids.size() != 2 or not cards.has(ids[0]) or not cards.has(ids[1]):
			continue
		var start: Vector2 = cards[ids[0]].position + Vector2(CARD_WIDTH/2,CARD_HEIGHT/2)
		var end: Vector2 = cards[ids[1]].position + Vector2(CARD_WIDTH/2,CARD_HEIGHT/2)
		draw_line(start,end,Color("8e8de5"),4.0,true)
		draw_circle(start,5.0,Color("ffd080"))
		draw_circle(end,5.0,Color("ffd080"))
