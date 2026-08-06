extends ChapterDirector

const DEFAULT_CAPTION_RECT := Rect2(100.0, 748.0, 860.0, 220.0)
const DESCENT_TRIGGER_LINE := "G4-05-05"
const DESCENT_SHOT_ID := "SHOT-61"
const DESCENT_HOLD := 4.8

const CAPTION_RECTS := {
	"SHOT-12": Rect2(100.0, 742.0, 900.0, 226.0),
	"SHOT-13": Rect2(1060.0, 94.0, 760.0, 220.0),
	"SHOT-43": Rect2(90.0, 744.0, 830.0, 220.0),
	"SHOT-44": Rect2(80.0, 70.0, 820.0, 220.0),
	"SHOT-45": Rect2(80.0, 744.0, 830.0, 220.0),
	"SHOT-46": Rect2(80.0, 72.0, 820.0, 220.0),
	"SHOT-47": Rect2(70.0, 70.0, 790.0, 220.0),
	"SHOT-48": Rect2(560.0, 66.0, 800.0, 220.0),
	"SHOT-49": Rect2(80.0, 748.0, 820.0, 220.0),
	"SHOT-50": Rect2(80.0, 748.0, 820.0, 220.0),
	"SHOT-51": Rect2(80.0, 748.0, 820.0, 220.0),
	"SHOT-52": Rect2(70.0, 70.0, 800.0, 220.0),
	"SHOT-53": Rect2(70.0, 70.0, 820.0, 220.0),
	"SHOT-54": Rect2(1040.0, 744.0, 800.0, 220.0),
	"SHOT-56": Rect2(70.0, 70.0, 820.0, 220.0),
	"SHOT-62": Rect2(70.0, 66.0, 820.0, 220.0),
	"SHOT-63": Rect2(1040.0, 748.0, 800.0, 220.0),
	"SHOT-66": Rect2(70.0, 70.0, 820.0, 220.0),
	"SHOT-68": Rect2(1050.0, 74.0, 790.0, 220.0),
	"SHOT-69": Rect2(70.0, 70.0, 820.0, 220.0),
	"SHOT-14": Rect2(90.0, 742.0, 900.0, 226.0),
	"SHOT-15": Rect2(90.0, 742.0, 900.0, 226.0),
	"SHOT-16": Rect2(90.0, 742.0, 900.0, 226.0),
	"SHOT-55": Rect2(90.0, 742.0, 900.0, 226.0),
	"SHOT-58": Rect2(90.0, 742.0, 900.0, 226.0),
	"SHOT-60": Rect2(90.0, 742.0, 900.0, 226.0),
}

const PLACEHOLDER_COPY := {
	"SHOT-12": "SHOT-12 · 旧作重演占位\n三十一岁的我继续向前走",
	"SHOT-14": "SHOT-14 · 出发前规划占位\n选题 · 路线 · 光线 · 机位",
	"SHOT-15": "SHOT-15 · 四人共同出发占位\n破晓 · 行李 · 摄影装备",
	"SHOT-16": "SHOT-16 · 固定机位天光占位\n日落 → 星空 → 月升",
	"SHOT-55": "SHOT-55 · 完成作品被观看占位\n投映画面将匹配切入四人出发",
	"SHOT-58": "SHOT-58 · 新都桥告别占位\n放晴 · 湿路 · 四人和行李分离",
	"SHOT-60": "SHOT-60 · 独自折返占位\n空副驾 · 摄影包 · 导航",
	"SHOT-61": "SHOT-61 · 夜间下山占位\n车灯 · 弯道 · 持续的环境声",
}

const SKY_PHASES := {
	"G4-05-01": {
		"variant": "sunset",
		"copy": "SHOT-16 · 日落占位\n同一机位，等待开始",
		"wash": Color(0.96, 0.55, 0.28, 0.30),
	},
	"G4-05-02": {
		"variant": "stars",
		"copy": "SHOT-16 · 星空占位\n道路、天气和落空已经进入画面",
		"wash": Color(0.10, 0.18, 0.34, 0.42),
	},
	"G4-05-03": {
		"variant": "stars",
		"copy": "SHOT-16 · 星空占位\n旅途记录继续",
		"wash": Color(0.08, 0.14, 0.30, 0.44),
	},
	"G4-05-04": {
		"variant": "moonrise",
		"copy": "SHOT-16 · 月升占位\n结局开始反转",
		"wash": Color(0.26, 0.31, 0.42, 0.38),
	},
	"G4-05-05": {
		"variant": "moonrise",
		"copy": "SHOT-16 · 月升占位\n庄严而美丽",
		"wash": Color(0.32, 0.35, 0.43, 0.34),
	},
}

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

var transition_overlay: ColorRect
var ambient_overlay: ColorRect
var transition_tween: Tween
var ambient_tween: Tween
var camera_tween: Tween

var current_unit_id := ""
var current_line_id := ""
var current_shot_id := ""
var descent_active := false


func _init() -> void:
	chapter_number = 4


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
	_build_chapter_effects()


func on_unit_changed(unit: Dictionary) -> void:
	var previous_shot_id := current_shot_id
	current_unit_id = str(unit.get("id", ""))
	current_line_id = ""
	current_shot_id = str(unit.get("shot", ""))
	descent_active = false
	_show_shot(current_shot_id, previous_shot_id, true)


func on_line_changed(line: Dictionary, unit: Dictionary) -> bool:
	current_line_id = str(line.get("id", ""))
	var next_shot_id := str(line.get("shot", unit.get("shot", "")))
	if next_shot_id.is_empty():
		return false

	if SKY_PHASES.has(current_line_id):
		var previous_shot_id := current_shot_id
		current_shot_id = next_shot_id
		_show_sky_phase(current_line_id, previous_shot_id)
		return false

	if next_shot_id != current_shot_id:
		var previous_shot_id := current_shot_id
		current_shot_id = next_shot_id
		_show_shot(current_shot_id, previous_shot_id, false)
	else:
		_apply_line_state()
	return false


func advance() -> bool:
	if descent_active:
		_finish_descent()
		return true
	if _can_start_descent():
		_start_descent()
		return true
	return false


func on_auto_timeout() -> bool:
	if descent_active:
		_finish_descent()
		return true
	if _can_start_descent():
		_start_descent()
		return true
	return false


func position_caption(label: Label, _presentation: String) -> bool:
	var rect: Rect2 = CAPTION_RECTS.get(current_shot_id, DEFAULT_CAPTION_RECT)
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 0.0
	label.anchor_bottom = 0.0
	label.offset_left = rect.position.x
	label.offset_top = rect.position.y
	label.offset_right = rect.end.x
	label.offset_bottom = rect.end.y
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 35)
	label.add_theme_constant_override("line_spacing", 13)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.96),
	)
	label.add_theme_constant_override("shadow_outline_size", 7)
	return true


func uses_speaker_label() -> bool:
	return false


func resume() -> bool:
	if descent_active and bool(host.get("is_auto")):
		auto_timer.start(DESCENT_HOLD)
		return true
	return false


func leave() -> void:
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	if ambient_tween != null and ambient_tween.is_valid():
		ambient_tween.kill()
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	transition_overlay.visible = false
	ambient_overlay.visible = false
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
	descent_active = false


func _build_chapter_effects() -> void:
	ambient_overlay = ColorRect.new()
	ambient_overlay.name = "G4AmbientOverlay"
	ambient_overlay.color = Color.TRANSPARENT
	ambient_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ambient_overlay.visible = false
	_set_full_rect(ambient_overlay)
	fx_layer.add_child(ambient_overlay)

	transition_overlay = ColorRect.new()
	transition_overlay.name = "G4TransitionOverlay"
	transition_overlay.color = Color.BLACK
	transition_overlay.modulate.a = 0.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.visible = false
	_set_full_rect(transition_overlay)
	fx_layer.add_child(transition_overlay)


func _show_shot(shot_id: String, previous_shot_id: String, unit_entry: bool) -> void:
	var texture: Texture2D = asset_registry.call("load_master", shot_id) as Texture2D
	ui.call("show_line_shot", shot_id, texture)
	_set_placeholder_copy(shot_id, PLACEHOLDER_COPY.get(shot_id, ""))
	_apply_ambient(_ambient_for_shot(shot_id, texture == null))
	_start_camera_motion(texture)
	_flash_for_shot(previous_shot_id, shot_id, unit_entry)


func _show_sky_phase(line_id: String, previous_shot_id: String) -> void:
	var phase := SKY_PHASES.get(line_id, {}) as Dictionary
	var variant_id := str(phase.get("variant", ""))
	var texture: Texture2D = asset_registry.call(
		"load_variant",
		"SHOT-16",
		variant_id,
	) as Texture2D
	if texture == null:
		texture = asset_registry.call("load_master", "SHOT-16") as Texture2D
	ui.call("show_line_shot", "SHOT-16", texture)
	_set_placeholder_copy("SHOT-16", str(phase.get("copy", PLACEHOLDER_COPY["SHOT-16"])))
	var wash: Color = phase.get("wash", Color.TRANSPARENT) as Color
	if texture != null:
		wash.a *= 0.28
	_apply_ambient(wash)
	_start_camera_motion(texture)
	if previous_shot_id != "SHOT-16" or ["G4-05-02", "G4-05-04"].has(line_id):
		_flash_for_shot(previous_shot_id, "SHOT-16", previous_shot_id.is_empty())


func _apply_line_state() -> void:
	if current_line_id == "G4-03-06":
		_apply_ambient(Color(0.18, 0.23, 0.30, 0.12))
	elif current_shot_id == "SHOT-53":
		_apply_ambient(Color.TRANSPARENT)


func _set_placeholder_copy(shot_id: String, copy: String) -> void:
	var placeholder := ui.get("asset_placeholder") as CenterContainer
	if placeholder == null or not placeholder.visible:
		return
	var label := ui.get("asset_placeholder_label") as Label
	label.add_theme_color_override(
		"font_color",
		Color(0.88, 0.92, 0.90, 0.82),
	)
	if copy.is_empty():
		label.text = "%s\n美术占位" % shot_id
	else:
		label.text = copy


func _ambient_for_shot(shot_id: String, is_placeholder: bool) -> Color:
	if not is_placeholder:
		return Color.TRANSPARENT
	match shot_id:
		"SHOT-12":
			return Color(0.36, 0.30, 0.22, 0.34)
		"SHOT-14":
			return Color(0.12, 0.28, 0.30, 0.34)
		"SHOT-15":
			return Color(0.22, 0.31, 0.38, 0.36)
		"SHOT-16":
			return Color(0.16, 0.20, 0.34, 0.38)
		"SHOT-55":
			return Color(0.30, 0.32, 0.34, 0.28)
		"SHOT-58":
			return Color(0.24, 0.36, 0.39, 0.34)
		"SHOT-60":
			return Color(0.05, 0.16, 0.24, 0.46)
		"SHOT-61":
			return Color(0.0, 0.01, 0.03, 0.66)
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
		0.48,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _start_camera_motion(texture: Texture2D) -> void:
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	master_texture.scale = Vector2.ONE
	master_texture.pivot_offset = Vector2(960.0, 540.0)
	if texture == null:
		return
	camera_tween = host.create_tween()
	camera_tween.tween_property(
		master_texture,
		"scale",
		Vector2(1.018, 1.018),
		9.0,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _flash_for_shot(previous_shot_id: String, shot_id: String, unit_entry: bool) -> void:
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	var is_projection_match := previous_shot_id == "SHOT-55" and shot_id == "SHOT-15"
	var is_step_match := previous_shot_id == "SHOT-12" and shot_id == "SHOT-13"
	transition_overlay.color = Color.WHITE if is_projection_match else Color.BLACK
	transition_overlay.modulate.a = (
		0.22 if is_step_match else (0.72 if is_projection_match else (0.80 if unit_entry else 0.48))
	)
	transition_overlay.visible = true
	transition_tween = host.create_tween()
	transition_tween.tween_property(
		transition_overlay,
		"modulate:a",
		0.0,
		0.22 if is_step_match else (0.62 if unit_entry else 0.36),
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	transition_tween.finished.connect(
		func() -> void: transition_overlay.visible = false
	)


func _can_start_descent() -> bool:
	return (
		current_line_id == DESCENT_TRIGGER_LINE
		and not descent_active
		and center_line_label.visible
		and center_line_label.visible_characters == -1
	)


func _start_descent() -> void:
	descent_active = true
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = false
	var previous_shot_id := current_shot_id
	current_shot_id = DESCENT_SHOT_ID
	_show_shot(current_shot_id, previous_shot_id, false)
	if bool(host.get("is_auto")):
		auto_timer.start(DESCENT_HOLD)


func _finish_descent() -> void:
	descent_active = false
	auto_timer.stop()
	story.call("advance")


func _set_full_rect(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
