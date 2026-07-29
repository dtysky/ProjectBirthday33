class_name ChapterDirector
extends RefCounted

var chapter_number := 0
var context: Dictionary = {}


func setup(director_context: Dictionary) -> void:
	context = director_context


func on_unit_changed(_unit: Dictionary) -> void:
	pass


func on_line_changed(_line: Dictionary, _unit: Dictionary) -> bool:
	return false


func handles_custom_reveal() -> bool:
	return false


func advance() -> bool:
	return false


func finish_reveal() -> bool:
	return false


func on_auto_timeout() -> bool:
	return false


func position_caption(_label: Label, _presentation: String) -> bool:
	return false


func resume() -> bool:
	return false


func leave() -> void:
	pass
