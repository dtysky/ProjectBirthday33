class_name GameUI
extends RefCounted

const CHAPTER_COLORS := {
	1: Color("#1b2023"),
	2: Color("#172723"),
	3: Color("#251f25"),
	4: Color("#293025"),
	5: Color("#302c28"),
}

var host: Control
var callbacks: Dictionary

var stage: ColorRect
var master_texture: TextureRect
var chapter_fx_layer: Control
var debug_meta: MarginContainer
var unit_label: Label
var unit_title_label: Label
var shot_label: Label
var dialogue_tail: Polygon2D
var dialogue_panel: PanelContainer
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
var toast_timer: Timer


func build(
	parent: Control,
	ui_callbacks: Dictionary,
	initial_settings: Dictionary,
) -> void:
	host = parent
	callbacks = ui_callbacks
	_build_stage()
	_build_debug_meta()
	_build_dialogue()
	_build_center_line()
	_build_quick_menu()
	_build_title_screen()
	_build_history()
	_build_settings(initial_settings)
	_build_ending()
	_build_toast()


func show_unit(unit: Dictionary, unit_index: int, unit_count: int, texture: Texture2D) -> void:
	var chapter := int(unit.get("chapter", 1))
	stage.color = CHAPTER_COLORS.get(chapter, Color("#1b2023"))
	unit_label.text = "%s  ·  %d / %d" % [
		unit.get("id", ""),
		unit_index + 1,
		unit_count,
	]
	unit_title_label.text = str(unit.get("title", ""))
	shot_label.text = "%s  ·  %s" % [
		unit.get("shot", "NO SHOT"),
		unit.get("production", ""),
	]
	master_texture.texture = texture
	master_texture.visible = texture != null


func show_toast(message: String) -> void:
	toast_label.text = message
	toast_label.visible = true
	toast_timer.start()


func _build_stage() -> void:
	stage = ColorRect.new()
	stage.name = "Stage"
	stage.color = CHAPTER_COLORS[1]
	_set_full_rect(stage)
	host.add_child(stage)

	master_texture = TextureRect.new()
	master_texture.name = "MasterTexture"
	master_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	master_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	master_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(master_texture)
	host.add_child(master_texture)

	chapter_fx_layer = Control.new()
	chapter_fx_layer.name = "ChapterFxLayer"
	chapter_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(chapter_fx_layer)
	host.add_child(chapter_fx_layer)


func _build_debug_meta() -> void:
	debug_meta = MarginContainer.new()
	debug_meta.name = "DebugMeta"
	debug_meta.anchor_right = 1.0
	debug_meta.offset_left = 42.0
	debug_meta.offset_top = 32.0
	debug_meta.offset_right = -42.0
	debug_meta.offset_bottom = 150.0
	debug_meta.visible = false
	debug_meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(debug_meta)

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
	host.add_child(dialogue_tail)

	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	dialogue_panel.position = Vector2(650.0, 150.0)
	dialogue_panel.size = Vector2(520.0, 144.0)
	dialogue_panel.add_theme_stylebox_override(
		"panel",
		_rounded_style(Color(0.035, 0.035, 0.038, 0.82), 22),
	)
	host.add_child(dialogue_panel)

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
	center_line_label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.9),
	)
	center_line_label.add_theme_constant_override("shadow_offset_x", 2)
	center_line_label.add_theme_constant_override("shadow_offset_y", 3)
	center_line_label.add_theme_constant_override("shadow_outline_size", 5)
	center_line_label.visible = false
	center_line_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(center_line_label)


func _build_quick_menu() -> void:
	menu_button = _make_button("···", callbacks["show_quick_menu"])
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
	menu_button.add_theme_stylebox_override(
		"normal",
		_rounded_style(Color(0.02, 0.02, 0.02, 0.38), 20),
	)
	menu_button.add_theme_stylebox_override(
		"hover",
		_rounded_style(Color(0.02, 0.02, 0.02, 0.72), 20),
	)
	host.add_child(menu_button)

	quick_menu_overlay = ColorRect.new()
	quick_menu_overlay.name = "QuickMenuOverlay"
	quick_menu_overlay.color = Color(0.0, 0.0, 0.0, 0.64)
	quick_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	quick_menu_overlay.visible = false
	_set_full_rect(quick_menu_overlay)
	host.add_child(quick_menu_overlay)

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
	box.add_child(_make_button("历史", callbacks["show_history"]))
	auto_button = _make_button("自动", callbacks["toggle_auto"])
	box.add_child(auto_button)
	box.add_child(_make_button("保存", callbacks["save_game"]))
	box.add_child(_make_button("读取", callbacks["load_game"]))
	box.add_child(_make_button("设置", callbacks["show_settings"]))
	box.add_child(_make_button("返回标题", callbacks["save_and_return_to_title"]))

	var final_gap := Control.new()
	final_gap.custom_minimum_size.y = 8
	box.add_child(final_gap)
	box.add_child(_make_button("继续", callbacks["close_quick_menu"]))


func _build_title_screen() -> void:
	title_overlay = ColorRect.new()
	title_overlay.name = "TitleOverlay"
	title_overlay.color = Color("#0d1011")
	title_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_full_rect(title_overlay)
	host.add_child(title_overlay)

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

	box.add_child(_make_button("开始", callbacks["start_new_game"], 360))
	continue_button = _make_button("继续", callbacks["load_game"], 360)
	box.add_child(continue_button)
	box.add_child(_make_button("设置", callbacks["show_settings"], 360))
	box.add_child(_make_button("退出", callbacks["quit_game"], 360))


func _build_history() -> void:
	history_overlay = ColorRect.new()
	history_overlay.name = "HistoryOverlay"
	history_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	history_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	history_overlay.visible = false
	_set_full_rect(history_overlay)
	host.add_child(history_overlay)

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
	header.add_child(_make_button(
		"关闭",
		func() -> void: history_overlay.visible = false,
	))

	history_text = RichTextLabel.new()
	history_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_text.add_theme_font_size_override("normal_font_size", 22)
	history_text.add_theme_constant_override("line_separation", 9)
	history_text.scroll_following = true
	box.add_child(history_text)


func _build_settings(initial_settings: Dictionary) -> void:
	settings_overlay = ColorRect.new()
	settings_overlay.name = "SettingsOverlay"
	settings_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_overlay.visible = false
	_set_full_rect(settings_overlay)
	host.add_child(settings_overlay)

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
		grid,
		"文字速度",
		20.0,
		90.0,
		1.0,
		float(initial_settings.get("text_speed", 42.0)),
		callbacks["set_text_speed"],
	)
	auto_delay_slider = _add_slider(
		grid,
		"自动等待",
		1.0,
		8.0,
		0.1,
		float(initial_settings.get("auto_delay", 3.4)),
		callbacks["set_auto_delay"],
	)
	volume_slider = _add_slider(
		grid,
		"主音量",
		0.0,
		1.0,
		0.01,
		float(initial_settings.get("master_volume", 0.8)),
		callbacks["set_master_volume"],
	)

	var fullscreen_label := Label.new()
	fullscreen_label.text = "全屏"
	fullscreen_label.add_theme_font_size_override("font_size", 20)
	grid.add_child(fullscreen_label)
	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "启用"
	fullscreen_toggle.toggled.connect(callbacks["set_fullscreen"])
	grid.add_child(fullscreen_toggle)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	box.add_child(_make_button(
		"关闭",
		func() -> void: settings_overlay.visible = false,
	))


func _build_ending() -> void:
	ending_overlay = ColorRect.new()
	ending_overlay.name = "EndingOverlay"
	ending_overlay.color = Color("#0b0d0e")
	ending_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ending_overlay.visible = false
	_set_full_rect(ending_overlay)
	host.add_child(ending_overlay)

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
	box.add_child(_make_button("返回标题", callbacks["return_to_title"], 340))


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
	host.add_child(toast_label)

	toast_timer = Timer.new()
	toast_timer.one_shot = true
	toast_timer.wait_time = 2.0
	toast_timer.timeout.connect(func() -> void: toast_label.visible = false)
	host.add_child(toast_timer)


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
