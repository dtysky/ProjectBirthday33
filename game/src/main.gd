extends Control

const StoryControllerClass := preload("res://src/story_controller.gd")
const AssetRegistryClass := preload("res://src/asset_registry.gd")
const SaveServiceClass := preload("res://src/save_service.gd")
const GameUIClass := preload("res://src/ui/game_ui.gd")
const DialoguePresenterClass := preload("res://src/ui/dialogue_presenter.gd")
const ChapterOneDirectorClass := preload("res://src/chapters/chapter_01.gd")
const ChapterTwoDirectorClass := preload("res://src/chapters/chapter_02.gd")
const ChapterThreeDirectorClass := preload("res://src/chapters/chapter_03.gd")
const ChapterFourDirectorClass := preload("res://src/chapters/chapter_04.gd")
const ChapterFiveDirectorClass := preload("res://src/chapters/chapter_05.gd")

var story := StoryControllerClass.new()
var asset_registry := AssetRegistryClass.new()
var ui := GameUIClass.new()
var dialogue_presenter := DialoguePresenterClass.new()
var auto_timer: Timer

var text_speed := 42.0
var auto_delay := 3.4
var master_volume := 0.8
var is_auto := false
var history_entries: Array[String] = []
var history_keys: Dictionary = {}
var chapter_directors: Dictionary = {}
var active_chapter_director


func _ready() -> void:
	ui.build(self, _ui_callbacks(), _settings_state())
	dialogue_presenter.setup(
		ui.dialogue_panel,
		ui.dialogue_tail,
		ui.speaker_label,
		ui.body_label,
		ui.center_line_label,
	)
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
	ui.menu_button.visible = false
	ui.title_overlay.visible = true


func _process(delta: float) -> void:
	if (
		active_chapter_director != null
		and active_chapter_director.handles_custom_reveal()
	):
		return
	if dialogue_presenter.tick(delta, text_speed):
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		ui.debug_meta.visible = not ui.debug_meta.visible
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		if ui.scene_select_overlay.visible:
			ui.scene_select_overlay.visible = false
		elif ui.history_overlay.visible:
			ui.history_overlay.visible = false
		elif ui.settings_overlay.visible:
			ui.settings_overlay.visible = false
		elif ui.quick_menu_overlay.visible:
			_close_quick_menu()
		elif not ui.title_overlay.visible and not ui.ending_overlay.visible:
			ui.quick_menu_overlay.visible = true
		get_viewport().set_input_as_handled()
		return

	if _has_blocking_overlay():
		return

	var advance_requested := event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		advance_requested = advance_requested or (
			event.button_index == MOUSE_BUTTON_LEFT and event.pressed
		)
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
	}
	for director in chapter_directors.values():
		director.setup(director_context)


func _start_new_game() -> void:
	history_entries.clear()
	history_keys.clear()
	ui.history_text.text = ""
	ui.title_overlay.visible = false
	ui.ending_overlay.visible = false
	ui.quick_menu_overlay.visible = false
	ui.scene_select_overlay.visible = false
	ui.menu_button.visible = true
	story.start_at(0, 0)


func _advance_story() -> void:
	if active_chapter_director != null and active_chapter_director.advance():
		return
	if dialogue_presenter.is_typing:
		_finish_typing()
		return
	auto_timer.stop()
	if dialogue_presenter.advance_page():
		if is_auto:
			auto_timer.start(auto_delay)
		return
	story.advance()


func _on_unit_changed(unit: Dictionary) -> void:
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
		active_chapter_director != null
		and active_chapter_director.on_line_changed(line, unit)
	):
		_append_history(line)
		return

	dialogue_presenter.start_line(line, active_chapter_director)
	_append_history(line)


func _on_story_finished() -> void:
	auto_timer.stop()
	dialogue_presenter.cancel_reveal()
	if active_chapter_director != null:
		active_chapter_director.leave()
		active_chapter_director = null
	is_auto = false
	ui.auto_button.text = "自动"
	ui.dialogue_panel.visible = false
	ui.dialogue_tail.visible = false
	ui.center_line_label.visible = false
	ui.menu_button.visible = false
	ui.quick_menu_overlay.visible = false
	ui.ending_overlay.visible = true


func _finish_typing() -> void:
	if active_chapter_director != null and active_chapter_director.finish_reveal():
		return
	dialogue_presenter.finish_reveal()
	if is_auto:
		auto_timer.start(auto_delay)


func _toggle_auto() -> void:
	is_auto = not is_auto
	ui.auto_button.text = "停止" if is_auto else "自动"
	ui.quick_menu_overlay.visible = false
	if is_auto and not dialogue_presenter.is_typing:
		auto_timer.start(auto_delay)
	else:
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
	ui.quick_menu_overlay.visible = true


func _close_quick_menu() -> void:
	ui.quick_menu_overlay.visible = false
	if active_chapter_director != null and active_chapter_director.resume():
		return
	if is_auto and not dialogue_presenter.is_typing:
		auto_timer.start(auto_delay)


func _show_history() -> void:
	auto_timer.stop()
	ui.quick_menu_overlay.visible = false
	ui.history_text.text = "\n\n".join(history_entries)
	ui.history_overlay.visible = true


func _show_settings() -> void:
	auto_timer.stop()
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
	ui.quick_menu_overlay.visible = false
	ui.show_scene_selector(story.unit_index)


func _jump_to_scene(unit_index: int) -> void:
	if story.units.is_empty():
		return
	auto_timer.stop()
	dialogue_presenter.cancel_reveal()
	if active_chapter_director != null:
		active_chapter_director.leave()
		active_chapter_director = null
	is_auto = false
	ui.auto_button.text = "自动"
	ui.title_overlay.visible = false
	ui.ending_overlay.visible = false
	ui.quick_menu_overlay.visible = false
	ui.scene_select_overlay.visible = false
	ui.dialogue_panel.visible = false
	ui.dialogue_tail.visible = false
	ui.center_line_label.visible = false
	ui.menu_button.visible = true
	history_entries.clear()
	history_keys.clear()
	ui.history_text.text = ""
	var safe_index := clampi(unit_index, 0, story.units.size() - 1)
	story.start_at(safe_index, 0)
	ui.show_toast("已进入 %s" % story.get_current_unit().get("id", ""))


func _save_game() -> void:
	if story.units.is_empty():
		return
	var progress: Dictionary = story.get_progress()
	progress["settings"] = _settings_state()
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

	_apply_settings(state.get("settings", {}) as Dictionary)
	_rebuild_history(int(state.get("unit_index", 0)), int(state.get("line_index", 0)))
	ui.title_overlay.visible = false
	ui.ending_overlay.visible = false
	ui.quick_menu_overlay.visible = false
	ui.scene_select_overlay.visible = false
	ui.menu_button.visible = true
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
	dialogue_presenter.cancel_reveal()
	if active_chapter_director != null:
		active_chapter_director.leave()
		active_chapter_director = null
	is_auto = false
	ui.auto_button.text = "自动"
	ui.history_overlay.visible = false
	ui.settings_overlay.visible = false
	ui.quick_menu_overlay.visible = false
	ui.ending_overlay.visible = false
	ui.dialogue_panel.visible = false
	ui.dialogue_tail.visible = false
	ui.center_line_label.visible = false
	ui.menu_button.visible = false
	ui.title_overlay.visible = true
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
		ui.title_overlay.visible
		or ui.ending_overlay.visible
		or ui.history_overlay.visible
		or ui.settings_overlay.visible
		or ui.scene_select_overlay.visible
		or ui.quick_menu_overlay.visible
	)
