extends ChapterDirector

const DEFAULT_CAPTION_RECT := Rect2(70.0, 70.0, 820.0, 220.0)
const FINAL_LINE_ID := "G5-05-04"
const FINAL_HOLD_SECONDS := 6.5
const FINAL_MANUAL_MINIMUM_MSEC := 2500

const AUTO_WAIT_MULTIPLIERS := {
	"G5-01": 1.50,
	"G5-02": 1.75,
	"G5-03": 1.70,
	"G5-04": 1.50,
	"G5-05": 1.60,
}

const SHOT_17_PHASES := {
	"G5-01-01": "fog",
	"G5-01-02": "fog",
	"G5-01-03": "fog",
	"G5-01-04": "fog",
	"G5-01-05": "wide",
	"G5-01-06": "wide",
	"G5-01-07": "wide",
	"G5-01-08": "wide",
	"G5-01-09": "sunrise_back",
	"G5-01-10": "sunrise_back",
	"G5-01-11": "sunrise_back",
	"G5-01-12": "sunrise_back",
	"G5-01-13": "sunrise_back",
}

const SHOT_70_PHASES := {
	"G5-02-03": "wide",
	"G5-02-04": "glass",
	"G5-02-05": "glass",
}

const CAPTION_RECTS := {
	"G5-01-01": Rect2(70.0, 70.0, 790.0, 220.0),
	"G5-01-02": Rect2(70.0, 70.0, 790.0, 220.0),
	"G5-01-03": Rect2(70.0, 70.0, 790.0, 220.0),
	"G5-01-04": Rect2(70.0, 70.0, 790.0, 220.0),
	"G5-01-05": Rect2(70.0, 760.0, 830.0, 220.0),
	"G5-01-06": Rect2(70.0, 760.0, 830.0, 220.0),
	"G5-01-07": Rect2(70.0, 760.0, 830.0, 220.0),
	"G5-01-08": Rect2(70.0, 760.0, 830.0, 220.0),
	"G5-01-09": Rect2(70.0, 60.0, 840.0, 220.0),
	"G5-01-10": Rect2(70.0, 60.0, 920.0, 250.0),
	"G5-01-11": Rect2(70.0, 60.0, 840.0, 220.0),
	"G5-01-12": Rect2(70.0, 60.0, 840.0, 220.0),
	"G5-01-13": Rect2(70.0, 60.0, 840.0, 220.0),
	"G5-02-01": Rect2(150.0, 790.0, 1620.0, 220.0),
	"G5-02-02": Rect2(150.0, 790.0, 1620.0, 220.0),
	"G5-02-03": Rect2(70.0, 70.0, 790.0, 220.0),
	"G5-02-04": Rect2(1060.0, 70.0, 790.0, 220.0),
	"G5-02-05": Rect2(1060.0, 70.0, 790.0, 220.0),
	"G5-03-01": Rect2(70.0, 70.0, 850.0, 220.0),
	"G5-03-02": Rect2(70.0, 790.0, 760.0, 220.0),
	"G5-03-03": Rect2(70.0, 70.0, 850.0, 220.0),
	"G5-03-04": Rect2(70.0, 790.0, 860.0, 220.0),
	"G5-03-05": Rect2(70.0, 70.0, 820.0, 220.0),
	"G5-03-06": Rect2(70.0, 70.0, 820.0, 220.0),
	"G5-03-07": Rect2(70.0, 70.0, 820.0, 220.0),
	"G5-03-08": Rect2(70.0, 70.0, 820.0, 220.0),
	"G5-04-01": Rect2(70.0, 70.0, 820.0, 220.0),
	"G5-04-02": Rect2(70.0, 70.0, 820.0, 220.0),
	"G5-04-03": Rect2(650.0, 70.0, 780.0, 220.0),
	"G5-04-04": Rect2(650.0, 70.0, 780.0, 220.0),
	"G5-04-05": Rect2(650.0, 70.0, 780.0, 220.0),
	"G5-04-06": Rect2(650.0, 70.0, 780.0, 220.0),
	"G5-05-01": Rect2(650.0, 70.0, 800.0, 220.0),
	"G5-05-02": Rect2(650.0, 70.0, 800.0, 220.0),
}

const PLACEHOLDER_COPY := {}

var host: Control
var fx_layer: Control
var master_texture: TextureRect
var center_line_label: Label
var dialogue_panel: PanelContainer
var dialogue_tail: Polygon2D
var story: RefCounted
var asset_registry: RefCounted
var ui
var auto_timer: Timer
var music_director: Node

var transition_texture: TextureRect
var transition_overlay: ColorRect
var ambient_overlay: ColorRect
var projection_card: PanelContainer
var projection_label: Label

var texture_tween: Tween
var transition_tween: Tween
var ambient_tween: Tween
var camera_tween: Tween
var projection_tween: Tween

var current_unit_id := ""
var current_line_id := ""
var current_shot_id := ""
var current_variant_id := ""
var displayed_texture: Texture2D
var final_hold_active := false
var final_hold_started_at_msec := 0


func _init() -> void:
	chapter_number = 5


func setup(director_context: Dictionary) -> void:
	super.setup(director_context)
	host = context.get("host") as Control
	fx_layer = context.get("fx_layer") as Control
	master_texture = context.get("master_texture") as TextureRect
	center_line_label = context.get("center_line_label") as Label
	dialogue_panel = context.get("dialogue_panel") as PanelContainer
	dialogue_tail = context.get("dialogue_tail") as Polygon2D
	story = context.get("story") as RefCounted
	asset_registry = context.get("asset_registry") as RefCounted
	ui = context.get("ui")
	auto_timer = context.get("auto_timer") as Timer
	music_director = context.get("music_director") as Node
	_build_chapter_effects()


func on_unit_changed(unit: Dictionary) -> void:
	var previous_shot_id := current_shot_id
	current_unit_id = str(unit.get("id", ""))
	current_line_id = ""
	final_hold_active = false
	final_hold_started_at_msec = 0

	if current_unit_id == "G5-01":
		_show_variant("SHOT-17", "fog", previous_shot_id, true)
		return

	current_shot_id = str(unit.get("shot", ""))
	if (
		current_unit_id == "G5-05"
		and previous_shot_id == "SHOT-74"
		and displayed_texture != null
	):
		current_variant_id = "lantern"
		ui.call("show_line_shot", "SHOT-74", displayed_texture)
		_set_projection_state(false)
		_apply_ambient(_ambient_for_shot("SHOT-74"))
		_start_camera_motion(displayed_texture)
		return

	_show_shot(current_shot_id, previous_shot_id, true)


func on_line_changed(line: Dictionary, unit: Dictionary) -> bool:
	current_line_id = str(line.get("id", ""))
	var next_shot_id := str(line.get("shot", unit.get("shot", "")))
	if next_shot_id.is_empty():
		return false

	if SHOT_17_PHASES.has(current_line_id):
		var next_variant_id := str(SHOT_17_PHASES[current_line_id])
		if current_shot_id != "SHOT-17" or current_variant_id != next_variant_id:
			_show_variant("SHOT-17", next_variant_id, current_shot_id, false)
		else:
			_apply_line_state()
		return false

	if SHOT_70_PHASES.has(current_line_id):
		var ruin_variant_id := str(SHOT_70_PHASES[current_line_id])
		if current_shot_id != "SHOT-70" or current_variant_id != ruin_variant_id:
			_show_variant("SHOT-70", ruin_variant_id, current_shot_id, false)
		else:
			_apply_line_state()
		return false

	if current_unit_id == "G5-05":
		var ending_variant_id := (
			"empty" if ["G5-05-03", "G5-05-04"].has(current_line_id) else "lantern"
		)
		if current_shot_id != "SHOT-74" or current_variant_id != ending_variant_id:
			_show_variant("SHOT-74", ending_variant_id, current_shot_id, false)
		else:
			_apply_line_state()
		return false

	if next_shot_id != current_shot_id:
		var previous_shot_id := current_shot_id
		_show_shot(next_shot_id, previous_shot_id, false)
	else:
		_apply_line_state()
	return false


func advance() -> bool:
	if final_hold_active:
		var elapsed := Time.get_ticks_msec() - final_hold_started_at_msec
		if elapsed < FINAL_MANUAL_MINIMUM_MSEC:
			return true
		_finish_final_hold()
		return true
	if _can_start_final_hold():
		_start_final_hold()
		return true
	return false


func on_auto_timeout() -> bool:
	if final_hold_active:
		_finish_final_hold()
		return true
	if _can_start_final_hold():
		_start_final_hold()
		return true
	return false


func position_caption(label: Label, presentation: String) -> bool:
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 0.0
	label.anchor_bottom = 0.0
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.96),
	)
	label.add_theme_constant_override("shadow_outline_size", 7)

	if presentation == "center":
		var center_rect := Rect2(300.0, 270.0, 1320.0, 540.0)
		label.offset_left = center_rect.position.x
		label.offset_top = center_rect.position.y
		label.offset_right = center_rect.end.x
		label.offset_bottom = center_rect.end.y
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override(
			"font_size",
			54 if current_line_id == FINAL_LINE_ID else 50,
		)
		label.add_theme_constant_override("line_spacing", 18)
		return true

	var rect: Rect2 = CAPTION_RECTS.get(current_line_id, DEFAULT_CAPTION_RECT)
	label.offset_left = rect.position.x
	label.offset_top = rect.position.y
	label.offset_right = rect.end.x
	label.offset_bottom = rect.end.y
	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
		if current_shot_id == "SHOT-18"
		else HORIZONTAL_ALIGNMENT_LEFT
	)
	label.add_theme_font_size_override("font_size", 35)
	label.add_theme_constant_override("line_spacing", 13)
	return true


func uses_speaker_label() -> bool:
	return false


func auto_wait_multiplier(line: Dictionary, unit: Dictionary) -> float:
	if str(line.get("id", "")) == FINAL_LINE_ID:
		return 1.85
	return float(AUTO_WAIT_MULTIPLIERS.get(str(unit.get("id", "")), 1.0))


func resume() -> bool:
	if final_hold_active and bool(host.get("is_auto")):
		auto_timer.start(FINAL_HOLD_SECONDS)
		return true
	return false


func leave() -> void:
	_kill_tweens()
	transition_texture.visible = false
	transition_texture.texture = null
	transition_overlay.visible = false
	ambient_overlay.visible = false
	projection_card.visible = false
	master_texture.scale = Vector2.ONE
	master_texture.pivot_offset = Vector2.ZERO
	var placeholder_label := ui.get("asset_placeholder_label") as Label
	placeholder_label.add_theme_color_override(
		"font_color",
		Color(0.86, 0.90, 0.88, 0.42),
	)
	current_unit_id = ""
	current_line_id = ""
	current_shot_id = ""
	current_variant_id = ""
	displayed_texture = null
	final_hold_active = false
	final_hold_started_at_msec = 0


func _build_chapter_effects() -> void:
	transition_texture = TextureRect.new()
	transition_texture.name = "G5TransitionTexture"
	transition_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	transition_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	transition_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_texture.visible = false
	_set_full_rect(transition_texture)
	fx_layer.add_child(transition_texture)

	ambient_overlay = ColorRect.new()
	ambient_overlay.name = "G5AmbientOverlay"
	ambient_overlay.color = Color.TRANSPARENT
	ambient_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ambient_overlay.visible = false
	_set_full_rect(ambient_overlay)
	fx_layer.add_child(ambient_overlay)

	projection_card = PanelContainer.new()
	projection_card.name = "G5LinksPlaceholder"
	projection_card.position = Vector2(410.0, 180.0)
	projection_card.size = Vector2(1100.0, 560.0)
	projection_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projection_card.visible = false
	var projection_style := StyleBoxFlat.new()
	projection_style.bg_color = Color(0.025, 0.045, 0.065, 0.94)
	projection_style.border_color = Color(0.54, 0.72, 0.78, 0.46)
	projection_style.set_border_width_all(3)
	projection_style.shadow_color = Color(0.16, 0.38, 0.48, 0.28)
	projection_style.shadow_size = 28
	projection_card.add_theme_stylebox_override("panel", projection_style)
	fx_layer.add_child(projection_card)

	projection_label = Label.new()
	projection_label.text = (
		"LINKS / NORDIC PHOTOGRAPHY\n\n"
		+ "画中视频语义占位\n"
		+ "链接或原片到位后，仅替换这一块屏幕内容"
	)
	projection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	projection_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	projection_label.add_theme_font_size_override("font_size", 32)
	projection_label.add_theme_constant_override("line_spacing", 14)
	projection_label.add_theme_color_override("font_color", Color(0.80, 0.90, 0.92, 0.88))
	projection_card.add_child(projection_label)

	transition_overlay = ColorRect.new()
	transition_overlay.name = "G5TransitionOverlay"
	transition_overlay.color = Color.BLACK
	transition_overlay.modulate.a = 0.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.visible = false
	_set_full_rect(transition_overlay)
	fx_layer.add_child(transition_overlay)


func _show_shot(shot_id: String, previous_shot_id: String, unit_entry: bool) -> void:
	current_shot_id = shot_id
	current_variant_id = "lantern" if shot_id == "SHOT-74" else ""
	var texture: Texture2D = asset_registry.call("load_master", shot_id) as Texture2D
	var hard_cut := false
	var duration := _transition_duration(previous_shot_id, shot_id)
	_present_texture(shot_id, texture, duration, hard_cut, unit_entry)


func _show_variant(
	shot_id: String,
	variant_id: String,
	_previous_shot_id: String,
	unit_entry: bool,
) -> void:
	current_shot_id = shot_id
	var previous_variant_id := current_variant_id
	current_variant_id = variant_id
	var texture: Texture2D = asset_registry.call(
		"load_variant",
		shot_id,
		variant_id,
	) as Texture2D
	if texture == null:
		texture = asset_registry.call("load_master", shot_id) as Texture2D
	var duration := 0.86
	if shot_id == "SHOT-74" and variant_id == "empty":
		duration = 1.8
	elif shot_id == "SHOT-74" and previous_variant_id == "empty":
		duration = 0.8
	_present_texture(shot_id, texture, duration, false, unit_entry)


func _present_texture(
	shot_id: String,
	texture: Texture2D,
	duration: float,
	hard_cut: bool,
	unit_entry: bool,
) -> void:
	var previous_texture := displayed_texture
	ui.call("show_line_shot", shot_id, texture)
	_set_placeholder_copy(shot_id)
	_set_projection_state(shot_id == "SHOT-18" and texture == null)
	_apply_ambient(_ambient_for_shot(shot_id))
	_start_camera_motion(texture)

	if hard_cut:
		_stop_transition_texture()
		_flash_from_black(0.18, 0.18)
	elif previous_texture != null and previous_texture != texture:
		_crossfade_from(previous_texture, duration)
	elif previous_texture == null and texture != null:
		_flash_from_black(0.82 if unit_entry else 0.46, 0.68 if unit_entry else 0.36)

	displayed_texture = texture


func _set_placeholder_copy(shot_id: String) -> void:
	var placeholder_label := ui.get("asset_placeholder_label") as Label
	placeholder_label.text = str(PLACEHOLDER_COPY.get(shot_id, "%s\n美术占位" % shot_id))
	placeholder_label.add_theme_color_override(
		"font_color",
		Color(0.82, 0.90, 0.91, 0.78),
	)


func _set_projection_state(visible: bool) -> void:
	projection_card.visible = visible
	if visible:
		var placeholder := ui.get("asset_placeholder") as CenterContainer
		placeholder.visible = false
		_start_projection_pulse()
	else:
		if projection_tween != null and projection_tween.is_valid():
			projection_tween.kill()
		projection_card.modulate.a = 1.0


func _start_projection_pulse() -> void:
	if projection_tween != null and projection_tween.is_valid():
		projection_tween.kill()
	projection_card.modulate.a = 0.88
	projection_tween = host.create_tween().set_loops()
	projection_tween.tween_property(
		projection_card,
		"modulate:a",
		1.0,
		1.8,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	projection_tween.tween_property(
		projection_card,
		"modulate:a",
		0.88,
		1.8,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _apply_line_state() -> void:
	if current_line_id == "G5-02-03":
		_apply_ambient(Color(0.04, 0.07, 0.04, 0.035))
	elif current_shot_id == "SHOT-74":
		_apply_ambient(Color(0.02, 0.07, 0.13, 0.035))


func _ambient_for_shot(shot_id: String) -> Color:
	match shot_id:
		"SHOT-18":
			return Color(0.01, 0.035, 0.06, 0.035)
		"SHOT-70":
			return Color(0.03, 0.06, 0.035, 0.025)
		"SHOT-71":
			return Color(0.015, 0.04, 0.08, 0.035)
		"SHOT-72":
			return Color(0.06, 0.055, 0.045, 0.02)
		"SHOT-75":
			return Color(0.035, 0.045, 0.055, 0.025)
		"SHOT-76":
			return Color(0.025, 0.055, 0.035, 0.04)
		"SHOT-73":
			return Color(0.10, 0.14, 0.17, 0.025)
		"SHOT-74":
			return Color(0.02, 0.07, 0.13, 0.035)
	return Color.TRANSPARENT


func _apply_ambient(color: Color) -> void:
	if ambient_tween != null and ambient_tween.is_valid():
		ambient_tween.kill()
	ambient_overlay.visible = color.a > 0.001
	if not ambient_overlay.visible:
		ambient_overlay.color = Color.TRANSPARENT
		return
	var target_alpha := color.a
	color.a = 1.0
	ambient_overlay.color = color
	ambient_overlay.modulate.a = 0.0
	ambient_tween = host.create_tween()
	ambient_tween.tween_property(
		ambient_overlay,
		"modulate:a",
		target_alpha,
		0.55,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _start_camera_motion(texture: Texture2D) -> void:
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	master_texture.scale = Vector2.ONE
	master_texture.pivot_offset = _camera_pivot()
	if texture == null or current_unit_id == "G5-05":
		return
	var target_scale := 1.014
	if current_shot_id == "SHOT-70" and current_variant_id == "glass":
		target_scale = 1.010
	elif current_shot_id == "SHOT-70" or current_shot_id == "SHOT-73":
		target_scale = 1.018
	elif current_shot_id == "SHOT-75" or current_shot_id == "SHOT-76":
		target_scale = 1.012
	elif current_shot_id == "SHOT-74":
		target_scale = 1.010
	camera_tween = host.create_tween()
	camera_tween.tween_property(
		master_texture,
		"scale",
		Vector2(target_scale, target_scale),
		11.5,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _camera_pivot() -> Vector2:
	match current_shot_id:
		"SHOT-70":
			return Vector2(900.0, 520.0) if current_variant_id == "glass" else Vector2(1010.0, 520.0)
		"SHOT-71":
			return Vector2(980.0, 590.0)
		"SHOT-72":
			return Vector2(960.0, 560.0)
		"SHOT-75":
			return Vector2(960.0, 560.0)
		"SHOT-76":
			return Vector2(1040.0, 560.0)
		"SHOT-73":
			return Vector2(980.0, 520.0)
		"SHOT-74":
			return Vector2(900.0, 520.0)
	return Vector2(960.0, 540.0)


func _transition_duration(previous_shot_id: String, shot_id: String) -> float:
	if previous_shot_id == "SHOT-17" and shot_id == "SHOT-18":
		return 1.05
	if previous_shot_id == "SHOT-70" and shot_id == "SHOT-71":
		return 0.48
	if previous_shot_id == "SHOT-71" and shot_id == "SHOT-72":
		return 0.36
	if previous_shot_id == "SHOT-72" and shot_id == "SHOT-75":
		return 0.44
	if previous_shot_id == "SHOT-75" and shot_id == "SHOT-76":
		return 0.72
	if previous_shot_id == "SHOT-76" and shot_id == "SHOT-73":
		return 1.00
	if previous_shot_id == "SHOT-73" and shot_id == "SHOT-74":
		return 1.15
	return 0.62


func _crossfade_from(texture: Texture2D, duration: float) -> void:
	_stop_transition_texture()
	transition_texture.texture = texture
	transition_texture.modulate.a = 1.0
	transition_texture.visible = true
	texture_tween = host.create_tween()
	texture_tween.tween_property(
		transition_texture,
		"modulate:a",
		0.0,
		duration,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	texture_tween.finished.connect(_stop_transition_texture)


func _stop_transition_texture() -> void:
	if texture_tween != null and texture_tween.is_valid():
		texture_tween.kill()
	transition_texture.visible = false
	transition_texture.texture = null
	transition_texture.modulate.a = 1.0


func _flash_from_black(alpha: float, duration: float) -> void:
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	transition_overlay.color = Color.BLACK
	transition_overlay.modulate.a = alpha
	transition_overlay.visible = true
	transition_tween = host.create_tween()
	transition_tween.tween_property(
		transition_overlay,
		"modulate:a",
		0.0,
		duration,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	transition_tween.finished.connect(
		func() -> void: transition_overlay.visible = false
	)


func _can_start_final_hold() -> bool:
	return (
		current_line_id == FINAL_LINE_ID
		and not final_hold_active
		and center_line_label.visible
		and center_line_label.visible_characters == -1
	)


func _start_final_hold() -> void:
	final_hold_active = true
	final_hold_started_at_msec = Time.get_ticks_msec()
	if music_director != null:
		music_director.call("fade_out", 2.4, "MUS-09C")
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = false
	var empty_texture: Texture2D = asset_registry.call(
		"load_variant",
		"SHOT-74",
		"empty",
	) as Texture2D
	if empty_texture != null and displayed_texture != empty_texture:
		current_variant_id = "empty"
		_present_texture("SHOT-74", empty_texture, 0.8, false, false)
	master_texture.scale = Vector2.ONE
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	if bool(host.get("is_auto")):
		auto_timer.start(FINAL_HOLD_SECONDS)


func _finish_final_hold() -> void:
	final_hold_active = false
	auto_timer.stop()
	request_story_advance()


func _kill_tweens() -> void:
	for tween in [texture_tween, transition_tween, ambient_tween, camera_tween, projection_tween]:
		if tween != null and tween.is_valid():
			tween.kill()


func _set_full_rect(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
