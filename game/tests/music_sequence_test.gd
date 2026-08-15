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
	var director := scene.get("music_director") as Node
	scene.call("_start_new_game")
	await create_timer(0.10).timeout
	_assert_music(director, "MUS-01", true, "opening")

	story.call("start_at", 0, 1)
	await process_frame
	_assert_music(director, "MUS-03B", true, "G0 after the dream")

	story.call("start_at", 3, 0)
	await process_frame
	_assert_music(director, "MUS-02", true, "G1 through scene 04")

	story.call("start_at", 4, 0)
	await create_timer(2.10).timeout
	_assert_music(director, "MUS-03B", true, "G1 scenes 05 and 06")
	var active_index := int(director.get("active_player_index"))
	var states := director.get("channel_states") as Array
	var active_player := (director.get("players") as Array)[active_index] as AudioStreamPlayer
	var music_bus_index := AudioServer.get_bus_index("Music")
	if (
		active_index < 0
		or float((states[active_index] as Dictionary).get("gain", 0.0)) < 0.95
		or active_player.volume_db < -4.0
		or music_bus_index < 0
		or AudioServer.is_bus_mute(music_bus_index)
		or AudioServer.get_bus_volume_db(music_bus_index) < -0.1
		or AudioServer.is_bus_mute(0)
		or AudioServer.get_bus_volume_db(0) < -2.1
	):
		push_error("MUS-03B was not audible in the G1 closing scenes.")
		quit(1)
		return

	story.call("start_at", 6, 0)
	await create_timer(2.10).timeout
	_assert_music(director, "MUS-04", true, "G2 long-form state")

	print("Music sequence test passed: G0/G1 remapping and G2 long state are active.")
	director.call("hard_stop")
	scene.free()
	quit(0)


func _assert_music(director: Node, cue_id: String, should_play: bool, stage: String) -> void:
	if str(director.get("active_cue_id")) != cue_id:
		push_error(
			"Unexpected cue at %s: expected %s, got %s." % [
				stage,
				cue_id,
				director.get("active_cue_id"),
			]
		)
		quit(1)
		return
	var playing := false
	for player_variant in director.get("players") as Array:
		if (player_variant as AudioStreamPlayer).playing:
			playing = true
	if playing != should_play:
		push_error("Unexpected playback state at %s." % stage)
		quit(1)
