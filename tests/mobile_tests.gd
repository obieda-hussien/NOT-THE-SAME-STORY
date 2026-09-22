extends SceneTree
## Mobile/world runtime smoke tests run with Godot --headless.
var passes := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, title: String) -> void:
	if condition:
		passes += 1
		print("PASS mobile: ", title)
	else:
		failures += 1
		printerr("FAIL mobile: ", title)

func _run() -> void:
	var case: Node = root.get_node("Case")
	case.new_game()
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	var neighborhood: Node3D = game.get_node("PhysicalNeighborhood")
	var actor: CharacterBody3D = game.get_node("Investigator")
	check(neighborhood != null, "physical scene exists")
	var solids := 0
	for child in neighborhood.get_children():
		if child is StaticBody3D:
			solids += 1
	check(solids > 30,"walls, trees, poles, furniture and NPC have physical bodies")
	check(actor.collision_mask == 1 and actor.floor_snap_length > 0.0,"player has physical collision and floor snap")
	check(neighborhood.get("doors").size() >= 4,"four interactive doors exist")
	check(not neighborhood.call("toggle_door","office",Vector3(8,0,8)),"doors cannot be opened remotely")
	var access := Vector3(-2.15,0,-2)
	check(neighborhood.call("toggle_door","office",access),"door opens in proximity")
	await physics_frame
	var doors: Dictionary = neighborhood.get("doors")
	check(doors["office"]["open"] == true,"door stays open")
	check(doors["office"]["shape"].disabled == true,"open door removes collision")
	check(neighborhood.call("toggle_door","office",access),"door closes")
	await physics_frame
	check(doors["office"]["shape"].disabled == false,"closed door blocks movement")
	actor.global_position = Vector3(0,0.35,7)
	actor.move_and_collide(Vector3(-30,0,0))
	check(actor.global_position.x > -12.6,"player cannot pass street walls")
	game.call("_enter_game")
	check(game.get("camera_mode") == 0,"game starts first-person")
	game.call("_cycle_camera")
	check(game.get("camera_mode") == 1,"camera switches to over shoulder")
	game.call("_cycle_camera")
	check(game.get("camera_mode") == 2,"camera switches to fixed CCTV")
	game.call("_cycle_camera")
	check(game.get("camera_mode") == 0,"camera returns to first person")
	var font_lang: Node = root.get_node("Loc")
	font_lang.apply_language("ar_EG")
	game.call("_show_message","loc.office","دي تجربة طويلة بالعربي عشان نتأكد إن الكلام جوه الشاشة ومش بيتقص برا حدود الديالوج.")
	await process_frame
	var window: Control = game.get("window")
	var panel: PanelContainer = window.get_child(1)
	var visible: Rect2 = root.get_visible_rect()
	check(visible.encloses(panel.get_global_rect()),"Arabic dialogue panel stays on screen")
	var image: Texture2D = load("res://assets/portraits/amina.svg")
	check(image != null,"original character portrait imported")
	font_lang.apply_language("en")
	game.queue_free()
	print("RESULT mobile: ", passes, "/", passes + failures)
	quit(0 if failures == 0 else 1)
