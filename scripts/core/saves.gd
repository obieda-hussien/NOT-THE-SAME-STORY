extends Node
const SAVE := "user://case_save_v1.json"
const TEMP := "user://case_save_v1.tmp"
const BACKUP := "user://case_save_v1.bak"

func has_save() -> bool:
	return _read_verified(SAVE) != null or _read_verified(BACKUP) != null

func save_game() -> bool:
	if not Case.started:
		return false
	var state: Dictionary = Case.export_state()
	# Hash the exact serialized bytes; JSON.parse_string can normalize ints to floats.
	var serialized := JSON.stringify(state)
	var envelope := {"payload_json":serialized, "checksum":serialized.sha256_text()}
	var tmp := FileAccess.open(TEMP, FileAccess.WRITE)
	if tmp == null:
		return false
	tmp.store_string(JSON.stringify(envelope))
	tmp.flush()
	tmp.close()
	if _read_verified(TEMP) == null:
		return false
	var src := ProjectSettings.globalize_path(SAVE)
	var bak := ProjectSettings.globalize_path(BACKUP)
	var temp := ProjectSettings.globalize_path(TEMP)
	if FileAccess.file_exists(SAVE):
		if FileAccess.file_exists(BACKUP):
			DirAccess.remove_absolute(bak)
		if DirAccess.rename_absolute(src, bak) != OK:
			return false
	if DirAccess.rename_absolute(temp, src) != OK:
		if FileAccess.file_exists(BACKUP):
			DirAccess.rename_absolute(bak, src)
		return false
	return true

func load_game() -> bool:
	var state: Variant = _read_verified(SAVE)
	if state == null:
		state = _read_verified(BACKUP)
	if state == null:
		return false
	return Case.import_state(state)

func _read_verified(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var value: Variant = JSON.parse_string(f.get_as_text())
	if not (value is Dictionary) or not (value.get("payload_json") is String):
		return null
	var raw: String = value["payload_json"]
	if value.get("checksum", "") != raw.sha256_text():
		return null
	var restored: Variant = JSON.parse_string(raw)
	return restored if restored is Dictionary else null
