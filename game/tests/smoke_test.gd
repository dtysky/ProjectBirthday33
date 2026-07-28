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
		"DialoguePanel",
		"CenterLine",
		"QuickMenuOverlay",
		"MenuButton",
		"TitleOverlay",
		"HistoryOverlay",
		"SettingsOverlay",
	]
	for node_name in required:
		if scene.get_node_or_null(node_name) == null:
			push_error("Missing runtime node: %s" % node_name)
			quit(1)
			return

	scene.call("_start_new_game")
	await process_frame
	var story: RefCounted = scene.get("story")
	if int(story.get("unit_index")) != 0 or int(story.get("line_index")) != 0:
		push_error("New game did not start at G1-01 line 1.")
		quit(1)
		return
	if (
		not (scene.get_node("DialoguePanel") as Control).visible
		and not (scene.get_node("CenterLine") as Control).visible
	):
		push_error("Neither dialogue bubble nor caption is visible after starting a new game.")
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

	story.call("start_at", 19, 0)
	await process_frame
	if (
		(scene.get_node("DialoguePanel") as Control).visible
		or not (scene.get_node("CenterLine") as Control).visible
	):
		push_error("G4-02 travel voiceover is not presented as an unboxed caption.")
		quit(1)
		return

	story.call("start_at", 16, 3)
	scene.call("_finish_typing")
	await process_frame
	if not (scene.get_node("DialoguePanel") as Control).visible:
		push_error("Dialogue bubble is hidden for a spoken line.")
		quit(1)
		return
	var current_line := story.call("get_current_line") as Dictionary
	if str(current_line.get("text", "")).length() != 75:
		push_error("Longest dialogue line was not loaded correctly.")
		quit(1)
		return
	var segments := scene.get("current_segments") as Array
	if segments.size() < 3:
		push_error("Long dialogue was not divided into compact visual beats.")
		quit(1)
		return
	for segment in segments:
		if str(segment).length() > 36:
			push_error("A dialogue bubble segment exceeds the visual limit.")
			quit(1)
			return
	scene.call("_advance_story")
	await process_frame
	if int(story.get("line_index")) != 3 or int(scene.get("current_segment_index")) != 1:
		push_error("Advancing a paginated line skipped directly to the next dialogue.")
		quit(1)
		return

	story.call("start_at", 0, 0)
	for index in range(111):
		story.call("advance")
	if not (scene.get_node("EndingOverlay") as Control).visible:
		push_error("Story did not reach the ending after 111 advances.")
		quit(1)
		return

	print("Smoke test passed: compact dialogue beats, core UI, and full 111-line flow.")
	quit(0)
