extends ChapterDirector

const DEFAULT_BUBBLE_POSITION := Vector2(80.0, 760.0)
const BUBBLE_POSITIONS := {
	"SHOT-05": {
		"我": Vector2(1000.0, 120.0),
	},
	"SHOT-07": {
		"大家": Vector2(680.0, 790.0),
		"我": Vector2(700.0, 760.0),
		"组员丁": Vector2(60.0, 650.0),
	},
	"SHOT-08": {
		"我": Vector2(620.0, 70.0),
		"组员": Vector2(1260.0, 640.0),
	},
	"SHOT-20": {
		"我": Vector2(120.0, 130.0),
	},
	"SHOT-21": {
		"我": Vector2(80.0, 110.0),
		"组员乙": Vector2(430.0, 100.0),
		"组员丙": Vector2(1110.0, 100.0),
		"组员甲": Vector2(1260.0, 660.0),
	},
	"SHOT-22": {
		"我": Vector2(650.0, 760.0),
		"组员丁": Vector2(40.0, 40.0),
		"组员乙": Vector2(490.0, 40.0),
		"组员丙": Vector2(1040.0, 610.0),
		"组员甲": Vector2(1260.0, 450.0),
	},
	"SHOT-23": {
		"我": Vector2(700.0, 40.0),
		"组员丙": Vector2(1110.0, 40.0),
		"组员甲": Vector2(1260.0, 600.0),
	},
	"SHOT-26": {
		"我": Vector2(1240.0, 90.0),
		"某个同事": Vector2(70.0, 650.0),
	},
	"SHOT-27": {
		"我": Vector2(120.0, 680.0),
		"组员丁": Vector2(850.0, 40.0),
	},
	"SHOT-29": {
		"我": Vector2(160.0, 100.0),
		"某HR": Vector2(1250.0, 700.0),
	},
	"SHOT-30": {
		"我": Vector2(720.0, 700.0),
		"组员乙": Vector2(70.0, 100.0),
		"组员丙": Vector2(1260.0, 180.0),
		"组员甲": Vector2(1250.0, 700.0),
	},
}

var current_shot_id := ""


func _init() -> void:
	chapter_number = 2


func on_unit_changed(unit: Dictionary) -> void:
	current_shot_id = str(unit.get("shot", ""))


func on_line_changed(line: Dictionary, unit: Dictionary) -> bool:
	var next_shot_id := str(line.get("shot", unit.get("shot", "")))
	if next_shot_id.is_empty() or next_shot_id == current_shot_id:
		return false

	current_shot_id = next_shot_id
	var asset_registry = context.get("asset_registry")
	var ui = context.get("ui")
	if asset_registry != null and ui != null:
		var texture: Texture2D = asset_registry.load_master(next_shot_id)
		ui.show_line_shot(next_shot_id, texture)
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


func uses_speaker_label() -> bool:
	return false


func position_caption(label: Label, _presentation: String) -> bool:
	label.offset_left = 0.0
	label.offset_top = 0.0
	label.offset_right = 0.0
	label.offset_bottom = 0.0
	label.anchor_left = 0.06
	label.anchor_top = 0.68
	label.anchor_right = 0.56
	label.anchor_bottom = 0.90
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_constant_override("line_spacing", 14)
	label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.92),
	)
	label.add_theme_constant_override("shadow_outline_size", 6)
	return true


func leave() -> void:
	current_shot_id = ""
