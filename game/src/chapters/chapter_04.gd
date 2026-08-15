extends ChapterDirector

const DEFAULT_CAPTION_RECT := Rect2(100.0, 748.0, 860.0, 220.0)
const DESCENT_TRIGGER_LINE := "G4-05-05"
const DESCENT_SHOT_ID := "SHOT-61"
const DESCENT_HOLD := 4.8
const THIRTY_ONE_FADE_DURATION := 1.6
const AGE_JUMP_BLACK_HOLD := 0.32
const THIRTY_THREE_REVEAL_DURATION := 1.25

# Preserve the user's auto-wait preference while restoring each scene's scripted dwell range.
const AUTO_WAIT_MULTIPLIERS := {
	"G4-01": 1.25,
	"G4-02": 1.35,
	"G4-03": 1.40,
	"G4-04": 1.55,
	"G4-05": 1.40,
}

const SHOT_12_PHASES := {
	"G4-01-01": "outward",
	"G4-01-02": "outward",
	"G4-01-03": "mountains",
	"G4-01-04": "mountains",
	"G4-01-05": "pleasure",
	"G4-01-06": "pleasure",
	"G4-01-07": "return",
	"G4-01-08": "return",
	"G4-01-09": "return",
}

const CAPTION_RECTS := {
	"G4-01-01": Rect2(70.0, 742.0, 760.0, 226.0),
	"G4-01-02": Rect2(70.0, 742.0, 760.0, 226.0),
	"G4-01-03": Rect2(70.0, 742.0, 820.0, 226.0),
	"G4-01-04": Rect2(70.0, 742.0, 820.0, 226.0),
	"G4-01-05": Rect2(70.0, 742.0, 800.0, 226.0),
	"G4-01-06": Rect2(70.0, 742.0, 800.0, 226.0),
	"G4-01-07": Rect2(70.0, 72.0, 780.0, 226.0),
	"G4-01-08": Rect2(70.0, 72.0, 780.0, 226.0),
	"G4-01-09": Rect2(70.0, 72.0, 780.0, 226.0),
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
	# 深圳地库图的四人与装备集中在中下部，字幕放到顶棚空区。
	"SHOT-15": Rect2(70.0, 38.0, 900.0, 210.0),
	"SHOT-16": Rect2(70.0, 70.0, 820.0, 220.0),
	"SHOT-55": Rect2(90.0, 742.0, 900.0, 226.0),
	"SHOT-58": Rect2(1040.0, 70.0, 800.0, 220.0),
	"SHOT-60": Rect2(90.0, 742.0, 900.0, 226.0),
}

const PLACEHOLDER_COPY := {
	"SHOT-14": "SHOT-14 · 出发前规划占位\n选题 · 路线 · 光线 · 机位",
	"SHOT-15": "SHOT-15 · 四人共同出发占位\n破晓 · 行李 · 摄影装备",
	"SHOT-16": "SHOT-16 · 固定机位天光占位\n日落 → 蓝调 → 星空 → 月照",
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
		"variant": "blue",
		"copy": "SHOT-16 · 蓝调占位\n道路、天气和落空已经进入画面",
		"wash": Color(0.10, 0.18, 0.34, 0.38),
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
var voice_sequence_player: Node

var transition_overlay: ColorRect
var transition_texture: TextureRect
var paper_frame: ColorRect
var paper_signature: Label
var time_marker: PanelContainer
var time_marker_label: Label
var ambient_overlay: ColorRect
var transition_tween: Tween
var texture_tween: Tween
var paper_tween: Tween
var signature_tween: Tween
var marker_tween: Tween
var ambient_tween: Tween
var camera_tween: Tween

var current_unit_id := ""
var current_line_id := ""
var current_shot_id := ""
var current_variant_id := ""
var displayed_texture: Texture2D
var descent_active := false
var age_jump_active := false


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
	voice_sequence_player = context.get("voice_sequence_player") as Node
	_build_chapter_effects()


func on_unit_changed(unit: Dictionary) -> void:
	var previous_shot_id := current_shot_id
	current_unit_id = str(unit.get("id", ""))
	current_line_id = ""
	descent_active = false
	if current_unit_id != "G4-01" and paper_frame.visible:
		_hide_paper_frame(true)
	if current_unit_id == "G4-01":
		_show_shot_12_variant("outward", previous_shot_id, true)
		_hide_paper_frame(true)
		_hide_time_marker(true)
		return
	if current_unit_id == "G4-02":
		_show_time_marker("2026 / 三十三岁", true)
		if age_jump_active:
			current_variant_id = ""
			current_shot_id = str(unit.get("shot", ""))
			_show_age_jump_destination(current_shot_id)
			return
	else:
		_hide_time_marker(true)
	current_variant_id = ""
	current_shot_id = str(unit.get("shot", ""))
	_show_shot(current_shot_id, previous_shot_id, true)


func on_line_changed(line: Dictionary, unit: Dictionary) -> bool:
	current_line_id = str(line.get("id", ""))
	var next_shot_id := str(line.get("shot", unit.get("shot", "")))
	if next_shot_id.is_empty():
		return false

	if SHOT_12_PHASES.has(current_line_id):
		var next_variant_id := str(SHOT_12_PHASES[current_line_id])
		if current_shot_id != "SHOT-12" or current_variant_id != next_variant_id:
			_show_shot_12_variant(next_variant_id, current_shot_id, false)
		else:
			_apply_line_state()
		return false

	if current_line_id == "G4-02-02":
		_hide_time_marker(false)

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


func begin_timed_sequence(unit_id: String, line_id: String) -> void:
	if unit_id == "G4-01" and line_id == "G4-01-01":
		_show_paper_frame()
	else:
		_hide_paper_frame(true)


func begin_voice_handoff(unit_id: String) -> bool:
	if unit_id != "G4-01" or age_jump_active:
		return age_jump_active
	age_jump_active = true
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	transition_overlay.color = Color(0.012, 0.016, 0.022, 1.0)
	transition_overlay.modulate.a = 0.0
	transition_overlay.visible = true
	if voice_sequence_player != null:
		voice_sequence_player.call("fade_out", THIRTY_ONE_FADE_DURATION)
	transition_tween = host.create_tween()
	transition_tween.tween_property(
		transition_overlay,
		"modulate:a",
		1.0,
		THIRTY_ONE_FADE_DURATION,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	transition_tween.tween_interval(AGE_JUMP_BLACK_HOLD)
	transition_tween.tween_callback(_finish_thirty_one_fade)
	return true


func blocks_input() -> bool:
	return age_jump_active


func advance() -> bool:
	if age_jump_active:
		return true
	if descent_active:
		_finish_descent()
		return true
	if _can_start_descent():
		_start_descent()
		return true
	return false


func on_auto_timeout() -> bool:
	if age_jump_active:
		return true
	if descent_active:
		_finish_descent()
		return true
	if _can_start_descent():
		_start_descent()
		return true
	return false


func position_caption(label: Label, _presentation: String) -> bool:
	var rect: Rect2 = CAPTION_RECTS.get(
		current_line_id,
		CAPTION_RECTS.get(current_shot_id, DEFAULT_CAPTION_RECT),
	)
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


func auto_wait_multiplier(_line: Dictionary, unit: Dictionary) -> float:
	return float(AUTO_WAIT_MULTIPLIERS.get(str(unit.get("id", "")), 1.0))


func resume() -> bool:
	if descent_active and bool(host.get("is_auto")):
		auto_timer.start(DESCENT_HOLD)
		return true
	return false


func leave() -> void:
	_stop_transition_texture()
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	if paper_tween != null and paper_tween.is_valid():
		paper_tween.kill()
	if signature_tween != null and signature_tween.is_valid():
		signature_tween.kill()
	if marker_tween != null and marker_tween.is_valid():
		marker_tween.kill()
	if ambient_tween != null and ambient_tween.is_valid():
		ambient_tween.kill()
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	transition_overlay.visible = false
	paper_frame.visible = false
	paper_signature.visible = false
	time_marker.visible = false
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
	current_variant_id = ""
	displayed_texture = null
	descent_active = false
	age_jump_active = false


func _build_chapter_effects() -> void:
	transition_texture = TextureRect.new()
	transition_texture.name = "G4TransitionTexture"
	transition_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	transition_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	transition_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_texture.visible = false
	_set_full_rect(transition_texture)
	fx_layer.add_child(transition_texture)

	ambient_overlay = ColorRect.new()
	ambient_overlay.name = "G4AmbientOverlay"
	ambient_overlay.color = Color.TRANSPARENT
	ambient_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ambient_overlay.visible = false
	_set_full_rect(ambient_overlay)
	fx_layer.add_child(ambient_overlay)

	paper_frame = ColorRect.new()
	paper_frame.name = "G4PaperFrame"
	paper_frame.color = Color.WHITE
	paper_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper_frame.visible = false
	_set_full_rect(paper_frame)
	var paper_shader := Shader.new()
	paper_shader.code = """
shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void fragment() {
	vec2 p = UV - vec2(0.5);
	float grain = (hash(floor(UV * vec2(210.0, 118.0))) - 0.5) * 0.045;
	float edge = length(p * vec2(1.0, 1.18)) * 1.58 + grain;
	float cover = smoothstep(progress - 0.075, progress + 0.075, edge);
	vec3 paper = vec3(0.91, 0.895, 0.84) + grain;
	COLOR = vec4(paper, cover * 0.96);
}
"""
	var paper_material := ShaderMaterial.new()
	paper_material.shader = paper_shader
	paper_frame.material = paper_material
	fx_layer.add_child(paper_frame)

	paper_signature = Label.new()
	paper_signature.name = "G4PaperSignature"
	paper_signature.position = Vector2(1420.0, 900.0)
	paper_signature.size = Vector2(390.0, 58.0)
	paper_signature.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	paper_signature.text = "《三十一》 / 2024"
	paper_signature.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper_signature.visible = false
	paper_signature.add_theme_font_size_override("font_size", 24)
	paper_signature.add_theme_color_override("font_color", Color(0.20, 0.19, 0.17, 0.78))
	fx_layer.add_child(paper_signature)

	time_marker = PanelContainer.new()
	time_marker.name = "G4TimeMarker"
	time_marker.position = Vector2(1400.0, 54.0)
	time_marker.size = Vector2(440.0, 64.0)
	time_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_marker.visible = false
	var marker_style := StyleBoxFlat.new()
	marker_style.bg_color = Color.TRANSPARENT
	marker_style.content_margin_left = 0.0
	marker_style.content_margin_top = 7.0
	marker_style.content_margin_right = 0.0
	marker_style.content_margin_bottom = 7.0
	time_marker.add_theme_stylebox_override("panel", marker_style)
	fx_layer.add_child(time_marker)

	time_marker_label = Label.new()
	time_marker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_marker_label.add_theme_font_size_override("font_size", 24)
	time_marker_label.add_theme_color_override("font_color", Color(0.92, 0.91, 0.88, 0.88))
	time_marker_label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.82),
	)
	time_marker_label.add_theme_constant_override("shadow_outline_size", 4)
	time_marker.add_child(time_marker_label)

	transition_overlay = ColorRect.new()
	transition_overlay.name = "G4TransitionOverlay"
	transition_overlay.color = Color.BLACK
	transition_overlay.modulate.a = 0.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.visible = false
	_set_full_rect(transition_overlay)
	fx_layer.add_child(transition_overlay)


func _show_shot(shot_id: String, previous_shot_id: String, unit_entry: bool) -> void:
	var previous_texture := displayed_texture
	var is_step_match := (
		previous_shot_id == "SHOT-12"
		and shot_id == "SHOT-13"
		and previous_texture != null
	)
	if not is_step_match:
		_stop_transition_texture()
	var texture: Texture2D = asset_registry.call("load_master", shot_id) as Texture2D
	ui.call("show_line_shot", shot_id, texture)
	_set_placeholder_copy(shot_id, PLACEHOLDER_COPY.get(shot_id, ""))
	_apply_ambient(_ambient_for_shot(shot_id, texture == null))
	_start_camera_motion(texture)
	if is_step_match:
		_crossfade_from(previous_texture, 1.8)
		_light_wash_for_step_match()
	else:
		_flash_for_shot(previous_shot_id, shot_id, unit_entry)
	displayed_texture = texture


func _show_age_jump_destination(shot_id: String) -> void:
	_stop_transition_texture()
	var texture: Texture2D = asset_registry.call("load_master", shot_id) as Texture2D
	ui.call("show_line_shot", shot_id, texture)
	_set_placeholder_copy(shot_id, PLACEHOLDER_COPY.get(shot_id, ""))
	_apply_ambient(_ambient_for_shot(shot_id, texture == null))
	_start_camera_motion(texture)
	displayed_texture = texture
	transition_overlay.color = Color(0.012, 0.016, 0.022, 1.0)
	transition_overlay.modulate.a = 1.0
	transition_overlay.visible = true
	transition_tween = host.create_tween()
	transition_tween.tween_interval(0.18)
	transition_tween.tween_property(
		transition_overlay,
		"modulate:a",
		0.0,
		THIRTY_THREE_REVEAL_DURATION,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	transition_tween.finished.connect(_finish_age_jump_reveal)


func _finish_thirty_one_fade() -> void:
	if not age_jump_active:
		return
	if voice_sequence_player != null and voice_sequence_player.call("is_active"):
		voice_sequence_player.call("stop")
	request_story_advance()


func _finish_age_jump_reveal() -> void:
	transition_overlay.visible = false
	transition_overlay.modulate.a = 0.0
	age_jump_active = false


func _show_shot_12_variant(
	variant_id: String,
	previous_shot_id: String,
	unit_entry: bool,
) -> void:
	var previous_texture := displayed_texture
	current_shot_id = "SHOT-12"
	current_variant_id = variant_id
	var texture: Texture2D = asset_registry.call(
		"load_variant",
		"SHOT-12",
		variant_id,
	) as Texture2D
	if texture == null:
		texture = asset_registry.call("load_master", "SHOT-12") as Texture2D
	ui.call("show_line_shot", "SHOT-12", texture)
	_set_placeholder_copy("SHOT-12", "")
	_apply_ambient(Color.TRANSPARENT)
	_start_camera_motion(texture)
	if previous_texture != null and previous_texture != texture:
		_crossfade_from(previous_texture, 0.92)
	else:
		_stop_transition_texture()
		_flash_for_shot(previous_shot_id, "SHOT-12", unit_entry)
	displayed_texture = texture


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
	if previous_shot_id != "SHOT-16" or ["G4-05-02", "G4-05-03", "G4-05-04"].has(line_id):
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
	master_texture.pivot_offset = (
		Vector2(1190.0, 520.0)
		if current_shot_id == "SHOT-12" and current_variant_id == "return"
		else Vector2(960.0, 540.0)
	)
	if texture == null:
		return
	camera_tween = host.create_tween()
	camera_tween.tween_property(
		master_texture,
		"scale",
		Vector2(1.018, 1.018),
		9.0,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


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


func _show_paper_frame() -> void:
	if paper_tween != null and paper_tween.is_valid():
		paper_tween.kill()
	if signature_tween != null and signature_tween.is_valid():
		signature_tween.kill()
	paper_frame.modulate.a = 1.0
	paper_frame.visible = true
	paper_signature.modulate.a = 0.0
	paper_signature.visible = true
	_set_paper_progress(0.0)
	paper_tween = host.create_tween()
	paper_tween.tween_method(_set_paper_progress, 0.0, 1.0, 2.7).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	paper_tween.finished.connect(func() -> void: paper_frame.visible = false)
	signature_tween = host.create_tween()
	signature_tween.tween_property(
		paper_signature,
		"modulate:a",
		0.86,
		0.42,
	).set_delay(0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	signature_tween.tween_interval(1.45)
	signature_tween.tween_property(
		paper_signature,
		"modulate:a",
		0.0,
		0.48,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	signature_tween.finished.connect(func() -> void: paper_signature.visible = false)


func _hide_paper_frame(immediate := false) -> void:
	if paper_tween != null and paper_tween.is_valid():
		paper_tween.kill()
	if signature_tween != null and signature_tween.is_valid():
		signature_tween.kill()
	if immediate:
		paper_frame.visible = false
		paper_signature.visible = false
		paper_frame.modulate.a = 1.0
		paper_signature.modulate.a = 1.0
		return
	if not paper_frame.visible and not paper_signature.visible:
		return
	paper_tween = host.create_tween()
	paper_tween.set_parallel(true)
	paper_tween.tween_property(paper_frame, "modulate:a", 0.0, 0.6).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN)
	paper_tween.tween_property(
		paper_signature,
		"modulate:a",
		0.0,
		0.45,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	paper_tween.finished.connect(func() -> void:
		paper_frame.visible = false
		paper_signature.visible = false
	)


func _set_paper_progress(value: float) -> void:
	var shader_material := paper_frame.material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter("progress", value)


func _show_time_marker(copy: String, lower_left: bool) -> void:
	if marker_tween != null and marker_tween.is_valid():
		marker_tween.kill()
	time_marker.position = Vector2(78.0, 944.0) if lower_left else Vector2(1400.0, 54.0)
	time_marker.size = Vector2(360.0, 58.0)
	time_marker_label.text = copy
	time_marker.modulate.a = 0.0
	time_marker.visible = true
	marker_tween = host.create_tween()
	marker_tween.tween_property(
		time_marker,
		"modulate:a",
		1.0,
		0.42,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _hide_time_marker(immediate: bool) -> void:
	if marker_tween != null and marker_tween.is_valid():
		marker_tween.kill()
	if immediate:
		time_marker.visible = false
		time_marker.modulate.a = 1.0
		return
	if not time_marker.visible:
		return
	marker_tween = host.create_tween()
	marker_tween.tween_property(
		time_marker,
		"modulate:a",
		0.0,
		0.48,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	marker_tween.finished.connect(func() -> void: time_marker.visible = false)


func _flash_for_shot(previous_shot_id: String, shot_id: String, unit_entry: bool) -> void:
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	var is_projection_match := previous_shot_id == "SHOT-55" and shot_id == "SHOT-15"
	transition_overlay.color = Color.WHITE if is_projection_match else Color.BLACK
	transition_overlay.modulate.a = (
		0.72 if is_projection_match else (0.80 if unit_entry else 0.48)
	)
	transition_overlay.visible = true
	transition_tween = host.create_tween()
	transition_tween.tween_property(
		transition_overlay,
		"modulate:a",
		0.0,
		0.62 if unit_entry else 0.36,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	transition_tween.finished.connect(
		func() -> void: transition_overlay.visible = false
	)


func _light_wash_for_step_match() -> void:
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	transition_overlay.color = Color(0.93, 0.95, 0.92, 1.0)
	transition_overlay.modulate.a = 0.0
	transition_overlay.visible = true
	transition_tween = host.create_tween()
	transition_tween.tween_property(
		transition_overlay,
		"modulate:a",
		0.24,
		0.58,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	transition_tween.tween_property(
		transition_overlay,
		"modulate:a",
		0.0,
		1.22,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
	request_story_advance()


func _set_full_rect(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
