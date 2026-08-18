extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://src/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.call("_start_new_game")
	await process_frame
	# Let the bespoke eye-opening coroutine finish so it cannot overwrite the
	# isolated transition states below while they are being sampled.
	await create_timer(5.60).timeout

	var story: RefCounted = scene.get("story")
	var director := scene.get("active_chapter_director") as RefCounted
	var black_transition := scene.get_node(
		"ChapterFxLayer/DreamSceneTransition"
	) as ColorRect
	var opening_texture := scene.get_node(
		"ChapterFxLayer/OpeningTexture"
	) as TextureRect
	var previous_texture := scene.get_node(
		"ChapterFxLayer/OpeningPreviousTexture"
	) as TextureRect

	# D06 -> D07 is an ordinary image change: it must crossfade directly,
	# without inserting a black frame between the two dream images.
	story.call("start_at", 0, 5)
	await process_frame
	scene.call("_finish_typing")
	scene.call("_advance_story")
	await create_timer(0.38).timeout
	if (
		int(story.get("line_index")) != 6
		or str(director.get("current_visual_id")) != "dream_shadow"
		or black_transition.visible
		or not previous_texture.visible
		or opening_texture.modulate.a <= 0.0
		or opening_texture.modulate.a >= 1.0
	):
		push_error("G0 ordinary image change did not use a direct crossfade.")
		quit(1)
		return

	await create_timer(0.65).timeout
	if (
		black_transition.visible
		or previous_texture.visible
		or opening_texture.modulate.a < 0.99
		or str(director.get("current_visual_id")) != "dream_shadow"
	):
		push_error("G0 ordinary direct crossfade did not settle cleanly.")
		quit(1)
		return

	# Bell/whistle transitions use the opposite rule: the old image must remain
	# until the blackout completes, then the new image is swapped under black.
	director.call("_play_dream_scene_transition", "dream_loss")
	await create_timer(0.18).timeout
	if (
		not black_transition.visible
		or black_transition.modulate.a <= 0.0
		or black_transition.modulate.a >= 1.0
		or str(director.get("current_visual_id")) != "dream_shadow"
	):
		push_error("G0 sound-event transition changed the image before reaching black.")
		quit(1)
		return

	await create_timer(0.24).timeout
	if (
		not black_transition.visible
		or black_transition.modulate.a < 0.9
		or str(director.get("current_visual_id")) != "dream_loss"
	):
		push_error("G0 sound-event transition did not swap the image under black.")
		quit(1)
		return

	await create_timer(0.60).timeout
	if (
		black_transition.visible
		or str(director.get("current_visual_id")) != "dream_loss"
		or opening_texture.modulate.a < 0.99
	):
		push_error(
			"G0 sound-event black transition did not fade back cleanly: visible=%s, alpha=%.3f, visual=%s, texture_alpha=%.3f."
			% [
				str(black_transition.visible),
				black_transition.modulate.a,
				str(director.get("current_visual_id")),
				opening_texture.modulate.a,
			]
		)
		quit(1)
		return

	print("G0 image transition test passed: ordinary images crossfade; sound cues cut through black.")
	scene.free()
	quit(0)
