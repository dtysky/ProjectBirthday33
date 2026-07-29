extends ChapterDirector

const OPENING_UNIT_ID := "G1-01"

var host: Control
var story: RefCounted
var asset_registry: RefCounted
var fx_layer: Control
var dialogue_panel: PanelContainer
var dialogue_tail: Polygon2D
var center_line_label: Label
var auto_timer: Timer
var open_variant_texture: TextureRect

var current_unit_id := ""
var current_line_id := ""
var current_segments: Array[String] = []
var current_segment_index := 0
var current_open_texture: Texture2D
var text_tween: Tween
var visual_tween: Tween
var waiting := false
var transitioning := false
var sequence_token := 0
var revealing := false


func _init() -> void:
	chapter_number = 1


func setup(director_context: Dictionary) -> void:
	super.setup(director_context)
	host = context.get("host") as Control
	story = context.get("story") as RefCounted
	asset_registry = context.get("asset_registry") as RefCounted
	fx_layer = context.get("fx_layer") as Control
	dialogue_panel = context.get("dialogue_panel") as PanelContainer
	dialogue_tail = context.get("dialogue_tail") as Polygon2D
	center_line_label = context.get("center_line_label") as Label
	auto_timer = context.get("auto_timer") as Timer

	open_variant_texture = TextureRect.new()
	open_variant_texture.name = "OpenVariantTexture"
	open_variant_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	open_variant_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	open_variant_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	open_variant_texture.visible = false
	open_variant_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	open_variant_texture.offset_left = 0.0
	open_variant_texture.offset_top = 0.0
	open_variant_texture.offset_right = 0.0
	open_variant_texture.offset_bottom = 0.0
	fx_layer.add_child(open_variant_texture)


func on_unit_changed(unit: Dictionary) -> void:
	_cancel_sequence()
	current_unit_id = str(unit.get("id", ""))
	current_line_id = ""
	open_variant_texture.visible = false
	open_variant_texture.modulate.a = 0.0
	current_open_texture = null

	if current_unit_id != OPENING_UNIT_ID:
		return

	var shot_id := str(unit.get("shot", ""))
	current_open_texture = asset_registry.call("load_variant", shot_id, "open") as Texture2D
	open_variant_texture.texture = current_open_texture


func on_line_changed(line: Dictionary, _unit: Dictionary) -> bool:
	if current_unit_id != OPENING_UNIT_ID:
		return false

	auto_timer.stop()
	current_line_id = str(line.get("id", ""))
	current_segments = _segments_for_line(current_line_id)
	current_segment_index = 0

	if current_line_id == "G1-01-01":
		waiting = true
		dialogue_panel.visible = false
		dialogue_tail.visible = false
		center_line_label.visible = false
		_show_after_delay(0.8)
	else:
		_show_caption()
	return true


func handles_custom_reveal() -> bool:
	return current_unit_id == OPENING_UNIT_ID


func advance() -> bool:
	if not handles_custom_reveal():
		return false
	_advance_opening()
	return true


func finish_reveal() -> bool:
	if not handles_custom_reveal() or not revealing:
		return false
	if text_tween != null and text_tween.is_valid():
		text_tween.kill()
	center_line_label.visible_characters = -1
	center_line_label.modulate.a = 1.0
	revealing = false
	auto_timer.start(_hold_seconds())
	return true


func on_auto_timeout() -> bool:
	if not handles_custom_reveal():
		return false
	_advance_opening()
	return true


func position_caption(label: Label, _presentation: String) -> bool:
	if not handles_custom_reveal():
		return false
	label.anchor_left = 0.09
	label.anchor_top = 0.30
	label.anchor_right = 0.52
	label.anchor_bottom = 0.70
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_constant_override("line_spacing", 14)
	label.add_theme_color_override(
		"font_shadow_color", Color(0.0, 0.0, 0.0, 0.68)
	)
	label.add_theme_constant_override("shadow_outline_size", 3)
	return true


func resume() -> bool:
	if (
		not handles_custom_reveal()
		or waiting
		or transitioning
		or revealing
		or not center_line_label.visible
	):
		return false
	auto_timer.start(_hold_seconds())
	return true


func leave() -> void:
	_cancel_sequence()
	if open_variant_texture != null:
		open_variant_texture.visible = false
		open_variant_texture.modulate.a = 0.0
	if center_line_label != null:
		center_line_label.modulate.a = 1.0
		center_line_label.visible_characters = -1


func _segments_for_line(line_id: String) -> Array[String]:
	if line_id == "G1-01-01":
		return [
			"三十三岁。",
			"进入社会已经十二年，\n有些事，我却仍然不明白。",
		]
	return [
		"当然。",
		"我可以装得很明白。\n这也没多难。",
		"比如——",
	]


func _show_after_delay(seconds: float) -> void:
	var token := sequence_token
	await host.get_tree().create_timer(seconds).timeout
	if token != sequence_token or current_line_id != "G1-01-01":
		return
	waiting = false
	_show_caption()


func _show_caption() -> void:
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = true
	center_line_label.text = current_segments[current_segment_index]
	center_line_label.visible_characters = -1
	position_caption(center_line_label, "caption")
	center_line_label.modulate = Color(0.94, 0.94, 0.91, 0.0)
	revealing = true

	if text_tween != null and text_tween.is_valid():
		text_tween.kill()
	text_tween = host.create_tween()
	text_tween.set_trans(Tween.TRANS_QUAD)
	text_tween.set_ease(Tween.EASE_OUT)
	text_tween.tween_property(center_line_label, "modulate:a", 1.0, 0.18)
	text_tween.finished.connect(_finish_caption_fade)


func _finish_caption_fade() -> void:
	if not handles_custom_reveal():
		return
	center_line_label.modulate.a = 1.0
	revealing = false
	auto_timer.start(_hold_seconds())


func _hold_seconds() -> float:
	if current_line_id == "G1-01-01":
		return 1.2 if current_segment_index == 0 else 2.4
	if current_segment_index == 0:
		return 0.8
	if current_segment_index == 1:
		return 1.8
	return 0.8


func _advance_opening() -> void:
	if transitioning:
		return
	if waiting:
		sequence_token += 1
		waiting = false
		_show_caption()
		return
	if revealing:
		finish_reveal()
		return

	transitioning = true
	auto_timer.stop()
	var token := sequence_token
	var line_id := current_line_id
	var segment_index := current_segment_index
	await _fade_out_caption()
	if token != sequence_token or line_id != current_line_id:
		return

	if line_id == "G1-01-02" and segment_index == 0:
		await _animate_eyes()
		await host.get_tree().create_timer(0.6).timeout
		if token != sequence_token or line_id != current_line_id:
			return

	if current_segment_index + 1 < current_segments.size():
		current_segment_index += 1
		transitioning = false
		_show_caption()
		return

	if line_id == "G1-01-01":
		await host.get_tree().create_timer(0.6).timeout
		if token != sequence_token or line_id != current_line_id:
			return
	transitioning = false
	story.call("advance")


func _fade_out_caption() -> void:
	if text_tween != null and text_tween.is_valid():
		text_tween.kill()
	text_tween = host.create_tween()
	text_tween.set_trans(Tween.TRANS_QUAD)
	text_tween.set_ease(Tween.EASE_IN)
	text_tween.tween_property(center_line_label, "modulate:a", 0.0, 0.22)
	await text_tween.finished
	center_line_label.visible = false


func _animate_eyes() -> void:
	if current_open_texture == null:
		return
	open_variant_texture.texture = current_open_texture
	open_variant_texture.visible = true
	open_variant_texture.modulate.a = 0.0
	if visual_tween != null and visual_tween.is_valid():
		visual_tween.kill()
	visual_tween = host.create_tween()
	visual_tween.set_trans(Tween.TRANS_QUAD)
	visual_tween.set_ease(Tween.EASE_IN_OUT)
	visual_tween.tween_property(open_variant_texture, "modulate:a", 1.0, 0.15)
	await visual_tween.finished


func _cancel_sequence() -> void:
	sequence_token += 1
	waiting = false
	transitioning = false
	revealing = false
	auto_timer.stop()
	if text_tween != null and text_tween.is_valid():
		text_tween.kill()
	if visual_tween != null and visual_tween.is_valid():
		visual_tween.kill()
