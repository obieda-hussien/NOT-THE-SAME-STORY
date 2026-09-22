extends Node
signal language_changed
const FILE := "user://preferences.json"
const TRANSLATIONS := "res://data/translations.json"
var language := "en"
var strings: Dictionary = {}

func _ready() -> void:
	var f := FileAccess.open(TRANSLATIONS, FileAccess.READ)
	if f != null:
		var value: Variant = JSON.parse_string(f.get_as_text())
		if value is Dictionary:
			strings = value
	var p := FileAccess.open(FILE, FileAccess.READ)
	if p != null:
		var pref: Variant = JSON.parse_string(p.get_as_text())
		if pref is Dictionary and pref.get("language", "en") in ["ar_EG", "en"]:
			language = pref["language"]
	apply_language(language)

func apply_language(code: String) -> void:
	if code not in ["en", "ar_EG"]:
		return
	language = code
	TranslationServer.set_locale("ar_EG" if code == "ar_EG" else "en")
	var p := FileAccess.open(FILE, FileAccess.WRITE)
	if p != null:
		p.store_string(JSON.stringify({"language":language}))
	language_changed.emit()

func t(key: String) -> String:
	var fallback: Dictionary = strings.get("en", {})
	return str(strings.get(language, {}).get(key, fallback.get(key, key)))
