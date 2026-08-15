extends ChapterDirector

const EVIDENCE_TRIGGER_LINE := "G3-03-04"
const EVIDENCE_DURATION := 20.0
const NIGHT_SHOT_ID := "SHOT-10"
const DEFAULT_BUBBLE_POSITION := Vector2(40.0, 40.0)
const BUBBLE_POSITIONS := {
	"SHOT-32": {
		"Poros": Vector2(60.0, 520.0),
	},
	"SHOT-33": {
		"Ariadne": Vector2(40.0, 40.0),
	},
	"SHOT-34": {
		"Pothos": Vector2(40.0, 40.0),
	},
	"SHOT-35": {
		"Pharos": Vector2(40.0, 40.0),
	},
	"SHOT-36": {
		"Kairos": Vector2(1300.0, 40.0),
	},
	"SHOT-37": {
		# Nostos 站在左侧梯子上；文本放到右上墙面，不再遮挡人脸。
		"Nostos": Vector2(1280.0, 40.0),
	},
	"SHOT-38": {
		"Ousia": Vector2(1300.0, 40.0),
		"我": Vector2(40.0, 40.0),
	},
	"SHOT-09": {
		"少女 H": Vector2(1300.0, 40.0),
		"我": Vector2(40.0, 40.0),
	},
	"SHOT-39": {
		"少女 H": Vector2(1300.0, 40.0),
		"我": Vector2(660.0, 40.0),
	},
	"SHOT-40": {
		"少女 H": Vector2(1300.0, 40.0),
		"我": Vector2(40.0, 40.0),
	},
	"SHOT-41": {
		"少女 H": Vector2(1300.0, 40.0),
		"我": Vector2(40.0, 40.0),
	},
	"SHOT-11": {
		"少女 H": Vector2(670.0, 40.0),
	},
}
var host: Control
var fx_layer: Control
var master_texture: TextureRect
var dialogue_panel: PanelContainer
var dialogue_tail: Polygon2D
var center_line_label: Label
var story: RefCounted
var asset_registry: RefCounted
var ui
var music_director: Node

var glare_overlay: ColorRect
var transition_overlay: ColorRect
var evidence_overlay: ColorRect
var evidence_flash: ColorRect
var evidence_progress: ProgressBar
var evidence_timer: Timer
var evidence_fragments: Array[ColorRect] = []
var evidence_fragment_meta: Array[Dictionary] = []

var glare_tween: Tween
var transition_tween: Tween
var evidence_tween: Tween
var evidence_flash_tween: Tween
var current_unit_id := ""
var current_line_id := ""
var current_shot_id := ""
var evidence_active := false
var evidence_consumed := false


func _init() -> void:
	chapter_number = 3


func setup(director_context: Dictionary) -> void:
	super.setup(director_context)
	host = context.get("host") as Control
	fx_layer = context.get("fx_layer") as Control
	master_texture = context.get("master_texture") as TextureRect
	dialogue_panel = context.get("dialogue_panel") as PanelContainer
	dialogue_tail = context.get("dialogue_tail") as Polygon2D
	center_line_label = context.get("center_line_label") as Label
	story = context.get("story") as RefCounted
	asset_registry = context.get("asset_registry") as RefCounted
	ui = context.get("ui")
	music_director = context.get("music_director") as Node
	_build_chapter_effects()


func on_unit_changed(unit: Dictionary) -> void:
	_hide_evidence()
	current_unit_id = str(unit.get("id", ""))
	current_line_id = ""
	current_shot_id = str(unit.get("shot", ""))
	evidence_consumed = false
	_flash_for_shot(current_shot_id, true)
	_update_glare()


func on_line_changed(line: Dictionary, unit: Dictionary) -> bool:
	current_line_id = str(line.get("id", ""))
	if current_line_id == EVIDENCE_TRIGGER_LINE:
		evidence_consumed = false

	var next_shot_id := str(line.get("shot", unit.get("shot", "")))
	if not next_shot_id.is_empty() and next_shot_id != current_shot_id:
		current_shot_id = next_shot_id
		var texture: Texture2D = asset_registry.call("load_master", next_shot_id) as Texture2D
		ui.call("show_line_shot", next_shot_id, texture)
		_flash_for_shot(next_shot_id, false)
	_update_glare()
	return false


func advance() -> bool:
	if evidence_active:
		_finish_evidence_and_advance()
		return true
	if _can_start_evidence():
		_start_evidence()
		return true
	return false


func on_auto_timeout() -> bool:
	if evidence_active:
		return true
	if _can_start_evidence():
		_start_evidence()
		return true
	return false


func position_bubble(
	panel: PanelContainer,
	tail: Polygon2D,
	speaker: String,
	_text: String,
) -> bool:
	tail.visible = false
	var position := DEFAULT_BUBBLE_POSITION
	var shot_positions: Dictionary = BUBBLE_POSITIONS.get(current_shot_id, {})
	if shot_positions.has(speaker):
		position = shot_positions[speaker]
	panel.position = Vector2(
		clampf(position.x, 40.0, 1880.0 - panel.size.x),
		clampf(position.y, 40.0, 1010.0 - panel.size.y),
	)
	return true


func position_caption(label: Label, presentation: String) -> bool:
	label.offset_left = 0.0
	label.offset_top = 0.0
	label.offset_right = 0.0
	label.offset_bottom = 0.0
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_constant_override("line_spacing", 14)
	label.add_theme_constant_override("shadow_outline_size", 6)

	if presentation == "center":
		label.anchor_left = 0.18
		label.anchor_top = 0.03
		label.anchor_right = 0.82
		label.anchor_bottom = 0.20
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 42)
		label.add_theme_color_override("font_color", Color("#24242a"))
		label.add_theme_color_override(
			"font_shadow_color",
			Color(1.0, 1.0, 1.0, 0.94),
		)
		return true

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", 36)
	if current_shot_id == "SHOT-42":
		label.anchor_left = 0.04
		label.anchor_top = 0.07
		label.anchor_right = 0.48
		label.anchor_bottom = 0.29
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override(
			"font_shadow_color",
			Color(0.0, 0.0, 0.0, 0.96),
		)
	elif current_shot_id == "SHOT-09":
		label.anchor_left = 0.03
		label.anchor_top = 0.03
		label.anchor_right = 0.48
		label.anchor_bottom = 0.22
		label.add_theme_color_override("font_color", Color("#24242a"))
		label.add_theme_color_override(
			"font_shadow_color",
			Color(1.0, 1.0, 1.0, 0.96),
		)
	elif current_shot_id == NIGHT_SHOT_ID:
		label.anchor_left = 0.06
		label.anchor_top = 0.67
		label.anchor_right = 0.58
		label.anchor_bottom = 0.92
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override(
			"font_shadow_color",
			Color(0.0, 0.0, 0.0, 0.96),
		)
	else:
		label.anchor_left = 0.06
		label.anchor_top = 0.68
		label.anchor_right = 0.56
		label.anchor_bottom = 0.91
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override(
			"font_shadow_color",
			Color(0.0, 0.0, 0.0, 0.92),
		)
	return true


func uses_speaker_label() -> bool:
	return false


func leave() -> void:
	_hide_evidence()
	_stop_glare()
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	transition_overlay.visible = false
	current_unit_id = ""
	current_line_id = ""
	current_shot_id = ""
	evidence_consumed = false


func _build_chapter_effects() -> void:
	glare_overlay = ColorRect.new()
	glare_overlay.name = "G3GlareOverlay"
	glare_overlay.color = Color("#dbe4ff")
	glare_overlay.modulate.a = 0.0
	glare_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glare_overlay.visible = false
	_set_full_rect(glare_overlay)
	fx_layer.add_child(glare_overlay)

	transition_overlay = ColorRect.new()
	transition_overlay.name = "G3TransitionOverlay"
	transition_overlay.color = Color.BLACK
	transition_overlay.modulate.a = 0.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.visible = false
	_set_full_rect(transition_overlay)
	fx_layer.add_child(transition_overlay)

	evidence_overlay = ColorRect.new()
	evidence_overlay.name = "G3EvidenceOverlay"
	evidence_overlay.color = Color.WHITE
	evidence_overlay.material = _evidence_background_material()
	evidence_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	evidence_overlay.visible = false
	_set_full_rect(evidence_overlay)
	fx_layer.add_child(evidence_overlay)

	var fragment_layer := Control.new()
	fragment_layer.name = "MemoryIndexFragments"
	fragment_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(fragment_layer)
	evidence_overlay.add_child(fragment_layer)
	_build_evidence_fragments(fragment_layer)

	evidence_flash = ColorRect.new()
	evidence_flash.name = "HitFlash"
	evidence_flash.color = Color(0.82, 0.90, 1.0, 1.0)
	evidence_flash.modulate.a = 0.0
	evidence_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(evidence_flash)
	evidence_overlay.add_child(evidence_flash)

	var evidence_box := VBoxContainer.new()
	evidence_box.anchor_left = 0.25
	evidence_box.anchor_top = 0.33
	evidence_box.anchor_right = 0.75
	evidence_box.anchor_bottom = 0.67
	evidence_box.add_theme_constant_override("separation", 20)
	evidence_overlay.add_child(evidence_box)

	var source_label := Label.new()
	source_label.text = "旧作全文索引"
	source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	source_label.add_theme_font_size_override("font_size", 20)
	source_label.add_theme_constant_override("letter_spacing", 3)
	source_label.add_theme_color_override("font_color", Color("#263847"))
	source_label.modulate.a = 0.78
	evidence_box.add_child(source_label)

	var title_label := Label.new()
	title_label.text = "正在回读旧作"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 38)
	title_label.add_theme_color_override("font_color", Color("#0b1720"))
	title_label.add_theme_color_override("font_outline_color", Color(0.88, 0.93, 0.97, 0.34))
	title_label.add_theme_constant_override("outline_size", 3)
	evidence_box.add_child(title_label)

	var note_label := Label.new()
	note_label.text = "约 200,000 字  /  从记忆之外重新定位一句话"
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.add_theme_font_size_override("font_size", 22)
	note_label.add_theme_color_override("font_color", Color("#2a3b49"))
	note_label.modulate.a = 0.86
	evidence_box.add_child(note_label)

	evidence_progress = ProgressBar.new()
	evidence_progress.custom_minimum_size = Vector2(0.0, 7.0)
	evidence_progress.show_percentage = false
	evidence_progress.min_value = 0.0
	evidence_progress.max_value = 100.0
	var progress_background := StyleBoxFlat.new()
	progress_background.bg_color = Color(0.10, 0.16, 0.21, 0.24)
	progress_background.corner_radius_top_left = 2
	progress_background.corner_radius_top_right = 2
	progress_background.corner_radius_bottom_left = 2
	progress_background.corner_radius_bottom_right = 2
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = Color(0.20, 0.36, 0.47, 0.86)
	progress_fill.corner_radius_top_left = 2
	progress_fill.corner_radius_top_right = 2
	progress_fill.corner_radius_bottom_left = 2
	progress_fill.corner_radius_bottom_right = 2
	evidence_progress.add_theme_stylebox_override("background", progress_background)
	evidence_progress.add_theme_stylebox_override("fill", progress_fill)
	evidence_box.add_child(evidence_progress)

	var skip_label := Label.new()
	skip_label.text = "点击可跳过检索"
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.add_theme_font_size_override("font_size", 18)
	skip_label.add_theme_color_override("font_color", Color("#263847"))
	skip_label.modulate.a = 0.62
	evidence_box.add_child(skip_label)

	evidence_timer = Timer.new()
	evidence_timer.name = "G3EvidenceTimer"
	evidence_timer.one_shot = true
	evidence_timer.timeout.connect(_finish_evidence_and_advance)
	host.add_child(evidence_timer)


func _can_start_evidence() -> bool:
	return (
		current_line_id == EVIDENCE_TRIGGER_LINE
		and not evidence_consumed
		and center_line_label.visible
		and center_line_label.visible_characters == -1
	)


func _start_evidence() -> void:
	evidence_active = true
	evidence_consumed = true
	if music_director != null:
		music_director.call("play_cue_id", "MUS-05A")
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = false
	evidence_overlay.visible = true
	evidence_overlay.modulate.a = 0.0
	evidence_flash.modulate.a = 0.0
	evidence_progress.value = 0.0
	_set_evidence_progress(0.0)
	evidence_timer.start(EVIDENCE_DURATION)
	if evidence_tween != null and evidence_tween.is_valid():
		evidence_tween.kill()
	if evidence_flash_tween != null and evidence_flash_tween.is_valid():
		evidence_flash_tween.kill()
	evidence_tween = host.create_tween().set_parallel(true)
	evidence_tween.tween_property(
		evidence_overlay,
		"modulate:a",
		1.0,
		0.72,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	evidence_tween.tween_property(
		evidence_progress,
		"value",
		100.0,
		EVIDENCE_DURATION,
	).set_trans(Tween.TRANS_LINEAR)
	evidence_tween.tween_method(
		_set_evidence_progress,
		0.0,
		1.0,
		EVIDENCE_DURATION,
	).set_trans(Tween.TRANS_LINEAR)

	evidence_flash_tween = host.create_tween()
	evidence_flash_tween.tween_interval(18.35)
	evidence_flash_tween.tween_property(
		evidence_flash,
		"modulate:a",
		0.22,
		0.28,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	evidence_flash_tween.tween_property(
		evidence_flash,
		"modulate:a",
		0.0,
		0.95,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _finish_evidence_and_advance() -> void:
	if not evidence_active:
		return
	_hide_evidence()
	request_story_advance()


func _hide_evidence() -> void:
	evidence_active = false
	if evidence_timer != null:
		evidence_timer.stop()
	if evidence_tween != null and evidence_tween.is_valid():
		evidence_tween.kill()
	if evidence_flash_tween != null and evidence_flash_tween.is_valid():
		evidence_flash_tween.kill()
	_set_evidence_progress(0.0)
	evidence_flash.modulate.a = 0.0
	evidence_overlay.modulate.a = 1.0
	evidence_overlay.visible = false


func _set_evidence_progress(value: float) -> void:
	var normalized := clampf(value, 0.0, 1.0)
	if evidence_overlay == null or evidence_overlay.material == null:
		return
	(evidence_overlay.material as ShaderMaterial).set_shader_parameter(
		"progress",
		normalized,
	)
	_update_evidence_fragments(normalized)


func _build_evidence_fragments(fragment_layer: Control) -> void:
	evidence_fragments.clear()
	evidence_fragment_meta.clear()
	for index in range(30):
		var fragment := ColorRect.new()
		fragment.name = "IndexFragment%02d" % index
		fragment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fragment.color = Color(0.56, 0.72, 0.84, 1.0)
		fragment.pivot_offset = Vector2.ZERO
		fragment_layer.add_child(fragment)
		evidence_fragments.append(fragment)

		var side := -1.0 if index % 2 == 0 else 1.0
		var width := 82.0 + float((index * 67) % 250)
		var start_y := 72.0 + float((index * 127) % 880)
		var start_x := 42.0 + float((index * 31) % 180)
		if side > 0.0:
			start_x = 1878.0 - width - float((index * 31) % 180)
		evidence_fragment_meta.append({
			"side": side,
			"width": width,
			"start": Vector2(start_x, start_y),
			"row_offset": float((index % 7) - 3) * 8.0,
			"phase": float((index * 43) % 100) / 100.0,
		})
	_update_evidence_fragments(0.0)


func _update_evidence_fragments(progress: float) -> void:
	if evidence_fragments.is_empty():
		return
	var appear := smoothstep(0.02, 0.22, progress)
	var collapse := smoothstep(0.72, 0.97, progress)
	for index in range(evidence_fragments.size()):
		var fragment := evidence_fragments[index]
		var meta: Dictionary = evidence_fragment_meta[index]
		var side := float(meta["side"])
		var width := float(meta["width"])
		var phase := float(meta["phase"])
		var start: Vector2 = meta["start"]
		var approach_x := 960.0 + side * (300.0 + phase * 220.0)
		var approach_y := start.y + sin(progress * 5.0 + phase * 6.283) * 16.0
		var position := start.lerp(Vector2(approach_x, approach_y), progress * 0.72)
		var final_x := 960.0 + side * (35.0 + phase * 170.0)
		var final_y := 432.0 + float(meta["row_offset"])
		position = position.lerp(Vector2(final_x, final_y), collapse)
		fragment.position = position
		fragment.size = Vector2(
			lerpf(width, 56.0 + phase * 130.0, collapse),
			2.0 if index % 3 != 0 else 3.0,
		)
		var stagger := smoothstep(phase * 0.12, phase * 0.12 + 0.16, progress)
		fragment.modulate.a = appear * stagger * lerpf(0.22, 0.42, collapse)


func _evidence_background_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 lamp_center = vec2(0.43, 0.40);

float hash21(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec3 source = texture(screen_texture, SCREEN_UV).rgb;
	float luma = dot(source, vec3(0.299, 0.587, 0.114));
	vec3 color = mix(source, vec3(luma), 0.68) * vec3(0.34, 0.38, 0.44);

	vec2 lamp_delta = (uv - lamp_center) * vec2(1.7778, 1.0);
	float lamp_distance = length(lamp_delta);
	float lamp_halo = 1.0 - smoothstep(0.035, 0.42, lamp_distance);
	float lamp_core = 1.0 - smoothstep(0.018, 0.19, lamp_distance);
	float pulse = 0.5 + 0.5 * sin(TIME * 0.85);
	color += vec3(0.58, 0.66, 0.76) * lamp_halo * (0.18 + pulse * 0.055);
	color += vec3(0.80, 0.86, 0.94) * lamp_core * 0.18;

	float collapse = smoothstep(0.70, 0.96, progress);

	float scan_position = fract(TIME * 0.070 + progress * 0.20);
	float scan = exp(-abs(uv.y - scan_position) * 78.0);
	color += vec3(0.58, 0.73, 0.85) * scan * (0.025 + progress * 0.075);

	float ripple = 0.5 + 0.5 * sin(lamp_distance * 105.0 - TIME * 1.25);
	ripple *= (1.0 - smoothstep(0.11, 0.52, lamp_distance));
	ripple *= smoothstep(0.05, 0.17, lamp_distance);
	color += vec3(0.48, 0.61, 0.73) * ripple * (0.025 + progress * 0.035);

	float memory_line = exp(-abs(uv.y - lamp_center.y) * mix(18.0, 115.0, collapse));
	color += vec3(0.76, 0.84, 0.91) * memory_line * collapse * 0.16;

	float vignette_distance = length((uv - vec2(0.5)) * vec2(1.10, 0.92));
	float vignette = 1.0 - smoothstep(0.29, 0.84, vignette_distance);
	color *= mix(0.42, 1.0, vignette);

	vec2 pixel_cell = floor(uv * vec2(960.0, 540.0));
	float grain = hash21(pixel_cell + floor(TIME * 8.0)) - 0.5;
	color += grain * 0.018;

	COLOR = vec4(color, 1.0);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("progress", 0.0)
	return material


func _flash_for_shot(shot_id: String, unit_entry: bool) -> void:
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	var use_white := ["SHOT-38", "SHOT-39", "SHOT-11"].has(shot_id)
	transition_overlay.color = Color.WHITE if use_white else Color.BLACK
	transition_overlay.modulate.a = 0.90 if unit_entry else 0.56
	transition_overlay.visible = true
	transition_tween = host.create_tween()
	transition_tween.tween_property(
		transition_overlay,
		"modulate:a",
		0.0,
		0.62 if unit_entry else 0.34,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	transition_tween.finished.connect(
		func() -> void: transition_overlay.visible = false
	)


func _update_glare() -> void:
	if current_shot_id != NIGHT_SHOT_ID:
		_stop_glare()
		return
	if glare_overlay.visible:
		return
	glare_overlay.visible = true
	glare_overlay.modulate.a = 0.0
	glare_tween = host.create_tween().set_loops()
	glare_tween.tween_property(
		glare_overlay,
		"modulate:a",
		0.045,
		3.8,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glare_tween.tween_property(
		glare_overlay,
		"modulate:a",
		0.0,
		4.6,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_glare() -> void:
	if glare_tween != null and glare_tween.is_valid():
		glare_tween.kill()
	glare_overlay.modulate.a = 0.0
	glare_overlay.visible = false


func _set_full_rect(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
