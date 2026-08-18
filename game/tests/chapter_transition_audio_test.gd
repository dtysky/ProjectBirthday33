extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://src/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var story: RefCounted = scene.get("story")
	var music_director := scene.get("music_director") as Node
	scene.call("_start_new_game")
	# Establish the outgoing G1 cue explicitly before jumping to the intentionally
	# unscored final unit, so this test measures the chapter pre-fade itself.
	story.call("start_at", 0, 1)
	await process_frame
	story.call("start_at", 5, 5)
	await process_frame
	scene.call("_finish_typing")
	scene.call("_advance_story")
	await create_timer(0.10).timeout

	if (
		not bool(scene.get("chapter_transition_pending"))
		or bool(scene.get("chapter_interlude_active"))
		or not str(music_director.get("active_cue_id")).is_empty()
		or not _any_player_is_playing(music_director)
	):
		_fail("The old BGM did not begin fading before the G2 chapter card.")
		return

	await create_timer(2.25).timeout
	if (
		bool(scene.get("chapter_transition_pending"))
		or not bool(scene.get("chapter_interlude_active"))
		or int(story.get("unit_index")) != 6
		or _any_player_is_playing(music_director)
	):
		_fail("The chapter card did not begin after the old BGM reached silence.")
		return

	await create_timer(5.25).timeout
	if (
		bool(scene.get("chapter_interlude_active"))
		or not bool(music_director.call("is_cue_active", "MUS-04"))
		or not _any_player_is_playing(music_director)
	):
		_fail("The G2 BGM did not enter together with the revealed scene.")
		return

	print(
		"Chapter transition audio test passed: 2.2s pre-fade, 5.2s card, "
		+ "then simultaneous scene and BGM entry."
	)
	music_director.call("hard_stop")
	scene.free()
	quit(0)


func _any_player_is_playing(director: Node) -> bool:
	for player_variant in director.get("players") as Array:
		if (player_variant as AudioStreamPlayer).playing:
			return true
	return false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
