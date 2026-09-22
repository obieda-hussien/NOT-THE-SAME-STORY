extends Node
signal changed
const CASE_PATH := "res://data/case_1142.json"
const VERSION := 1
var definition: Dictionary = {}
var found: Dictionary = {}
var links: Array = []
var board_positions: Dictionary = {}
var resolved := false
var player_position := Vector3(0, 0.35, 7)
var started := false

func _ready() -> void:
	var file := FileAccess.open(CASE_PATH, FileAccess.READ)
	if file == null:
		push_error("Missing case file")
		return
	var loaded: Variant = JSON.parse_string(file.get_as_text())
	if loaded is Dictionary:
		definition = loaded

func new_game() -> void:
	found = {}
	links = []
	board_positions = {}
	resolved = false
	started = true
	player_position = Vector3(0, 0.35, 7)
	changed.emit()

func evidence_for_location(location: String) -> Array:
	var result: Array = []
	for item in definition.get("evidence", []):
		if item["location"] == location:
			result.append(item)
	return result

func evidence_by_id(id: String) -> Dictionary:
	for item in definition.get("evidence", []):
		if item["id"] == id:
			return item
	return {}

func discover(id: String, location: String) -> bool:
	var item := evidence_by_id(id)
	if item.is_empty() or item.get("location") != location or not started:
		return false
	if found.has(id):
		return false
	found[id] = true
	changed.emit()
	return true

func link_key(a: String, b: String) -> String:
	var pair := [a, b]
	pair.sort()
	return "|".join(pair)

func valid_link(a: String, b: String) -> bool:
	for pair in definition.get("required_links", []):
		if link_key(a, b) == link_key(str(pair[0]), str(pair[1])):
			return true
	return false

func connect_clues(a: String, b: String) -> String:
	if a == b or not found.has(a) or not found.has(b):
		return "board.invalid"
	var key := link_key(a, b)
	if key in links:
		return "board.duplicate"
	if not valid_link(a, b):
		return "board.invalid"
	links.append(key)
	changed.emit()
	return "board.connected"

func link_count() -> int:
	var number := 0
	for pair in definition.get("required_links", []):
		if link_key(str(pair[0]), str(pair[1])) in links:
			number += 1
	return number

func evaluate(hypothesis: String) -> String:
	match hypothesis:
		"clock":
			return "hyp.clock_wrong" if found.has("clock_note") else "hyp.not_enough"
		"camera":
			return "hyp.camera_wrong" if found.has("ups") else "hyp.not_enough"
		"jacket":
			return "hyp.jacket_unknown" if found.has("witness_coat") else "hyp.not_enough"
		"roof":
			return "hyp.roof_supported" if link_key("roof_marks", "shop_receipt") in links else "hyp.roof_unproven"
		"ending":
			if link_count() != 3 or not found.has("glass") or not found.has("witness_coat"):
				return "hyp.ending_unproven"
			resolved = true
			changed.emit()
			return "hyp.ending_supported"
	return "hyp.not_enough"

func export_state() -> Dictionary:
	return {"version":VERSION, "case_id":definition.get("id", ""), "found":found.duplicate(true),
		"links":links.duplicate(), "board_positions":board_positions.duplicate(true), "resolved":resolved,
		"position":[player_position.x, player_position.y, player_position.z]}

func import_state(data: Dictionary) -> bool:
	if data.get("version") != VERSION or data.get("case_id") != definition.get("id"):
		return false
	if not (data.get("found") is Dictionary and data.get("links") is Array):
		return false
	var restored: Dictionary = {}
	for key in data["found"]:
		if evidence_by_id(str(key)).is_empty() or data["found"][key] != true:
			return false
		restored[str(key)] = true
	var restored_links: Array = []
	for item in data["links"]:
		if not (item is String):
			return false
		var parts: PackedStringArray = item.split("|")
		if parts.size() != 2 or not restored.has(parts[0]) or not restored.has(parts[1]) or not valid_link(parts[0], parts[1]):
			return false
		if item not in restored_links:
			restored_links.append(item)
	var restored_positions: Dictionary = {}
	var stored_positions: Variant = data.get("board_positions", {})
	if stored_positions is Dictionary:
		for id in stored_positions:
			var coord: Variant = stored_positions[id]
			if not restored.has(str(id)) or not (coord is Array) or coord.size() != 2:
				return false
			if absf(float(coord[0])) > 2000.0 or absf(float(coord[1])) > 2000.0:
				return false
			restored_positions[str(id)] = [float(coord[0]),float(coord[1])]
	var pos: Variant = data.get("position", [])
	if not (pos is Array) or pos.size() != 3:
		return false
	var candidate := Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	if absf(candidate.x) > 50.0 or absf(candidate.z) > 50.0:
		return false
	found = restored
	links = restored_links
	board_positions = restored_positions
	resolved = data.get("resolved", false) == true and link_count() == 3 and found.has("glass") and found.has("witness_coat")
	player_position = candidate
	started = true
	changed.emit()
	return true
