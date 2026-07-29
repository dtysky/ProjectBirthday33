class_name DialoguePresenter
extends RefCounted

const PAGE_BREAK_PUNCTUATION := "，。！？；：、—…,.!?;:"
const BUBBLE_PAGE_LIMIT := 30
const CAPTION_PAGE_LIMIT := 38
const CENTER_PAGE_LIMIT := 32

var dialogue_panel: PanelContainer
var dialogue_tail: Polygon2D
var body_label: Label
var center_line_label: Label

var current_text := ""
var current_presentation := "bubble"
var current_speaker := ""
var current_segments: Array[String] = []
var current_segment_index := 0
var type_progress := 0.0
var is_typing := false
var is_screen_line := false
var caption_director


func setup(
	panel: PanelContainer,
	tail: Polygon2D,
	body: Label,
	center_line: Label,
) -> void:
	dialogue_panel = panel
	dialogue_tail = tail
	body_label = body
	center_line_label = center_line


func start_line(line: Dictionary, director = null) -> void:
	cancel_reveal()
	current_presentation = str(line.get("presentation", "bubble"))
	current_speaker = str(line.get("speaker", ""))
	current_segments = paginate_text(str(line.get("text", "")), current_presentation)
	current_segment_index = 0
	caption_director = director
	_show_current_segment()


func tick(delta: float, text_speed: float) -> bool:
	if not is_typing:
		return false
	type_progress += delta * text_speed
	var visible_count := mini(int(type_progress), current_text.length())
	get_active_label().visible_characters = visible_count
	return visible_count >= current_text.length()


func finish_reveal() -> void:
	get_active_label().visible_characters = -1
	is_typing = false


func advance_page() -> bool:
	if current_segment_index + 1 >= current_segments.size():
		return false
	current_segment_index += 1
	_show_current_segment()
	return true


func cancel_reveal() -> void:
	is_typing = false
	type_progress = 0.0


func get_active_label() -> Label:
	return center_line_label if is_screen_line else body_label


func paginate_text(text: String, presentation: String) -> Array[String]:
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


func _show_current_segment() -> void:
	var segment_text := current_segments[current_segment_index] if not current_segments.is_empty() else ""
	is_screen_line = current_presentation != "bubble"
	dialogue_panel.visible = not is_screen_line
	dialogue_tail.visible = not is_screen_line
	center_line_label.visible = is_screen_line

	if is_screen_line:
		current_text = _format_screen_text(segment_text)
		center_line_label.text = current_text
		_position_caption()
	else:
		current_text = _format_bubble_text(segment_text)
		body_label.text = current_text
		_position_bubble()

	var active := get_active_label()
	active.modulate.a = 1.0
	active.visible_characters = 0
	type_progress = 0.0
	is_typing = true


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


func _position_bubble() -> void:
	var lines := current_text.split("\n")
	var line_count := lines.size()
	var longest_line_chars := 1
	for line in lines:
		longest_line_chars = maxi(longest_line_chars, line.length())
	var bubble_width := clampf(96.0 + longest_line_chars * 32.0, 430.0, 680.0)
	var bubble_height := 144.0 if line_count == 1 else 190.0
	var bubble_position := Vector2(600.0, 140.0)
	var tail_ratio := 0.5

	match current_speaker:
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


func _position_caption() -> void:
	center_line_label.offset_left = 0.0
	center_line_label.offset_top = 0.0
	center_line_label.offset_right = 0.0
	center_line_label.offset_bottom = 0.0
	if (
		caption_director != null
		and caption_director.position_caption(center_line_label, current_presentation)
	):
		return

	center_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_line_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_line_label.add_theme_constant_override("line_spacing", 18)
	center_line_label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.9),
	)
	center_line_label.add_theme_constant_override("shadow_outline_size", 5)
	if current_presentation == "center":
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
