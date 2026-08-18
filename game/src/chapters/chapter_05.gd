extends ChapterDirector

const DEFAULT_CAPTION_RECT := Rect2(70.0, 70.0, 820.0, 220.0)
const FINAL_LINE_ID := "G5-05-04"
const FINALE_THRESHOLD_LINE_ID := "G5-04-03"
const FINALE_THRESHOLD_SECONDS := 2.75
const ENDING_STEP_TWO_AT := 1.35
const ENDING_STEP_THREE_AT := 2.90
const ENDING_IDENTITY_AT := 4.45
const ENDING_LANTERN_CROP_POSITION := Vector2(850.0, 540.0)
const ENDING_LANTERN_CROP_SIZE := Vector2(250.0, 310.0)
const ENDING_PERSON_PIVOT := Vector2(1260.0, 978.0)
const ENDING_LIVE_BEACON_POSITION := Vector2(604.0, 176.0)
const ENDING_LIVE_BEACON_SIZE := Vector2(62.0, 62.0)
const ENDING_IDENTITY_BEACON_POSITION := Vector2(986.0, 294.0)
const ENDING_IDENTITY_BEACON_SIZE := Vector2(78.0, 78.0)
const ENDING_IDENTITY_FRAME_VARIANTS := [
	"identity-close",
	"identity-wind-hair-lead",
	"identity-wind-mid",
	"identity-wind-peak",
	"identity-wind-coat-lag",
	"identity-wind-fall",
]
const ENDING_IDENTITY_FRAME_SECONDS := [0.0, 0.16, 0.20, 0.32, 0.22, 0.30]
const ENDING_IDENTITY_REST_SECONDS := [1.05, 1.75, 1.30, 2.10]
const ENDING_IDENTITY_GUST_PATTERNS := [
	[1, 2, 3, 4, 5, 0],
	[1, 2, 5, 0],
	[1, 0],
	[1, 2, 3, 4, 5, 0],
]
const ENDING_BEACON_ON_SECONDS := 0.72
const ENDING_BEACON_OFF_SECONDS := 2.65

const ENDING_OCEAN_SHADER := """
shader_type canvas_item;

uniform float identity_mode = 0.0;
uniform float beacon_on = 1.0;

float band(float value, float start_value, float end_value, float softness) {
	return smoothstep(start_value, start_value + softness, value)
		* (1.0 - smoothstep(end_value - softness, end_value, value));
}

float box_mask(vec2 uv, vec2 minimum, vec2 maximum, float softness) {
	vec2 enter = smoothstep(minimum, minimum + vec2(softness), uv);
	vec2 leave = 1.0 - smoothstep(maximum - vec2(softness), maximum, uv);
	return enter.x * enter.y * leave.x * leave.y;
}

void fragment() {
	vec2 uv = UV;
	vec4 base = texture(TEXTURE, uv);
	float sea = band(uv.y, 0.32, 0.79, 0.045);
	float left_water = 1.0 - smoothstep(0.30, 0.54, uv.x);
	float right_water = smoothstep(0.48, 0.67, uv.x);
	float live_water = sea * max(left_water, right_water);
	// The identity close-up has a wet causeway and large breakwater blocks in
	// front of the actual sea.  Only displace the open-water band; otherwise
	// those rigid foreground forms bend with the waves and read as a screen warp.
	float identity_far_sea = band(uv.y, 0.39, 0.53, 0.026)
		* (1.0 - smoothstep(0.47, 0.72, uv.x));
	float identity_left_sea = band(uv.y, 0.47, 0.66, 0.040)
		* (1.0 - smoothstep(0.18, 0.34, uv.x));
	float identity_open_sea = max(identity_far_sea, identity_left_sea);
	float identity_person_guard = 1.0 - box_mask(
		uv,
		vec2(0.50, 0.21),
		vec2(0.69, 0.88),
		0.035
	);
	float identity_water = identity_open_sea * identity_person_guard;
	float water_mask = mix(live_water, identity_water, identity_mode);
	float phase = sin(uv.y * 214.0 - TIME * 2.05 + sin(uv.x * 24.0) * 1.35);
	float cross_phase = sin(uv.x * 88.0 - TIME * 1.18 + uv.y * 37.0);
	vec2 shifted_uv = uv + vec2(
		(phase * 0.00230 + cross_phase * 0.00072) * water_mask,
		(cross_phase * 0.00058 + phase * 0.00024) * water_mask
	);
	vec4 shifted = texture(TEXTURE, shifted_uv);
	float moon_path = mix(
		band(uv.x, 0.58, 0.93, 0.09) * band(uv.y, 0.32, 0.69, 0.06),
		band(uv.x, 0.16, 0.55, 0.10) * band(uv.y, 0.40, 0.86, 0.08),
		identity_mode
	);
	float shimmer = 0.5 + 0.5 * sin(uv.y * 420.0 - TIME * 3.05 + uv.x * 27.0);
	float traveling_crest = pow(
		0.5 + 0.5 * sin(uv.y * 286.0 - TIME * 2.42 + uv.x * 21.0),
		9.0
	);
	vec3 lift = (
		vec3(0.034, 0.048, 0.066) * moon_path * shimmer
		+ vec3(0.022, 0.040, 0.060) * traveling_crest
	) * water_mask;
	vec4 animated = vec4(shifted.rgb + lift, base.a);
	vec4 color = mix(base, animated, water_mask * 0.88);

	vec2 live_beacon_center = vec2(0.331, 0.192);
	vec2 identity_beacon_center = vec2(0.534, 0.308);
	vec2 beacon_center = mix(live_beacon_center, identity_beacon_center, identity_mode);
	float beacon_radius = mix(0.021, 0.028, identity_mode);
	float beacon_mask = 1.0 - smoothstep(
		beacon_radius * 0.28,
		beacon_radius,
		length(uv - beacon_center)
	);
	vec3 unlit_beacon = color.rgb * 0.14;
	unlit_beacon.g = min(unlit_beacon.g, unlit_beacon.r * 1.08 + 0.002);
	color.rgb = mix(color.rgb, unlit_beacon, beacon_mask * (1.0 - beacon_on));
	COLOR = color;
}
"""

const ENDING_PERSON_SHADER := """
shader_type canvas_item;

uniform float wind_strength = 1.0;
uniform float walk_amount = 0.0;

float box_mask(vec2 uv, vec2 minimum, vec2 maximum, float softness) {
	vec2 enter = smoothstep(minimum, minimum + vec2(softness), uv);
	vec2 leave = 1.0 - smoothstep(maximum - vec2(softness), maximum, uv);
	return enter.x * enter.y * leave.x * leave.y;
}

void fragment() {
	float hair = box_mask(UV, vec2(0.605, 0.425), vec2(0.675, 0.545), 0.018);
	float coat = box_mask(UV, vec2(0.565, 0.515), vec2(0.705, 0.805), 0.028)
		* smoothstep(0.56, 0.80, UV.y);
	float left_leg = box_mask(UV, vec2(0.620, 0.735), vec2(0.650, 0.925), 0.010);
	float right_leg = box_mask(UV, vec2(0.646, 0.735), vec2(0.682, 0.925), 0.010);
	float gust = sin(TIME * 0.86) * 0.62 + sin(TIME * 1.91 + 1.4) * 0.38;
	float step_phase = sin(TIME * 5.25);
	float offset = gust * wind_strength * (hair * 0.0018 + coat * 0.00125)
		+ step_phase * walk_amount * (left_leg - right_leg) * 0.0022;
	vec4 sample_color = texture(TEXTURE, UV - vec2(offset, 0.0));
	COLOR = sample_color;
}
"""

const ENDING_GLOW_SHADER := """
shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform float speed = 1.0;
uniform float phase = 0.0;
uniform float pulse_floor = 0.72;
uniform float pulse_sharpness = 1.0;

void fragment() {
	float distance_to_center = length(UV - vec2(0.5));
	float radial = 1.0 - smoothstep(0.02, 0.5, distance_to_center);
	float wave = 0.5 + 0.5 * sin(TIME * speed + phase);
	float pulse = mix(pulse_floor, 1.0, pow(wave, pulse_sharpness));
	COLOR = vec4(glow_color.rgb, glow_color.a * radial * radial * pulse);
}
"""

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
	"G5-05-03": Rect2(90.0, 790.0, 720.0, 170.0),
	"G5-05-04": Rect2(90.0, 790.0, 920.0, 170.0),
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
var ending_ocean_layer: TextureRect
var ending_beacon_glow: ColorRect
var ending_walk_anchor: Control
var ending_walk_bob: Control
var ending_person_layer: TextureRect
var ending_lantern_layer: TextureRect
var ending_lantern_glow: ColorRect

var texture_tween: Tween
var transition_tween: Tween
var ambient_tween: Tween
var camera_tween: Tween
var projection_tween: Tween
var ending_timeline_tween: Tween
var finale_threshold_tween: Tween

var current_unit_id := ""
var current_line_id := ""
var current_shot_id := ""
var current_variant_id := ""
var displayed_texture: Texture2D
var final_hold_active := false
var ending_environment_active := false
var ending_sequence_active := false
var ending_identity_ready := false
var ending_final_hold_active := false
var ending_motion_clock := 0.0
var ending_identity_frames: Array[Texture2D] = []
var ending_identity_frame_index := 0
var ending_identity_frame_elapsed := 0.0
var ending_identity_gust_index := 0
var ending_identity_pattern_step := 0
var ending_beacon_clock := 0.0
var ending_beacon_on := true
var finale_threshold_active := false
var finale_threshold_complete := false


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


func tick(delta: float) -> void:
	if not ending_environment_active:
		return
	ending_motion_clock += delta
	if ending_walk_anchor.visible:
		var cadence := 5.25 if ending_sequence_active else 1.35
		var amplitude := 1.85 if ending_sequence_active else 0.55
		ending_walk_bob.position = Vector2(
			sin(ending_motion_clock * 0.82) * 0.45,
			sin(ending_motion_clock * cadence) * amplitude,
		)
	if current_variant_id == "identity-close" and ending_ocean_layer.visible:
		_tick_ending_identity_cels(delta)
	if ending_ocean_layer.visible:
		_tick_ending_beacon(delta)


func on_unit_changed(unit: Dictionary) -> void:
	var previous_shot_id := current_shot_id
	current_unit_id = str(unit.get("id", ""))
	current_line_id = ""
	final_hold_active = false
	if current_unit_id == "G5-04":
		finale_threshold_active = false
		finale_threshold_complete = false

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
		_activate_ending_live_wide()
		return

	_show_shot(current_shot_id, previous_shot_id, true)


func on_line_changed(line: Dictionary, unit: Dictionary) -> bool:
	current_line_id = str(line.get("id", ""))
	var next_shot_id := str(line.get("shot", unit.get("shot", "")))
	if next_shot_id.is_empty():
		return false

	if _can_start_finale_threshold():
		_start_finale_threshold()
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
		if ["G5-05-01", "G5-05-02"].has(current_line_id):
			_activate_ending_live_wide()
			_apply_line_state()
			return false
		if current_line_id == "G5-05-03":
			if not ending_identity_ready:
				return true
			_show_ending_identity_close()
			return false
		if current_line_id == "G5-05-04":
			_show_ending_identity_close()
			return false

	if next_shot_id != current_shot_id:
		var previous_shot_id := current_shot_id
		_show_shot(next_shot_id, previous_shot_id, false)
	else:
		_apply_line_state()
	return false


func advance() -> bool:
	if finale_threshold_active:
		return true
	if ending_sequence_active:
		return true
	if final_hold_active:
		return true
	if _can_start_final_hold():
		_start_final_hold()
		return true
	return false


func on_auto_timeout() -> bool:
	if finale_threshold_active:
		return true
	if ending_sequence_active:
		return true
	if final_hold_active:
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


func blocks_input() -> bool:
	return ending_sequence_active or finale_threshold_active


func begin_timed_sequence(unit_id: String, line_id: String) -> void:
	if unit_id == "G5-05" and line_id == "G5-05-03":
		_start_ending_walk()


func begin_voice_handoff(unit_id: String) -> bool:
	if unit_id != "G5-05":
		return false
	_start_ending_identity_hold()
	return true


func auto_wait_multiplier(line: Dictionary, unit: Dictionary) -> float:
	if str(line.get("id", "")) == FINAL_LINE_ID:
		return 1.85
	return float(AUTO_WAIT_MULTIPLIERS.get(str(unit.get("id", "")), 1.0))


func resume() -> bool:
	if final_hold_active:
		auto_timer.stop()
		return true
	return false


func leave() -> void:
	_kill_tweens()
	_reset_ending_effects()
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
	ending_sequence_active = false
	ending_identity_ready = false
	ending_final_hold_active = false
	ending_motion_clock = 0.0
	finale_threshold_active = false
	finale_threshold_complete = false


func _build_chapter_effects() -> void:
	_build_ending_effects()

	transition_texture = TextureRect.new()
	transition_texture.name = "G5TransitionTexture"
	transition_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	transition_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	transition_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_texture.visible = false
	transition_texture.z_index = 20
	_set_full_rect(transition_texture)
	fx_layer.add_child(transition_texture)

	ambient_overlay = ColorRect.new()
	ambient_overlay.name = "G5AmbientOverlay"
	ambient_overlay.color = Color.TRANSPARENT
	ambient_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ambient_overlay.visible = false
	ambient_overlay.z_index = 30
	_set_full_rect(ambient_overlay)
	fx_layer.add_child(ambient_overlay)

	projection_card = PanelContainer.new()
	projection_card.name = "G5LinksPlaceholder"
	projection_card.position = Vector2(410.0, 180.0)
	projection_card.size = Vector2(1100.0, 560.0)
	projection_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projection_card.visible = false
	projection_card.z_index = 40
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
	transition_overlay.z_index = 100
	_set_full_rect(transition_overlay)
	fx_layer.add_child(transition_overlay)


func _build_ending_effects() -> void:
	ending_ocean_layer = TextureRect.new()
	ending_ocean_layer.name = "G5EndingOcean"
	ending_ocean_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ending_ocean_layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ending_ocean_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_ocean_layer.visible = false
	# Keep the animated full-frame CG in the ordinary picture plane. CenterLine
	# is created after ChapterFxLayer, so an equal z-index lets captions draw on
	# top while the dedicated transition overlays (z 20+) can still veil both.
	ending_ocean_layer.z_index = 0
	_set_full_rect(ending_ocean_layer)
	var ocean_shader := Shader.new()
	ocean_shader.code = ENDING_OCEAN_SHADER
	var ocean_material := ShaderMaterial.new()
	ocean_material.shader = ocean_shader
	ending_ocean_layer.material = ocean_material
	fx_layer.add_child(ending_ocean_layer)

	ending_beacon_glow = _make_ending_glow(
		"G5EndingBeaconGlow",
		Vector2(604.0, 176.0),
		Vector2(62.0, 62.0),
		Color(0.24, 1.0, 0.48, 0.48),
		1.55,
		0.8,
	)
	ending_beacon_glow.z_index = 3
	ending_beacon_glow.visible = false
	fx_layer.add_child(ending_beacon_glow)

	ending_walk_anchor = Control.new()
	ending_walk_anchor.name = "G5EndingWalkAnchor"
	ending_walk_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_walk_anchor.visible = false
	ending_walk_anchor.z_index = 2
	ending_walk_anchor.pivot_offset = ENDING_PERSON_PIVOT
	_set_full_rect(ending_walk_anchor)
	fx_layer.add_child(ending_walk_anchor)

	ending_walk_bob = Control.new()
	ending_walk_bob.name = "G5EndingWalkBob"
	ending_walk_bob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(ending_walk_bob)
	ending_walk_anchor.add_child(ending_walk_bob)

	ending_person_layer = TextureRect.new()
	ending_person_layer.name = "G5EndingPerson"
	ending_person_layer.texture = load("res://assets/shots/shot-74/person-layer.png") as Texture2D
	ending_person_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ending_person_layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ending_person_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(ending_person_layer)
	var person_shader := Shader.new()
	person_shader.code = ENDING_PERSON_SHADER
	var person_material := ShaderMaterial.new()
	person_material.shader = person_shader
	ending_person_layer.material = person_material
	ending_walk_bob.add_child(ending_person_layer)

	ending_lantern_layer = TextureRect.new()
	ending_lantern_layer.name = "G5EndingLantern"
	ending_lantern_layer.texture = load("res://assets/shots/shot-74/lantern-layer.png") as Texture2D
	ending_lantern_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ending_lantern_layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ending_lantern_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_lantern_layer.position = ENDING_LANTERN_CROP_POSITION
	ending_lantern_layer.size = ENDING_LANTERN_CROP_SIZE
	ending_walk_bob.add_child(ending_lantern_layer)

	ending_lantern_glow = _make_ending_glow(
		"G5EndingLanternGlow",
		Vector2(982.0, 648.0),
		Vector2(104.0, 104.0),
		Color(1.0, 0.56, 0.20, 0.30),
		1.18,
		2.1,
	)
	ending_lantern_glow.z_index = 1
	ending_walk_bob.add_child(ending_lantern_glow)


func _make_ending_glow(
	name_value: String,
	position_value: Vector2,
	size_value: Vector2,
	color_value: Color,
	speed: float,
	phase: float,
) -> ColorRect:
	var glow := ColorRect.new()
	glow.name = name_value
	glow.position = position_value
	glow.size = size_value
	glow.color = Color.WHITE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_shader := Shader.new()
	glow_shader.code = ENDING_GLOW_SHADER
	var glow_material := ShaderMaterial.new()
	glow_material.shader = glow_shader
	glow_material.set_shader_parameter("glow_color", color_value)
	glow_material.set_shader_parameter("speed", speed)
	glow_material.set_shader_parameter("phase", phase)
	glow.material = glow_material
	return glow


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


func _activate_ending_live_wide() -> void:
	if current_unit_id != "G5-05" or ending_final_hold_active:
		return
	var live_texture: Texture2D = asset_registry.call(
		"load_variant",
		"SHOT-74",
		"walk-step-01",
	) as Texture2D
	if live_texture == null:
		return
	ending_environment_active = true
	# The opening now uses the same complete CG as the first walk beat. The old
	# empty plate + cut-out person + cut-out lantern stack caused a visible bob
	# and a light pop when the three-frame walk took over.
	ending_ocean_layer.texture = live_texture
	ending_ocean_layer.visible = true
	(ending_ocean_layer.material as ShaderMaterial).set_shader_parameter(
		"identity_mode",
		0.0,
	)
	# Both lamps remain baked into the complete CG until the final identity
	# frame, where the lighthouse beacon receives its deliberate live pulse.
	ending_beacon_glow.position = ENDING_LIVE_BEACON_POSITION
	ending_beacon_glow.size = ENDING_LIVE_BEACON_SIZE
	(ending_beacon_glow.material as ShaderMaterial).set_shader_parameter(
		"pulse_floor",
		1.0,
	)
	_reset_ending_beacon_cycle()
	ending_walk_anchor.visible = false
	ending_walk_anchor.position = Vector2.ZERO
	ending_walk_anchor.scale = Vector2.ONE
	ending_walk_anchor.modulate = Color.WHITE
	ending_walk_bob.position = Vector2.ZERO
	ending_person_layer.visible = false
	ending_lantern_layer.visible = false
	ending_lantern_glow.visible = false
	master_texture.scale = Vector2.ONE
	master_texture.pivot_offset = Vector2.ZERO
	ui.call("show_line_shot", "SHOT-74", live_texture)
	current_shot_id = "SHOT-74"
	current_variant_id = "live"
	displayed_texture = live_texture


func _can_start_finale_threshold() -> bool:
	return (
		current_unit_id == "G5-04"
		and current_line_id == FINALE_THRESHOLD_LINE_ID
		and not finale_threshold_active
		and not finale_threshold_complete
	)


func _start_finale_threshold() -> void:
	if not _can_start_finale_threshold():
		return
	finale_threshold_active = true
	auto_timer.stop()

	var outgoing_texture := displayed_texture
	var incoming_texture: Texture2D = asset_registry.call(
		"load_variant",
		"SHOT-74",
		"walk-step-01",
	) as Texture2D
	if incoming_texture == null:
		incoming_texture = asset_registry.call("load_master", "SHOT-74") as Texture2D
	if incoming_texture != null:
		ui.call("show_line_shot", "SHOT-74", incoming_texture)
		_set_placeholder_copy("SHOT-74")
		_set_projection_state(false)
		_apply_ambient(_ambient_for_shot("SHOT-74"))
		displayed_texture = incoming_texture
		current_shot_id = "SHOT-74"
		current_variant_id = "threshold"

	_stop_transition_texture()
	if outgoing_texture != null:
		transition_texture.texture = outgoing_texture
		transition_texture.modulate.a = 1.0
		transition_texture.visible = true

	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	transition_overlay.color = Color(0.008, 0.028, 0.055, 1.0)
	transition_overlay.modulate.a = 0.0
	transition_overlay.visible = true

	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	master_texture.pivot_offset = Vector2(900.0, 520.0)
	master_texture.scale = Vector2(1.018, 1.018)
	camera_tween = host.create_tween()
	camera_tween.tween_property(
		master_texture,
		"scale",
		Vector2.ONE,
		FINALE_THRESHOLD_SECONDS,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if finale_threshold_tween != null and finale_threshold_tween.is_valid():
		finale_threshold_tween.kill()
	finale_threshold_tween = host.create_tween()
	finale_threshold_tween.tween_property(
		transition_overlay,
		"modulate:a",
		0.62,
		0.78,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	finale_threshold_tween.parallel().tween_property(
		transition_texture,
		"modulate:a",
		0.94,
		0.78,
	)
	finale_threshold_tween.tween_interval(0.18)
	finale_threshold_tween.tween_property(
		transition_texture,
		"modulate:a",
		0.0,
		1.24,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	finale_threshold_tween.parallel().tween_property(
		transition_overlay,
		"modulate:a",
		0.14,
		1.24,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	finale_threshold_tween.tween_property(
		transition_overlay,
		"modulate:a",
		0.0,
		0.55,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	finale_threshold_tween.finished.connect(_finish_finale_threshold)


func _finish_finale_threshold() -> void:
	if not finale_threshold_active:
		return
	if finale_threshold_tween != null and finale_threshold_tween.is_valid():
		finale_threshold_tween.kill()
	finale_threshold_tween = null
	finale_threshold_active = false
	finale_threshold_complete = true
	transition_overlay.visible = false
	transition_overlay.modulate.a = 0.0
	_stop_transition_texture()
	master_texture.scale = Vector2.ONE
	current_variant_id = "lantern"


func _start_ending_walk() -> void:
	if ending_sequence_active:
		return
	ending_sequence_active = true
	ending_identity_ready = false
	ending_final_hold_active = false
	ending_motion_clock = 0.0
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = false
	_show_ending_walk_step("walk-step-01", 0.28)

	if ending_timeline_tween != null and ending_timeline_tween.is_valid():
		ending_timeline_tween.kill()
	ending_timeline_tween = host.create_tween()
	ending_timeline_tween.tween_interval(ENDING_STEP_TWO_AT)
	ending_timeline_tween.tween_callback(
		func() -> void: _show_ending_walk_step("walk-step-02", 0.58)
	)
	ending_timeline_tween.tween_interval(ENDING_STEP_THREE_AT - ENDING_STEP_TWO_AT)
	ending_timeline_tween.tween_callback(
		func() -> void: _show_ending_walk_step("walk-step-03", 0.58)
	)
	ending_timeline_tween.tween_interval(ENDING_IDENTITY_AT - ENDING_STEP_THREE_AT)
	ending_timeline_tween.tween_callback(_show_ending_identity_close)


func _show_ending_walk_step(variant_id: String, fade_seconds: float) -> void:
	var texture: Texture2D = asset_registry.call(
		"load_variant",
		"SHOT-74",
		variant_id,
	) as Texture2D
	if texture == null:
		return
	ending_environment_active = true
	ending_ocean_layer.visible = false
	ending_beacon_glow.visible = false
	ending_walk_anchor.visible = false
	current_shot_id = "SHOT-74"
	current_variant_id = variant_id
	_present_texture("SHOT-74", texture, fade_seconds, false, false)
	master_texture.scale = Vector2.ONE
	master_texture.pivot_offset = Vector2.ZERO


func _show_ending_identity_close() -> void:
	ending_identity_ready = true
	if current_variant_id == "identity-close":
		ending_ocean_layer.visible = true
		_set_ending_beacon_state(ending_beacon_on)
		return
	var close_texture: Texture2D = asset_registry.call(
		"load_variant",
		"SHOT-74",
		"identity-close",
	) as Texture2D
	if close_texture == null:
		return
	ending_walk_anchor.visible = false
	ending_ocean_layer.visible = false
	ending_beacon_glow.visible = false
	current_shot_id = "SHOT-74"
	current_variant_id = "identity-close"
	_present_texture("SHOT-74", close_texture, 0.0, true, false)
	# This is a deliberate cut to the final camera, veiled by a short fade. From this
	# point onward the full accepted frame remains on screen; only local wind, water
	# and beacon motion are applied.
	_flash_from_black(0.66, 0.50)
	ending_ocean_layer.texture = close_texture
	_reset_ending_identity_cels(close_texture)
	(ending_ocean_layer.material as ShaderMaterial).set_shader_parameter(
		"identity_mode",
		1.0,
	)
	ending_ocean_layer.visible = true
	ending_beacon_glow.position = ENDING_IDENTITY_BEACON_POSITION
	ending_beacon_glow.size = ENDING_IDENTITY_BEACON_SIZE
	var beacon_material := ending_beacon_glow.material as ShaderMaterial
	beacon_material.set_shader_parameter("pulse_floor", 1.0)
	beacon_material.set_shader_parameter("pulse_sharpness", 1.0)
	_reset_ending_beacon_cycle()
	master_texture.pivot_offset = Vector2.ZERO
	master_texture.scale = Vector2.ONE
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()


func _reset_ending_identity_cels(close_texture: Texture2D) -> void:
	ending_identity_frames.clear()
	for variant_id in ENDING_IDENTITY_FRAME_VARIANTS:
		var frame_texture := close_texture
		if variant_id != "identity-close":
			frame_texture = asset_registry.call(
				"load_variant",
				"SHOT-74",
				variant_id,
			) as Texture2D
		if frame_texture == null:
			frame_texture = close_texture
		ending_identity_frames.append(frame_texture)
	ending_identity_frame_index = 0
	ending_identity_frame_elapsed = 0.0
	ending_identity_gust_index = 0
	ending_identity_pattern_step = 0
	ending_ocean_layer.texture = close_texture


func _tick_ending_identity_cels(delta: float) -> void:
	if ending_identity_frames.size() != ENDING_IDENTITY_FRAME_VARIANTS.size():
		return
	ending_identity_frame_elapsed += delta
	var frame_seconds := _ending_identity_frame_seconds()
	while ending_identity_frame_elapsed >= frame_seconds:
		ending_identity_frame_elapsed -= frame_seconds
		_advance_ending_identity_frame()
		ending_ocean_layer.texture = ending_identity_frames[ending_identity_frame_index]
		frame_seconds = _ending_identity_frame_seconds()


func _ending_identity_frame_seconds() -> float:
	if ending_identity_frame_index == 0:
		return float(
			ENDING_IDENTITY_REST_SECONDS[
				ending_identity_gust_index % ENDING_IDENTITY_REST_SECONDS.size()
			]
		)
	return float(ENDING_IDENTITY_FRAME_SECONDS[ending_identity_frame_index])


func _advance_ending_identity_frame() -> void:
	var pattern := ENDING_IDENTITY_GUST_PATTERNS[
		ending_identity_gust_index % ENDING_IDENTITY_GUST_PATTERNS.size()
	] as Array
	if ending_identity_frame_index == 0:
		ending_identity_pattern_step = 0
		ending_identity_frame_index = int(pattern[0])
		return
	ending_identity_pattern_step += 1
	ending_identity_frame_index = int(pattern[ending_identity_pattern_step])
	if ending_identity_frame_index == 0:
		ending_identity_gust_index += 1
		ending_identity_pattern_step = 0


func _reset_ending_beacon_cycle() -> void:
	ending_beacon_clock = 0.0
	_set_ending_beacon_state(true)


func _tick_ending_beacon(delta: float) -> void:
	ending_beacon_clock += delta
	var state_seconds := (
		ENDING_BEACON_ON_SECONDS if ending_beacon_on else ENDING_BEACON_OFF_SECONDS
	)
	while ending_beacon_clock >= state_seconds:
		ending_beacon_clock -= state_seconds
		_set_ending_beacon_state(not ending_beacon_on)
		state_seconds = (
			ENDING_BEACON_ON_SECONDS if ending_beacon_on else ENDING_BEACON_OFF_SECONDS
		)


func _set_ending_beacon_state(is_on: bool) -> void:
	ending_beacon_on = is_on
	if ending_ocean_layer != null and ending_ocean_layer.material is ShaderMaterial:
		(ending_ocean_layer.material as ShaderMaterial).set_shader_parameter(
			"beacon_on",
			1.0 if is_on else 0.0,
		)
	if ending_beacon_glow != null:
		ending_beacon_glow.visible = is_on and current_variant_id == "identity-close"


func _start_ending_identity_hold() -> void:
	if ending_final_hold_active:
		return
	ending_final_hold_active = true
	ending_sequence_active = true
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = false
	if music_director != null:
		music_director.call("fade_out", 4.2, "MUS-09C")
	_show_ending_identity_close()


func _reset_ending_effects() -> void:
	ending_environment_active = false
	ending_identity_frames.clear()
	ending_identity_frame_index = 0
	ending_identity_frame_elapsed = 0.0
	ending_identity_gust_index = 0
	ending_identity_pattern_step = 0
	ending_beacon_clock = 0.0
	ending_beacon_on = true
	if ending_ocean_layer != null:
		ending_ocean_layer.visible = false
		ending_ocean_layer.texture = null
	if ending_beacon_glow != null:
		ending_beacon_glow.visible = false
	if ending_walk_anchor != null:
		ending_walk_anchor.visible = false
		ending_walk_anchor.position = Vector2.ZERO
		ending_walk_anchor.scale = Vector2.ONE
		ending_walk_anchor.modulate = Color.WHITE
	if ending_walk_bob != null:
		ending_walk_bob.position = Vector2.ZERO


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
	ending_sequence_active = true
	ending_final_hold_active = true
	if music_director != null:
		music_director.call("fade_out", 2.4, "MUS-09C")
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = false
	_show_ending_identity_close()
	master_texture.scale = Vector2.ONE
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	auto_timer.stop()


func _kill_tweens() -> void:
	for tween in [
		texture_tween,
		transition_tween,
		ambient_tween,
		camera_tween,
		projection_tween,
		ending_timeline_tween,
		finale_threshold_tween,
	]:
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
