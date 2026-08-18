extends ChapterDirector

const OPENING_UNIT_ID := "G1-01"
const WORKSTATION_UNIT_ID := "G1-03"
const VLOG_UNIT_ID := "G1-04"
const REVERSE_UNIT_ID := "G1-05"
const CLOSEUP_UNIT_ID := "G1-06"
const DREAM_LINE_PREFIX := "G1-01-D"
const DREAM_OPENING_LINE_ID := "G1-01-D01"
const DREAM_MEMORY_LINE_ID := "G1-01-D12"
const DREAM_MEMORY_RETURN_LINE_ID := "G1-01-D13"
const DREAM_FINAL_LINE_ID := "G1-01-D18"
const G0_MUSIC_CUE_ID := "MUS-03C"
const G1_OPENING_MUSIC_CUE_ID := "MUS-03B"
const DREAM_WIND_PATH := "res://assets/audio/ambience/amb-g0-rooftop-wind-v2.ogg"
const DREAM_SCENE_FADE_OUT := 0.34
const DREAM_SCENE_BLACK_HOLD := 0.08
const DREAM_SCENE_FADE_IN := 0.46
const VISUAL_VARIANTS := [
	"wake", "wash", "cats", "board", "drive", "arrive",
	"dream_pov_wake", "dream_wake", "dream_loss", "dream_shadow", "dream_reveal",
	"dream_youth_close", "dream_adult_reaction", "dream_confrontation",
	"dream_train_approach", "dream_train_stop",
]

var host: Control
var story: RefCounted
var asset_registry: RefCounted
var fx_layer: Control
var dialogue_panel: PanelContainer
var dialogue_tail: Polygon2D
var center_line_label: Label
var auto_timer: Timer
var sound_director: Node

var opening_backdrop: ColorRect
var opening_previous_texture: TextureRect
var opening_texture: TextureRect
var opening_placeholder: Label
var dream_loss_transition: ColorRect
var dream_scene_transition: ColorRect
var dream_whiteout: ColorRect
var dream_eyelids: ColorRect
var dream_memory_veil: ColorRect
var dream_memory_echo: Label
var dream_final_answer: Control
var dream_final_answer_word: Label
var dream_final_answer_line: ColorRect
var dream_wind_player: AudioStreamPlayer
var visual_textures: Dictionary = {}
var g1_split_root: Control
var g1_split_left: TextureRect
var g1_split_right: TextureRect

var current_unit_id := ""
var current_line_id := ""
var current_speaker := ""
var current_beats: Array[Dictionary] = []
var current_beat_index := 0
var current_visual_id := ""
var text_tween: Tween
var visual_tween: Tween
var drift_tween: Tween
var loss_transition_tween: Tween
var scene_transition_tween: Tween
var whiteout_tween: Tween
var eyelid_tween: Tween
var memory_tween: Tween
var wind_tween: Tween
var wind_schedule_token := 0
var waiting := false
var prelude_locked := false
var transitioning := false
var revealing := false
var type_progress := 0.0
var sequence_token := 0
var scene_transition_token := 0
var scene_transition_active := false


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
	sound_director = context.get("sound_director") as Node

	opening_backdrop = ColorRect.new()
	opening_backdrop.name = "OpeningBackdrop"
	opening_backdrop.color = Color.BLACK
	opening_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_backdrop.visible = false
	_set_full_rect(opening_backdrop)
	fx_layer.add_child(opening_backdrop)

	opening_previous_texture = TextureRect.new()
	opening_previous_texture.name = "OpeningPreviousTexture"
	opening_previous_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	opening_previous_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	opening_previous_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_previous_texture.visible = false
	_set_full_rect(opening_previous_texture)
	fx_layer.add_child(opening_previous_texture)

	opening_texture = TextureRect.new()
	opening_texture.name = "OpeningTexture"
	opening_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	opening_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	opening_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_texture.visible = false
	_set_full_rect(opening_texture)
	fx_layer.add_child(opening_texture)
	_build_dream_loss_transition()
	_build_dream_scene_transition()
	_build_dream_whiteout()
	_build_dream_memory_layer()
	_build_dream_eyelids()
	_build_dream_final_answer()
	_build_dream_wind_player()

	opening_placeholder = Label.new()
	opening_placeholder.name = "OpeningPlaceholder"
	opening_placeholder.anchor_left = 0.30
	opening_placeholder.anchor_top = 0.36
	opening_placeholder.anchor_right = 0.70
	opening_placeholder.anchor_bottom = 0.64
	opening_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opening_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	opening_placeholder.add_theme_font_size_override("font_size", 34)
	opening_placeholder.add_theme_constant_override("line_spacing", 12)
	opening_placeholder.modulate = Color(1.0, 1.0, 1.0, 0.42)
	opening_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_placeholder.visible = false
	fx_layer.add_child(opening_placeholder)
	_build_g1_split_layer()


func on_unit_changed(unit: Dictionary) -> void:
	wind_schedule_token += 1
	_cancel_sequence()
	current_unit_id = str(unit.get("id", ""))
	current_line_id = ""
	_hide_opening_visuals()
	_hide_g1_split()
	visual_textures.clear()

	var shot_id := str(unit.get("shot", ""))
	match current_unit_id:
		OPENING_UNIT_ID:
			_load_variants(shot_id, VISUAL_VARIANTS)
			opening_backdrop.visible = true
			opening_backdrop.color = Color.BLACK
		WORKSTATION_UNIT_ID:
			_load_variants(shot_id, ["base", "reflection"])
		VLOG_UNIT_ID:
			_load_variants(shot_id, ["point", "thumb"])
		REVERSE_UNIT_ID:
			_show_g1_split(true)
		CLOSEUP_UNIT_ID:
			_load_variants(shot_id, ["closed", "open"])
	if current_unit_id != OPENING_UNIT_ID:
		_stop_dream_wind()


func on_line_changed(line: Dictionary, _unit: Dictionary) -> bool:
	current_line_id = str(line.get("id", ""))
	current_speaker = str(line.get("speaker", ""))
	var line_number := current_line_id.get_slice("-", 2).to_int()
	match current_unit_id:
		WORKSTATION_UNIT_ID:
			_set_g1_overlay("reflection" if line_number >= 4 else "")
			return false
		VLOG_UNIT_ID:
			_set_g1_overlay("thumb" if line_number >= 4 else "")
			return false
		REVERSE_UNIT_ID:
			_show_g1_split(line_number <= 1)
			return false
		CLOSEUP_UNIT_ID:
			_set_g1_overlay("open" if line_number >= 6 else "")
			return false
		OPENING_UNIT_ID:
			pass
		_:
			return false

	_cancel_line_state()
	if (
		current_line_id.begins_with(DREAM_LINE_PREFIX)
		and current_line_id != DREAM_OPENING_LINE_ID
		and not dream_wind_player.playing
	):
		_start_dream_wind(-7.0, 0.55)
	current_beats = _beats_for_line(
		current_line_id,
		str(line.get("text", "")),
		line.get("segments", []) as Array,
	)
	current_beat_index = 0

	var first_beat := current_beats[0]
	if (
		not str(first_beat.get("prelude_visual", "")).is_empty()
		or not str(first_beat.get("prelude_effect", "")).is_empty()
	):
		_start_dream_prelude(first_beat)
	else:
		_show_current_beat()
	return true


func handles_custom_reveal() -> bool:
	return current_unit_id == OPENING_UNIT_ID


func defers_music_for_line(line_id: String) -> bool:
	return current_unit_id == OPENING_UNIT_ID and line_id == DREAM_OPENING_LINE_ID


func is_revealing() -> bool:
	return handles_custom_reveal() and revealing


func tick_reveal(delta: float, text_speed: float) -> bool:
	if not handles_custom_reveal() or not revealing:
		return false
	if current_line_id == DREAM_FINAL_LINE_ID:
		type_progress += delta
		var progress := clampf(type_progress / 0.72, 0.0, 1.0)
		dream_final_answer_word.modulate.a = clampf(progress / 0.28, 0.0, 1.0)
		var line_progress := smoothstep(0.16, 0.92, progress)
		dream_final_answer_line.modulate.a = clampf(line_progress * 1.6, 0.0, 1.0)
		dream_final_answer_line.anchor_right = lerpf(0.502, 0.592, line_progress)
		return progress >= 1.0
	type_progress += delta * text_speed
	var visible_count := mini(int(type_progress), center_line_label.text.length())
	center_line_label.visible_characters = visible_count
	return visible_count >= center_line_label.text.length()


func advance() -> bool:
	if not handles_custom_reveal():
		return false
	if scene_transition_active:
		return true
	if waiting:
		if not prelude_locked:
			_skip_prelude()
		return true
	if transitioning:
		return true
	if revealing:
		finish_reveal()
		return true

	_advance_opening()
	return true


func finish_reveal() -> bool:
	if not handles_custom_reveal() or not revealing:
		return false
	if text_tween != null and text_tween.is_valid():
		text_tween.kill()
	if current_line_id == DREAM_FINAL_LINE_ID:
		dream_final_answer_word.modulate.a = 1.0
		dream_final_answer_line.modulate.a = 1.0
		dream_final_answer_line.anchor_right = 0.592
	else:
		center_line_label.visible_characters = -1
		center_line_label.modulate.a = 1.0
	type_progress = 0.0
	revealing = false
	_schedule_auto_advance(_hold_seconds())
	return true


func show_timed_segment(line_id: String, segment_index: int) -> bool:
	if (
		not handles_custom_reveal()
		or line_id != current_line_id
		or segment_index < 0
		or segment_index >= current_beats.size()
	):
		return false
	sequence_token += 1
	waiting = false
	transitioning = false
	revealing = false
	type_progress = 0.0
	auto_timer.stop()
	if text_tween != null and text_tween.is_valid():
		text_tween.kill()
	current_beat_index = segment_index
	_show_current_beat()
	center_line_label.visible_characters = -1
	revealing = false
	return true


func on_auto_timeout() -> bool:
	if not handles_custom_reveal() or not _is_auto_enabled():
		return false
	var voice_player = context.get("voice_sequence_player")
	if (
		voice_player != null
		and voice_player.call("is_active")
		and not voice_player.call("advances_automatically")
	):
		return true
	if waiting:
		_skip_prelude()
	else:
		_advance_opening()
	return true


func position_caption(label: Label, _presentation: String) -> bool:
	if current_unit_id == REVERSE_UNIT_ID:
		label.offset_left = 0.0
		label.offset_top = 0.0
		label.offset_right = 0.0
		label.offset_bottom = 0.0
		label.anchor_left = 0.12
		label.anchor_top = 0.08
		label.anchor_right = 0.88
		label.anchor_bottom = 0.28
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 42)
		label.add_theme_constant_override("line_spacing", 14)
		return true
	if current_unit_id == CLOSEUP_UNIT_ID:
		label.offset_left = 0.0
		label.offset_top = 0.0
		label.offset_right = 0.0
		label.offset_bottom = 0.0
		label.anchor_left = 0.055
		label.anchor_top = 0.12
		label.anchor_right = 0.42
		label.anchor_bottom = 0.39
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 38)
		label.add_theme_constant_override("line_spacing", 14)
		return true
	return handles_custom_reveal()


func position_bubble(
	panel: PanelContainer,
	tail: Polygon2D,
	_speaker: String,
	_text: String,
) -> bool:
	match current_unit_id:
		"G1-02":
			_place_dialogue_card(panel, tail, Vector2(470.0, 38.0))
			return true
		WORKSTATION_UNIT_ID:
			_place_dialogue_card(panel, tail, Vector2(60.0, 42.0))
			return true
		VLOG_UNIT_ID:
			_place_dialogue_card(panel, tail, Vector2(1220.0, 42.0))
			return true
		CLOSEUP_UNIT_ID:
			_place_dialogue_card(panel, tail, Vector2(70.0, 106.0))
			return true
		_:
			return false


func _place_dialogue_card(
	panel: PanelContainer,
	tail: Polygon2D,
	card_position: Vector2,
) -> void:
	# 同一张 CG 内使用固定画幅。文字分页时只替换内容，不再重算卡片边界。
	panel.position = card_position
	panel.size = Vector2(620.0, 158.0)
	# 这些镜头以构图和固定位置识别发声者，不使用会造成错误空间指向的尖角。
	tail.visible = false


func resume() -> bool:
	if (
		not handles_custom_reveal()
		or waiting
		or transitioning
		or revealing
		or (
			not center_line_label.visible
			and not dream_final_answer.visible
		)
		or not _is_auto_enabled()
	):
		return false
	_schedule_auto_advance(_hold_seconds())
	return true


func leave() -> void:
	wind_schedule_token += 1
	_cancel_sequence()
	_stop_dream_wind()
	_hide_opening_visuals()
	_hide_g1_split()
	if center_line_label != null:
		center_line_label.modulate.a = 1.0
		center_line_label.visible_characters = -1


func _beats_for_line(line_id: String, text: String, segments: Array) -> Array[Dictionary]:
	if line_id.begins_with(DREAM_LINE_PREFIX):
		return _dream_beats_for_line(line_id, text, segments)

	var line_number := line_id.get_slice("-", 2).to_int()
	var visual := "wake"
	if line_number <= 6:
		visual = "wake"
	elif line_number <= 10:
		visual = "wash"
	elif line_number <= 14:
		visual = "cats"
	elif line_number <= 17:
		visual = "board"
	elif line_number <= 20:
		visual = "drive"
	elif line_number == 21:
		# 恢复的“我不明白”直接切黑，随后再进入公司地库。
		visual = "black"
	elif line_number <= 24:
		visual = "arrive"

	var reviewed_segments := segments
	if reviewed_segments.is_empty():
		reviewed_segments = [text]
	var beats: Array[Dictionary] = []
	for segment in reviewed_segments:
		beats.append({"text": str(segment), "visual": visual})
	return beats


func _dream_beats_for_line(line_id: String, text: String, segments: Array) -> Array[Dictionary]:
	var line_number := line_id.trim_prefix(DREAM_LINE_PREFIX).to_int()
	var visual := "dream_wake"
	if line_number <= 2:
		visual = "dream_wake"
	elif line_number <= 6:
		visual = "dream_loss"
	elif line_number <= 8:
		visual = "dream_shadow"
	elif line_number <= 10:
		visual = "dream_youth_close"
	elif line_number <= 12:
		visual = "dream_adult_reaction"
	elif line_number <= 15:
		visual = "dream_confrontation"
	elif line_number == 16:
		visual = "dream_train_approach"
	elif line_number == 17:
		visual = "dream_train_stop"
	else:
		visual = "black"

	var reviewed_segments := segments
	if reviewed_segments.is_empty():
		reviewed_segments = [text]
	var beats: Array[Dictionary] = []
	for segment in reviewed_segments:
		beats.append({"text": str(segment), "visual": visual})
	if line_number == 1:
		beats[0]["prelude_effect"] = "eyes_open"
	elif line_number == 3:
		beats[0]["prelude_effect"] = "church_bell"
	elif line_number == 9:
		beats[0]["prelude_visual"] = "dream_reveal"
		beats[0]["prelude_seconds"] = 1.2
	elif line_number == 12:
		beats[0]["prelude_effect"] = "memory_recall"
	elif line_number == 13:
		beats[0]["prelude_effect"] = "memory_return"
	elif line_number == 17:
		beats[0]["prelude_effect"] = "train_whistle"
	elif line_number == 18:
		beats[0]["prelude_effect"] = "door_whiteout"
	return beats


func _start_dream_prelude(beat: Dictionary) -> void:
	waiting = true
	prelude_locked = true
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = false
	dream_final_answer.visible = false
	var token := sequence_token
	var effect := str(beat.get("prelude_effect", ""))
	var uses_black_transition := effect in ["church_bell", "train_whistle"]
	if effect == "door_whiteout":
		await _play_dream_whiteout()
	elif effect == "eyes_open":
		await _play_dream_eyes_open()
	elif effect == "church_bell":
		await _play_sound_event_prelude("G1-01-D03")
	elif effect == "train_whistle":
		await _play_sound_event_prelude("G1-01-D17")
	elif effect == "memory_recall":
		await _play_dream_memory_recall()
	elif effect == "memory_return":
		await _play_dream_memory_return()
	else:
		var prelude_visual := str(beat.get("prelude_visual", ""))
		_set_visual(prelude_visual, 0.72)
		await host.get_tree().create_timer(
			float(beat.get("prelude_seconds", 1.0))
		).timeout
	if token != sequence_token:
		return
	var target_visual := str(beat.get("visual", ""))
	if not target_visual.is_empty() and target_visual != current_visual_id:
		if uses_black_transition:
			await _play_dream_loss_transition(target_visual)
		else:
			_set_visual(target_visual, 0.68)
			await host.get_tree().create_timer(0.72).timeout
		if token != sequence_token:
			return
	prelude_locked = false
	waiting = false
	_show_current_beat()


func _skip_prelude() -> void:
	if prelude_locked:
		return
	sequence_token += 1
	waiting = false
	_show_current_beat()


func _show_current_beat() -> void:
	if current_beats.is_empty():
		return
	var beat := current_beats[current_beat_index]
	_set_visual(str(beat.get("visual", "placeholder")))
	_show_caption(str(beat.get("text", "")))


func _show_caption(text: String) -> void:
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	dream_final_answer.visible = false
	dream_final_answer.modulate.a = 1.0
	if current_line_id == DREAM_FINAL_LINE_ID:
		center_line_label.visible = false
		dream_final_answer.visible = true
		dream_final_answer_word.modulate.a = 0.0
		dream_final_answer_line.modulate.a = 0.0
		dream_final_answer_line.anchor_right = 0.502
		type_progress = 0.0
		revealing = true
		if text_tween != null and text_tween.is_valid():
			text_tween.kill()
		return
	center_line_label.visible = not text.is_empty()
	center_line_label.text = text
	center_line_label.visible_characters = 0
	_position_opening_caption()
	center_line_label.modulate = (
		Color(0.96, 0.89, 0.74, 1.0)
		if current_line_id == DREAM_MEMORY_LINE_ID
		else Color(0.97, 0.97, 0.94, 1.0)
	)
	type_progress = 0.0
	revealing = true

	if text_tween != null and text_tween.is_valid():
		text_tween.kill()


func _position_opening_caption() -> void:
	center_line_label.offset_left = 0.0
	center_line_label.offset_top = 0.0
	center_line_label.offset_right = 0.0
	center_line_label.offset_bottom = 0.0
	center_line_label.add_theme_constant_override("line_spacing", 14)
	center_line_label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.92),
	)
	center_line_label.add_theme_constant_override("shadow_outline_size", 6)
	center_line_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if current_visual_id == "black":
		center_line_label.add_theme_font_size_override("font_size", 44)
		center_line_label.anchor_left = 0.18
		center_line_label.anchor_top = 0.32
		center_line_label.anchor_right = 0.82
		center_line_label.anchor_bottom = 0.72
		center_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return
	if current_visual_id.begins_with("dream_"):
		_position_dream_caption()
		return

	center_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	match current_visual_id:
		"wake":
			center_line_label.add_theme_font_size_override("font_size", 40)
			center_line_label.anchor_left = 0.06
			center_line_label.anchor_top = 0.22
			center_line_label.anchor_right = 0.48
			center_line_label.anchor_bottom = 0.78
		"wash":
			center_line_label.add_theme_font_size_override("font_size", 34)
			center_line_label.anchor_left = 0.70
			center_line_label.anchor_top = 0.20
			center_line_label.anchor_right = 0.95
			center_line_label.anchor_bottom = 0.82
		"cats":
			center_line_label.add_theme_font_size_override("font_size", 34)
			center_line_label.anchor_left = 0.64
			center_line_label.anchor_top = 0.38
			center_line_label.anchor_right = 0.95
			center_line_label.anchor_bottom = 0.86
		"board":
			center_line_label.add_theme_font_size_override("font_size", 36)
			center_line_label.anchor_left = 0.05
			center_line_label.anchor_top = 0.46
			center_line_label.anchor_right = 0.36
			center_line_label.anchor_bottom = 0.88
		"drive":
			center_line_label.add_theme_font_size_override("font_size", 34)
			center_line_label.anchor_left = 0.58
			center_line_label.anchor_top = 0.48
			center_line_label.anchor_right = 0.96
			center_line_label.anchor_bottom = 0.92
		"arrive":
			center_line_label.add_theme_font_size_override("font_size", 34)
			center_line_label.anchor_left = 0.055
			center_line_label.anchor_top = 0.38
			center_line_label.anchor_right = 0.39
			center_line_label.anchor_bottom = 0.88
		_:
			center_line_label.add_theme_font_size_override("font_size", 38)
			center_line_label.anchor_left = 0.58
			center_line_label.anchor_top = 0.56
			center_line_label.anchor_right = 0.94
			center_line_label.anchor_bottom = 0.90


func _position_dream_caption() -> void:
	center_line_label.add_theme_font_size_override("font_size", 37)
	center_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if current_line_id == DREAM_MEMORY_LINE_ID:
		center_line_label.add_theme_font_size_override("font_size", 42)
		center_line_label.add_theme_constant_override("line_spacing", 0)
		center_line_label.anchor_top = 0.34
		center_line_label.anchor_bottom = 0.68
		_center_multiline_text_block(center_line_label, 42)
		return
	match current_visual_id:
		"dream_wake":
			center_line_label.anchor_left = 0.57
			center_line_label.anchor_top = 0.16
			center_line_label.anchor_right = 0.94
			center_line_label.anchor_bottom = 0.42
		"dream_loss":
			center_line_label.anchor_left = 0.59
			center_line_label.anchor_top = 0.61
			center_line_label.anchor_right = 0.94
			center_line_label.anchor_bottom = 0.90
		"dream_shadow":
			if current_speaker == "我":
				center_line_label.anchor_left = 0.055
				center_line_label.anchor_top = 0.12
				center_line_label.anchor_right = 0.42
				center_line_label.anchor_bottom = 0.34
			else:
				center_line_label.anchor_left = 0.56
				center_line_label.anchor_top = 0.12
				center_line_label.anchor_right = 0.93
				center_line_label.anchor_bottom = 0.36
		"dream_youth_close":
			center_line_label.anchor_left = 0.31
			center_line_label.anchor_top = 0.055
			center_line_label.anchor_right = 0.90
			center_line_label.anchor_bottom = 0.25
			center_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		"dream_adult_reaction":
			center_line_label.anchor_left = 0.60
			center_line_label.anchor_top = 0.20
			center_line_label.anchor_right = 0.94
			center_line_label.anchor_bottom = 0.46
		"dream_confrontation", "dream_train_approach", "dream_train_stop":
			if current_speaker == "我":
				center_line_label.anchor_left = 0.055
				center_line_label.anchor_top = 0.10
				center_line_label.anchor_right = 0.44
				center_line_label.anchor_bottom = 0.34
			else:
				center_line_label.anchor_left = 0.56
				center_line_label.anchor_top = 0.10
				center_line_label.anchor_right = 0.94
				center_line_label.anchor_bottom = 0.36
		_:
			center_line_label.anchor_left = 0.58
			center_line_label.anchor_top = 0.56
			center_line_label.anchor_right = 0.94
			center_line_label.anchor_bottom = 0.90


func _hold_seconds() -> float:
	if current_beats.is_empty():
		return 1.6
	var text := str(current_beats[current_beat_index].get("text", ""))
	return clampf(0.9 + text.length() / 11.0, 1.4, 4.2)


func _advance_opening() -> void:
	if transitioning:
		return
	transitioning = true
	auto_timer.stop()

	var token := sequence_token
	var line_id := current_line_id
	await _fade_out_caption()
	if token != sequence_token or line_id != current_line_id:
		return
	if line_id == DREAM_MEMORY_LINE_ID:
		await _play_dream_memory_release()
		if token != sequence_token or line_id != current_line_id:
			return
	if line_id == DREAM_FINAL_LINE_ID:
		await _play_dream_to_reality_transition()
		if token != sequence_token or line_id != current_line_id:
			return

	if current_beat_index + 1 < current_beats.size():
		current_beat_index += 1
		var next_beat := current_beats[current_beat_index]
		var placeholder := str(next_beat.get("transition_placeholder", ""))
		if not placeholder.is_empty():
			_show_placeholder(placeholder)
			transitioning = false
			waiting = true
			_schedule_auto_advance(0.9)
			return
		transitioning = false
		_show_current_beat()
		var play_voice_segment: Callable = context.get("play_voice_segment", Callable())
		if play_voice_segment.is_valid():
			play_voice_segment.call(current_line_id, current_beat_index)
		return

	transitioning = false
	request_story_advance()


func _fade_out_caption() -> void:
	if dream_final_answer.visible:
		if text_tween != null and text_tween.is_valid():
			text_tween.kill()
		text_tween = host.create_tween()
		text_tween.set_trans(Tween.TRANS_QUAD)
		text_tween.set_ease(Tween.EASE_IN)
		text_tween.tween_property(dream_final_answer, "modulate:a", 0.0, 0.42)
		await text_tween.finished
		dream_final_answer.visible = false
		return
	if not center_line_label.visible:
		return
	if text_tween != null and text_tween.is_valid():
		text_tween.kill()
	text_tween = host.create_tween()
	text_tween.set_trans(Tween.TRANS_QUAD)
	text_tween.set_ease(Tween.EASE_IN)
	text_tween.tween_property(center_line_label, "modulate:a", 0.0, 0.20)
	await text_tween.finished
	center_line_label.visible = false


func _set_visual(visual_id: String, transition_seconds: float = -1.0) -> void:
	var previous_visual_id := current_visual_id
	current_visual_id = visual_id
	opening_backdrop.visible = true
	opening_placeholder.visible = false

	if visual_id == "black":
		opening_backdrop.color = Color.BLACK
		opening_previous_texture.visible = false
		opening_texture.visible = false
		if drift_tween != null and drift_tween.is_valid():
			drift_tween.kill()
		return

	var texture := visual_textures.get(visual_id) as Texture2D
	if texture == null:
		_show_placeholder("%s\n（占位）" % visual_id)
		return
	if (
		previous_visual_id == visual_id
		and opening_texture.visible
		and opening_texture.texture == texture
	):
		opening_texture.modulate.a = 1.0
		opening_previous_texture.visible = false
		return
	var duration := transition_seconds
	if duration < 0.0:
		duration = 0.68 if visual_id.begins_with("dream_") else 0.22
	if (
		dream_scene_transition != null
		and dream_scene_transition.visible
		and dream_scene_transition.modulate.a >= 0.99
	):
		duration = 0.0
	if duration <= 0.0:
		if visual_tween != null and visual_tween.is_valid():
			visual_tween.kill()
		opening_previous_texture.visible = false
		opening_texture.texture = texture
		opening_texture.visible = true
		opening_texture.modulate.a = 1.0
		opening_texture.scale = Vector2.ONE * 1.008
		opening_texture.pivot_offset = host.size * 0.5
		_start_visual_drift()
		return

	opening_backdrop.color = Color.BLACK
	if opening_texture.visible and opening_texture.texture != null:
		opening_previous_texture.texture = opening_texture.texture
		opening_previous_texture.scale = opening_texture.scale
		opening_previous_texture.pivot_offset = opening_texture.pivot_offset
		opening_previous_texture.modulate = opening_texture.modulate
		opening_previous_texture.visible = true
	else:
		opening_previous_texture.visible = false
	opening_texture.texture = texture
	opening_texture.visible = true
	opening_texture.modulate.a = 0.0
	opening_texture.scale = Vector2.ONE * 1.008
	opening_texture.pivot_offset = host.size * 0.5
	if visual_tween != null and visual_tween.is_valid():
		visual_tween.kill()
	visual_tween = host.create_tween().set_parallel(true)
	visual_tween.set_trans(Tween.TRANS_QUAD)
	visual_tween.set_ease(Tween.EASE_OUT)
	visual_tween.tween_property(opening_texture, "modulate:a", 1.0, duration)
	if opening_previous_texture.visible:
		visual_tween.tween_property(
			opening_previous_texture,
			"modulate:a",
			0.0,
			duration,
		)
		visual_tween.chain().tween_callback(
			func() -> void: opening_previous_texture.visible = false
		)
	_start_visual_drift()


func _start_visual_drift() -> void:
	if drift_tween != null and drift_tween.is_valid():
		drift_tween.kill()
	if not current_visual_id.begins_with("dream_"):
		opening_texture.scale = Vector2.ONE
		return
	drift_tween = host.create_tween()
	drift_tween.set_trans(Tween.TRANS_SINE)
	drift_tween.set_ease(Tween.EASE_IN_OUT)
	drift_tween.tween_property(opening_texture, "scale", Vector2.ONE * 1.028, 13.0)


func _load_variants(shot_id: String, variant_ids: Array) -> void:
	visual_textures.clear()
	for variant_id_value in variant_ids:
		var variant_id := str(variant_id_value)
		visual_textures[variant_id] = asset_registry.call(
			"load_variant",
			shot_id,
			variant_id,
		) as Texture2D


func _build_dream_eyelids() -> void:
	dream_eyelids = ColorRect.new()
	dream_eyelids.name = "DreamEyelids"
	dream_eyelids.color = Color.BLACK
	dream_eyelids.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dream_eyelids.visible = false
	_set_full_rect(dream_eyelids)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float openness : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float half_open = mix(-0.025, 0.63, openness);
	float horizontal_curve = 0.84 + 0.16 * sin(UV.x * 3.14159265);
	float center = 0.51 - 0.015 * openness;
	float upper_edge = center - half_open * horizontal_curve;
	float lower_edge = center + half_open * horizontal_curve;
	float upper_clear = smoothstep(upper_edge, upper_edge + 0.018, UV.y);
	float lower_clear = 1.0 - smoothstep(lower_edge - 0.018, lower_edge, UV.y);
	float visible_scene = upper_clear * lower_clear;
	COLOR = vec4(0.005, 0.004, 0.004, 1.0 - visible_scene);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("openness", 0.0)
	dream_eyelids.material = material
	fx_layer.add_child(dream_eyelids)


func _build_dream_memory_layer() -> void:
	dream_memory_veil = ColorRect.new()
	dream_memory_veil.name = "DreamMemoryVeil"
	dream_memory_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dream_memory_veil.visible = false
	dream_memory_veil.modulate.a = 0.0
	_set_full_rect(dream_memory_veil)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float ripple = sin(UV.y * 148.0 + TIME * 0.75) * 0.0007;
	vec3 source = texture(screen_texture, UV + vec2(ripple, 0.0)).rgb;
	float gray = dot(source, vec3(0.299, 0.587, 0.114));
	vec3 recalled = mix(source, vec3(gray), 0.76);
	recalled *= vec3(0.90, 0.86, 0.76);
	float vignette = smoothstep(0.78, 0.26, length(centered));
	float grain = (hash(floor(UV * vec2(960.0, 540.0)) + floor(TIME * 3.0)) - 0.5) * 0.035;
	recalled = recalled * mix(0.58, 1.0, vignette) + grain;
	COLOR = vec4(recalled, 1.0);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	dream_memory_veil.material = material
	fx_layer.add_child(dream_memory_veil)

	dream_memory_echo = Label.new()
	dream_memory_echo.name = "DreamMemoryEcho"
	dream_memory_echo.anchor_left = 0.12
	dream_memory_echo.anchor_top = 0.23
	dream_memory_echo.anchor_right = 0.88
	dream_memory_echo.anchor_bottom = 0.76
	dream_memory_echo.text = "「回到你所厌恶，\n又不得不赞美的世界。」"
	dream_memory_echo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dream_memory_echo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dream_memory_echo.add_theme_font_size_override("font_size", 62)
	dream_memory_echo.add_theme_constant_override("line_spacing", 0)
	dream_memory_echo.add_theme_color_override(
		"font_color",
		Color(0.90, 0.82, 0.66, 1.0),
	)
	dream_memory_echo.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.88),
	)
	dream_memory_echo.add_theme_constant_override("shadow_outline_size", 10)
	dream_memory_echo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dream_memory_echo.visible = false
	dream_memory_echo.modulate.a = 0.0
	fx_layer.add_child(dream_memory_echo)
	_center_multiline_text_block(dream_memory_echo, 62)


func _center_multiline_text_block(label: Label, font_size: int) -> void:
	var font := label.get_theme_font("font")
	var block_width := 0.0
	for line_variant in label.text.split("\n"):
		block_width = maxf(
			block_width,
			font.get_string_size(
				str(line_variant),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				font_size,
			).x,
		)
	var half_width := ceilf(block_width * 0.5) + 8.0
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = -half_width
	label.offset_right = half_width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _build_dream_wind_player() -> void:
	dream_wind_player = AudioStreamPlayer.new()
	dream_wind_player.name = "G0WindAmbience"
	dream_wind_player.bus = "Ambience"
	dream_wind_player.volume_db = -80.0
	var stream := ResourceLoader.load(DREAM_WIND_PATH) as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	dream_wind_player.stream = stream
	host.add_child(dream_wind_player)


func _build_dream_final_answer() -> void:
	dream_final_answer = Control.new()
	dream_final_answer.name = "DreamFinalAnswer"
	dream_final_answer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dream_final_answer.visible = false
	_set_full_rect(dream_final_answer)
	fx_layer.add_child(dream_final_answer)

	dream_final_answer_word = Label.new()
	dream_final_answer_word.name = "Word"
	dream_final_answer_word.anchor_left = 0.425
	dream_final_answer_word.anchor_top = 0.42
	dream_final_answer_word.anchor_right = 0.495
	dream_final_answer_word.anchor_bottom = 0.58
	dream_final_answer_word.text = "我"
	dream_final_answer_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dream_final_answer_word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dream_final_answer_word.add_theme_font_size_override("font_size", 50)
	dream_final_answer_word.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.92),
	)
	dream_final_answer_word.add_theme_constant_override("shadow_outline_size", 6)
	dream_final_answer_word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dream_final_answer.add_child(dream_final_answer_word)

	dream_final_answer_line = ColorRect.new()
	dream_final_answer_line.name = "UnfinishedLine"
	dream_final_answer_line.anchor_left = 0.502
	dream_final_answer_line.anchor_top = 0.501
	dream_final_answer_line.anchor_right = 0.592
	dream_final_answer_line.anchor_bottom = 0.501
	dream_final_answer_line.offset_top = -1.5
	dream_final_answer_line.offset_bottom = 1.5
	dream_final_answer_line.color = Color(0.97, 0.97, 0.94, 1.0)
	dream_final_answer_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dream_final_answer.add_child(dream_final_answer_line)


func _play_dream_eyes_open() -> void:
	var music_director = context.get("music_director")
	if music_director != null:
		music_director.call("hard_stop")
	_set_visual("black", 0.0)
	_stop_dream_wind()
	_start_dream_wind_after_opening(wind_schedule_token)
	dream_eyelids.visible = false
	await host.get_tree().create_timer(1.75).timeout

	_set_visual("dream_pov_wake", 0.0)
	dream_eyelids.visible = true
	_set_eyelid_openness(0.0)
	await host.get_tree().create_timer(0.16).timeout
	if eyelid_tween != null and eyelid_tween.is_valid():
		eyelid_tween.kill()
	eyelid_tween = host.create_tween()
	eyelid_tween.set_trans(Tween.TRANS_SINE)
	eyelid_tween.set_ease(Tween.EASE_OUT)
	eyelid_tween.tween_method(_set_eyelid_openness, 0.0, 0.78, 0.82)
	eyelid_tween.tween_method(_set_eyelid_openness, 0.78, 0.52, 0.16)
	eyelid_tween.tween_method(_set_eyelid_openness, 0.52, 1.0, 0.42)
	await eyelid_tween.finished
	await host.get_tree().create_timer(0.72).timeout

	_set_visual("dream_wake", 0.82)
	await host.get_tree().create_timer(0.86).timeout
	dream_eyelids.visible = false
	_set_eyelid_openness(0.0)
	if music_director != null:
		music_director.call("play_cue_id", G0_MUSIC_CUE_ID)


func _start_dream_wind_after_opening(scheduled_token: int) -> void:
	await host.get_tree().create_timer(5.75).timeout
	if (
		scheduled_token != wind_schedule_token
		or current_unit_id != OPENING_UNIT_ID
		or not current_line_id.begins_with(DREAM_LINE_PREFIX)
		or dream_wind_player.playing
	):
		return
	_start_dream_wind(-6.0, 0.9)


func _play_sound_event_prelude(event_line_id: String) -> void:
	var event_seconds := 0.0
	if sound_director != null:
		event_seconds = float(
			sound_director.call("play_event_for_line", event_line_id, true)
		)
	# 事件声完整落下后，才切入结果画面与人物反应。
	if event_seconds > 0.0:
		await host.get_tree().create_timer(event_seconds).timeout


func _play_dream_to_reality_transition() -> void:
	var music_director = context.get("music_director")
	if music_director != null:
		music_director.call("fade_out", 1.35, G0_MUSIC_CUE_ID)
	_set_dream_wind_volume(-80.0, 0.8)
	await host.get_tree().create_timer(1.52).timeout
	_stop_dream_wind()

	# 先让现实晨景独自出现，再让下一段音乐与旁白进入。
	_set_visual("wake", 1.16)
	await host.get_tree().create_timer(1.30).timeout
	if music_director != null:
		music_director.call("play_cue_id", G1_OPENING_MUSIC_CUE_ID)
	await host.get_tree().create_timer(0.48).timeout


func _play_dream_memory_recall() -> void:
	_set_visual("dream_adult_reaction")
	dream_memory_veil.visible = true
	dream_memory_echo.visible = true
	dream_memory_veil.modulate.a = 0.0
	dream_memory_echo.modulate.a = 0.0
	_set_dream_wind_volume(-12.0, 0.8)
	if memory_tween != null and memory_tween.is_valid():
		memory_tween.kill()
	memory_tween = host.create_tween().set_parallel(true)
	memory_tween.set_trans(Tween.TRANS_SINE)
	memory_tween.set_ease(Tween.EASE_OUT)
	memory_tween.tween_property(dream_memory_veil, "modulate:a", 0.86, 0.62)
	memory_tween.tween_property(dream_memory_echo, "modulate:a", 0.095, 0.82)
	await memory_tween.finished
	await host.get_tree().create_timer(0.42).timeout


func _play_dream_memory_release() -> void:
	if memory_tween != null and memory_tween.is_valid():
		memory_tween.kill()
	memory_tween = host.create_tween().set_parallel(true)
	memory_tween.set_trans(Tween.TRANS_SINE)
	memory_tween.set_ease(Tween.EASE_IN)
	memory_tween.tween_property(dream_memory_veil, "modulate:a", 0.0, 0.66)
	memory_tween.tween_property(dream_memory_echo, "modulate:a", 0.0, 0.48)
	await memory_tween.finished
	dream_memory_veil.visible = false
	dream_memory_echo.visible = false
	_set_dream_wind_volume(-6.0, 0.9)
	await host.get_tree().create_timer(0.20).timeout


func _play_dream_memory_return() -> void:
	_set_visual("dream_confrontation", 0.76)
	await host.get_tree().create_timer(0.88).timeout


func _set_eyelid_openness(value: float) -> void:
	var material := dream_eyelids.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("openness", value)


func _start_dream_wind(
	target_db: float,
	fade_seconds: float,
	restart: bool = false,
) -> void:
	if dream_wind_player.stream == null:
		return
	if restart and dream_wind_player.playing:
		dream_wind_player.stop()
	if not dream_wind_player.playing:
		dream_wind_player.volume_db = -80.0
		dream_wind_player.play()
	_set_dream_wind_volume(target_db, fade_seconds)


func _set_dream_wind_volume(target_db: float, seconds: float) -> void:
	if wind_tween != null and wind_tween.is_valid():
		wind_tween.kill()
	wind_tween = host.create_tween()
	wind_tween.set_trans(Tween.TRANS_SINE)
	wind_tween.set_ease(Tween.EASE_OUT)
	wind_tween.tween_property(
		dream_wind_player,
		"volume_db",
		target_db,
		maxf(seconds, 0.0),
	)


func _stop_dream_wind() -> void:
	if dream_wind_player == null:
		return
	if wind_tween != null and wind_tween.is_valid():
		wind_tween.kill()
	dream_wind_player.stop()
	dream_wind_player.volume_db = -80.0


func _build_dream_loss_transition() -> void:
	dream_loss_transition = ColorRect.new()
	dream_loss_transition.name = "DreamLossTransition"
	dream_loss_transition.color = Color.BLACK
	dream_loss_transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dream_loss_transition.visible = false
	dream_loss_transition.modulate.a = 0.0
	_set_full_rect(dream_loss_transition)
	fx_layer.add_child(dream_loss_transition)


func _build_dream_scene_transition() -> void:
	dream_scene_transition = ColorRect.new()
	dream_scene_transition.name = "DreamSceneTransition"
	dream_scene_transition.color = Color.BLACK
	dream_scene_transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dream_scene_transition.visible = false
	dream_scene_transition.modulate.a = 0.0
	dream_scene_transition.z_index = 200
	_set_full_rect(dream_scene_transition)
	fx_layer.add_child(dream_scene_transition)


func _begin_dream_scene_blackout() -> int:
	scene_transition_token += 1
	var token := scene_transition_token
	scene_transition_active = true
	if scene_transition_tween != null and scene_transition_tween.is_valid():
		scene_transition_tween.kill()
	dream_scene_transition.visible = true
	dream_scene_transition.modulate.a = 0.0
	scene_transition_tween = host.create_tween()
	scene_transition_tween.set_trans(Tween.TRANS_SINE)
	scene_transition_tween.set_ease(Tween.EASE_IN_OUT)
	scene_transition_tween.tween_property(
		dream_scene_transition,
		"modulate:a",
		1.0,
		DREAM_SCENE_FADE_OUT,
	)
	await scene_transition_tween.finished
	if token != scene_transition_token:
		return -1
	return token


func _finish_dream_scene_blackout(token: int) -> void:
	if token != scene_transition_token:
		return
	await host.get_tree().create_timer(DREAM_SCENE_BLACK_HOLD).timeout
	if token != scene_transition_token:
		return
	scene_transition_tween = host.create_tween()
	scene_transition_tween.set_trans(Tween.TRANS_SINE)
	scene_transition_tween.set_ease(Tween.EASE_IN_OUT)
	scene_transition_tween.tween_property(
		dream_scene_transition,
		"modulate:a",
		0.0,
		DREAM_SCENE_FADE_IN,
	)
	await scene_transition_tween.finished
	if token != scene_transition_token:
		return
	dream_scene_transition.visible = false
	dream_scene_transition.modulate.a = 0.0
	scene_transition_active = false


func _play_dream_scene_transition(target_visual: String) -> void:
	if target_visual.is_empty() or target_visual == current_visual_id:
		return
	var token := await _begin_dream_scene_blackout()
	if token < 0:
		return
	_set_visual(target_visual, 0.0)
	await host.get_tree().process_frame
	await _finish_dream_scene_blackout(token)


func _cancel_dream_scene_transition() -> void:
	scene_transition_token += 1
	scene_transition_active = false
	if scene_transition_tween != null and scene_transition_tween.is_valid():
		scene_transition_tween.kill()
	scene_transition_tween = null
	if dream_scene_transition != null:
		dream_scene_transition.visible = false
		dream_scene_transition.modulate.a = 0.0


func _play_dream_loss_transition(target_visual: String) -> void:
	await _play_dream_scene_transition(target_visual)


func _build_dream_whiteout() -> void:
	dream_whiteout = ColorRect.new()
	dream_whiteout.name = "DreamDoorWhiteout"
	dream_whiteout.color = Color.WHITE
	dream_whiteout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dream_whiteout.visible = false
	_set_full_rect(dream_whiteout)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 origin = vec2(0.245, 0.40);

void fragment() {
	float radius = mix(-0.12, 1.45, progress);
	float distance_from_door = distance(UV, origin);
	float mask = 1.0 - smoothstep(radius - 0.13, radius, distance_from_door);
	vec3 warm_white = vec3(1.0, 0.985, 0.92);
	COLOR = vec4(warm_white, mask);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("progress", 0.0)
	dream_whiteout.material = material
	fx_layer.add_child(dream_whiteout)


func _play_dream_whiteout() -> void:
	_set_dream_wind_volume(-30.0, 0.9)
	dream_whiteout.visible = true
	dream_whiteout.modulate.a = 1.0
	_set_whiteout_progress(0.0)
	if whiteout_tween != null and whiteout_tween.is_valid():
		whiteout_tween.kill()
	whiteout_tween = host.create_tween()
	whiteout_tween.set_trans(Tween.TRANS_QUAD)
	whiteout_tween.set_ease(Tween.EASE_IN)
	whiteout_tween.tween_method(_set_whiteout_progress, 0.0, 1.0, 0.9)
	await whiteout_tween.finished
	_set_visual("black", 0.0)
	whiteout_tween = host.create_tween()
	whiteout_tween.tween_property(dream_whiteout, "modulate:a", 0.0, 0.18)
	await whiteout_tween.finished
	dream_whiteout.visible = false
	_set_whiteout_progress(0.0)
	_stop_dream_wind()


func _set_whiteout_progress(value: float) -> void:
	var material := dream_whiteout.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("progress", value)


func _set_g1_overlay(variant_id: String) -> void:
	opening_backdrop.visible = false
	opening_placeholder.visible = false
	if variant_id.is_empty():
		opening_texture.visible = false
		return

	var texture := visual_textures.get(variant_id) as Texture2D
	if texture == null:
		opening_texture.visible = false
		return
	if opening_texture.visible and opening_texture.texture == texture:
		opening_texture.modulate.a = 1.0
		return

	opening_texture.texture = texture
	opening_texture.visible = true
	opening_texture.modulate.a = 0.0
	if visual_tween != null and visual_tween.is_valid():
		visual_tween.kill()
	visual_tween = host.create_tween()
	visual_tween.set_trans(Tween.TRANS_QUAD)
	visual_tween.set_ease(Tween.EASE_OUT)
	visual_tween.tween_property(opening_texture, "modulate:a", 1.0, 0.24)


func _build_g1_split_layer() -> void:
	g1_split_root = Control.new()
	g1_split_root.name = "G1ReverseSplit"
	g1_split_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g1_split_root.visible = false
	_set_full_rect(g1_split_root)
	fx_layer.add_child(g1_split_root)

	var split_backdrop := ColorRect.new()
	split_backdrop.color = Color.BLACK
	split_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(split_backdrop)
	g1_split_root.add_child(split_backdrop)

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray * 0.64), color.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader

	var left_clip := Control.new()
	left_clip.anchor_right = 0.5
	left_clip.anchor_bottom = 1.0
	left_clip.clip_contents = true
	left_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g1_split_root.add_child(left_clip)
	g1_split_left = TextureRect.new()
	g1_split_left.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g1_split_left.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	g1_split_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g1_split_left.material = material
	_set_full_rect(g1_split_left)
	left_clip.add_child(g1_split_left)

	var right_clip := Control.new()
	right_clip.anchor_left = 0.5
	right_clip.anchor_right = 1.0
	right_clip.anchor_bottom = 1.0
	right_clip.clip_contents = true
	right_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g1_split_root.add_child(right_clip)
	g1_split_right = TextureRect.new()
	g1_split_right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g1_split_right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	g1_split_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g1_split_right.material = material
	_set_full_rect(g1_split_right)
	right_clip.add_child(g1_split_right)

	var divider := ColorRect.new()
	divider.anchor_left = 0.5
	divider.anchor_right = 0.5
	divider.anchor_bottom = 1.0
	divider.offset_left = -2.0
	divider.offset_right = 2.0
	divider.color = Color(0.0, 0.0, 0.0, 0.82)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g1_split_root.add_child(divider)


func _show_g1_split(show_terminal_frames: bool) -> void:
	opening_backdrop.visible = false
	opening_texture.visible = false
	opening_placeholder.visible = false
	if show_terminal_frames:
		g1_split_left.texture = asset_registry.call(
			"load_variant",
			"SHOT-19",
			"reflection",
		) as Texture2D
		g1_split_right.texture = asset_registry.call(
			"load_variant",
			"SHOT-03",
			"thumb",
		) as Texture2D
	else:
		g1_split_left.texture = asset_registry.call(
			"load_master",
			"SHOT-02",
		) as Texture2D
		g1_split_right.texture = asset_registry.call(
			"load_variant",
			"SHOT-03",
			"point",
		) as Texture2D
	g1_split_root.visible = (
		g1_split_left.texture != null
		and g1_split_right.texture != null
	)


func _hide_g1_split() -> void:
	if g1_split_root != null:
		g1_split_root.visible = false


func _show_placeholder(label: String) -> void:
	current_visual_id = "placeholder"
	opening_backdrop.visible = true
	opening_backdrop.color = Color("#171b1d")
	opening_texture.visible = false
	opening_placeholder.text = label
	opening_placeholder.visible = true


func _hide_opening_visuals() -> void:
	_cancel_dream_scene_transition()
	if drift_tween != null and drift_tween.is_valid():
		drift_tween.kill()
	if opening_backdrop != null:
		opening_backdrop.visible = false
	if opening_previous_texture != null:
		opening_previous_texture.visible = false
	if opening_texture != null:
		opening_texture.visible = false
	if opening_placeholder != null:
		opening_placeholder.visible = false
	if dream_whiteout != null:
		dream_whiteout.visible = false
	if dream_loss_transition != null:
		dream_loss_transition.visible = false
		dream_loss_transition.modulate.a = 0.0
	if dream_eyelids != null:
		dream_eyelids.visible = false
		_set_eyelid_openness(0.0)
	if dream_memory_veil != null:
		dream_memory_veil.visible = false
		dream_memory_veil.modulate.a = 0.0
	if dream_memory_echo != null:
		dream_memory_echo.visible = false
		dream_memory_echo.modulate.a = 0.0
	if dream_final_answer != null:
		dream_final_answer.visible = false
		dream_final_answer.modulate.a = 1.0


func _cancel_line_state() -> void:
	sequence_token += 1
	waiting = false
	prelude_locked = false
	transitioning = false
	revealing = false
	type_progress = 0.0
	auto_timer.stop()
	if text_tween != null and text_tween.is_valid():
		text_tween.kill()
	if visual_tween != null and visual_tween.is_valid():
		visual_tween.kill()
	if loss_transition_tween != null and loss_transition_tween.is_valid():
		loss_transition_tween.kill()
	if whiteout_tween != null and whiteout_tween.is_valid():
		whiteout_tween.kill()
	if eyelid_tween != null and eyelid_tween.is_valid():
		eyelid_tween.kill()
	if memory_tween != null and memory_tween.is_valid():
		memory_tween.kill()
	if dream_whiteout != null:
		dream_whiteout.visible = false
		_set_whiteout_progress(0.0)
	if dream_loss_transition != null:
		dream_loss_transition.visible = false
		dream_loss_transition.modulate.a = 0.0
	if dream_eyelids != null:
		dream_eyelids.visible = false
		_set_eyelid_openness(0.0)
	if dream_memory_veil != null:
		dream_memory_veil.visible = false
		dream_memory_veil.modulate.a = 0.0
	if dream_memory_echo != null:
		dream_memory_echo.visible = false
		dream_memory_echo.modulate.a = 0.0
	if dream_final_answer != null:
		dream_final_answer.visible = false
		dream_final_answer.modulate.a = 1.0


func _cancel_sequence() -> void:
	_cancel_line_state()
	current_beats.clear()
	current_beat_index = 0
	current_visual_id = ""
	current_speaker = ""


func _schedule_auto_advance(seconds: float) -> void:
	auto_timer.stop()
	if _is_auto_enabled():
		auto_timer.start(seconds)


func _is_auto_enabled() -> bool:
	return bool(host.get("is_auto"))


func _set_full_rect(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
