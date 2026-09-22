extends SceneTree
# Execute after importing project: godot --headless --path . --script tests/core_tests.gd
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)
	else:
		print("PASS: ", description)

func _run() -> void:
	var game: Node = get_root().get_node("Case")
	var language: Node = get_root().get_node("Loc")
	var saves: Node = get_root().get_node("Saves")
	game.new_game()
	_check(game.definition["truth"]["camera_offset_minutes"] == 7,"canonical camera offset")
	_check(not game.discover("roof_marks", "entrance"),"wrong-location discovery denied")
	_check(not game.discover("invented", "entrance"),"unknown evidence denied")
	_check(game.discover("camera_frame", "entrance"),"valid discovery")
	_check(not game.discover("camera_frame", "entrance"),"discovery idempotent")
	_check(game.connect_clues("camera_frame", "clock_note") == "board.invalid","cannot connect undiscovered clue")
	_check(game.discover("clock_note", "office"),"clock discovery")
	_check(game.connect_clues("clock_note", "camera_frame") == "board.connected","verified connection")
	_check(game.connect_clues("clock_note", "camera_frame") == "board.duplicate","deduplicate connections")
	_check(game.evaluate("clock") == "hyp.clock_wrong","timestamp contradiction")
	_check(game.evaluate("camera") == "hyp.not_enough","UPS cannot be assumed")
	_check(game.discover("ups", "maintenance"),"UPS discovery")
	_check(game.evaluate("camera") == "hyp.camera_wrong","UPS changes camera explanation")
	game.board_positions["camera_frame"] = [38.0,49.0]
	var original: Dictionary = game.export_state()
	language.apply_language("ar_EG")
	_check(JSON.stringify(original) == JSON.stringify(game.export_state()),"changing language preserves truth and progress")
	language.apply_language("en")
	_check(saves.save_game(),"atomic save")
	game.new_game()
	_check(saves.load_game(),"restore save")
	_check(game.found.has("camera_frame") and game.link_count() == 1,"restored evidence and links")
	_check(game.board_positions.get("camera_frame",[]) == [38.0,49.0],"board layout preserved")
	_check(game.export_state()["case_id"] == "case_1142","restored correct case")
	print("RESULT: ", checks - failures, "/", checks, " passed")
	quit(0 if failures == 0 else 1)
