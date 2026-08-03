extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://src/main.tscn") as PackedScene
	if packed == null:
		push_error("Cannot load main scene.")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var required := [
		"Stage",
		"MasterTexture",
		"ChapterFxLayer",
		"DialoguePanel",
		"CenterLine",
		"QuickMenuOverlay",
		"SceneSelectOverlay",
		"MenuButton",
		"TitleOverlay",
		"HistoryOverlay",
		"SettingsOverlay",
		"ChapterFxLayer/OpeningBackdrop",
		"ChapterFxLayer/OpeningTexture",
		"ChapterFxLayer/OpeningPlaceholder",
		"ChapterFxLayer/G1ReverseSplit",
	]
	for node_name in required:
		if scene.get_node_or_null(node_name) == null:
			push_error("Missing runtime node: %s" % node_name)
			quit(1)
			return

	scene.call("_show_scene_select")
	await process_frame
	var scene_select := scene.get_node("SceneSelectOverlay") as Control
	var scene_list := scene_select.find_child("SceneList", true, false) as ItemList
	if not scene_select.visible or scene_list.item_count != 6:
		push_error("Scene selector did not expose all six G1 units.")
		quit(1)
		return
	scene.call("_jump_to_scene", 6)
	await process_frame
	var selector_story: RefCounted = scene.get("story")
	var selector_director := scene.get("active_chapter_director") as RefCounted
	if (
		scene_select.visible
		or int(selector_story.get("unit_index")) != 6
		or selector_director == null
		or int(selector_director.get("chapter_number")) != 2
	):
		push_error("Scene selector did not jump directly to G2-01.")
		quit(1)
		return

	scene.call("_start_new_game")
	await process_frame
	var story: RefCounted = scene.get("story")
	if int(story.get("unit_index")) != 0 or int(story.get("line_index")) != 0:
		push_error("New game did not start at G1-01 line 1.")
		quit(1)
		return

	var opening_director := scene.get("active_chapter_director") as RefCounted
	if opening_director == null or int(opening_director.get("chapter_number")) != 1:
		push_error("Chapter 1 director was not activated.")
		quit(1)
		return

	var opening_texture := scene.get_node(
		"ChapterFxLayer/OpeningTexture"
	) as TextureRect
	var opening_placeholder := scene.get_node(
		"ChapterFxLayer/OpeningPlaceholder"
	) as Label
	var center_line := scene.get_node("CenterLine") as Label
	if not opening_placeholder.visible or not opening_placeholder.text.contains("梦境"):
		push_error("G0 did not begin on the dream placeholder.")
		quit(1)
		return
	if center_line.visible:
		push_error("G0 dream placeholder did not preserve its opening silent hold.")
		quit(1)
		return
	await create_timer(1.10).timeout
	if (
		int(story.get("line_index")) != 0
		or not opening_placeholder.visible
		or center_line.visible
	):
		push_error("G0 advanced from the dream placeholder while auto mode was off.")
		quit(1)
		return

	scene.call("_advance_story")
	await process_frame
	if (
		not center_line.visible
		or str(opening_director.get("current_visual_id")) != "black"
	):
		push_error("G0 did not cut from the dream placeholder to the black-screen line.")
		quit(1)
		return

	scene.call("_finish_typing")
	scene.call("_advance_story")
	await create_timer(0.30).timeout
	if (
		int(story.get("line_index")) != 1
		or str(opening_director.get("current_visual_id")) != "wake"
		or not opening_texture.visible
		or opening_texture.texture == null
	):
		push_error("G0 wake CG was not shown for the birthday line.")
		quit(1)
		return
	await create_timer(1.60).timeout
	if (
		int(story.get("line_index")) != 1
		or str(opening_director.get("current_visual_id")) != "wake"
	):
		push_error("G0 advanced from the wake CG while auto mode was off.")
		quit(1)
		return

	story.call("start_at", 0, 4)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "wake"
		or opening_texture.texture == null
		or center_line.anchor_right > 0.50
		or _max_line_length(center_line.text) > 16
	):
		push_error("G0 wake narration did not use the left-side bed safe area and compact wrapping.")
		quit(1)
		return

	story.call("start_at", 0, 6)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "wash"
		or opening_texture.texture == null
		or center_line.anchor_left < 0.68
		or _max_line_length(center_line.text) > 13
	):
		push_error("G0 wash narration did not use the mirror's right-side safe area.")
		quit(1)
		return

	story.call("start_at", 0, 10)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "cats"
		or opening_texture.texture == null
		or center_line.anchor_left < 0.62
		or center_line.anchor_top < 0.36
		or _max_line_length(center_line.text) > 13
	):
		push_error(
			(
				"G0 cats narration missed its safe area: visual=%s, left=%.3f, "
				+ "top=%.3f, max_line=%d, text=%s"
			) % [
				str(opening_director.get("current_visual_id")),
				center_line.anchor_left,
				center_line.anchor_top,
				_max_line_length(center_line.text),
				center_line.text.replace("\n", " / "),
			]
		)
		quit(1)
		return

	story.call("start_at", 0, 14)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "board"
		or opening_texture.texture == null
		or center_line.anchor_right > 0.38
	):
		push_error("G0 boarding narration did not use the garage's left-side safe area.")
		quit(1)
		return

	story.call("start_at", 0, 17)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "drive"
		or opening_texture.texture == null
		or center_line.anchor_left < 0.68
		or _max_line_length(center_line.text) > 13
	):
		push_error("G0 commute narration did not use the dark dashboard safe area.")
		quit(1)
		return

	story.call("start_at", 0, 20)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "drive"
		or not opening_texture.visible
		or center_line.visible
	):
		push_error("G0 did not hold on normal driving before the returning dream line.")
		quit(1)
		return
	scene.call("_advance_story")
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "black"
		or not center_line.visible
	):
		push_error("G0 did not flash back to black for the returning dream line.")
		quit(1)
		return

	story.call("start_at", 0, 21)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "arrive"
		or opening_texture.texture == null
		or center_line.anchor_right > 0.41
		or _max_line_length(center_line.text) > 13
	):
		push_error("G0 company-arrival narration did not use the left-side garage safe area.")
		quit(1)
		return

	story.call("start_at", 5, 0)
	await process_frame
	if (
		not (scene.get_node("DialoguePanel") as Control).visible
		or (scene.get_node("CenterLine") as Control).visible
	):
		push_error("G1-06 scene monologue is not presented from the on-screen character.")
		quit(1)
		return

	var master_texture := scene.get_node("MasterTexture") as TextureRect
	var dialogue_panel := scene.get_node("DialoguePanel") as PanelContainer
	var dialogue_tail := scene.get_node("DialogueTail") as Polygon2D
	var reverse_split := scene.get_node("ChapterFxLayer/G1ReverseSplit") as Control

	story.call("start_at", 1, 0)
	await process_frame
	if (
		master_texture.texture == null
		or dialogue_panel.position.x < 440.0
		or dialogue_panel.position.x > 500.0
		or dialogue_tail.visible
		or not dialogue_panel.size.is_equal_approx(Vector2(620.0, 158.0))
		or not str((scene.get("dialogue_presenter") as RefCounted).get("current_text")).contains("\n")
	):
		push_error("G1-02 did not use the fixed tailless dialogue card.")
		quit(1)
		return
	var g1_02_position := dialogue_panel.position
	var g1_02_size := dialogue_panel.size
	story.call("start_at", 1, 1)
	await process_frame
	(scene.get("dialogue_presenter") as RefCounted).call("advance_page")
	await process_frame
	if (
		not dialogue_panel.position.is_equal_approx(g1_02_position)
		or not dialogue_panel.size.is_equal_approx(g1_02_size)
	):
		push_error("G1-02 dialogue card moved between pages while the CG stayed fixed.")
		quit(1)
		return

	story.call("start_at", 2, 0)
	await process_frame
	if (
		master_texture.texture == null
		or opening_texture.visible
		or dialogue_panel.position.x > 100.0
		or dialogue_tail.visible
		or not dialogue_panel.size.is_equal_approx(Vector2(620.0, 158.0))
	):
		push_error("G1-03 did not use the fixed upper-left dialogue card.")
		quit(1)
		return
	story.call("start_at", 2, 3)
	await process_frame
	if not opening_texture.visible or opening_texture.texture == null:
		push_error("G1-03 did not add the professional-smile reflection on its final line.")
		quit(1)
		return

	story.call("start_at", 3, 0)
	await process_frame
	if (
		opening_texture.visible
		or not is_equal_approx(dialogue_panel.position.x, 1220.0)
		or dialogue_tail.visible
		or not dialogue_panel.size.is_equal_approx(Vector2(620.0, 158.0))
	):
		push_error("G1-04 did not begin with the tailless camera-addressed pixel card.")
		quit(1)
		return
	story.call("start_at", 3, 3)
	await process_frame
	if not opening_texture.visible or opening_texture.texture == null:
		push_error("G1-04 did not switch to the thumbs-up CG between lines three and four.")
		quit(1)
		return

	story.call("start_at", 4, 0)
	await process_frame
	if not reverse_split.visible or not center_line.visible:
		push_error("G1-05 did not show the desaturated work/creation reverse split.")
		quit(1)
		return

	story.call("start_at", 5, 0)
	await process_frame
	if (
		opening_texture.visible
		or dialogue_panel.position.x > 100.0
		or dialogue_tail.visible
		or not dialogue_panel.size.is_equal_approx(Vector2(620.0, 158.0))
	):
		push_error("G1-06 did not begin with the fixed left dialogue card.")
		quit(1)
		return
	story.call("start_at", 5, 5)
	await process_frame
	if not opening_texture.visible or opening_texture.texture == null:
		push_error("G1-06 did not open the protagonist's eyes for the final line.")
		quit(1)
		return

	story.call("start_at", 19, 0)
	await process_frame
	if (
		(scene.get_node("DialoguePanel") as Control).visible
		or not (scene.get_node("CenterLine") as Control).visible
	):
		push_error("G4-02 travel voiceover is not presented as an unboxed caption.")
		quit(1)
		return

	var longest := _find_longest_bubble(story.get("units") as Array)
	story.call(
		"start_at",
		int(longest.get("unit_index", 0)),
		int(longest.get("line_index", 0)),
	)
	await process_frame
	if not (scene.get_node("DialoguePanel") as Control).visible:
		push_error("Dialogue bubble is hidden for a spoken line.")
		quit(1)
		return
	var current_line := story.call("get_current_line") as Dictionary
	if str(current_line.get("text", "")).length() != int(longest.get("length", 0)):
		push_error("Longest bubble line was not loaded correctly.")
		quit(1)
		return
	var presenter := scene.get("dialogue_presenter") as RefCounted
	var segments := presenter.get("current_segments") as Array
	if segments.size() < 2:
		push_error("Longest dialogue was not divided into compact visual beats.")
		quit(1)
		return
	for segment in segments:
		if str(segment).length() > 36:
			push_error("A dialogue bubble segment exceeds the visual limit.")
			quit(1)
			return
	scene.call("_finish_typing")
	scene.call("_advance_story")
	await process_frame
	if int(presenter.get("current_segment_index")) != 1:
		push_error("Advancing a paginated line skipped directly to the next dialogue.")
		quit(1)
		return

	var units := story.get("units") as Array
	var last_unit_index := units.size() - 1
	var last_unit := units[last_unit_index] as Dictionary
	var last_lines := last_unit.get("lines", []) as Array
	story.call("start_at", last_unit_index, last_lines.size() - 1)
	await process_frame
	story.call("advance")
	await process_frame
	if not (scene.get_node("EndingOverlay") as Control).visible:
		push_error("Story did not reach the ending from its final current-script line.")
		quit(1)
		return

	print(
		"Smoke test passed: current script, six G0 CGs, seven G1 CGs, "
		+ "semantic dialogue beats, shot variants, reverse split, core UI, and ending flow."
	)
	quit(0)


func _find_longest_bubble(units: Array) -> Dictionary:
	var result := {
		"unit_index": 0,
		"line_index": 0,
		"length": 0,
	}
	for unit_index in range(units.size()):
		var unit := units[unit_index] as Dictionary
		var lines := unit.get("lines", []) as Array
		for line_index in range(lines.size()):
			var line := lines[line_index] as Dictionary
			if str(line.get("presentation", "")) != "bubble":
				continue
			var length := str(line.get("text", "")).length()
			if length > int(result["length"]):
				result = {
					"unit_index": unit_index,
					"line_index": line_index,
					"length": length,
				}
	return result


func _max_line_length(text: String) -> int:
	var longest := 0
	for line in text.split("\n"):
		longest = maxi(longest, line.length())
	return longest
