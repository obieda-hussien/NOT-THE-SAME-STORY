extends Node3D
# Godot 4.7.2, Compatibility renderer. Procedural low-poly diorama is original temp art.
const WALK_SPEED := 5.2
const INTERACTION_RADIUS := 2.2
const BG := Color("111729")
const PANEL := Color("1c2639")
const PANEL_HI := Color("293750")
const WHITE := Color("f4eddb")
const GOLD := Color("ffd080")
const PURPLE := Color("8e8de5")
var camera: Camera3D
var actor: CharacterBody3D
var actor_model: Node3D
var objects: Dictionary = {}
var clue_objects: Dictionary = {}
var keys: Vector2 = Vector2.ZERO
var touch: Vector2 = Vector2.ZERO
var hud: Control
var canvas: CanvasLayer
var window: Control
var toast: Label
var proximity: Label
var current_screen := "menu"
var board_selection := ""
var viewport_font: Font
var _message := ""

func _ready() -> void:
	_make_world()
	_make_overlay()
	Case.changed.connect(_refresh_hud)
	Loc.language_changed.connect(_retranslate)
	_show_menu()

func _make_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b3c7e8")
	env.ambient_light_energy = 0.75
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 27, -30)
	sun.light_color = Color("ffd7a2")
	sun.light_energy = 0.95
	sun.shadow_enabled = false
	add_child(sun)
	_box(Vector3(0,-0.24,-2), Vector3(27,0.42,31), Color("33374f"))
	_box(Vector3(0,-0.02,7), Vector3(26,0.08,7), Color("303548"))
	for i in range(-12, 13, 4):
		_box(Vector3(float(i),0.02,7), Vector3(1.5,0.018,0.11), Color("d2b882"))
	for id in Case.definition.get("map", {}).keys():
		var pos: Dictionary = Case.definition["map"][id]
		var origin := Vector3(float(pos["x"]), 0, float(pos["z"]))
		var color := Color("506079")
		match id:
			"office": color = Color("64506b")
			"maintenance": color = Color("4e6870")
			"roof": color = Color("5d597f")
			"shop": color = Color("827357")
			"street": color = Color("655567")
		_box(origin + Vector3(0,0.018,0), Vector3(5.6,0.04,5.6), color)
		_box(origin + Vector3(0.04,0.15,-2.65), Vector3(5.4,0.3,0.12), Color("bbb0a6"))
		_box(origin + Vector3(-2.65,0.15,0), Vector3(0.12,0.3,5.3), Color("bbb0a6"))
		objects[id] = origin
	_make_props()
	actor = CharacterBody3D.new()
	actor.name = "Investigator"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.65
	var collision := CollisionShape3D.new()
	collision.shape = shape
	actor.add_child(collision)
	add_child(actor)
	actor_model = Node3D.new()
	actor.add_child(actor_model)
	_box(Vector3(0,0.7,0), Vector3(0.73,0.9,0.48), PURPLE, actor_model)
	_box(Vector3(0,1.4,0), Vector3(0.51,0.56,0.48), Color("efbd97"), actor_model)
	_box(Vector3(0,1.76,-0.05), Vector3(0.77,0.20,0.62), Color("28263b"), actor_model)
	_box(Vector3(-0.25,0.17,0), Vector3(0.22,0.52,0.34), Color("222b44"), actor_model)
	_box(Vector3(0.25,0.17,0), Vector3(0.22,0.52,0.34), Color("222b44"), actor_model)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 23.5
	camera.current = true
	add_child(camera)
	actor.global_position = Case.player_position
	_update_camera()

func _make_props() -> void:
	# Each room has a tangible, differently shaped marker; inspection requires proximity.
	_box(Vector3(0,0.7,-0.4),Vector3(1.7,1.3,0.3),Color("202639")) # camera
	_box(Vector3(0,1.3,-0.62),Vector3(1.2,0.75,0.12),Color("9cb8ca"))
	_box(Vector3(-7,0.47,-2),Vector3(2.3,0.9,1.25),Color("695044")) # desk
	_box(Vector3(-7,1,-2),Vector3(1,0.07,0.75),Color("dad9c9"))
	_box(Vector3(7,0.9,-2),Vector3(2.0,1.7,0.4),Color("536f72")) # electrical panel
	for i in range(3):
		_box(Vector3(6.4+float(i)*0.6,1.15,-2.25),Vector3(0.2,0.3,0.10), GOLD)
	for i in range(4):
		_box(Vector3(0,0.10+float(i)*0.12,-7-float(i)*0.43), Vector3(2.2,0.22,0.40),Color("998c84"))
	_box(Vector3(-7,0.22,-11), Vector3(2.3,0.42,2),Color("767e8c"))
	_box(Vector3(-7,0.55,-11.5), Vector3(0.28,0.3,0.6),GOLD)
	_box(Vector3(7,1,-11),Vector3(3.8,1.9,1.4),Color("837354"))
	_box(Vector3(7,1.7,-10.21),Vector3(2.7,0.37,0.10),Color("ddbc84"))
	_box(Vector3(0,0.10,5),Vector3(1.2,0.2,0.6),Color("948378"))
	# Street witness represented with face, dark hair and orange coat.
	_box(Vector3(1.45,0.81,7),Vector3(0.64,1.08,0.50),Color("bd7955"))
	_box(Vector3(1.45,1.5,7),Vector3(0.49,0.52,0.45),Color("f1b48d"))
	_box(Vector3(1.45,1.78,7),Vector3(0.65,0.15,0.51),Color("2b2836"))
	for sx in [-1.0,1.0]:
		_box(Vector3(sx*12.5,1.15,-4),Vector3(0.25,2.4,23),Color("565166"))
	# Each discovery is a separate interactable physical object, not a room-wide loot action.
	clue_objects = {
		"camera_frame": Vector3(0.0,0.0,-0.4),
		"clock_note": Vector3(-8.2,0.0,-0.7),
		"glass": Vector3(-5.9,0.0,-3.6),
		"power_log": Vector3(6.2,0.0,-0.7),
		"ups": Vector3(8.0,0.0,-3.5),
		"witness_coat": Vector3(1.45,0.0,7.0),
		"roof_marks": Vector3(-7.0,0.0,-11.0),
		"shop_receipt": Vector3(7.0,0.0,-11.0),
	}
	for clue_id in clue_objects:
		var loc: Vector3 = clue_objects[clue_id]
		# Gold floor pins are replaceable scene hooks for licensed GLB props.
		_box(loc + Vector3(0.0,0.09,0.0),Vector3(0.38,0.13,0.38),GOLD)

func _box(pos: Vector3, size: Vector3, color: Color, parent: Node3D = null) -> void:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mesh.material_override = mat
	mesh.position = pos
	(parent if parent != null else self).add_child(mesh)

func _make_overlay() -> void:
	viewport_font = SystemFont.new()
	viewport_font.font_names = PackedStringArray(["Noto Sans Arabic", "Noto Sans", "Arial", "Roboto"])
	var theme := Theme.new()
	theme.default_font = viewport_font
	theme.default_font_size = 19
	canvas = CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = theme
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas.add_child(root)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(hud)
	window = Control.new()
	window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(window)
	toast = Label.new()
	toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toast.offset_top = 75
	toast.offset_bottom = 135
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color", GOLD)
	toast.add_theme_color_override("font_shadow_color", Color.BLACK)
	toast.add_theme_constant_override("shadow_offset_x", 2)
	toast.add_theme_constant_override("shadow_offset_y", 2)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast)

func _physics_process(delta: float) -> void:
	if current_screen != "game" or not Case.started:
		return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1
	var v := (direction + touch).limit_length(1.0)
	actor.velocity = Vector3(v.x, 0, v.y) * WALK_SPEED
	actor.move_and_slide()
	actor.position.x = clampf(actor.position.x, -11.8, 11.8)
	actor.position.z = clampf(actor.position.z, -13.3, 11.2)
	if v.length_squared() > 0.03:
		actor_model.rotation.y = lerp_angle(actor_model.rotation.y, atan2(v.x, v.y), minf(delta*9,1.0))
	Case.player_position = actor.position
	if is_instance_valid(proximity):
		var nearby := _nearby_clue()
		var prompt := Loc.t("hud.prompt") if nearby.is_empty() else Loc.t("hud.clue_near") + Loc.t("ev.name."+nearby)
		if proximity.text != prompt:
			proximity.text = prompt
	_update_camera()

func _update_camera() -> void:
	camera.position = actor.global_position + Vector3(15,19,18)
	camera.look_at(actor.global_position + Vector3(0,0.6,0))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or current_screen != "game":
		return
	if key.keycode == KEY_E:
		_inspect()
	if key.keycode == KEY_B:
		_show_board()

func _nearby() -> String:
	var nearest := ""
	var distance := INTERACTION_RADIUS
	for id in objects:
		var d: float = actor.position.distance_to(objects[id])
		if d < distance:
			distance = d
			nearest = id
	return nearest

func _nearby_clue() -> String:
	var nearest := ""
	var distance := INTERACTION_RADIUS
	for clue_id in clue_objects:
		var target: Vector3 = clue_objects[clue_id]
		var d := actor.position.distance_to(target)
		if d < distance:
			distance = d
			nearest = clue_id
	return nearest

func _inspect() -> void:
	var clue_id := _nearby_clue()
	if clue_id.is_empty():
		_show_toast(Loc.t("hint.unavailable"))
		return
	var item: Dictionary = Case.evidence_by_id(clue_id)
	var location: String = item.get("location", "")
	var lines: Array[String] = []
	if clue_id == "witness_coat":
		lines.append(Loc.t("npc.hello"))
	if Case.discover(clue_id, location):
		lines.append(Loc.t("hint.new") + Loc.t(item["text_key"]))
	else:
		lines.append(Loc.t("hint.old") + Loc.t(item["text_key"]))
	_show_message("loc."+location, "\n\n".join(lines))

func _make_button(label: String, callback: Callable, accent: bool = false) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(180,49)
	b.add_theme_color_override("font_color", Color("111729") if accent else WHITE)
	b.add_theme_color_override("font_hover_color", Color("111729") if accent else GOLD)
	var sb := StyleBoxFlat.new()
	sb.bg_color = GOLD if accent else PANEL_HI
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	b.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate()
	hover.bg_color = PURPLE if accent else Color("455575")
	b.add_theme_stylebox_override("hover", hover)
	b.pressed.connect(callback)
	return b

func _label(text_value: String, font_size: int = 19, tint: Color = WHITE) -> Label:
	var l := Label.new()
	l.text = text_value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", tint)
	l.add_theme_font_size_override("font_size", font_size)
	return l

func _clean(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		child.queue_free()

func _panel(title: String, width: float = 930, height: float = 610) -> VBoxContainer:
	_clean(window)
	window.visible = true
	var scrim := ColorRect.new()
	scrim.color = Color(0.035,0.047,0.079,0.87)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	window.add_child(scrim)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(width,height)
	panel.position = Vector2(-width*0.5,-height*0.5)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = PURPLE
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", style)
	window.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	col.add_child(_label(title, 31, GOLD))
	return col

func _show_menu() -> void:
	current_screen = "menu"
	hud.visible = false
	var content := _panel(Loc.t("app.title"),780,555)
	content.add_child(_label(Loc.t("app.subtitle"),22, PURPLE))
	content.add_child(_label(Loc.t("case.title"),27))
	content.add_child(_label(Loc.t("case.brief")))
	content.add_spacer(false)
	content.add_child(_make_button(Loc.t("menu.start"), func(): Case.new_game(); _enter_game(), true))
	if Saves.has_save():
		content.add_child(_make_button(Loc.t("menu.resume"), func():
			if Saves.load_game():
				_enter_game()
			else:
				_show_toast(Loc.t("ui.no_resume"))))
	content.add_child(_make_button(Loc.t("menu.language"),func():
		Loc.apply_language("en" if Loc.language == "ar_EG" else "ar_EG")))
	content.add_child(_make_button(Loc.t("menu.quit"),func():get_tree().quit()))

func _enter_game() -> void:
	actor.position = Case.player_position
	current_screen = "game"
	window.visible = false
	_rebuild_hud()
	_show_toast(Loc.t("hud.prompt"))

func _rebuild_hud() -> void:
	_clean(hud)
	hud.visible = true
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 14
	top.offset_bottom = 74
	top.add_theme_constant_override("separation", 10)
	hud.add_child(top)
	top.add_child(_label(Loc.t("case.title"),25,GOLD))
	top.add_spacer(false)
	var progress := Loc.t("ui.saved").replace("{count}",str(Case.found.size())).replace("{links}",str(Case.link_count()))
	top.add_child(_label(progress,18))
	proximity = _label(Loc.t("hud.prompt"),21,GOLD)
	proximity.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	proximity.offset_left = 24
	proximity.offset_top = 78
	proximity.offset_bottom = 127
	hud.add_child(proximity)
	var bottom := HBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 20
	bottom.offset_right = -20
	bottom.offset_top = -125
	bottom.offset_bottom = -14
	hud.add_child(bottom)
	var left := GridContainer.new()
	left.columns = 3
	bottom.add_child(left)
	var movements := [Vector2(-1,0),Vector2(0,-1),Vector2(1,0),Vector2(0,1)]
	var titles := ["◀","▲","▶","▼"]
	for index in range(4):
		var arrow := _make_button(titles[index],func():pass)
		arrow.custom_minimum_size = Vector2(64,48)
		var heading: Vector2 = movements[index]
		arrow.button_down.connect(func(): touch = heading)
		arrow.button_up.connect(func(): touch = Vector2.ZERO)
		left.add_child(arrow)
	bottom.add_spacer(false)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation",8)
	bottom.add_child(actions)
	actions.add_child(_make_button(Loc.t("hud.interact"), _inspect, true))
	actions.add_child(_make_button(Loc.t("hud.board"), _show_board))
	var others := VBoxContainer.new()
	bottom.add_child(others)
	others.add_child(_make_button(Loc.t("hud.save"),func():
		_show_toast(Loc.t("hud.saved") if Saves.save_game() else Loc.t("hud.save_fail"))))
	others.add_child(_make_button(Loc.t("hud.menu"),func():
		Saves.save_game(); _show_menu()))

func _refresh_hud() -> void:
	if current_screen == "game":
		_rebuild_hud()

func _show_toast(message: String) -> void:
	toast.text = message

func _show_message(title: String, message: String) -> void:
	current_screen = "message"
	hud.visible = false
	var content := _panel(Loc.t(title),920,525)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var paragraph := _label(message,23)
	paragraph.custom_minimum_size.x = 800
	scroll.add_child(paragraph)
	content.add_child(_make_button(Loc.t("ui.dismiss"),_return_to_game,true))

func _return_to_game() -> void:
	current_screen = "game"
	window.visible = false
	_rebuild_hud()

func _show_board() -> void:
	current_screen = "board"
	hud.visible = false
	var content := _panel(Loc.t("board.title"),1060,655)
	content.add_child(_label(Loc.t("board.hint"),18,PURPLE))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 958
	list.add_theme_constant_override("separation",10)
	scroll.add_child(list)
	if Case.found.is_empty():
		list.add_child(_label(Loc.t("board.empty")))
	else:
		var diagram := Control.new()
		diagram.set_script(load("res://scripts/ui/evidence_board.gd"))
		list.add_child(diagram)
		diagram.connect("clue_selected",Callable(self,"_choose_evidence"))
	list.add_child(_label(Loc.t("board.links"),21,GOLD))
	if Case.links.is_empty():
		list.add_child(_label(Loc.t("board.no_links")))
	else:
		for link in Case.links:
			var split: PackedStringArray = link.split("|")
			list.add_child(_label("↔  "+Loc.t(Case.evidence_by_id(split[0])["text_key"])+"\n       "+Loc.t(Case.evidence_by_id(split[1])["text_key"]),16))
	var footer := HBoxContainer.new()
	content.add_child(footer)
	footer.add_child(_make_button(Loc.t("board.timeline"),_show_timeline,true))
	footer.add_child(_make_button(Loc.t("board.close"),_return_to_game))

func _choose_evidence(id: String) -> void:
	if board_selection.is_empty() or board_selection == id:
		board_selection = id
		_show_toast(Loc.t("board.select")+Loc.t(Case.evidence_by_id(id)["text_key"]))
	else:
		var feedback := Case.connect_clues(board_selection,id)
		board_selection = ""
		_show_toast(Loc.t(feedback))
	_show_board()

func _show_timeline() -> void:
	current_screen = "timeline"
	var content := _panel(Loc.t("timeline.title"),1000,660)
	content.add_child(_label(Loc.t("timeline.hint"),18,PURPLE))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var theories := VBoxContainer.new()
	theories.custom_minimum_size.x = 880
	theories.add_theme_constant_override("separation",8)
	scroll.add_child(theories)
	for id in ["clock","camera","jacket","roof","ending"]:
		var hypothesis: String = id
		theories.add_child(_make_button(Loc.t("hyp."+id),func():_test(hypothesis),id == "ending"))
	content.add_child(_make_button(Loc.t("board.close"),_return_to_game))

func _test(hypothesis: String) -> void:
	var feedback := Case.evaluate(hypothesis)
	if hypothesis == "ending" and Case.resolved:
		Saves.save_game()
	_show_message("timeline.title",Loc.t(feedback))

func _retranslate() -> void:
	match current_screen:
		"menu":_show_menu()
		"game":_rebuild_hud()
		"board":_show_board()
		"timeline":_show_timeline()
		"message":_return_to_game()
