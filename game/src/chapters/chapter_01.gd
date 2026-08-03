extends ChapterDirector

const OPENING_UNIT_ID := "G1-01"
const WORKSTATION_UNIT_ID := "G1-03"
const VLOG_UNIT_ID := "G1-04"
const REVERSE_UNIT_ID := "G1-05"
const CLOSEUP_UNIT_ID := "G1-06"
const VISUAL_VARIANTS := ["wake", "wash", "cats", "board", "drive", "arrive"]
const CAPTION_BREAK_PUNCTUATION := "，。！？；：、—"
const CAPTION_BREAK_MARKERS := {
	"G1-01-02": ["日。", "一天。"],
	"G1-01-03": ["清晰，"],
	"G1-01-04": ["清晰，"],
	"G1-01-05": ["印象，", "开始，"],
	"G1-01-06": ["一次重复，"],
	"G1-01-07": ["往常一样，"],
	"G1-01-08": ["洗脸，"],
	"G1-01-09": ["没变，"],
	"G1-01-10": ["今天，"],
	"G1-01-11": ["变得"],
	"G1-01-12": ["和", "相关，"],
	"G1-01-13": ["受不了", "城市，"],
	"G1-01-14": ["主人，", "心态"],
	"G1-01-15": ["上车，"],
	"G1-01-16": ["破晓，"],
	"G1-01-17": ["改变，", "帅，"],
	"G1-01-18": ["赚钱，", "好好过日子，", "有时间"],
	"G1-01-19": ["公司，", "职级，"],
	"G1-01-20": ["下去。"],
	"G1-01-22": ["是啊，", "十二年了，"],
	"G1-01-23": ["很多事，"],
	"G1-01-24": ["明白。"],
}
const G1_DIALOGUE_SEGMENTS := {
	"G1-02-01": [
		"这块我看过了，技术上没啥本质问题，\n说白了技术他就不太重要。",
	],
	"G1-02-02": [
		"老板上次说的其实\n已经点到本质了。",
		"她看的是业务全局，\n我们手里这些数据，只能说明局部。",
	],
	"G1-02-03": [
		"现在结果不太好，\n不代表老板的方向错了。",
		"更可能是我们的方案\n还没跟上。",
	],
	"G1-02-04": [
		"方向已经定了，这时候再纠结对不对，\n其实意义不大。",
	],
	"G1-02-05": [
		"今天加班出个方案吧，\n明早开会和她对一对。",
	],
	"G1-03-01": [
		"不是突然不做了，只是优先级调低。\n毕竟老板也有她的考量。",
	],
	"G1-03-02": [
		"这样吧，这个方案先归档。",
		"今晚我们再努努力\n出下一个方案。",
	],
	"G1-03-03": [
		"然后也争取有个Demo可以演示。",
		"不行就加班吧，\n也没办法。",
	],
	"G1-03-04": [
		"后面真有偏差，\n完整的决策过程也都在。",
		"没问题，\n我来推。",
	],
	"G1-04-01": [
		"大家好！\n我是瞬光！",
	],
	"G1-04-02": [
		"哇，这个地方真的好美啊！\n就像是仙境一样。",
	],
	"G1-04-03": [
		"你们看后面，太阳出来以后，\n整个山一下就亮了。",
		"随手拍都特别好看！",
	],
	"G1-04-04": [
		"还有这个云海，\n就像是仙境一样。",
		"仙人的住所也不过如此！",
	],
	"G1-04-05": [
		"真的，照片根本拍不出来。",
		"你们有机会的话，一定要自己来一次。\n我用人格保证！",
	],
	"G1-04-06": [
		"今天就先带你们看到这里啦。\n我们下一个地方见。",
	],
	"G1-06-01": [
		"装明白也好，装糊涂也好，\n本质都是一码事。",
	],
	"G1-06-02": [
		"顺着他们，我会更安全，\n也会更轻松。",
	],
	"G1-06-03": [
		"而那种安全，\n恰恰是我从小最缺失，",
		"也花了十几年\n才得到的东西。",
	],
	"G1-06-04": [
		"但是，我总是学不会装糊涂，\n总想把东西搞明白。",
	],
	"G1-06-05": [
		"逐渐，我理解了一切，\n理解他们为什么要那么做。",
		"但理解\n并不代表明白。",
	],
	"G1-06-06": [
		"我想，既然不明白，\n那就放弃吧。",
	],
}

var host: Control
var story: RefCounted
var asset_registry: RefCounted
var fx_layer: Control
var dialogue_panel: PanelContainer
var dialogue_tail: Polygon2D
var center_line_label: Label
var auto_timer: Timer

var opening_backdrop: ColorRect
var opening_texture: TextureRect
var opening_placeholder: Label
var visual_textures: Dictionary = {}
var g1_split_root: Control
var g1_split_left: TextureRect
var g1_split_right: TextureRect

var current_unit_id := ""
var current_line_id := ""
var current_beats: Array[Dictionary] = []
var current_beat_index := 0
var current_visual_id := ""
var text_tween: Tween
var visual_tween: Tween
var waiting := false
var transitioning := false
var revealing := false
var sequence_token := 0


func _init() -> void:
	chapter_number = 1


func setup(director_context: Dictionary) -> void:
	super.setup(director_context)
	host = context.get("host") as Control
	story = context.get("story") as RefCounted
	asset_registry = context.get("asset_registry") as RefCounted
	fx_layer = context.get("fx_layer") as Control
	dialogue_panel = context.get("dialogue_panel") as PanelContainer
	dialogue_tail = context.get("dialogue_tail") as Polygon2D
	center_line_label = context.get("center_line_label") as Label
	auto_timer = context.get("auto_timer") as Timer

	opening_backdrop = ColorRect.new()
	opening_backdrop.name = "OpeningBackdrop"
	opening_backdrop.color = Color.BLACK
	opening_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_backdrop.visible = false
	_set_full_rect(opening_backdrop)
	fx_layer.add_child(opening_backdrop)

	opening_texture = TextureRect.new()
	opening_texture.name = "OpeningTexture"
	opening_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	opening_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	opening_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_texture.visible = false
	_set_full_rect(opening_texture)
	fx_layer.add_child(opening_texture)

	opening_placeholder = Label.new()
	opening_placeholder.name = "OpeningPlaceholder"
	opening_placeholder.anchor_left = 0.30
	opening_placeholder.anchor_top = 0.36
	opening_placeholder.anchor_right = 0.70
	opening_placeholder.anchor_bottom = 0.64
	opening_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opening_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	opening_placeholder.add_theme_font_size_override("font_size", 34)
	opening_placeholder.add_theme_constant_override("line_spacing", 12)
	opening_placeholder.modulate = Color(1.0, 1.0, 1.0, 0.42)
	opening_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_placeholder.visible = false
	fx_layer.add_child(opening_placeholder)
	_build_g1_split_layer()


func on_unit_changed(unit: Dictionary) -> void:
	_cancel_sequence()
	current_unit_id = str(unit.get("id", ""))
	current_line_id = ""
	_hide_opening_visuals()
	_hide_g1_split()
	visual_textures.clear()

	var shot_id := str(unit.get("shot", ""))
	match current_unit_id:
		OPENING_UNIT_ID:
			_load_variants(shot_id, VISUAL_VARIANTS)
			opening_backdrop.visible = true
			opening_backdrop.color = Color.BLACK
		WORKSTATION_UNIT_ID:
			_load_variants(shot_id, ["base", "reflection"])
		VLOG_UNIT_ID:
			_load_variants(shot_id, ["point", "thumb"])
		REVERSE_UNIT_ID:
			_show_g1_split(true)
		CLOSEUP_UNIT_ID:
			_load_variants(shot_id, ["closed", "open"])


func on_line_changed(line: Dictionary, _unit: Dictionary) -> bool:
	current_line_id = str(line.get("id", ""))
	var line_number := current_line_id.get_slice("-", 2).to_int()
	match current_unit_id:
		WORKSTATION_UNIT_ID:
			_set_g1_overlay("reflection" if line_number >= 4 else "")
			return false
		VLOG_UNIT_ID:
			_set_g1_overlay("thumb" if line_number >= 4 else "")
			return false
		REVERSE_UNIT_ID:
			_show_g1_split(line_number <= 1)
			return false
		CLOSEUP_UNIT_ID:
			_set_g1_overlay("open" if line_number >= 6 else "")
			return false
		OPENING_UNIT_ID:
			pass
		_:
			return false

	_cancel_line_state()
	current_beats = _beats_for_line(current_line_id, str(line.get("text", "")))
	current_beat_index = 0

	var first_beat := current_beats[0]
	var prelude := str(first_beat.get("prelude", ""))
	if not prelude.is_empty():
		_start_prelude(prelude)
	else:
		_show_current_beat()
	return true


func handles_custom_reveal() -> bool:
	return current_unit_id == OPENING_UNIT_ID


func advance() -> bool:
	if not handles_custom_reveal():
		return false
	if waiting:
		_skip_prelude()
		return true
	if transitioning:
		return true
	if revealing:
		finish_reveal()
		return true

	_advance_opening()
	return true


func finish_reveal() -> bool:
	if not handles_custom_reveal() or not revealing:
		return false
	if text_tween != null and text_tween.is_valid():
		text_tween.kill()
	center_line_label.visible_characters = -1
	center_line_label.modulate.a = 1.0
	revealing = false
	_schedule_auto_advance(_hold_seconds())
	return true


func on_auto_timeout() -> bool:
	if not handles_custom_reveal() or not _is_auto_enabled():
		return false
	if waiting:
		_skip_prelude()
	else:
		_advance_opening()
	return true


func position_caption(label: Label, _presentation: String) -> bool:
	if current_unit_id == REVERSE_UNIT_ID:
		label.offset_left = 0.0
		label.offset_top = 0.0
		label.offset_right = 0.0
		label.offset_bottom = 0.0
		label.anchor_left = 0.12
		label.anchor_top = 0.08
		label.anchor_right = 0.88
		label.anchor_bottom = 0.28
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 42)
		label.add_theme_constant_override("line_spacing", 14)
		return true
	return handles_custom_reveal()


func paginate_dialogue(line: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for segment in G1_DIALOGUE_SEGMENTS.get(str(line.get("id", "")), []):
		result.append(str(segment))
	return result


func position_bubble(
	panel: PanelContainer,
	tail: Polygon2D,
	_speaker: String,
	_text: String,
) -> bool:
	match current_unit_id:
		"G1-02":
			_place_dialogue_card(panel, tail, Vector2(470.0, 38.0))
			return true
		WORKSTATION_UNIT_ID:
			_place_dialogue_card(panel, tail, Vector2(60.0, 42.0))
			return true
		VLOG_UNIT_ID:
			_place_dialogue_card(panel, tail, Vector2(1220.0, 42.0))
			return true
		CLOSEUP_UNIT_ID:
			_place_dialogue_card(panel, tail, Vector2(70.0, 106.0))
			return true
		_:
			return false


func _place_dialogue_card(
	panel: PanelContainer,
	tail: Polygon2D,
	card_position: Vector2,
) -> void:
	# 同一张 CG 内使用固定画幅。文字分页时只替换内容，不再重算卡片边界。
	panel.position = card_position
	panel.size = Vector2(620.0, 158.0)
	# 这些镜头以构图和固定位置识别发声者，不使用会造成错误空间指向的尖角。
	tail.visible = false


func resume() -> bool:
	if (
		not handles_custom_reveal()
		or waiting
		or transitioning
		or revealing
		or not center_line_label.visible
		or not _is_auto_enabled()
	):
		return false
	_schedule_auto_advance(_hold_seconds())
	return true


func leave() -> void:
	_cancel_sequence()
	_hide_opening_visuals()
	_hide_g1_split()
	if center_line_label != null:
		center_line_label.modulate.a = 1.0
		center_line_label.visible_characters = -1


func _beats_for_line(line_id: String, text: String) -> Array[Dictionary]:
	var line_number := line_id.get_slice("-", 2).to_int()
	if line_number == 1:
		return [{
			"text": text,
			"visual": "black",
			"prelude": "梦境画面\n（占位）",
		}]
	if line_number <= 6:
		return [{"text": text, "visual": "wake"}]
	if line_number <= 10:
		return [{"text": text, "visual": "wash"}]
	if line_number <= 14:
		return [{"text": text, "visual": "cats"}]
	if line_number <= 17:
		return [{"text": text, "visual": "board"}]
	if line_number <= 20:
		return [{"text": text, "visual": "drive"}]
	if line_number == 21:
		return [{
			"text": text,
			"visual": "black",
			"prelude": "drive",
		}]
	if line_number <= 24:
		return [{"text": text, "visual": "arrive"}]
	return [{"text": text, "visual": "placeholder"}]


func _start_prelude(prelude: String) -> void:
	waiting = true
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = false

	if prelude == "drive":
		_set_visual("drive")
	else:
		_show_placeholder(prelude)
	_schedule_auto_advance(0.9)


func _skip_prelude() -> void:
	sequence_token += 1
	waiting = false
	_show_current_beat()


func _show_current_beat() -> void:
	if current_beats.is_empty():
		return
	var beat := current_beats[current_beat_index]
	_set_visual(str(beat.get("visual", "placeholder")))
	_show_caption(str(beat.get("text", "")))


func _show_caption(text: String) -> void:
	dialogue_panel.visible = false
	dialogue_tail.visible = false
	center_line_label.visible = not text.is_empty()
	center_line_label.text = _format_caption(text)
	center_line_label.visible_characters = -1
	_position_opening_caption()
	center_line_label.modulate = Color(0.97, 0.97, 0.94, 0.0)
	revealing = true

	if text_tween != null and text_tween.is_valid():
		text_tween.kill()
	text_tween = host.create_tween()
	text_tween.set_trans(Tween.TRANS_QUAD)
	text_tween.set_ease(Tween.EASE_OUT)
	text_tween.tween_property(center_line_label, "modulate:a", 1.0, 0.18)
	text_tween.finished.connect(_finish_caption_fade)


func _format_caption(text: String) -> String:
	var markers := CAPTION_BREAK_MARKERS.get(current_line_id, []) as Array
	if not markers.is_empty():
		var marked_text := _break_after_markers(text, markers)
		if not marked_text.is_empty():
			return marked_text

	var max_chars := _caption_line_width()
	var lines: Array[String] = []
	var remaining := text.strip_edges()
	while remaining.length() > max_chars:
		var cut := -1
		var back_limit := maxi(6, max_chars - 5)
		for index in range(max_chars, back_limit - 1, -1):
			if CAPTION_BREAK_PUNCTUATION.contains(remaining.substr(index - 1, 1)):
				cut = index
				break
		if cut < 0:
			var forward_limit := mini(remaining.length(), max_chars + 2)
			for index in range(max_chars, forward_limit):
				if CAPTION_BREAK_PUNCTUATION.contains(remaining.substr(index, 1)):
					cut = index + 1
					break
		if cut < 0:
			cut = max_chars
		lines.append(remaining.substr(0, cut).strip_edges())
		remaining = remaining.substr(cut).strip_edges()
	if not remaining.is_empty():
		lines.append(remaining)
	return "\n".join(lines)


func _break_after_markers(text: String, markers: Array) -> String:
	var lines: Array[String] = []
	var search_from := 0
	for marker_variant in markers:
		var marker := str(marker_variant)
		var marker_index := text.find(marker, search_from)
		if marker_index < 0:
			return ""
		var cut := marker_index + marker.length()
		lines.append(text.substr(search_from, cut - search_from).strip_edges())
		search_from = cut
	var remaining := text.substr(search_from).strip_edges()
	if not remaining.is_empty():
		lines.append(remaining)
	return "\n".join(lines)


func _caption_line_width() -> int:
	match current_visual_id:
		"black":
			return 20
		"wake":
			return 16
		_:
			return 13


func _position_opening_caption() -> void:
	center_line_label.offset_left = 0.0
	center_line_label.offset_top = 0.0
	center_line_label.offset_right = 0.0
	center_line_label.offset_bottom = 0.0
	center_line_label.add_theme_constant_override("line_spacing", 14)
	center_line_label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.92),
	)
	center_line_label.add_theme_constant_override("shadow_outline_size", 6)
	center_line_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if current_visual_id == "black":
		center_line_label.add_theme_font_size_override("font_size", 44)
		center_line_label.anchor_left = 0.18
		center_line_label.anchor_top = 0.32
		center_line_label.anchor_right = 0.82
		center_line_label.anchor_bottom = 0.72
		center_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return

	center_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	match current_visual_id:
		"wake":
			center_line_label.add_theme_font_size_override("font_size", 40)
			center_line_label.anchor_left = 0.06
			center_line_label.anchor_top = 0.22
			center_line_label.anchor_right = 0.48
			center_line_label.anchor_bottom = 0.78
		"wash":
			center_line_label.add_theme_font_size_override("font_size", 34)
			center_line_label.anchor_left = 0.70
			center_line_label.anchor_top = 0.20
			center_line_label.anchor_right = 0.95
			center_line_label.anchor_bottom = 0.82
		"cats":
			center_line_label.add_theme_font_size_override("font_size", 34)
			center_line_label.anchor_left = 0.64
			center_line_label.anchor_top = 0.38
			center_line_label.anchor_right = 0.95
			center_line_label.anchor_bottom = 0.86
		"board":
			center_line_label.add_theme_font_size_override("font_size", 36)
			center_line_label.anchor_left = 0.05
			center_line_label.anchor_top = 0.46
			center_line_label.anchor_right = 0.36
			center_line_label.anchor_bottom = 0.88
		"drive":
			center_line_label.add_theme_font_size_override("font_size", 34)
			center_line_label.anchor_left = 0.70
			center_line_label.anchor_top = 0.48
			center_line_label.anchor_right = 0.96
			center_line_label.anchor_bottom = 0.92
		"arrive":
			center_line_label.add_theme_font_size_override("font_size", 34)
			center_line_label.anchor_left = 0.055
			center_line_label.anchor_top = 0.38
			center_line_label.anchor_right = 0.39
			center_line_label.anchor_bottom = 0.88
		_:
			center_line_label.add_theme_font_size_override("font_size", 38)
			center_line_label.anchor_left = 0.58
			center_line_label.anchor_top = 0.56
			center_line_label.anchor_right = 0.94
			center_line_label.anchor_bottom = 0.90


func _finish_caption_fade() -> void:
	if not handles_custom_reveal():
		return
	center_line_label.modulate.a = 1.0
	revealing = false
	_schedule_auto_advance(_hold_seconds())


func _hold_seconds() -> float:
	if current_beats.is_empty():
		return 1.6
	var text := str(current_beats[current_beat_index].get("text", ""))
	return clampf(0.9 + text.length() / 11.0, 1.4, 4.2)


func _advance_opening() -> void:
	if transitioning:
		return
	transitioning = true
	auto_timer.stop()

	var token := sequence_token
	var line_id := current_line_id
	await _fade_out_caption()
	if token != sequence_token or line_id != current_line_id:
		return

	if current_beat_index + 1 < current_beats.size():
		current_beat_index += 1
		var next_beat := current_beats[current_beat_index]
		var placeholder := str(next_beat.get("transition_placeholder", ""))
		if not placeholder.is_empty():
			_show_placeholder(placeholder)
			transitioning = false
			waiting = true
			_schedule_auto_advance(0.9)
			return
		transitioning = false
		_show_current_beat()
		return

	transitioning = false
	story.call("advance")


func _fade_out_caption() -> void:
	if not center_line_label.visible:
		return
	if text_tween != null and text_tween.is_valid():
		text_tween.kill()
	text_tween = host.create_tween()
	text_tween.set_trans(Tween.TRANS_QUAD)
	text_tween.set_ease(Tween.EASE_IN)
	text_tween.tween_property(center_line_label, "modulate:a", 0.0, 0.20)
	await text_tween.finished
	center_line_label.visible = false


func _set_visual(visual_id: String) -> void:
	var previous_visual_id := current_visual_id
	current_visual_id = visual_id
	opening_backdrop.visible = true
	opening_placeholder.visible = false

	if visual_id == "black":
		opening_backdrop.color = Color.BLACK
		opening_texture.visible = false
		return

	var texture := visual_textures.get(visual_id) as Texture2D
	if texture == null:
		_show_placeholder("%s\n（占位）" % visual_id)
		return
	if (
		previous_visual_id == visual_id
		and opening_texture.visible
		and opening_texture.texture == texture
	):
		opening_texture.modulate.a = 1.0
		return

	opening_backdrop.color = Color.BLACK
	opening_texture.texture = texture
	opening_texture.visible = true
	opening_texture.modulate.a = 0.0
	if visual_tween != null and visual_tween.is_valid():
		visual_tween.kill()
	visual_tween = host.create_tween()
	visual_tween.set_trans(Tween.TRANS_QUAD)
	visual_tween.set_ease(Tween.EASE_OUT)
	visual_tween.tween_property(opening_texture, "modulate:a", 1.0, 0.22)


func _load_variants(shot_id: String, variant_ids: Array) -> void:
	visual_textures.clear()
	for variant_id_value in variant_ids:
		var variant_id := str(variant_id_value)
		visual_textures[variant_id] = asset_registry.call(
			"load_variant",
			shot_id,
			variant_id,
		) as Texture2D


func _set_g1_overlay(variant_id: String) -> void:
	opening_backdrop.visible = false
	opening_placeholder.visible = false
	if variant_id.is_empty():
		opening_texture.visible = false
		return

	var texture := visual_textures.get(variant_id) as Texture2D
	if texture == null:
		opening_texture.visible = false
		return
	if opening_texture.visible and opening_texture.texture == texture:
		opening_texture.modulate.a = 1.0
		return

	opening_texture.texture = texture
	opening_texture.visible = true
	opening_texture.modulate.a = 0.0
	if visual_tween != null and visual_tween.is_valid():
		visual_tween.kill()
	visual_tween = host.create_tween()
	visual_tween.set_trans(Tween.TRANS_QUAD)
	visual_tween.set_ease(Tween.EASE_OUT)
	visual_tween.tween_property(opening_texture, "modulate:a", 1.0, 0.24)


func _build_g1_split_layer() -> void:
	g1_split_root = Control.new()
	g1_split_root.name = "G1ReverseSplit"
	g1_split_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g1_split_root.visible = false
	_set_full_rect(g1_split_root)
	fx_layer.add_child(g1_split_root)

	var split_backdrop := ColorRect.new()
	split_backdrop.color = Color.BLACK
	split_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(split_backdrop)
	g1_split_root.add_child(split_backdrop)

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray * 0.64), color.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader

	var left_clip := Control.new()
	left_clip.anchor_right = 0.5
	left_clip.anchor_bottom = 1.0
	left_clip.clip_contents = true
	left_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g1_split_root.add_child(left_clip)
	g1_split_left = TextureRect.new()
	g1_split_left.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g1_split_left.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	g1_split_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g1_split_left.material = material
	_set_full_rect(g1_split_left)
	left_clip.add_child(g1_split_left)

	var right_clip := Control.new()
	right_clip.anchor_left = 0.5
	right_clip.anchor_right = 1.0
	right_clip.anchor_bottom = 1.0
	right_clip.clip_contents = true
	right_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g1_split_root.add_child(right_clip)
	g1_split_right = TextureRect.new()
	g1_split_right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g1_split_right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	g1_split_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g1_split_right.material = material
	_set_full_rect(g1_split_right)
	right_clip.add_child(g1_split_right)

	var divider := ColorRect.new()
	divider.anchor_left = 0.5
	divider.anchor_right = 0.5
	divider.anchor_bottom = 1.0
	divider.offset_left = -2.0
	divider.offset_right = 2.0
	divider.color = Color(0.0, 0.0, 0.0, 0.82)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g1_split_root.add_child(divider)


func _show_g1_split(show_terminal_frames: bool) -> void:
	opening_backdrop.visible = false
	opening_texture.visible = false
	opening_placeholder.visible = false
	if show_terminal_frames:
		g1_split_left.texture = asset_registry.call(
			"load_variant",
			"SHOT-19",
			"reflection",
		) as Texture2D
		g1_split_right.texture = asset_registry.call(
			"load_variant",
			"SHOT-03",
			"thumb",
		) as Texture2D
	else:
		g1_split_left.texture = asset_registry.call(
			"load_master",
			"SHOT-02",
		) as Texture2D
		g1_split_right.texture = asset_registry.call(
			"load_variant",
			"SHOT-03",
			"point",
		) as Texture2D
	g1_split_root.visible = (
		g1_split_left.texture != null
		and g1_split_right.texture != null
	)


func _hide_g1_split() -> void:
	if g1_split_root != null:
		g1_split_root.visible = false


func _show_placeholder(label: String) -> void:
	current_visual_id = "placeholder"
	opening_backdrop.visible = true
	opening_backdrop.color = Color("#171b1d")
	opening_texture.visible = false
	opening_placeholder.text = label
	opening_placeholder.visible = true


func _hide_opening_visuals() -> void:
	if opening_backdrop != null:
		opening_backdrop.visible = false
	if opening_texture != null:
		opening_texture.visible = false
	if opening_placeholder != null:
		opening_placeholder.visible = false


func _cancel_line_state() -> void:
	sequence_token += 1
	waiting = false
	transitioning = false
	revealing = false
	auto_timer.stop()
	if text_tween != null and text_tween.is_valid():
		text_tween.kill()
	if visual_tween != null and visual_tween.is_valid():
		visual_tween.kill()


func _cancel_sequence() -> void:
	_cancel_line_state()
	current_beats.clear()
	current_beat_index = 0
	current_visual_id = ""


func _schedule_auto_advance(seconds: float) -> void:
	auto_timer.stop()
	if _is_auto_enabled():
		auto_timer.start(seconds)


func _is_auto_enabled() -> bool:
	return bool(host.get("is_auto"))


func _set_full_rect(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
