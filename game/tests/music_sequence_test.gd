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
	_assert_music(director, "", false, "wind-only opening")
	await create_timer(5.20).timeout
	_assert_music(director, "MUS-03C", true, "rooftop dialogue after eye opening")

	story.call("start_at", 0, 18)
	await process_frame
	_assert_music(director, "MUS-03B", true, "G0 after the dream")

	story.call("start_at", 3, 0)
	await process_frame
	_assert_music(director, "MUS-02", true, "G1 through scene 04")

	story.call("start_at", 4, 0)
	await create_timer(0.10).timeout
	_assert_music(director, "", true, "G1 replay fade")
	await create_timer(2.80).timeout
	_assert_music(director, "", false, "G1 closing silence")

	story.call("start_at", 6, 0)
	await create_timer(2.10).timeout
	_assert_music(director, "MUS-04", true, "G2 long-form state")

	print("Music sequence test passed: wind-only G0 opening, G1 replay fade and G2 long state are active.")
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
