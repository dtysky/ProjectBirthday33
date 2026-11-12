extends Control

const StoryControllerClass := preload("res://src/story_controller.gd")
const AssetRegistryClass := preload("res://src/asset_registry.gd")
const SaveServiceClass := preload("res://src/save_service.gd")
const GameUIClass := preload("res://src/ui/game_ui.gd")
const DialoguePresenterClass := preload("res://src/ui/dialogue_presenter.gd")
const MusicDirectorClass := preload("res://src/music_director.gd")
const SoundDirectorClass := preload("res://src/sound_director.gd")
const VoiceSequencePlayerClass := preload("res://src/voice_sequence_player.gd")
const ChapterOneDirectorClass := preload("res://src/chapters/chapter_01.gd")
const ChapterTwoDirectorClass := preload("res://src/chapters/chapter_02.gd")
const ChapterThreeDirectorClass := preload("res://src/chapters/chapter_03.gd")
const ChapterFourDirectorClass := preload("res://src/chapters/chapter_04.gd")
const ChapterFiveDirectorClass := preload("res://src/chapters/chapter_05.gd")

const CHAPTER_MUSIC_FADE_SECONDS := 2.2
const CHAPTER_INTERLUDE_SECONDS := 5.2
const RECORDING_TITLE_HOLD_SECONDS := 10.0
const RECORDING_END_HOLD_SECONDS := 10.0
const VOICED_AUTO_WAIT_RATIO := 0.24

const CHAPTER_INTERLUDES := {
	"G1-02": {
		"number": "第一章",
		"title": "装明白",
		"background_shot": "SHOT-01",
		"background_variant": "arrive",
		"title_rect": Rect2(132.0, 320.0, 650.0, 250.0),
		"alignment": HORIZONTAL_ALIGNMENT_LEFT,
		"focus": Vector2(0.22, 0.48),
		"wash_color": Color(0.025, 0.045, 0.055, 0.38),
		"veil_color": Color(0.015, 0.028, 0.034, 1.0),
		"veil_strength": 0.52,
		"grade": Color(0.035, 0.075, 0.085, 0.12),
		"desaturation": 0.34,
		"accent_color": Color("#b6c9c5"),
		"title_color": Color("#e7e2d9"),
		"zoom": 1.015,
	},
	"G2-01": {
		"number": "第二章",
		"title": "最后一次迂回",
		"background_shot": "SHOT-04",
		"background_variant": "open",
		"title_rect": Rect2(112.0, 300.0, 690.0, 270.0),
		"alignment": HORIZONTAL_ALIGNMENT_LEFT,
		"focus": Vector2(0.22, 0.48),
		"wash_color": Color(0.018, 0.033, 0.036, 0.40),
		"veil_color": Color(0.012, 0.025, 0.026, 1.0),
		"veil_strength": 0.61,
		"grade": Color(0.025, 0.075, 0.063, 0.11),
		"desaturation": 0.30,
		"accent_color": Color("#abc5ba"),
		"title_color": Color("#e7e2d9"),
		"title_size": 70,
		"rule_width": 118.0,
		"zoom": 1.018,
	},
	"G3-01": {
		"number": "第三章",
		"title": "十秒",
		"background_shot": "SHOT-21",
		"title_rect": Rect2(570.0, 116.0, 780.0, 250.0),
		"alignment": HORIZONTAL_ALIGNMENT_CENTER,
		"focus": Vector2(0.50, 0.28),
		"wash_color": Color(0.075, 0.040, 0.035, 0.34),
		"veil_color": Color(0.055, 0.025, 0.027, 1.0),
		"veil_strength": 0.54,
		"grade": Color(0.12, 0.055, 0.040, 0.10),
		"desaturation": 0.28,
		"accent_color": Color("#d2b9a5"),
		"title_color": Color("#eee5db"),
		"zoom": 1.016,
	},
	"G4-01": {
		"number": "第四章",
		"title": "另一种媒介",
		"background_shot": "SHOT-11",
		"title_rect": Rect2(716.0, 484.0, 610.0, 230.0),
		"alignment": HORIZONTAL_ALIGNMENT_CENTER,
		"focus": Vector2(0.53, 0.61),
		"wash_color": Color(0.10, 0.095, 0.075, 0.10),
		"veil_color": Color(0.035, 0.040, 0.033, 1.0),
		"veil_strength": 0.26,
		"grade": Color(0.18, 0.15, 0.10, 0.06),
		"desaturation": 0.10,
		"accent_color": Color("#5e625b"),
		"title_color": Color("#343834"),
		"title_size": 60,
		"title_rotation": -1.0,
		"rule_width": 92.0,
		"zoom": 1.012,
	},
	"G5-01": {
		"number": "第五章",
		"title": "主动失去",
		"background_shot": "SHOT-61",
		"title_rect": Rect2(625.0, 150.0, 760.0, 250.0),
		"alignment": HORIZONTAL_ALIGNMENT_CENTER,
		"focus": Vector2(0.52, 0.34),
		"wash_color": Color(0.018, 0.038, 0.060, 0.34),
		"veil_color": Color(0.010, 0.026, 0.045, 1.0),
		"veil_strength": 0.55,
		"grade": Color(0.025, 0.070, 0.110, 0.12),
		"desaturation": 0.22,
		"accent_color": Color("#b7cbd2"),
		"title_color": Color("#e7e2d9"),
		"zoom": 1.020,
	},
}

var story := StoryControllerClass.new()
var asset_registry := AssetRegistryClass.new()
var ui := GameUIClass.new()
var dialogue_presenter := DialoguePresenterClass.new()
var music_director := MusicDirectorClass.new()
var sound_director := SoundDirectorClass.new()
var voice_sequence_player := VoiceSequencePlayerClass.new()
var auto_timer: Timer

var text_speed := 42.0
var auto_delay := 3.4
var master_volume := 0.8
var is_auto := false
var recording_auto_mode := false
var recording_end_scheduled := false
var history_entries: Array[String] = []
var history_keys: Dictionary = {}
var chapter_directors: Dictionary = {}
var active_chapter_director
var chapter_interlude_tween: Tween
var chapter_music_fade_tween: Tween
var sound_transition_tween: Tween
var chapter_interlude_active := false
var chapter_transition_pending := false
var sound_transition_pending := false
var allow_next_chapter_interlude := false
var pending_chapter_line: Dictionary = {}
var pending_chapter_unit: Dictionary = {}
var voice_cue_dispatch := false
var pending_voice_resume_position := -1.0
var suppress_next_sound_event := false


func _ready() -> void:
	ui.build(self, _ui_callbacks(), _settings_state())
	dialogue_presenter.setup(
		ui.dialogue_panel,
		ui.dialogue_tail,
		ui.speaker_label,
		ui.body_label,
		ui.center_line_label,
	)
	music_director.name = "MusicDirector"
	add_child(music_director)
	if not music_director.setup():
		ui.show_toast("配乐配置加载失败")
	sound_director.name = "SoundDirector"
	add_child(sound_director)
	if not sound_director.setup():
		ui.show_toast("音效资源加载失败")
	voice_sequence_player.name = "VoiceSequencePlayer"
	add_child(voice_sequence_player)
	if not voice_sequence_player.setup():
		ui.show_toast("配音时间轴加载失败")
	voice_sequence_player.cue_started.connect(_on_voice_cue_started)
	voice_sequence_player.segment_cue_started.connect(_on_voice_segment_cue_started)
	voice_sequence_player.handoff_reached.connect(_on_voice_handoff_reached)
	voice_sequence_player.sequence_finished.connect(_on_voice_sequence_finished)
	_set_master_volume(master_volume)
	_setup_auto_timer()
	_setup_chapter_directors()
	story.unit_changed.connect(_on_unit_changed)
	story.line_changed.connect(_on_line_changed)
	story.story_finished.connect(_on_story_finished)

	if not story.load_story():
		ui.show_toast("台本数据加载失败")
		return
	ui.set_scene_units(story.units)
	if not asset_registry.load_manifest():
		ui.show_toast("资产清单加载失败")

	ui.continue_button.disabled = not SaveServiceClass.has_save()
	ui.dialogue_panel.visible = false
	ui.dialogue_tail.visible = false
	ui.show_title_screen()
	if (
		not Engine.get_write_movie_path().is_empty()
		and OS.get_cmdline_user_args().has("--record-full-run")
	):
		_start_full_recording_after_title()


func _start_full_recording_after_title() -> void:
	await get_tree().create_timer(RECORDING_TITLE_HOLD_SECONDS).timeout
	_start_new_game()
	_toggle_recording_auto_mode()


func _process(delta: float) -> void:
	voice_sequence_player.set_paused(
		ui.quick_menu_overlay.visible
		or ui.history_overlay.visible
		or ui.settings_overlay.visible
		or ui.scene_select_overlay.visible
	)
	sound_director.set_paused(
		ui.quick_menu_overlay.visible
		or ui.history_overlay.visible
		or ui.settings_overlay.visible
		or ui.scene_select_overlay.visible
	)
	if active_chapter_director != null:
		active_chapter_director.tick(delta)
	if chapter_transition_pending or chapter_interlude_active:
		return
	if (
		active_chapter_director != null
		and active_chapter_director.handles_custom_reveal()
	):
		if active_chapter_director.tick_reveal(delta, text_speed):
			_finish_typing()
		return
	if dialogue_presenter.tick(delta, text_speed):
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		ui.debug_meta.visible = not ui.debug_meta.visible
		get_viewport().set_input_as_handled()
		return
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_F9
	):
		_toggle_recording_auto_mode()
		get_viewport().set_input_as_handled()
		return
	if active_chapter_director != null and active_chapter_director.blocks_input():
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		if chapter_transition_pending:
			get_viewport().set_input_as_handled()
			return
		elif chapter_interlude_active:
			_finish_chapter_interlude()
		elif ui.scene_select_overlay.visible:
			ui.scene_select_overlay.visible = false
			voice_sequence_player.set_paused(false)
		elif ui.history_overlay.visible:
			ui.history_overlay.visible = false
			voice_sequence_player.set_paused(false)
		elif ui.settings_overlay.visible:
			ui.settings_overlay.visible = false
			voice_sequence_player.set_paused(false)
		elif ui.quick_menu_overlay.visible:
			_close_quick_menu()
		elif not ui.title_overlay.visible and not ui.ending_overlay.visible:
			voice_sequence_player.set_paused(true)
			ui.quick_menu_overlay.visible = true
		get_viewport().set_input_as_handled()
		return

	var advance_requested := event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		advance_requested = advance_requested or (
			event.button_index == MOUSE_BUTTON_LEFT and event.pressed
		)
	if chapter_interlude_active:
		if advance_requested:
			_finish_chapter_interlude()
			get_viewport().set_input_as_handled()
		return

	if _has_blocking_overlay():
		return

	if advance_requested:
		_advance_story()
		get_viewport().set_input_as_handled()


func _ui_callbacks() -> Dictionary:
	return {
		"show_quick_menu": _show_quick_menu,
		"show_history": _show_history,
		"toggle_auto": _toggle_auto,
		"save_game": _save_game,
		"load_game": _load_game,
		"show_settings": _show_settings,
		"show_scene_select": _show_scene_select,
		"jump_to_scene": _jump_to_scene,
		"save_and_return_to_title": _save_and_return_to_title,
		"close_quick_menu": _close_quick_menu,
		"start_new_game": _start_new_game,
		"quit_game": func() -> void: get_tree().quit(),
		"return_to_title": _return_to_title,
		"set_text_speed": func(value: float) -> void: text_speed = value,
		"set_auto_delay": func(value: float) -> void: auto_delay = value,
		"set_master_volume": _set_master_volume,
		"set_fullscreen": _set_fullscreen,
	}


func _setup_auto_timer() -> void:
	auto_timer = Timer.new()
	auto_timer.one_shot = true
	auto_timer.timeout.connect(_on_auto_timeout)
	add_child(auto_timer)


func _setup_chapter_directors() -> void:
	chapter_directors = {
		1: ChapterOneDirectorClass.new(),
		2: ChapterTwoDirectorClass.new(),
		3: ChapterThreeDirectorClass.new(),
		4: ChapterFourDirectorClass.new(),
		5: ChapterFiveDirectorClass.new(),
	}
	var director_context := {
		"host": self,
		"ui": ui,
		"story": story,
		"asset_registry": asset_registry,
		"master_texture": ui.master_texture,
		"fx_layer": ui.chapter_fx_layer,
		"dialogue_panel": ui.dialogue_panel,
		"dialogue_tail": ui.dialogue_tail,
		"center_line_label": ui.center_line_label,
		"auto_timer": auto_timer,
		"music_director": music_director,
		"sound_director": sound_director,
		"voice_sequence_player": voice_sequence_player,
		"advance_story": _request_story_advance,
		"play_voice_segment": _play_voice_segment,
	}
	for director in chapter_directors.values():
		director.setup(director_context)


func _start_new_game() -> void:
	recording_auto_mode = false
	_set_auto_enabled(false)
	music_director.hard_stop()
	sound_director.hard_stop()
	voice_sequence_player.stop()
	_cancel_sound_transition()
	_cancel_chapter_interlude()
	allow_next_chapter_interlude = false
	suppress_next_sound_event = false
	history_entries.clear()
	history_keys.clear()
	ui.history_text.text = ""
	ui.hide_title_screen()
	ui.ending_overlay.visible = false
	ui.quick_menu_overlay.visible = false
	ui.scene_select_overlay.visible = false
	ui.debug_meta.visible = false
	story.start_at(0, 0)


func _advance_story() -> void:
	if voice_sequence_player.is_active() and (
		voice_sequence_player.advances_automatically() or is_auto
	):
		return
	if active_chapter_director != null and active_chapter_director.advance():
		return
	if dialogue_presenter.is_typing:
		_finish_typing()
		return
	auto_timer.stop()
	if dialogue_presenter.advance_page():
		_play_voice_segment(
			str((story.get_current_line() as Dictionary).get("id", "")),
			dialogue_presenter.current_segment_index,
		)
		if is_auto:
			_start_auto_wait()
		return
	_request_story_advance()


func _on_unit_changed(unit: Dictionary) -> void:
	var unit_id := str(unit.get("id", ""))
	if (
		voice_sequence_player.is_active()
		and not voice_sequence_player.has_sequence_for_unit(unit_id)
		and not voice_sequence_player.is_carrying_soundtrack()
	):
		voice_sequence_player.stop()
	var should_show_interlude := (
		allow_next_chapter_interlude
		and CHAPTER_INTERLUDES.has(unit_id)
	)
	allow_next_chapter_interlude = false
	if should_show_interlude:
		_start_chapter_interlude(CHAPTER_INTERLUDES[unit_id] as Dictionary)

	var chapter := int(unit.get("chapter", 1))
	var next_director = chapter_directors.get(chapter)
	if active_chapter_director != next_director:
		if active_chapter_director != null:
			active_chapter_director.leave()
		active_chapter_director = next_director

	var shot_id := str(unit.get("shot", ""))
	var texture: Texture2D = asset_registry.load_master(shot_id)
	ui.show_unit(unit, story.unit_index, story.units.size(), texture)
	if active_chapter_director != null:
		active_chapter_director.on_unit_changed(unit)


func _on_line_changed(line: Dictionary, unit: Dictionary) -> void:
	auto_timer.stop()
	dialogue_presenter.cancel_reveal()
	if (
		voice_sequence_player.is_active()
		and not voice_sequence_player.advances_automatically()
	):
		voice_sequence_player.stop()
	var line_id := str(line.get("id", ""))
	if chapter_interlude_active:
		pending_chapter_line = line.duplicate(true)
		pending_chapter_unit = unit.duplicate(true)
		ui.dialogue_panel.visible = false
		ui.dialogue_tail.visible = false
		ui.center_line_label.visible = false
		return
	sound_director.sync_to_line(line_id, not suppress_next_sound_event)
	suppress_next_sound_event = false
	if voice_sequence_player.has_sequence_for_line(line_id):
		if voice_cue_dispatch:
			voice_cue_dispatch = false
			_present_voiced_line(line, unit)
		else:
			_start_voiced_sequence(line, unit)
		return
	if (
		not voice_sequence_player.is_carrying_soundtrack()
		and (
			active_chapter_director == null
			or not active_chapter_director.defers_music_for_line(line_id)
		)
	):
		music_director.sync_to_line(line_id)
	_present_story_line(line, unit)


func _present_story_line(line: Dictionary, unit: Dictionary) -> void:
	if (
		active_chapter_director != null
		and active_chapter_director.on_line_changed(line, unit)
	):
		_append_history(line)
		return

	dialogue_presenter.start_line(line, active_chapter_director)
	_append_history(line)


func _present_voiced_line(line: Dictionary, unit: Dictionary) -> void:
	_present_story_line(line, unit)
	if active_chapter_director == null or not active_chapter_director.finish_reveal():
		dialogue_presenter.finish_reveal()
	ui.dialogue_panel.visible = false
	ui.dialogue_tail.visible = false


func _start_voiced_sequence(line: Dictionary, unit: Dictionary) -> void:
	auto_timer.stop()
	var line_id := str(line.get("id", ""))
	var unit_id := str(unit.get("id", ""))
	var is_soundtrack := voice_sequence_player.is_soundtrack_line(line_id)
	if is_soundtrack:
		ui.dialogue_panel.visible = false
		ui.dialogue_tail.visible = false
		ui.center_line_label.visible = false
		music_director.hard_stop()
	else:
		music_director.sync_to_line(line_id)
	if not is_soundtrack:
		_present_story_line(line, unit)
	if active_chapter_director != null:
		active_chapter_director.begin_timed_sequence(unit_id, line_id)
	var resume_position := pending_voice_resume_position
	pending_voice_resume_position = -1.0
	if not voice_sequence_player.start_for_line(unit_id, line_id, resume_position):
		if is_soundtrack:
			_present_story_line(line, unit)


func _play_voice_segment(line_id: String, segment_index: int) -> void:
	if story.units.is_empty():
		return
	var current_line_id := str((story.get_current_line() as Dictionary).get("id", ""))
	if current_line_id != line_id:
		return
	var unit_id := str((story.get_current_unit() as Dictionary).get("id", ""))
	voice_sequence_player.start_for_segment(unit_id, line_id, segment_index)


func _on_voice_cue_started(line_id: String) -> void:
	if story.units.is_empty():
		return
	var current_line := story.get_current_line() as Dictionary
	var current_line_id := str(current_line.get("id", ""))
	if current_line_id == line_id:
		_present_voiced_line(current_line, story.get_current_unit() as Dictionary)
		return
	voice_cue_dispatch = true
	story.advance()
	if voice_cue_dispatch:
		voice_cue_dispatch = false


func _on_voice_segment_cue_started(line_id: String, segment_index: int) -> void:
	if story.units.is_empty():
		return
	var current_line_id := str((story.get_current_line() as Dictionary).get("id", ""))
	if current_line_id != line_id:
		push_warning(
			"Timed voice segment cue %s/%d does not match current line %s."
			% [line_id, segment_index, current_line_id]
		)
		return
	if (
		active_chapter_director != null
		and active_chapter_director.show_timed_segment(line_id, segment_index)
	):
		return
	if not dialogue_presenter.show_timed_segment(segment_index):
		push_warning("Timed voice segment cue is outside the reviewed pages: %s/%d." % [
			line_id,
			segment_index,
		])


func _on_voice_handoff_reached(unit_id: String) -> void:
	ui.dialogue_panel.visible = false
	ui.dialogue_tail.visible = false
	ui.center_line_label.visible = false
	if (
		active_chapter_director != null
		and active_chapter_director.begin_voice_handoff(unit_id)
	):
		return
	_request_story_advance()


func _on_voice_sequence_finished(
	_unit_id: String,
	handed_off: bool,
	advance_on_finish: bool,
) -> void:
	if not advance_on_finish:
		if is_auto and not _is_text_revealing():
			_start_auto_wait(_current_voiced_auto_wait_seconds())
		return
	if handed_off:
		if not story.units.is_empty():
			music_director.sync_to_line(
				str((story.get_current_line() as Dictionary).get("id", ""))
			)
		return
	ui.dialogue_panel.visible = false
	ui.dialogue_tail.visible = false
	ui.center_line_label.visible = false
	_request_story_advance()


func _on_story_finished() -> void:
	var should_finalize_movie := (
		recording_auto_mode
		and not Engine.get_write_movie_path().is_empty()
	)
	music_director.fade_out(2.4)
	voice_sequence_player.stop()
	_cancel_chapter_interlude()
	allow_next_chapter_interlude = false
	auto_timer.stop()
	dialogue_presenter.cancel_reveal()
	if active_chapter_director != null:
		active_chapter_director.leave()
		active_chapter_director = null
	recording_auto_mode = false
	_set_auto_enabled(false)
	ui.dialogue_panel.visible = false
	ui.dialogue_tail.visible = false
	ui.center_line_label.visible = false
	ui.quick_menu_overlay.visible = false
	ui.ending_overlay.visible = true
	if should_finalize_movie:
		schedule_recording_end_from_finale()


func schedule_recording_end_from_finale() -> void:
	if recording_end_scheduled or Engine.get_write_movie_path().is_empty():
		return
	recording_end_scheduled = true
	_finalize_recorded_movie_after_hold()


func _finalize_recorded_movie_after_hold() -> void:
	await get_tree().create_timer(RECORDING_END_HOLD_SECONDS).timeout
	get_tree().quit()


func _finish_typing() -> void:
	if active_chapter_director != null and active_chapter_director.finish_reveal():
		return
	dialogue_presenter.finish_reveal()
	if is_auto:
		_start_auto_wait()


func _toggle_auto() -> void:
	recording_auto_mode = false
	_set_auto_enabled(not is_auto)
	ui.quick_menu_overlay.visible = false
	if is_auto and not _is_text_revealing():
		_start_auto_wait()


func _toggle_recording_auto_mode() -> void:
	if ui.title_overlay.visible or ui.ending_overlay.visible:
		return
	recording_auto_mode = not recording_auto_mode
	_set_auto_enabled(recording_auto_mode)
	ui.debug_meta.visible = false
	ui.quick_menu_overlay.visible = false
	voice_sequence_player.set_paused(false)
	sound_director.set_paused(false)
	if (
		recording_auto_mode
		and not _is_text_revealing()
		and not voice_sequence_player.is_active()
		and not _has_blocking_overlay()
	):
		_start_auto_wait()


func _set_auto_enabled(enabled: bool) -> void:
	is_auto = enabled
	ui.auto_button.text = "停止自动" if is_auto else "自动播放"
	if not is_auto:
		auto_timer.stop()


func _on_auto_timeout() -> void:
	if _has_blocking_overlay():
		return
	if active_chapter_director != null and active_chapter_director.on_auto_timeout():
		return
	if is_auto:
		_advance_story()


func _show_quick_menu() -> void:
	auto_timer.stop()
	voice_sequence_player.set_paused(true)
	ui.quick_menu_overlay.visible = true


func _close_quick_menu() -> void:
	ui.quick_menu_overlay.visible = false
	voice_sequence_player.set_paused(false)
	if active_chapter_director != null and active_chapter_director.resume():
		return
	if is_auto and not _is_text_revealing():
		_start_auto_wait()


func _is_text_revealing() -> bool:
	if (
		active_chapter_director != null
		and active_chapter_director.handles_custom_reveal()
	):
		return active_chapter_director.is_revealing()
	return dialogue_presenter.is_typing


func _start_auto_wait(wait_seconds: float = -1.0) -> void:
	auto_timer.start(
		_current_auto_wait_seconds()
		if wait_seconds < 0.0
		else wait_seconds
	)


func _current_auto_wait_seconds() -> float:
	return auto_delay * _current_auto_wait_multiplier()


func _current_voiced_auto_wait_seconds() -> float:
	return auto_delay * VOICED_AUTO_WAIT_RATIO * _current_auto_wait_multiplier()


func _current_auto_wait_multiplier() -> float:
	var multiplier := 1.0
	if active_chapter_director != null and not story.units.is_empty():
		multiplier = maxf(
			0.1,
			float(active_chapter_director.auto_wait_multiplier(
				story.get_current_line(),
				story.get_current_unit(),
			)),
		)
	return multiplier


func _show_history() -> void:
	auto_timer.stop()
	voice_sequence_player.set_paused(true)
	ui.quick_menu_overlay.visible = false
	ui.history_text.text = "\n\n".join(history_entries)
	ui.history_overlay.visible = true


func _show_settings() -> void:
	auto_timer.stop()
	voice_sequence_player.set_paused(true)
	ui.quick_menu_overlay.visible = false
	ui.text_speed_slider.value = text_speed
	ui.auto_delay_slider.value = auto_delay
	ui.volume_slider.value = master_volume
	ui.fullscreen_toggle.button_pressed = (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	ui.settings_overlay.visible = true


func _show_scene_select() -> void:
	auto_timer.stop()
	voice_sequence_player.set_paused(true)
	ui.quick_menu_overlay.visible = false
	ui.show_scene_selector(story.unit_index)


func _jump_to_scene(unit_index: int) -> void:
	if story.units.is_empty():
		return
	auto_timer.stop()
	voice_sequence_player.stop()
	sound_director.hard_stop()
	_cancel_sound_transition()
	_cancel_chapter_interlude()
	allow_next_chapter_interlude = false
	dialogue_presenter.cancel_reveal()
	if active_chapter_director != null:
		active_chapter_director.leave()
		active_chapter_director = null
	recording_auto_mode = false
	_set_auto_enabled(false)
	ui.hide_title_screen()
	ui.ending_overlay.visible = false
	ui.quick_menu_overlay.visible = false
	ui.scene_select_overlay.visible = false
	ui.dialogue_panel.visible = false
	ui.dialogue_tail.visible = false
	ui.center_line_label.visible = false
	history_entries.clear()
	history_keys.clear()
	ui.history_text.text = ""
	var safe_index := clampi(unit_index, 0, story.units.size() - 1)
	var target_unit := story.units[safe_index] as Dictionary
	var show_interlude := CHAPTER_INTERLUDES.has(str(target_unit.get("id", "")))
	allow_next_chapter_interlude = show_interlude
	if show_interlude:
		music_director.fade_out(1.0)
	story.start_at(safe_index, 0)
	if not show_interlude:
		ui.show_toast("已进入 %s" % story.get_current_unit().get("id", ""))


func _save_game() -> void:
	if story.units.is_empty():
		return
	var progress: Dictionary = story.get_progress()
	progress["settings"] = _settings_state()
	progress["voice_sequence"] = voice_sequence_player.get_state()
	var error: Error = SaveServiceClass.write_save(progress)
	if error == OK:
		ui.continue_button.disabled = false
		ui.show_toast("已保存")
	else:
		ui.show_toast("保存失败")


func _load_game() -> void:
	var state: Dictionary = SaveServiceClass.read_save()
	if state.is_empty():
		ui.show_toast("没有可读取的存档")
		return
	recording_auto_mode = false
	_set_auto_enabled(false)
	_cancel_chapter_interlude()
	voice_sequence_player.stop()
	sound_director.hard_stop()
	_cancel_sound_transition()
	allow_next_chapter_interlude = false
	suppress_next_sound_event = true

	_apply_settings(state.get("settings", {}) as Dictionary)
	var voice_state := state.get("voice_sequence", {}) as Dictionary
	var voice_resume_position := float(voice_state.get("position", -1.0))
	if bool(voice_state.get("handed_off", false)):
		music_director.hard_stop()
		voice_sequence_player.resume_carry(
			str(voice_state.get("unit_id", "")),
			voice_resume_position,
		)
	else:
		pending_voice_resume_position = voice_resume_position
	_rebuild_history(int(state.get("unit_index", 0)), int(state.get("line_index", 0)))
	ui.hide_title_screen()
	ui.ending_overlay.visible = false
	ui.quick_menu_overlay.visible = false
	ui.scene_select_overlay.visible = false
	story.start_at(
		int(state.get("unit_index", 0)),
		int(state.get("line_index", 0)),
	)
	ui.show_toast("已读取")


func _save_and_return_to_title() -> void:
	_save_game()
	_return_to_title()


func _return_to_title() -> void:
	auto_timer.stop()
	music_director.hard_stop()
	sound_director.hard_stop()
	voice_sequence_player.stop()
	_cancel_sound_transition()
	_cancel_chapter_interlude()
	allow_next_chapter_interlude = false
	dialogue_presenter.cancel_reveal()
	if active_chapter_director != null:
		active_chapter_director.leave()
		active_chapter_director = null
	recording_auto_mode = false
	_set_auto_enabled(false)
	ui.history_overlay.visible = false
	ui.settings_overlay.visible = false
	ui.quick_menu_overlay.visible = false
	ui.ending_overlay.visible = false
	ui.dialogue_panel.visible = false
	ui.dialogue_tail.visible = false
	ui.center_line_label.visible = false
	ui.show_title_screen()
	ui.continue_button.disabled = not SaveServiceClass.has_save()


func _append_history(line: Dictionary) -> void:
	var key := str(line.get("id", ""))
	if history_keys.has(key):
		return
	history_keys[key] = true
	history_entries.append("%s\n%s" % [line.get("speaker", ""), line.get("text", "")])


func _rebuild_history(target_unit: int, target_line: int) -> void:
	history_entries.clear()
	history_keys.clear()
	for unit_index in range(story.units.size()):
		if unit_index > target_unit:
			break
		var unit := story.units[unit_index] as Dictionary
		var lines := unit.get("lines", []) as Array
		var last_line := lines.size() - 1
		if unit_index == target_unit:
			last_line = mini(target_line, last_line)
		for line_index in range(last_line + 1):
			_append_history(lines[line_index] as Dictionary)
	ui.history_text.text = "\n\n".join(history_entries)


func _settings_state() -> Dictionary:
	return {
		"text_speed": text_speed,
		"auto_delay": auto_delay,
		"master_volume": master_volume,
		"fullscreen": DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
	}


func _apply_settings(settings: Dictionary) -> void:
	if settings.is_empty():
		return
	text_speed = float(settings.get("text_speed", text_speed))
	auto_delay = float(settings.get("auto_delay", auto_delay))
	_set_master_volume(float(settings.get("master_volume", master_volume)))
	_set_fullscreen(bool(settings.get("fullscreen", false)))


func _set_master_volume(value: float) -> void:
	master_volume = value
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.0001)))


func _set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _has_blocking_overlay() -> bool:
	return (
		chapter_transition_pending
		or sound_transition_pending
		or chapter_interlude_active
		or ui.title_overlay.visible
		or ui.ending_overlay.visible
		or ui.history_overlay.visible
		or ui.settings_overlay.visible
		or ui.scene_select_overlay.visible
		or ui.quick_menu_overlay.visible
	)


func _request_story_advance() -> void:
	if chapter_transition_pending or sound_transition_pending:
		return
	if _next_unit_starts_chapter_interlude():
		_begin_chapter_music_fade()
		return
	var next_line_id := _next_story_line_id()
	var next_ambience_id := sound_director.ambience_for_line(next_line_id)
	if (
		not next_line_id.is_empty()
		and not sound_director.active_ambience_id.is_empty()
		and next_ambience_id != sound_director.active_ambience_id
	):
		_begin_sound_transition(next_line_id)
		return
	story.advance()


func _next_story_line_id() -> String:
	if story.units.is_empty():
		return ""
	var current_lines := story.get_current_unit().get("lines", []) as Array
	if story.line_index + 1 < current_lines.size():
		return str((current_lines[story.line_index + 1] as Dictionary).get("id", ""))
	var next_unit_index := story.unit_index + 1
	if next_unit_index >= story.units.size():
		return ""
	var next_unit := story.units[next_unit_index] as Dictionary
	var next_lines := next_unit.get("lines", []) as Array
	if next_lines.is_empty():
		return ""
	return str((next_lines[0] as Dictionary).get("id", ""))


func _begin_sound_transition(next_line_id: String) -> void:
	sound_transition_pending = true
	auto_timer.stop()
	var fade_seconds := 0.24 if next_line_id == "G1-01-21" else 0.65
	sound_director.fade_out(fade_seconds)
	sound_transition_tween = create_tween()
	sound_transition_tween.tween_interval(fade_seconds)
	sound_transition_tween.finished.connect(_finish_sound_transition)


func _finish_sound_transition() -> void:
	if not sound_transition_pending:
		return
	sound_transition_tween = null
	sound_transition_pending = false
	story.advance()


func _cancel_sound_transition() -> void:
	if sound_transition_tween != null and sound_transition_tween.is_valid():
		sound_transition_tween.kill()
	sound_transition_tween = null
	sound_transition_pending = false


func _next_unit_starts_chapter_interlude() -> bool:
	if story.units.is_empty():
		return false
	var current_lines := story.get_current_unit().get("lines", []) as Array
	if story.line_index + 1 < current_lines.size():
		return false
	var next_unit_index := story.unit_index + 1
	if next_unit_index >= story.units.size():
		return false
	var next_unit := story.units[next_unit_index] as Dictionary
	return CHAPTER_INTERLUDES.has(str(next_unit.get("id", "")))


func _begin_chapter_music_fade() -> void:
	chapter_transition_pending = true
	auto_timer.stop()
	dialogue_presenter.cancel_reveal()
	ui.dialogue_panel.visible = false
	ui.dialogue_tail.visible = false
	ui.center_line_label.visible = false
	music_director.fade_out(CHAPTER_MUSIC_FADE_SECONDS)
	sound_director.fade_out(CHAPTER_MUSIC_FADE_SECONDS)
	if chapter_music_fade_tween != null and chapter_music_fade_tween.is_valid():
		chapter_music_fade_tween.kill()
	chapter_music_fade_tween = create_tween()
	chapter_music_fade_tween.tween_interval(CHAPTER_MUSIC_FADE_SECONDS)
	chapter_music_fade_tween.finished.connect(_finish_chapter_music_fade)


func _finish_chapter_music_fade() -> void:
	if not chapter_transition_pending:
		return
	if chapter_music_fade_tween != null and chapter_music_fade_tween.is_valid():
		chapter_music_fade_tween.kill()
	chapter_music_fade_tween = null
	chapter_transition_pending = false
	music_director.hard_stop()
	sound_director.hard_stop()
	allow_next_chapter_interlude = true
	story.advance()


func _start_chapter_interlude(spec: Dictionary) -> void:
	_cancel_chapter_interlude()
	auto_timer.stop()
	dialogue_presenter.cancel_reveal()
	ui.dialogue_panel.visible = false
	ui.dialogue_tail.visible = false
	ui.center_line_label.visible = false

	var shot_id := str(spec.get("background_shot", ""))
	var variant_id := str(spec.get("background_variant", ""))
	var texture: Texture2D
	if not variant_id.is_empty():
		texture = asset_registry.load_variant(shot_id, variant_id)
	if texture == null and not shot_id.is_empty():
		texture = asset_registry.load_master(shot_id)
	if texture == null:
		texture = ui.master_texture.texture

	ui.configure_chapter_interlude(spec, texture)
	chapter_interlude_active = true
	pending_chapter_line.clear()
	pending_chapter_unit.clear()

	var kicker_target_y := ui.chapter_interlude_kicker.position.y
	var title_target_y := ui.chapter_interlude_title.position.y
	ui.chapter_interlude_kicker.position.y = kicker_target_y + 9.0
	ui.chapter_interlude_title.position.y = title_target_y + 15.0

	chapter_interlude_tween = create_tween().set_parallel(true)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_backdrop,
		"scale",
		Vector2.ONE * float(spec.get("zoom", 1.018)),
		CHAPTER_INTERLUDE_SECONDS,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_wash,
		"modulate:a",
		1.0,
		0.55,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_vignette,
		"modulate:a",
		1.0,
		0.70,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_kicker,
		"modulate:a",
		1.0,
		0.34,
	).set_delay(0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_kicker,
		"position:y",
		kicker_target_y,
		0.42,
	).set_delay(0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_rule,
		"modulate:a",
		0.84,
		0.24,
	).set_delay(0.58)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_rule,
		"scale:x",
		1.0,
		0.48,
	).set_delay(0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_title,
		"modulate:a",
		1.0,
		0.48,
	).set_delay(0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_title,
		"position:y",
		title_target_y,
		0.56,
	).set_delay(0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_kicker,
		"modulate:a",
		0.0,
		0.42,
	).set_delay(3.80)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_rule,
		"modulate:a",
		0.0,
		0.42,
	).set_delay(3.80)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_title,
		"modulate:a",
		0.0,
		0.46,
	).set_delay(3.80)
	chapter_interlude_tween.tween_property(
		ui.chapter_interlude_overlay,
		"modulate:a",
		0.0,
		1.05,
	).set_delay(4.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	chapter_interlude_tween.finished.connect(_finish_chapter_interlude)


func _finish_chapter_interlude() -> void:
	if not chapter_interlude_active:
		return
	if chapter_interlude_tween != null and chapter_interlude_tween.is_valid():
		chapter_interlude_tween.kill()
	chapter_interlude_tween = null
	chapter_interlude_active = false
	ui.hide_chapter_interlude()
	if pending_chapter_line.is_empty():
		return
	var line := pending_chapter_line.duplicate(true)
	var unit := pending_chapter_unit.duplicate(true)
	pending_chapter_line.clear()
	pending_chapter_unit.clear()
	var line_id := str(line.get("id", ""))
	sound_director.sync_to_line(line_id)
	if voice_sequence_player.has_sequence_for_line(line_id):
		_start_voiced_sequence(line, unit)
		return
	if not voice_sequence_player.is_carrying_soundtrack():
		music_director.sync_to_line(line_id)
	_present_story_line(line, unit)


func _cancel_chapter_interlude() -> void:
	if chapter_music_fade_tween != null and chapter_music_fade_tween.is_valid():
		chapter_music_fade_tween.kill()
	chapter_music_fade_tween = null
	if chapter_interlude_tween != null and chapter_interlude_tween.is_valid():
		chapter_interlude_tween.kill()
		chapter_interlude_tween = null
	chapter_transition_pending = false
	chapter_interlude_active = false
	pending_chapter_line.clear()
	pending_chapter_unit.clear()
	if ui.chapter_interlude_overlay != null:
		ui.hide_chapter_interlude()
