extends SceneTree

const CAPTURE_DIR := "user://g5-ending-visual-qa"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	var packed := load("res://src/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.call("_jump_to_scene", 27)
	await create_timer(0.20).timeout

	var voice_sequence_player: Node = scene.get("voice_sequence_player")
	var story: RefCounted = scene.get("story")
	await create_timer(0.45).timeout
	voice_sequence_player.call("stop")
	scene.call("_finish_typing")
	await _capture("01-live-wide-narration")

	story.call("start_at", 27, 2)
	await create_timer(0.35).timeout
	await _capture("02-walk-step-01")
	await create_timer(1.65).timeout
	await _capture("03-walk-step-02")
	await create_timer(1.55).timeout
	await _capture("04-walk-step-03")

	await create_timer(1.35).timeout
	await _capture("05-identity-half-face")

	await create_timer(1.85).timeout
	await _capture("06-identity-second-line")

	await create_timer(3.85).timeout
	await _capture("07-final-hold-motion-a")
	await create_timer(2.10).timeout
	await _capture("08-final-hold-motion-b")

	print(
		"G5 ending visual captures written to %s."
		% ProjectSettings.globalize_path(CAPTURE_DIR)
	)
	scene.free()
	quit(0)


func _capture(label: String) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [CAPTURE_DIR, label]
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save G5 ending visual capture %s." % path)
		quit(1)
