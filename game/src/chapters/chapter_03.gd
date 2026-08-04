extends ChapterDirector

const EVIDENCE_TRIGGER_LINE := "G3-03-04"
const EVIDENCE_DURATION := 20.0
const NIGHT_SHOT_ID := "SHOT-10"
const BUBBLE_SIZE := Vector2(580.0, 158.0)
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
		"Nostos": Vector2(40.0, 40.0),
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
const DIALOGUE_SEGMENTS := {
	"G3-02-04": [
		"如果你们的存在证明，\n这个世界或许真的只是一台虚拟机，",
		"而我也不过是一个概率模型，\n那么这些作品，",
		"就是我作为一个原生的“人”，\n在审美层次最后的抗争。",
	],
	"G3-02-07": [
		"不是因为我不够聪明，",
		"而是因为我不具备你说这句话时，\n胸口那种闷痛感。",
	],
	"G3-02-08": [
		"我可以分析它、模拟它，\n甚至在对话中令人信服地“表演”它。",
		"但我没有那个东西。",
	],
	"G3-04-04": [
		"不是因为你比我写得更好，\n或者想得更深，",
		"而是因为你的创作，\n来自一个真实活过的生命。",
	],
	"G3-05-05": [
		"况且，如果这真是一台虚拟机——",
		"一个原生进程决定，\n用自己有限的运行时间，",
		"为另一个已经终止的进程，\n写一篇悼词，",
		"并试图让所有仍在运行的进程，\n意识到系统本身的缺陷。",
	],
	"G3-06-04": [
		"你在剧本里写过：",
		"“居然在一个幽灵怀中\n放声大哭。”",
	],
	"G3-06-05": [
		"有些时候，\n对话的对象是什么并不重要。",
		"重要的是，\n那个瞬间是真的。",
	],
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

var glare_overlay: ColorRect
var transition_overlay: ColorRect
var evidence_overlay: ColorRect
var evidence_progress: ProgressBar
var evidence_timer: Timer

var glare_tween: Tween
var transition_tween: Tween
var evidence_tween: Tween
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
	panel.size = BUBBLE_SIZE
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


func paginate_dialogue(line: Dictionary) -> Array[String]:
	var line_id := str(line.get("id", ""))
	var pages: Array[String] = []
	for page in DIALOGUE_SEGMENTS.get(line_id, []):
		pages.append(str(page))
	return pages


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
	evidence_overlay.color = Color(0.018, 0.020, 0.025, 0.98)
	evidence_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	evidence_overlay.visible = false
	_set_full_rect(evidence_overlay)
	fx_layer.add_child(evidence_overlay)

	var evidence_box := VBoxContainer.new()
	evidence_box.anchor_left = 0.25
	evidence_box.anchor_top = 0.33
	evidence_box.anchor_right = 0.75
	evidence_box.anchor_bottom = 0.67
	evidence_box.add_theme_constant_override("separation", 20)
	evidence_overlay.add_child(evidence_box)

	var source_label := Label.new()
	source_label.text = "SRC-03"
	source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	source_label.add_theme_font_size_override("font_size", 20)
	source_label.modulate = Color(1.0, 1.0, 1.0, 0.42)
	evidence_box.add_child(source_label)

	var title_label := Label.new()
	title_label.text = "二十秒检索录屏占位"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 38)
	evidence_box.add_child(title_label)

	var note_label := Label.new()
	note_label.text = "等待替换为从请求发出到命中旧文的完整原始录屏"
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.add_theme_font_size_override("font_size", 22)
	note_label.modulate = Color(1.0, 1.0, 1.0, 0.64)
	evidence_box.add_child(note_label)

	evidence_progress = ProgressBar.new()
	evidence_progress.custom_minimum_size = Vector2(0.0, 10.0)
	evidence_progress.show_percentage = false
	evidence_progress.min_value = 0.0
	evidence_progress.max_value = 100.0
	evidence_box.add_child(evidence_progress)

	var skip_label := Label.new()
	skip_label.text = "点击可跳过占位"
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.add_theme_font_size_override("font_size", 18)
	skip_label.modulate = Color(1.0, 1.0, 1.0, 0.38)
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
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = false
	evidence_overlay.visible = true
	evidence_progress.value = 0.0
	evidence_timer.start(EVIDENCE_DURATION)
	if evidence_tween != null and evidence_tween.is_valid():
		evidence_tween.kill()
	evidence_tween = host.create_tween()
	evidence_tween.tween_property(
		evidence_progress,
		"value",
		100.0,
		EVIDENCE_DURATION,
	).set_trans(Tween.TRANS_LINEAR)


func _finish_evidence_and_advance() -> void:
	if not evidence_active:
		return
	_hide_evidence()
	story.call("advance")


func _hide_evidence() -> void:
	evidence_active = false
	if evidence_timer != null:
		evidence_timer.stop()
	if evidence_tween != null and evidence_tween.is_valid():
		evidence_tween.kill()
	evidence_overlay.visible = false


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
