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


func begin_timed_sequence(_unit_id: String, _line_id: String) -> void:
	pass


func begin_voice_handoff(_unit_id: String) -> bool:
	return false


func blocks_input() -> bool:
	return false


func handles_custom_reveal() -> bool:
	return false


func tick_reveal(_delta: float, _text_speed: float) -> bool:
	return false


func request_story_advance() -> void:
	var callback: Callable = context.get("advance_story", Callable())
	if callback.is_valid():
		callback.call()
		return
	var story_ref = context.get("story")
	if story_ref != null:
		story_ref.call("advance")


func advance() -> bool:
	return false


func finish_reveal() -> bool:
	return false


func on_auto_timeout() -> bool:
	return false


func position_caption(_label: Label, _presentation: String) -> bool:
	return false


func paginate_dialogue(_line: Dictionary) -> Array[String]:
	return []


func auto_wait_multiplier(_line: Dictionary, _unit: Dictionary) -> float:
	return 1.0


func uses_speaker_label() -> bool:
	return false


func position_bubble(
	_panel: PanelContainer,
	_tail: Polygon2D,
	_speaker: String,
	_text: String,
) -> bool:
	return false


func resume() -> bool:
	return false


func leave() -> void:
	pass
