class_name StoryController
extends RefCounted

signal unit_changed(unit: Dictionary)
signal line_changed(line: Dictionary, unit: Dictionary)
signal story_finished

const STORY_PATH := "res://content/story.json"

var units: Array = []
var unit_index := 0
var line_index := 0


func load_story() -> bool:
	var file := FileAccess.open(STORY_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open story data: %s" % STORY_PATH)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Story data is not a JSON object.")
		return false

	var data := parsed as Dictionary
	var loaded_units: Variant = data.get("units", [])
	if typeof(loaded_units) != TYPE_ARRAY or loaded_units.is_empty():
		push_error("Story data has no units.")
		return false

	units = loaded_units
	return true


func start_at(next_unit_index: int = 0, next_line_index: int = 0) -> void:
	if units.is_empty():
		return

	unit_index = clampi(next_unit_index, 0, units.size() - 1)
	var lines := get_current_unit().get("lines", []) as Array
	line_index = clampi(next_line_index, 0, maxi(lines.size() - 1, 0))
	unit_changed.emit(get_current_unit())
	line_changed.emit(get_current_line(), get_current_unit())


func advance() -> void:
	if units.is_empty():
		return

	var lines := get_current_unit().get("lines", []) as Array
	if line_index + 1 < lines.size():
		line_index += 1
		line_changed.emit(get_current_line(), get_current_unit())
		return

	if unit_index + 1 < units.size():
		unit_index += 1
		line_index = 0
		unit_changed.emit(get_current_unit())
		line_changed.emit(get_current_line(), get_current_unit())
		return

	story_finished.emit()


func get_current_unit() -> Dictionary:
	if units.is_empty():
		return {}
	return units[unit_index] as Dictionary


func get_current_line() -> Dictionary:
	var unit := get_current_unit()
	var lines := unit.get("lines", []) as Array
	if lines.is_empty():
		return {}
	return lines[line_index] as Dictionary


func get_progress() -> Dictionary:
	return {
		"unit_index": unit_index,
		"line_index": line_index,
	}
