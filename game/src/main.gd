extends Control

const StoryControllerClass := preload("res://src/story_controller.gd")
const AssetRegistryClass := preload("res://src/asset_registry.gd")
const SaveServiceClass := preload("res://src/save_service.gd")
const CHAPTER_COLORS := {
	1: Color("#1b2023"),
	2: Color("#172723"),
	3: Color("#251f25"),
	4: Color("#293025"),
	5: Color("#302c28"),
}
const PAGE_BREAK_PUNCTUATION := "，。！？；：、—…,.!?;:"
const BUBBLE_PAGE_LIMIT := 30
const CAPTION_PAGE_LIMIT := 38
const CENTER_PAGE_LIMIT := 32

var story := StoryControllerClass.new()
var asset_registry := AssetRegistryClass.new()

var stage: ColorRect
var master_texture: TextureRect
var debug_meta: MarginContainer
var unit_label: Label
var unit_title_label: Label
var shot_label: Label
var dialogue_tail: Polygon2D
var dialogue_panel: PanelContainer
var dialogue_style: StyleBoxFlat
var body_label: Label
var bubble_next_mark: Label
var center_line_label: Label
var menu_button: Button
var quick_menu_overlay: ColorRect
var auto_button: Button
var continue_button: Button
var title_overlay: ColorRect
var history_overlay: ColorRect
var history_text: RichTextLabel
var settings_overlay: ColorRect
var ending_overlay: ColorRect
var toast_label: Label
var text_speed_slider: HSlider
var auto_delay_slider: HSlider
var volume_slider: HSlider
var fullscreen_toggle: CheckButton
var auto_timer: Timer
var toast_timer: Timer

var text_speed := 42.0
var auto_delay := 3.4
var master_volume := 0.8
var is_auto := false
var is_typing := false
var is_screen_line := false
var type_progress := 0.0
var current_text := ""
var current_presentation := "bubble"
var current_speaker := ""
var current_segments: Array[String] = []
var current_segment_index := 0
var history_entries: Array[String] = []
var history_keys: Dictionary = {}


func _ready() -> void:
	_build_ui()
	story.unit_changed.connect(_on_unit_changed)
	story.line_changed.connect(_on_line_changed)
	story.story_finished.connect(_on_story_finished)

	if not story.load_story():
		_show_toast("台本数据加载失败")
		return
	if not asset_registry.load_manifest():
		_show_toast("资产清单加载失败")

	continue_button.disabled = not SaveServiceClass.has_save()
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	menu_button.visible = false
	title_overlay.visible = true


func _process(delta: float) -> void:
	if not is_typing:
		return

	type_progress += delta * text_speed
	var visible_count := mini(int(type_progress), current_text.length())
	_get_active_label().visible_characters = visible_count
	if visible_count >= current_text.length():
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		debug_meta.visible = not debug_meta.visible
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		if history_overlay.visible:
			history_overlay.visible = false
		elif settings_overlay.visible:
			settings_overlay.visible = false
		elif quick_menu_overlay.visible:
			_close_quick_menu()
		elif not title_overlay.visible and not ending_overlay.visible:
			quick_menu_overlay.visible = true
		get_viewport().set_input_as_handled()
		return

	if (
		title_overlay.visible
		or ending_overlay.visible
		or history_overlay.visible
		or settings_overlay.visible
		or quick_menu_overlay.visible
	):
		return

	var advance_requested := event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		advance_requested = advance_requested or (
			event.button_index == MOUSE_BUTTON_LEFT and event.pressed
		)
	if advance_requested:
		_advance_story()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	stage = ColorRect.new()
	stage.name = "Stage"
	stage.color = CHAPTER_COLORS[1]
	_set_full_rect(stage)
	add_child(stage)

	master_texture = TextureRect.new()
	master_texture.name = "MasterTexture"
	master_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	master_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	master_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(master_texture)
	add_child(master_texture)

	debug_meta = MarginContainer.new()
	debug_meta.name = "DebugMeta"
	debug_meta.anchor_right = 1.0
	debug_meta.offset_left = 42.0
	debug_meta.offset_top = 32.0
	debug_meta.offset_right = -42.0
	debug_meta.offset_bottom = 150.0
	debug_meta.visible = false
	debug_meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(debug_meta)

	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 4)
	debug_meta.add_child(top_box)

	unit_label = Label.new()
	unit_label.add_theme_font_size_override("font_size", 18)
	unit_label.modulate = Color(1.0, 1.0, 1.0, 0.72)
	top_box.add_child(unit_label)

	unit_title_label = Label.new()
	unit_title_label.add_theme_font_size_override("font_size", 34)
	top_box.add_child(unit_title_label)

	shot_label = Label.new()
	shot_label.add_theme_font_size_override("font_size", 15)
	shot_label.modulate = Color(1.0, 1.0, 1.0, 0.46)
	top_box.add_child(shot_label)

	_build_dialogue()
	_build_center_line()
	_build_quick_menu()
	_build_title_screen()
	_build_history()
	_build_settings()
	_build_ending()
	_build_toast()

	auto_timer = Timer.new()
	auto_timer.one_shot = true
	auto_timer.timeout.connect(_on_auto_timeout)
	add_child(auto_timer)

	toast_timer = Timer.new()
	toast_timer.one_shot = true
	toast_timer.wait_time = 2.0
	toast_timer.timeout.connect(func() -> void: toast_label.visible = false)
	add_child(toast_timer)


func _build_dialogue() -> void:
	dialogue_tail = Polygon2D.new()
	dialogue_tail.name = "DialogueTail"
	dialogue_tail.color = Color(0.035, 0.035, 0.038, 0.82)
	dialogue_tail.polygon = PackedVector2Array([
		Vector2(-18.0, 0.0),
		Vector2(18.0, 0.0),
		Vector2(0.0, 38.0),
	])
	dialogue_tail.visible = false
	add_child(dialogue_tail)

	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	dialogue_panel.position = Vector2(650.0, 150.0)
	dialogue_panel.size = Vector2(520.0, 144.0)
	dialogue_style = _rounded_style(Color(0.035, 0.035, 0.038, 0.82), 22)
	dialogue_panel.add_theme_stylebox_override("panel", dialogue_style)
	add_child(dialogue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 18)
	dialogue_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	body_label = Label.new()
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_label.add_theme_font_size_override("font_size", 32)
	body_label.add_theme_constant_override("line_spacing", 8)
	box.add_child(body_label)

	var marker_row := HBoxContainer.new()
	marker_row.custom_minimum_size.y = 24
	box.add_child(marker_row)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marker_row.add_child(spacer)
	bubble_next_mark = Label.new()
	bubble_next_mark.text = "▶"
	bubble_next_mark.add_theme_font_size_override("font_size", 18)
	bubble_next_mark.modulate = Color(1.0, 1.0, 1.0, 0.78)
	marker_row.add_child(bubble_next_mark)


func _build_center_line() -> void:
	center_line_label = Label.new()
	center_line_label.name = "CenterLine"
	center_line_label.anchor_left = 0.18
	center_line_label.anchor_top = 0.30
	center_line_label.anchor_right = 0.82
	center_line_label.anchor_bottom = 0.74
	center_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_line_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_line_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	center_line_label.add_theme_font_size_override("font_size", 44)
	center_line_label.add_theme_constant_override("line_spacing", 18)
	center_line_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	center_line_label.add_theme_constant_override("shadow_offset_x", 2)
	center_line_label.add_theme_constant_override("shadow_offset_y", 3)
	center_line_label.add_theme_constant_override("shadow_outline_size", 5)
	center_line_label.visible = false
	center_line_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center_line_label)


func _build_quick_menu() -> void:
	menu_button = _make_button("···", _show_quick_menu)
	menu_button.name = "MenuButton"
	menu_button.anchor_left = 0.944
	menu_button.anchor_top = 0.914
	menu_button.anchor_right = 0.982
	menu_button.anchor_bottom = 0.968
	menu_button.offset_left = 0.0
	menu_button.offset_top = 0.0
	menu_button.offset_right = 0.0
	menu_button.offset_bottom = 0.0
	menu_button.add_theme_font_size_override("font_size", 24)
	menu_button.add_theme_stylebox_override("normal", _rounded_style(Color(0.02, 0.02, 0.02, 0.38), 20))
	menu_button.add_theme_stylebox_override("hover", _rounded_style(Color(0.02, 0.02, 0.02, 0.72), 20))
	add_child(menu_button)

	quick_menu_overlay = ColorRect.new()
	quick_menu_overlay.name = "QuickMenuOverlay"
	quick_menu_overlay.color = Color(0.0, 0.0, 0.0, 0.64)
	quick_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	quick_menu_overlay.visible = false
	_set_full_rect(quick_menu_overlay)
	add_child(quick_menu_overlay)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.40
	panel.anchor_top = 0.26
	panel.anchor_right = 0.60
	panel.anchor_bottom = 0.74
	panel.add_theme_stylebox_override("panel", _rounded_style(Color("#15191a"), 18))
	quick_menu_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := Label.new()
	title.text = "菜单"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)

	var gap := Control.new()
	gap.custom_minimum_size.y = 12
	box.add_child(gap)
	box.add_child(_make_button("历史", _show_history))
	auto_button = _make_button("自动", _toggle_auto)
	box.add_child(auto_button)
	box.add_child(_make_button("保存", _save_game))
	box.add_child(_make_button("读取", _load_game))
	box.add_child(_make_button("设置", _show_settings))
	box.add_child(_make_button("返回标题", _save_and_return_to_title))

	var final_gap := Control.new()
	final_gap.custom_minimum_size.y = 8
	box.add_child(final_gap)
	box.add_child(_make_button("继续", _close_quick_menu))


func _build_title_screen() -> void:
	title_overlay = ColorRect.new()
	title_overlay.name = "TitleOverlay"
	title_overlay.color = Color("#0d1011")
	title_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_full_rect(title_overlay)
	add_child(title_overlay)

	var center := CenterContainer.new()
	_set_full_rect(center)
	title_overlay.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 360
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = "三十三"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 92)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "我的第二段人生，即将开始"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 21)
	subtitle.modulate = Color(1.0, 1.0, 1.0, 0.62)
	box.add_child(subtitle)

	var gap := Control.new()
	gap.custom_minimum_size.y = 42
	box.add_child(gap)

	box.add_child(_make_button("开始", _start_new_game, 360))
	continue_button = _make_button("继续", _load_game, 360)
	box.add_child(continue_button)
	box.add_child(_make_button("设置", _show_settings, 360))
	box.add_child(_make_button("退出", func() -> void: get_tree().quit(), 360))


func _build_history() -> void:
	history_overlay = ColorRect.new()
	history_overlay.name = "HistoryOverlay"
	history_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	history_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	history_overlay.visible = false
	_set_full_rect(history_overlay)
	add_child(history_overlay)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.14
	panel.anchor_top = 0.09
	panel.anchor_right = 0.86
	panel.anchor_bottom = 0.91
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#15191a")))
	history_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "历史"
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(_make_button("关闭", func() -> void: history_overlay.visible = false))

	history_text = RichTextLabel.new()
	history_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_text.add_theme_font_size_override("normal_font_size", 22)
	history_text.add_theme_constant_override("line_separation", 9)
	history_text.scroll_following = true
	box.add_child(history_text)


func _build_settings() -> void:
	settings_overlay = ColorRect.new()
	settings_overlay.name = "SettingsOverlay"
	settings_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_overlay.visible = false
	_set_full_rect(settings_overlay)
	add_child(settings_overlay)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.28
	panel.anchor_top = 0.18
	panel.anchor_right = 0.72
	panel.anchor_bottom = 0.82
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#15191a")))
	settings_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	margin.add_child(box)

	var title := Label.new()
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 22)
	box.add_child(grid)

	text_speed_slider = _add_slider(
		grid, "文字速度", 20.0, 90.0, 1.0, text_speed,
		func(value: float) -> void: text_speed = value
	)
	auto_delay_slider = _add_slider(
		grid, "自动等待", 1.0, 8.0, 0.1, auto_delay,
		func(value: float) -> void: auto_delay = value
	)
	volume_slider = _add_slider(
		grid, "主音量", 0.0, 1.0, 0.01, master_volume,
		_set_master_volume
	)

	var fullscreen_label := Label.new()
	fullscreen_label.text = "全屏"
	fullscreen_label.add_theme_font_size_override("font_size", 20)
	grid.add_child(fullscreen_label)
	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "启用"
	fullscreen_toggle.toggled.connect(_set_fullscreen)
	grid.add_child(fullscreen_toggle)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	box.add_child(_make_button("关闭", func() -> void: settings_overlay.visible = false))


func _build_ending() -> void:
	ending_overlay = ColorRect.new()
	ending_overlay.name = "EndingOverlay"
	ending_overlay.color = Color("#0b0d0e")
	ending_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ending_overlay.visible = false
	_set_full_rect(ending_overlay)
	add_child(ending_overlay)

	var center := CenterContainer.new()
	_set_full_rect(center)
	ending_overlay.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 340
	box.add_theme_constant_override("separation", 30)
	center.add_child(box)
	var label := Label.new()
	label.text = "终"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 72)
	box.add_child(label)
	box.add_child(_make_button("返回标题", _return_to_title, 340))


func _build_toast() -> void:
	toast_label = Label.new()
	toast_label.anchor_left = 0.7
	toast_label.anchor_top = 0.05
	toast_label.anchor_right = 0.95
	toast_label.anchor_bottom = 0.12
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 18)
	toast_label.visible = false
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_label)


func _start_new_game() -> void:
	history_entries.clear()
	history_keys.clear()
	history_text.text = ""
	title_overlay.visible = false
	ending_overlay.visible = false
	quick_menu_overlay.visible = false
	menu_button.visible = true
	story.start_at(0, 0)


func _advance_story() -> void:
	if is_typing:
		_finish_typing()
		return
	auto_timer.stop()
	if current_segment_index + 1 < current_segments.size():
		current_segment_index += 1
		_show_current_segment()
		return
	story.advance()


func _on_unit_changed(unit: Dictionary) -> void:
	var chapter := int(unit.get("chapter", 1))
	stage.color = CHAPTER_COLORS.get(chapter, Color("#1b2023"))
	unit_label.text = "%s  ·  %d / %d" % [
		unit.get("id", ""),
		story.unit_index + 1,
		story.units.size(),
	]
	unit_title_label.text = str(unit.get("title", ""))
	shot_label.text = "%s  ·  %s" % [
		unit.get("shot", "NO SHOT"),
		unit.get("production", ""),
	]

	var texture: Texture2D = asset_registry.load_master(str(unit.get("shot", "")))
	master_texture.texture = texture
	master_texture.visible = texture != null


func _on_line_changed(line: Dictionary, unit: Dictionary) -> void:
	auto_timer.stop()
	current_presentation = str(line.get("presentation", "bubble"))
	current_speaker = str(line.get("speaker", ""))
	current_segments = _paginate_text(str(line.get("text", "")), current_presentation)
	current_segment_index = 0
	_show_current_segment()
	_append_history(line)


func _show_current_segment() -> void:
	var segment_text := current_segments[current_segment_index] if not current_segments.is_empty() else ""
	is_screen_line = current_presentation != "bubble"
	dialogue_panel.visible = not is_screen_line
	dialogue_tail.visible = not is_screen_line
	center_line_label.visible = is_screen_line

	if is_screen_line:
		current_text = _format_screen_text(segment_text)
		center_line_label.text = current_text
		_position_caption(current_presentation)
	else:
		current_text = _format_bubble_text(segment_text)
		body_label.text = current_text
		_position_bubble(current_speaker, current_text)

	var active := _get_active_label()
	active.visible_characters = 0
	type_progress = 0.0
	is_typing = true


func _on_story_finished() -> void:
	auto_timer.stop()
	is_auto = false
	auto_button.text = "自动"
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = false
	menu_button.visible = false
	quick_menu_overlay.visible = false
	ending_overlay.visible = true


func _finish_typing() -> void:
	_get_active_label().visible_characters = -1
	is_typing = false
	if is_auto:
		auto_timer.start(auto_delay)


func _toggle_auto() -> void:
	is_auto = not is_auto
	auto_button.text = "停止" if is_auto else "自动"
	quick_menu_overlay.visible = false
	if is_auto and not is_typing:
		auto_timer.start(auto_delay)
	else:
		auto_timer.stop()


func _on_auto_timeout() -> void:
	if (
		is_auto
		and not title_overlay.visible
		and not history_overlay.visible
		and not settings_overlay.visible
		and not quick_menu_overlay.visible
	):
		_advance_story()


func _show_quick_menu() -> void:
	auto_timer.stop()
	quick_menu_overlay.visible = true


func _close_quick_menu() -> void:
	quick_menu_overlay.visible = false
	if is_auto and not is_typing:
		auto_timer.start(auto_delay)


func _paginate_text(text: String, presentation: String) -> Array[String]:
	var page_limit := BUBBLE_PAGE_LIMIT
	if presentation == "caption":
		page_limit = CAPTION_PAGE_LIMIT
	elif presentation == "center":
		page_limit = CENTER_PAGE_LIMIT

	var pages: Array[String] = []
	var remaining := text.strip_edges()
	while remaining.length() > page_limit:
		var cut := page_limit
		var earliest_break := maxi(10, int(page_limit * 0.56))
		var found_break := false
		for index in range(page_limit - 1, earliest_break - 1, -1):
			if PAGE_BREAK_PUNCTUATION.contains(remaining.substr(index, 1)):
				cut = index + 1
				found_break = true
				break
		if not found_break:
			var forward_limit := mini(remaining.length(), page_limit + 6)
			for index in range(page_limit, forward_limit):
				if PAGE_BREAK_PUNCTUATION.contains(remaining.substr(index, 1)):
					cut = index + 1
					break
		pages.append(remaining.substr(0, cut).strip_edges())
		remaining = remaining.substr(cut).strip_edges()
	if not remaining.is_empty():
		pages.append(remaining)
	if pages.is_empty():
		pages.append("")
	return pages


func _format_screen_text(text: String) -> String:
	if text.length() <= 20:
		return text

	var target := ceili(text.length() / 2.0)
	var cut := target
	var nearest_distance := 99
	for index in range(7, text.length() - 1):
		if not PAGE_BREAK_PUNCTUATION.contains(text.substr(index, 1)):
			continue
		var distance := absi(index + 1 - target)
		if distance < nearest_distance:
			nearest_distance = distance
			cut = index + 1
	return "%s\n%s" % [
		text.substr(0, cut).strip_edges(),
		text.substr(cut).strip_edges(),
	]


func _format_bubble_text(text: String) -> String:
	if text.length() <= 16:
		return text

	var target := ceili(text.length() / 2.0)
	var cut := target
	var nearest_distance := 99
	for index in range(9, mini(text.length() - 1, 21)):
		if not PAGE_BREAK_PUNCTUATION.contains(text.substr(index, 1)):
			continue
		var distance := absi(index + 1 - target)
		if distance < nearest_distance:
			nearest_distance = distance
			cut = index + 1
	return "%s\n%s" % [
		text.substr(0, cut).strip_edges(),
		text.substr(cut).strip_edges(),
	]


func _position_bubble(speaker: String, text: String) -> void:
	var lines := text.split("\n")
	var line_count := lines.size()
	var longest_line_chars := 1
	for line in lines:
		longest_line_chars = maxi(longest_line_chars, line.length())
	var bubble_width := clampf(96.0 + longest_line_chars * 32.0, 430.0, 680.0)
	var bubble_height := 144.0 if line_count == 1 else 190.0
	var bubble_position := Vector2(600.0, 140.0)
	var tail_ratio := 0.5

	match speaker:
		"我", "我／旅途记录":
			bubble_position = Vector2(230.0, 145.0)
			tail_ratio = 0.34
		"三十一岁的我":
			bubble_position = Vector2(340.0, 130.0)
			tail_ratio = 0.42
		"Ousia", "少女 H":
			bubble_position = Vector2(940.0, 135.0)
			tail_ratio = 0.64
		"Poros":
			bubble_position = Vector2(150.0, 135.0)
			tail_ratio = 0.28
		"Ariadne":
			bubble_position = Vector2(430.0, 105.0)
			tail_ratio = 0.42
		"Pothos":
			bubble_position = Vector2(720.0, 135.0)
			tail_ratio = 0.5
		"Pharos":
			bubble_position = Vector2(1030.0, 130.0)
			tail_ratio = 0.68
		"Kairos":
			bubble_position = Vector2(940.0, 170.0)
			tail_ratio = 0.58
		"Nostos":
			bubble_position = Vector2(590.0, 100.0)
			tail_ratio = 0.48

	bubble_position.x = clampf(bubble_position.x, 80.0, 1840.0 - bubble_width)
	bubble_position.y = clampf(bubble_position.y, 70.0, 950.0 - bubble_height)
	dialogue_panel.position = bubble_position
	dialogue_panel.size = Vector2(bubble_width, bubble_height)
	dialogue_tail.position = Vector2(
		bubble_position.x + bubble_width * tail_ratio,
		bubble_position.y + bubble_height - 1.0,
	)


func _position_caption(presentation: String) -> void:
	center_line_label.offset_left = 0.0
	center_line_label.offset_top = 0.0
	center_line_label.offset_right = 0.0
	center_line_label.offset_bottom = 0.0
	if presentation == "center":
		center_line_label.anchor_left = 0.22
		center_line_label.anchor_top = 0.28
		center_line_label.anchor_right = 0.72
		center_line_label.anchor_bottom = 0.76
		center_line_label.add_theme_font_size_override("font_size", 44)
	else:
		center_line_label.anchor_left = 0.22
		center_line_label.anchor_top = 0.58
		center_line_label.anchor_right = 0.72
		center_line_label.anchor_bottom = 0.86
		center_line_label.add_theme_font_size_override("font_size", 38)


func _show_history() -> void:
	auto_timer.stop()
	quick_menu_overlay.visible = false
	history_text.text = "\n\n".join(history_entries)
	history_overlay.visible = true


func _show_settings() -> void:
	auto_timer.stop()
	quick_menu_overlay.visible = false
	text_speed_slider.value = text_speed
	auto_delay_slider.value = auto_delay
	volume_slider.value = master_volume
	fullscreen_toggle.button_pressed = (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	settings_overlay.visible = true


func _save_game() -> void:
	if story.units.is_empty():
		return
	var progress: Dictionary = story.get_progress()
	progress["settings"] = _settings_state()
	var error: Error = SaveServiceClass.write_save(progress)
	if error == OK:
		continue_button.disabled = false
		_show_toast("已保存")
	else:
		_show_toast("保存失败")


func _load_game() -> void:
	var state: Dictionary = SaveServiceClass.read_save()
	if state.is_empty():
		_show_toast("没有可读取的存档")
		return

	_apply_settings(state.get("settings", {}) as Dictionary)
	_rebuild_history(int(state.get("unit_index", 0)), int(state.get("line_index", 0)))
	title_overlay.visible = false
	ending_overlay.visible = false
	quick_menu_overlay.visible = false
	menu_button.visible = true
	story.start_at(
		int(state.get("unit_index", 0)),
		int(state.get("line_index", 0)),
	)
	_show_toast("已读取")


func _save_and_return_to_title() -> void:
	_save_game()
	_return_to_title()


func _return_to_title() -> void:
	auto_timer.stop()
	is_auto = false
	auto_button.text = "自动"
	history_overlay.visible = false
	settings_overlay.visible = false
	quick_menu_overlay.visible = false
	ending_overlay.visible = false
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = false
	menu_button.visible = false
	title_overlay.visible = true
	continue_button.disabled = not SaveServiceClass.has_save()


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
	history_text.text = "\n\n".join(history_entries)


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


func _show_toast(message: String) -> void:
	toast_label.text = message
	toast_label.visible = true
	if toast_timer != null:
		toast_timer.start()


func _get_active_label() -> Label:
	return center_line_label if is_screen_line else body_label


func _make_button(label_text: String, callback: Callable, min_width: float = 0.0) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(min_width, 38)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.82))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color("#202526")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#303637")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#16191a")))
	button.add_theme_stylebox_override("disabled", _button_style(Color("#171a1b")))
	button.pressed.connect(callback)
	return button


func _add_slider(
	parent: GridContainer,
	label_text: String,
	minimum: float,
	maximum: float,
	step_value: float,
	current: float,
	callback: Callable,
) -> HSlider:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 20)
	parent.add_child(label)

	var slider := HSlider.new()
	slider.custom_minimum_size.x = 260
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step_value
	slider.value = current
	slider.value_changed.connect(callback)
	parent.add_child(slider)
	return slider


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _button_style(color: Color) -> StyleBoxFlat:
	var style := _panel_style(color)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


func _rounded_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := _panel_style(color)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _set_full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
