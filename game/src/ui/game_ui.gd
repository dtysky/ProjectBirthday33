class_name GameUI
extends RefCounted

const CHAPTER_COLORS := {
	1: Color("#1b2023"),
	2: Color("#172723"),
	3: Color("#251f25"),
	4: Color("#293025"),
	5: Color("#302c28"),
}
const CJK_FONT := preload("res://assets/fonts/NotoSansSC-b33.otf")
const TITLE_WIND_PATH := "res://assets/audio/ambience/amb-title-sea-wind-v2.ogg"
const TITLE_VIDEO_PATH := "res://assets/ui/title/title-background-loop-v1.ogv"
const TITLE_SPARE_OVERLAY_PATH := "res://assets/ui/title/title-vehicle-spare-overlay-v1.png"

var host: Control
var callbacks: Dictionary

var stage: ColorRect
var master_texture: TextureRect
var asset_placeholder: CenterContainer
var asset_placeholder_label: Label
var chapter_fx_layer: Control
var debug_meta: MarginContainer
var unit_label: Label
var unit_title_label: Label
var shot_label: Label
var dialogue_tail: Polygon2D
var dialogue_panel: PanelContainer
var speaker_label: Label
var body_label: Label
var bubble_next_mark: Label
var center_line_label: Label
var chapter_interlude_overlay: Control
var chapter_interlude_backdrop: TextureRect
var chapter_interlude_wash: ColorRect
var chapter_interlude_vignette: ColorRect
var chapter_interlude_kicker: Label
var chapter_interlude_rule: ColorRect
var chapter_interlude_title: Label
var quick_menu_overlay: ColorRect
var auto_button: Button
var continue_button: Button
var title_overlay: ColorRect
var title_video_player: VideoStreamPlayer
var title_wind_player: AudioStreamPlayer
var title_wind_tween: Tween
var history_overlay: ColorRect
var history_text: RichTextLabel
var settings_overlay: ColorRect
var scene_select_overlay: ColorRect
var scene_list: ItemList
var scene_chapter_label: Label
var ending_overlay: ColorRect
var toast_label: Label
var text_speed_slider: HSlider
var auto_delay_slider: HSlider
var volume_slider: HSlider
var fullscreen_toggle: CheckButton
var toast_timer: Timer
var scene_units: Array = []
var scene_unit_indices: Array[int] = []
var selected_scene_chapter := 1
var current_production := ""


func build(
	parent: Control,
	ui_callbacks: Dictionary,
	initial_settings: Dictionary,
) -> void:
	host = parent
	callbacks = ui_callbacks
	# 随游戏内置当前完整台本所需的简体中文字形，避免系统字体回退差异造成缺字框。
	var cjk_theme := Theme.new()
	cjk_theme.default_font = CJK_FONT
	host.theme = cjk_theme
	_build_stage()
	_build_debug_meta()
	_build_dialogue()
	_build_center_line()
	_build_chapter_interlude()
	_build_quick_menu()
	_build_title_screen()
	_build_scene_selector()
	_build_history()
	_build_settings(initial_settings)
	_build_ending()
	_build_toast()


func show_unit(unit: Dictionary, unit_index: int, unit_count: int, texture: Texture2D) -> void:
	var chapter := int(unit.get("chapter", 1))
	stage.color = CHAPTER_COLORS.get(chapter, Color("#1b2023"))
	current_production = str(unit.get("production", ""))
	unit_label.text = "%s  ·  %d / %d" % [
		unit.get("id", ""),
		unit_index + 1,
		unit_count,
	]
	unit_title_label.text = str(unit.get("title", ""))
	show_line_shot(str(unit.get("shot", "NO SHOT")), texture)


func show_line_shot(shot_id: String, texture: Texture2D) -> void:
	shot_label.text = "%s  ·  %s" % [shot_id, current_production]
	master_texture.texture = texture
	master_texture.visible = texture != null
	asset_placeholder_label.text = "%s\n美术占位" % shot_id
	asset_placeholder.visible = texture == null


func show_toast(message: String) -> void:
	toast_label.text = message
	toast_label.visible = true
	toast_timer.start()


func show_title_screen() -> void:
	title_overlay.visible = true
	if (
		title_video_player != null
		and title_video_player.stream != null
		and not title_video_player.is_playing()
	):
		title_video_player.play()
	if title_wind_player == null or title_wind_player.stream == null:
		return
	_stop_title_wind_tween()
	title_wind_player.bus = "Ambience"
	if not title_wind_player.playing:
		title_wind_player.volume_db = -80.0
		title_wind_player.play()
	title_wind_tween = host.create_tween()
	title_wind_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	title_wind_tween.tween_property(title_wind_player, "volume_db", -7.5, 2.2)


func hide_title_screen(fade_seconds := 1.35) -> void:
	title_overlay.visible = false
	if title_video_player != null and title_video_player.is_playing():
		title_video_player.stop()
	if title_wind_player == null or not title_wind_player.playing:
		return
	_stop_title_wind_tween()
	title_wind_tween = host.create_tween()
	title_wind_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	title_wind_tween.tween_property(
		title_wind_player,
		"volume_db",
		-80.0,
		maxf(fade_seconds, 0.05),
	)
	title_wind_tween.tween_callback(title_wind_player.stop)


func _stop_title_wind_tween() -> void:
	if title_wind_tween != null and title_wind_tween.is_valid():
		title_wind_tween.kill()
	title_wind_tween = null


func set_scene_units(units: Array) -> void:
	scene_units = units
	_populate_scene_list(selected_scene_chapter)


func show_scene_selector(current_unit_index: int) -> void:
	if scene_units.is_empty():
		return
	var safe_index := clampi(current_unit_index, 0, scene_units.size() - 1)
	var unit := scene_units[safe_index] as Dictionary
	_populate_scene_list(int(unit.get("chapter", 1)))
	for item_index in range(scene_unit_indices.size()):
		if scene_unit_indices[item_index] == safe_index:
			scene_list.select(item_index)
			scene_list.ensure_current_is_visible()
			break
	scene_select_overlay.visible = true


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

	asset_placeholder = CenterContainer.new()
	asset_placeholder.name = "AssetPlaceholder"
	asset_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(asset_placeholder)
	host.add_child(asset_placeholder)

	asset_placeholder_label = Label.new()
	asset_placeholder_label.name = "PlaceholderLabel"
	asset_placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	asset_placeholder_label.add_theme_font_size_override("font_size", 42)
	asset_placeholder_label.add_theme_constant_override("line_spacing", 12)
	asset_placeholder_label.add_theme_color_override(
		"font_color",
		Color(0.86, 0.90, 0.88, 0.42),
	)
	asset_placeholder.add_child(asset_placeholder_label)
	asset_placeholder.visible = false

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
	dialogue_tail.color = Color(0.025, 0.028, 0.032, 0.90)
	dialogue_tail.polygon = PackedVector2Array([
		Vector2(-12.0, 0.0),
		Vector2(12.0, 0.0),
		Vector2(0.0, 34.0),
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
		_bubble_style(),
	)
	host.add_child(dialogue_panel)

	var margin := MarginContainer.new()
	margin.name = "DialogueMargin"
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 12)
	dialogue_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "DialogueBox"
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	speaker_label = Label.new()
	speaker_label.name = "SpeakerLabel"
	speaker_label.add_theme_font_size_override("font_size", 18)
	speaker_label.add_theme_color_override("font_color", Color("#a8c6b6"))
	speaker_label.visible = false
	box.add_child(speaker_label)

	body_label = Label.new()
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_label.add_theme_font_size_override("font_size", 30)
	body_label.add_theme_constant_override("line_spacing", 7)
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


func _build_chapter_interlude() -> void:
	chapter_interlude_overlay = Control.new()
	chapter_interlude_overlay.name = "ChapterInterludeOverlay"
	chapter_interlude_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chapter_interlude_overlay.clip_contents = true
	chapter_interlude_overlay.visible = false
	_set_full_rect(chapter_interlude_overlay)
	host.add_child(chapter_interlude_overlay)

	chapter_interlude_backdrop = TextureRect.new()
	chapter_interlude_backdrop.name = "Backdrop"
	chapter_interlude_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chapter_interlude_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	chapter_interlude_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chapter_interlude_backdrop.material = _chapter_backdrop_material()
	_set_full_rect(chapter_interlude_backdrop)
	chapter_interlude_overlay.add_child(chapter_interlude_backdrop)

	chapter_interlude_wash = ColorRect.new()
	chapter_interlude_wash.name = "AtmosphereWash"
	chapter_interlude_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(chapter_interlude_wash)
	chapter_interlude_overlay.add_child(chapter_interlude_wash)

	chapter_interlude_vignette = ColorRect.new()
	chapter_interlude_vignette.name = "OrganicVignette"
	chapter_interlude_vignette.color = Color.WHITE
	chapter_interlude_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chapter_interlude_vignette.material = _chapter_vignette_material()
	_set_full_rect(chapter_interlude_vignette)
	chapter_interlude_overlay.add_child(chapter_interlude_vignette)

	chapter_interlude_kicker = Label.new()
	chapter_interlude_kicker.name = "ChapterNumber"
	chapter_interlude_kicker.add_theme_font_size_override("font_size", 23)
	chapter_interlude_kicker.add_theme_constant_override("letter_spacing", 5)
	chapter_interlude_kicker.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.52),
	)
	chapter_interlude_kicker.add_theme_constant_override("shadow_offset_y", 2)
	chapter_interlude_kicker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chapter_interlude_overlay.add_child(chapter_interlude_kicker)

	chapter_interlude_rule = ColorRect.new()
	chapter_interlude_rule.name = "ChapterRule"
	chapter_interlude_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chapter_interlude_overlay.add_child(chapter_interlude_rule)

	chapter_interlude_title = Label.new()
	chapter_interlude_title.name = "ChapterTitle"
	chapter_interlude_title.add_theme_font_size_override("font_size", 74)
	chapter_interlude_title.add_theme_constant_override("letter_spacing", 7)
	chapter_interlude_title.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.62),
	)
	chapter_interlude_title.add_theme_constant_override("shadow_offset_x", 2)
	chapter_interlude_title.add_theme_constant_override("shadow_offset_y", 3)
	chapter_interlude_title.add_theme_constant_override("shadow_outline_size", 2)
	chapter_interlude_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chapter_interlude_overlay.add_child(chapter_interlude_title)


func configure_chapter_interlude(spec: Dictionary, texture: Texture2D) -> void:
	var title_rect: Rect2 = spec.get(
		"title_rect",
		Rect2(160.0, 300.0, 760.0, 260.0),
	) as Rect2
	var alignment := int(spec.get("alignment", HORIZONTAL_ALIGNMENT_LEFT))
	var title_color: Color = spec.get("title_color", Color("#e7e2d9")) as Color
	var accent_color: Color = spec.get("accent_color", title_color) as Color
	var wash_color: Color = spec.get(
		"wash_color",
		Color(0.035, 0.045, 0.055, 0.34),
	) as Color

	chapter_interlude_backdrop.texture = texture
	chapter_interlude_backdrop.visible = texture != null
	chapter_interlude_backdrop.pivot_offset = Vector2(960.0, 540.0)
	chapter_interlude_backdrop.scale = Vector2.ONE
	chapter_interlude_backdrop.modulate = Color.WHITE
	var backdrop_material := chapter_interlude_backdrop.material as ShaderMaterial
	backdrop_material.set_shader_parameter(
		"desaturation",
		float(spec.get("desaturation", 0.26)),
	)
	backdrop_material.set_shader_parameter(
		"grade",
		spec.get("grade", Color(0.03, 0.045, 0.06, 0.10)),
	)

	chapter_interlude_wash.color = wash_color
	chapter_interlude_wash.modulate.a = 0.0
	var vignette_material := chapter_interlude_vignette.material as ShaderMaterial
	vignette_material.set_shader_parameter(
		"veil_color",
		spec.get("veil_color", Color(0.02, 0.025, 0.03, 1.0)),
	)
	vignette_material.set_shader_parameter(
		"strength",
		float(spec.get("veil_strength", 0.58)),
	)
	vignette_material.set_shader_parameter(
		"focus",
		spec.get("focus", Vector2(0.5, 0.46)),
	)
	chapter_interlude_vignette.modulate.a = 0.0

	chapter_interlude_kicker.text = str(spec.get("number", ""))
	chapter_interlude_kicker.position = title_rect.position
	chapter_interlude_kicker.size = Vector2(title_rect.size.x, 40.0)
	chapter_interlude_kicker.horizontal_alignment = alignment
	chapter_interlude_kicker.add_theme_color_override("font_color", accent_color)
	chapter_interlude_kicker.modulate.a = 0.0

	var rule_width := float(spec.get("rule_width", 104.0))
	var rule_x := title_rect.position.x
	if alignment == HORIZONTAL_ALIGNMENT_CENTER:
		rule_x += (title_rect.size.x - rule_width) * 0.5
	elif alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		rule_x += title_rect.size.x - rule_width
	chapter_interlude_rule.position = Vector2(rule_x, title_rect.position.y + 49.0)
	chapter_interlude_rule.size = Vector2(rule_width, 2.0)
	var rule_pivot_x := 0.0
	if alignment == HORIZONTAL_ALIGNMENT_CENTER:
		rule_pivot_x = rule_width * 0.5
	elif alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		rule_pivot_x = rule_width
	chapter_interlude_rule.pivot_offset = Vector2(
		rule_pivot_x,
		1.0,
	)
	chapter_interlude_rule.color = accent_color
	chapter_interlude_rule.scale = Vector2(0.0, 1.0)
	chapter_interlude_rule.modulate.a = 0.0

	chapter_interlude_title.text = str(spec.get("title", ""))
	chapter_interlude_title.position = title_rect.position + Vector2(0.0, 74.0)
	chapter_interlude_title.size = Vector2(title_rect.size.x, title_rect.size.y - 74.0)
	chapter_interlude_title.horizontal_alignment = alignment
	chapter_interlude_title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	chapter_interlude_title.add_theme_font_size_override(
		"font_size",
		int(spec.get("title_size", 74)),
	)
	chapter_interlude_title.add_theme_color_override("font_color", title_color)
	chapter_interlude_title.rotation_degrees = float(spec.get("title_rotation", 0.0))
	chapter_interlude_title.modulate.a = 0.0

	chapter_interlude_overlay.modulate = Color.WHITE
	chapter_interlude_overlay.visible = true


func hide_chapter_interlude() -> void:
	chapter_interlude_overlay.visible = false
	chapter_interlude_overlay.modulate = Color.WHITE
	chapter_interlude_backdrop.scale = Vector2.ONE
	chapter_interlude_kicker.modulate.a = 0.0
	chapter_interlude_title.modulate.a = 0.0
	chapter_interlude_rule.modulate.a = 0.0


func _chapter_backdrop_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float desaturation : hint_range(0.0, 1.0) = 0.26;
uniform vec4 grade : source_color = vec4(0.03, 0.045, 0.06, 0.10);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	source.rgb = mix(source.rgb, vec3(luminance), desaturation);
	source.rgb = mix(source.rgb, grade.rgb, grade.a);
	COLOR = source;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _chapter_vignette_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 veil_color : source_color = vec4(0.02, 0.025, 0.03, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.58;
uniform vec2 focus = vec2(0.5, 0.46);

void fragment() {
	vec2 distance_from_focus = (UV - focus) * vec2(1.0, 1.18);
	float edge = smoothstep(0.18, 0.82, length(distance_from_focus));
	float lower_weight = smoothstep(0.18, 1.0, UV.y) * 0.12;
	float veil = clamp(0.22 + edge * 0.66 + lower_weight, 0.0, 1.0);
	COLOR = vec4(veil_color.rgb, veil_color.a * strength * veil);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _build_quick_menu() -> void:
	quick_menu_overlay = ColorRect.new()
	quick_menu_overlay.name = "QuickMenuOverlay"
	quick_menu_overlay.color = Color(0.0, 0.0, 0.0, 0.64)
	quick_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	quick_menu_overlay.visible = false
	_set_full_rect(quick_menu_overlay)
	host.add_child(quick_menu_overlay)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.40
	panel.anchor_top = 0.18
	panel.anchor_right = 0.60
	panel.anchor_bottom = 0.82
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
	auto_button = _make_button("自动播放", callbacks["toggle_auto"])
	box.add_child(auto_button)
	box.add_child(_make_button("保存", callbacks["save_game"]))
	box.add_child(_make_button("读取", callbacks["load_game"]))
	box.add_child(_make_button("设置", callbacks["show_settings"]))
	box.add_child(_make_button("场景选择", callbacks["show_scene_select"]))
	box.add_child(_make_button("返回标题", callbacks["save_and_return_to_title"]))

	var final_gap := Control.new()
	final_gap.custom_minimum_size.y = 8
	box.add_child(final_gap)
	box.add_child(_make_button("继续", callbacks["close_quick_menu"]))


func _build_title_screen() -> void:
	title_overlay = ColorRect.new()
	title_overlay.name = "TitleOverlay"
	title_overlay.color = Color("#080b10")
	title_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_full_rect(title_overlay)
	host.add_child(title_overlay)

	var backdrop := TextureRect.new()
	backdrop.name = "TitleBackdrop"
	backdrop.texture = load("res://assets/ui/title/title-background-v5.webp")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(backdrop)
	title_overlay.add_child(backdrop)

	title_video_player = VideoStreamPlayer.new()
	title_video_player.name = "TitleBackdropVideo"
	title_video_player.stream = load(TITLE_VIDEO_PATH) as VideoStream
	title_video_player.autoplay = true
	title_video_player.loop = true
	title_video_player.expand = true
	title_video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(title_video_player)
	title_overlay.add_child(title_video_player)

	var spare_overlay := TextureRect.new()
	spare_overlay.name = "TitleVehicleSpareOverlay"
	spare_overlay.texture = load(TITLE_SPARE_OVERLAY_PATH)
	spare_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spare_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	spare_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(spare_overlay)
	title_overlay.add_child(spare_overlay)

	var box := VBoxContainer.new()
	box.name = "TitleContent"
	box.anchor_left = 0.075
	box.anchor_top = 0.095
	box.anchor_right = 0.49
	box.anchor_bottom = 0.92
	box.add_theme_constant_override("separation", 10)
	title_overlay.add_child(box)

	var kicker := Label.new()
	kicker.name = "TitleKicker"
	kicker.text = "PROJECT BIRTHDAY 33  /  2026"
	kicker.add_theme_font_size_override("font_size", 16)
	kicker.add_theme_constant_override("letter_spacing", 3)
	kicker.add_theme_color_override("font_color", Color(0.74, 0.80, 0.80, 0.72))
	box.add_child(kicker)

	var title := Label.new()
	title.name = "TitleName"
	title.text = "三十三岁的勇气，\n是坦然的失去"
	title.custom_minimum_size.y = 160.0
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_constant_override("line_spacing", 12)
	title.add_theme_color_override("font_color", Color(0.96, 0.95, 0.90, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 5)
	box.add_child(title)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0.0, 1.0)
	rule.color = Color(0.82, 0.65, 0.43, 0.64)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rule)

	var gap := Control.new()
	gap.custom_minimum_size.y = 48
	box.add_child(gap)

	var start_button := _make_title_button("开始", callbacks["start_new_game"])
	box.add_child(start_button)
	continue_button = _make_title_button("继续", callbacks["load_game"])
	box.add_child(continue_button)
	box.add_child(_make_title_button("场景选择", callbacks["show_scene_select"]))
	box.add_child(_make_title_button("设置", callbacks["show_settings"]))
	box.add_child(_make_title_button("退出", callbacks["quit_game"]))

	var flexible_gap := Control.new()
	flexible_gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(flexible_gap)

	var footer := Label.new()
	footer.text = "ENTER  确认    ·    ESC  返回"
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_constant_override("letter_spacing", 2)
	footer.add_theme_color_override("font_color", Color(0.68, 0.72, 0.72, 0.38))
	box.add_child(footer)

	title_wind_player = AudioStreamPlayer.new()
	title_wind_player.name = "TitleSeaWind"
	title_wind_player.volume_db = -80.0
	var title_wind_stream := ResourceLoader.load(TITLE_WIND_PATH) as AudioStream
	if title_wind_stream is AudioStreamOggVorbis:
		(title_wind_stream as AudioStreamOggVorbis).loop = true
	title_wind_player.stream = title_wind_stream
	host.add_child(title_wind_player)
	start_button.call_deferred("grab_focus")


func _build_scene_selector() -> void:
	scene_select_overlay = ColorRect.new()
	scene_select_overlay.name = "SceneSelectOverlay"
	scene_select_overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	scene_select_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	scene_select_overlay.visible = false
	_set_full_rect(scene_select_overlay)
	host.add_child(scene_select_overlay)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.19
	panel.anchor_top = 0.10
	panel.anchor_right = 0.81
	panel.anchor_bottom = 0.90
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#15191a")))
	scene_select_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "章节与场景"
	title.add_theme_font_size_override("font_size", 30)
	header.add_child(title)
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	header.add_child(_make_button(
		"关闭",
		func() -> void: scene_select_overlay.visible = false,
	))

	var chapter_row := HBoxContainer.new()
	chapter_row.add_theme_constant_override("separation", 10)
	box.add_child(chapter_row)
	for chapter in range(1, 6):
		chapter_row.add_child(_make_button(
			"G%d" % chapter,
			_populate_scene_list.bind(chapter),
			104,
		))
	var chapter_spacer := Control.new()
	chapter_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapter_row.add_child(chapter_spacer)
	scene_chapter_label = Label.new()
	scene_chapter_label.add_theme_font_size_override("font_size", 18)
	scene_chapter_label.modulate = Color(1.0, 1.0, 1.0, 0.56)
	chapter_row.add_child(scene_chapter_label)

	scene_list = ItemList.new()
	scene_list.name = "SceneList"
	scene_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene_list.add_theme_font_size_override("font_size", 22)
	scene_list.add_theme_constant_override("v_separation", 9)
	scene_list.item_activated.connect(_activate_scene_item)
	box.add_child(scene_list)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)
	var hint := Label.new()
	hint.text = "双击场景，或选中后进入"
	hint.modulate = Color(1.0, 1.0, 1.0, 0.48)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(hint)
	footer.add_child(_make_button("进入场景", _activate_selected_scene, 180))


func _populate_scene_list(chapter: int) -> void:
	selected_scene_chapter = chapter
	if scene_list == null:
		return
	scene_chapter_label.text = "第 %d 章" % chapter
	scene_list.clear()
	scene_unit_indices.clear()
	for unit_index in range(scene_units.size()):
		var unit := scene_units[unit_index] as Dictionary
		if int(unit.get("chapter", 1)) != chapter:
			continue
		scene_unit_indices.append(unit_index)
		var item_index := scene_list.add_item("%s    %s" % [
			unit.get("id", ""),
			unit.get("title", ""),
		])
		scene_list.set_item_tooltip(
			item_index,
			str(unit.get("production", "")),
		)
	if scene_list.item_count > 0:
		scene_list.select(0)


func _activate_selected_scene() -> void:
	var selected := scene_list.get_selected_items()
	if selected.is_empty():
		return
	_activate_scene_item(int(selected[0]))


func _activate_scene_item(item_index: int) -> void:
	if item_index < 0 or item_index >= scene_unit_indices.size():
		return
	callbacks["jump_to_scene"].call(scene_unit_indices[item_index])


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


func _make_title_button(label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(420.0, 46.0)
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_constant_override("outline_size", 0)
	button.add_theme_color_override("font_color", Color(0.84, 0.86, 0.84, 0.68))
	button.add_theme_color_override("font_hover_color", Color(0.98, 0.95, 0.87, 1.0))
	button.add_theme_color_override("font_focus_color", Color(0.98, 0.95, 0.87, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.92, 0.73, 0.50, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.62, 0.65, 0.64, 0.28))
	button.add_theme_stylebox_override(
		"normal",
		_title_button_style(Color(0.03, 0.04, 0.05, 0.0), Color(0.58, 0.63, 0.62, 0.20), 2),
	)
	button.add_theme_stylebox_override(
		"hover",
		_title_button_style(Color(0.66, 0.49, 0.31, 0.08), Color(0.85, 0.66, 0.43, 0.90), 4),
	)
	button.add_theme_stylebox_override(
		"focus",
		_title_button_style(Color(0.66, 0.49, 0.31, 0.08), Color(0.85, 0.66, 0.43, 0.90), 4),
	)
	button.add_theme_stylebox_override(
		"pressed",
		_title_button_style(Color(0.66, 0.49, 0.31, 0.14), Color(0.91, 0.72, 0.48, 1.0), 4),
	)
	button.add_theme_stylebox_override(
		"disabled",
		_title_button_style(Color(0.03, 0.04, 0.05, 0.0), Color(0.50, 0.54, 0.53, 0.10), 2),
	)
	button.pressed.connect(callback)
	return button


func _title_button_style(
	background: Color,
	accent: Color,
	accent_width: int,
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = accent
	style.border_width_left = accent_width
	style.content_margin_left = 18.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


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


func _bubble_style() -> StyleBoxFlat:
	var style := _rounded_style(Color(0.025, 0.028, 0.032, 0.90), 0)
	style.border_color = Color(0.82, 0.86, 0.88, 0.30)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 5
	return style


func _set_full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
