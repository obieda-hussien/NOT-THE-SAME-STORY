extends Node3D
# Godot 4.7.2, Compatibility renderer. Procedural low-poly diorama is original temp art.
const WALK_SPEED := 4.3
const LOOK_SENSITIVITY := 0.0038
const GRAVITY := 21.0
const INTERACTION_RADIUS := 2.2
const BG := Color("111729")
const PANEL := Color("1c2639")
const PANEL_HI := Color("293750")
const WHITE := Color("f4eddb")
const GOLD := Color("ffd080")
const PURPLE := Color("8e8de5")
var camera: Camera3D
var world_root: Node3D
var camera_mode := 0 # 0 first-person, 1 shoulder, 2 fixed surveillance
var yaw := 0.0
var pitch := 0.0
var actor: CharacterBody3D
var actor_model: Node3D
var objects: Dictionary = {}
var clue_objects: Dictionary = {}
var keys: Vector2 = Vector2.ZERO
var touch: Vector2 = Vector2.ZERO
var stick: Control
var look_pad: Control
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
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c0bed6")
	env.ambient_light_energy = 0.85
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42,30,-24)
	light.light_color = Color("eecfac")
	light.light_energy = 1.05
	light.shadow_enabled = false
	add_child(light)
	world_root = Node3D.new()
	world_root.set_script(load("res://scripts/world/neighborhood.gd"))
	world_root.name = "PhysicalNeighborhood"
	add_child(world_root)
	world_root.call("build",Case.definition)
	objects = world_root.get("points")
	clue_objects = world_root.get("clues")
	actor = CharacterBody3D.new()
	actor.name = "Investigator"
	actor.floor_snap_length = 0.38
	actor.collision_layer = 1
	actor.collision_mask = 1
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.31
	capsule.height = 1.70
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.86
	actor.add_child(collision)
	add_child(actor)
	actor_model = Node3D.new()
	actor.add_child(actor_model)
	_box(Vector3(0,0.89,0),Vector3(0.68,1.01,0.46),Color("655e9a"),actor_model)
	_box(Vector3(0,1.52,0),Vector3(0.45,0.45,0.40),Color("c99372"),actor_model)
	_box(Vector3(0,1.78,0.01),Vector3(0.58,0.19,0.50),Color("2d2940"),actor_model)
	_box(Vector3(-0.24,0.25,0),Vector3(0.18,0.51,0.29),Color("2a304b"),actor_model)
	_box(Vector3(0.24,0.25,0),Vector3(0.18,0.51,0.29),Color("2a304b"),actor_model)
	_box(Vector3(0.31,0.88,0),Vector3(0.17,0.62,0.25),Color("d8b1a2"),actor_model)
	_box(Vector3(-0.31,0.88,0),Vector3(0.17,0.62,0.25),Color("d8b1a2"),actor_model)
	_box(Vector3(0,1.17,0.27),Vector3(0.22,0.35,0.07),Color("e8c97a"),actor_model)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 74.0
	camera.near = 0.08
	camera.current = true
	add_child(camera)
	actor.global_position = Case.player_position
	_update_camera()
	actor_model.visible = false

func _box(pos: Vector3, dimensions: Vector3, color: Color, parent: Node3D = null) -> void:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = dimensions
	mesh.mesh = cube
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mesh.material_override = mat
	mesh.position = pos
	(parent if parent != null else self).add_child(mesh)

func _make_overlay() -> void:
	viewport_font = SystemFont.new()
	viewport_font.font_names = PackedStringArray(["Noto Naskh Arabic", "Noto Sans Arabic", "Noto Sans", "Roboto"])
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
	var motion := Vector3.ZERO
	if camera_mode != 2:
		# Stick y points down on screen; negative y is forward (-Z).
		motion = Vector3(touch.x,0,touch.y).rotated(Vector3.UP,yaw).limit_length(1.0)
	actor.velocity.x = motion.x * WALK_SPEED
	actor.velocity.z = motion.z * WALK_SPEED
	if actor.is_on_floor():
		actor.velocity.y = -0.15
	else:
		actor.velocity.y -= GRAVITY * delta
	actor.move_and_slide()
	if motion.length_squared() > 0.04:
		actor_model.rotation.y = lerp_angle(actor_model.rotation.y,atan2(-motion.x,-motion.z),minf(delta*9.0,1.0))
	Case.player_position = actor.global_position
	if is_instance_valid(proximity):
		var evidence := _nearby_clue()
		var door: String = world_root.call("nearest_door",actor.global_position)
		var prompt := Loc.t("hud.prompt")
		if not evidence.is_empty():
			prompt = Loc.t("hud.clue_near") + Loc.t("ev.name."+evidence)
		elif not door.is_empty():
			prompt = Loc.t("hud.door_near") + Loc.t("loc."+door)
		if proximity.text != prompt:
			proximity.text = prompt
	_update_camera()

func _update_camera() -> void:
	if camera_mode == 2:
		camera.global_position = Vector3(0.8,6.7,4.8)
		camera.look_at(Vector3(0,0.6,-1.9),Vector3.UP)
	elif camera_mode == 1:
		camera.global_position = actor.global_position + Vector3(0,2.20,0) + Vector3(0,0,3.65).rotated(Vector3.UP,yaw)
		camera.look_at(actor.global_position + Vector3(0,1.25,0),Vector3.UP)
	else:
		camera.global_position = actor.global_position + Vector3(0,1.59,0)
		camera.rotation = Vector3(pitch,yaw,0)
	actor_model.visible = camera_mode != 0

func _look(delta_pixels: Vector2) -> void:
	if current_screen != "game" or camera_mode == 2:
		return
	yaw -= delta_pixels.x * LOOK_SENSITIVITY
	pitch = clampf(pitch-delta_pixels.y*LOOK_SENSITIVITY,-1.20,1.20)
	_update_camera()

func _cycle_camera() -> void:
	camera_mode = (camera_mode+1)%3
	touch = Vector2.ZERO
	if is_instance_valid(stick):
		stick.call("release")
	_show_toast(Loc.t(["camera.first","camera.shoulder","camera.cctv"][camera_mode]))
	_update_camera()

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
		var door_id: String = world_root.call("nearest_door",actor.global_position)
		if not door_id.is_empty() and world_root.call("toggle_door",door_id,actor.global_position):
			_show_toast(Loc.t("hud.door_toggled"))
			return
		_show_toast(Loc.t("hint.unavailable"))
		return
	var item: Dictionary = Case.evidence_by_id(clue_id)
	var location: String = item.get("location","")
	var lines: Array[String] = []
	if clue_id == "witness_coat":
		lines.append(Loc.t("npc.hello"))
	if Case.discover(clue_id,location):
		lines.append(Loc.t("hint.new")+Loc.t(item["text_key"]))
	else:
		lines.append(Loc.t("hint.old")+Loc.t(item["text_key"]))
	var portrait := ""
	match clue_id:
		"witness_coat": portrait = "amina"
		"camera_frame","roof_marks": portrait = "mariam"
		"power_log","clock_note","glass": portrait = "fared"
		"shop_receipt": portrait = "nabil"
	_show_message("loc."+location,"\n\n".join(lines),portrait,clue_id)

func _make_button(label: String, callback: Callable, accent: bool = false) -> Button:
	var b := Button.new()
	b.text = label
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.text_direction = Control.TEXT_DIRECTION_RTL if Loc.language == "ar_EG" else Control.TEXT_DIRECTION_LTR
	b.custom_minimum_size = Vector2(136,55)
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
	l.text_direction = Control.TEXT_DIRECTION_RTL if Loc.language == "ar_EG" else Control.TEXT_DIRECTION_LTR
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if Loc.language == "ar_EG" else HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	scrim.color = Color(0.035,0.047,0.079,0.90)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	window.add_child(scrim)
	var panel := PanelContainer.new()
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	var safe_width := minf(width,viewport.x*0.94)
	var safe_height := minf(height,viewport.y*0.91)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -safe_width*0.5
	panel.offset_right = safe_width*0.5
	panel.offset_top = -safe_height*0.5
	panel.offset_bottom = safe_height*0.5
	panel.clip_contents = true
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = PURPLE
	style.set_border_width_all(2)
	style.set_corner_radius_all(17)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel",style)
	window.add_child(panel)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation",9)
	panel.add_child(col)
	col.add_child(_label(title,26,GOLD))
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
	camera_mode = 0
	touch = Vector2.ZERO
	_update_camera()
	current_screen = "game"
	window.visible = false
	_rebuild_hud()
	_show_toast(Loc.t("hud.prompt"))

func _rebuild_hud() -> void:
	_clean(hud)
	hud.visible = true
	# The right half handles free-look; controls sit above it and consume their touches.
	look_pad = Control.new()
	look_pad.set_script(load("res://scripts/ui/look_pad.gd"))
	look_pad.anchor_left = 0.42
	look_pad.anchor_right = 1.0
	look_pad.anchor_top = 0.14
	look_pad.anchor_bottom = 0.96
	hud.add_child(look_pad)
	look_pad.connect("look_changed",Callable(self,"_look"))
	var header := HBoxContainer.new()
	header.anchor_right = 1.0
	header.offset_left = 20
	header.offset_right = -20
	header.offset_top = 10
	header.offset_bottom = 73
	header.add_theme_constant_override("separation",9)
	hud.add_child(header)
	var title := _label(Loc.t("case.title"),21,GOLD)
	header.add_child(title)
	header.add_spacer(false)
	var progress := Loc.t("ui.saved").replace("{count}",str(Case.found.size())).replace("{links}",str(Case.link_count()))
	var status := _label(progress,15)
	status.custom_minimum_size.x = 140
	header.add_child(status)
	header.add_child(_make_button(Loc.t("hud.camera"),_cycle_camera))
	header.add_child(_make_button(Loc.t("hud.menu"),func():
		Saves.save_game()
		_show_menu()))
	proximity = _label(Loc.t("hud.prompt"),17,GOLD)
	proximity.anchor_left = 0.20
	proximity.anchor_right = 0.80
	proximity.offset_top = 77
	proximity.offset_bottom = 125
	proximity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(proximity)
	stick = Control.new()
	stick.set_script(load("res://scripts/ui/touch_joystick.gd"))
	stick.anchor_top = 1.0
	stick.anchor_bottom = 1.0
	stick.offset_left = 24
	stick.offset_right = 196
	stick.offset_top = -216
	stick.offset_bottom = -44
	hud.add_child(stick)
	stick.connect("changed",func(dir:Vector2):touch=dir)
	var actions := VBoxContainer.new()
	actions.anchor_left = 1.0
	actions.anchor_right = 1.0
	actions.anchor_top = 1.0
	actions.anchor_bottom = 1.0
	actions.offset_left = -220
	actions.offset_right = -22
	actions.offset_top = -236
	actions.offset_bottom = -30
	actions.add_theme_constant_override("separation",7)
	hud.add_child(actions)
	actions.add_child(_make_button(Loc.t("hud.interact"),_inspect,true))
	actions.add_child(_make_button(Loc.t("hud.board"),_show_board))
	actions.add_child(_make_button(Loc.t("hud.save"),func():
		_show_toast(Loc.t("hud.saved") if Saves.save_game() else Loc.t("hud.save_fail"))))

func _refresh_hud() -> void:
	if current_screen == "game":
		_rebuild_hud()

func _show_toast(message: String) -> void:
	toast.text = message

func _show_message(title: String, message: String, portrait_id: String = "", evidence_id: String = "") -> void:
	current_screen = "message"
	hud.visible = false
	var content := _panel(Loc.t(title),900,540)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation",14)
	content.add_child(row)
	if portrait_id in ["amina","mariam","fared","nabil"]:
		var image := TextureRect.new()
		image.texture = load("res://assets/portraits/"+portrait_id+".svg")
		image.custom_minimum_size = Vector2(112,112)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(image)
	if evidence_id in ["camera_frame","clock_note","power_log","roof_marks"]:
		var evidence_picture := TextureRect.new()
		evidence_picture.texture = load("res://assets/evidence/"+evidence_id+".svg")
		evidence_picture.custom_minimum_size = Vector2(156,116)
		evidence_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		evidence_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		evidence_picture.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(evidence_picture)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(scroll)
	var paragraph := _label(message,23)
	paragraph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	list.custom_minimum_size.x = 0
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	theories.custom_minimum_size.x = 0
	theories.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
