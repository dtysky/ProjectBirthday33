extends SceneTree

const CAPTURE_DIR := "user://g0-visual-qa"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	var packed := load("res://src/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.call("_start_new_game")
	await create_timer(2.40).timeout
	await _capture("01-pov-eyes-open")
	await create_timer(2.90).timeout
	await _capture("02-wake-dialogue")
	var story: RefCounted = scene.get("story")
	story.call("start_at", 0, 2)
	await create_timer(5.98).timeout
	await _capture("02a-bell-transition-cover")
	await create_timer(0.64).timeout
	await _capture("02b-bell-transition-reveal")
	await create_timer(0.62).timeout
	scene.call("_finish_typing")
	await process_frame
	await _capture("02c-bell-transition-settled")

	story.call("start_at", 0, 8)
	await create_timer(2.10).timeout
	await _capture("03-youth-close")

	story.call("start_at", 0, 10)
	await create_timer(0.75).timeout
	await _capture("04-adult-reaction")

	story.call("start_at", 0, 11)
	await create_timer(1.30).timeout
	scene.call("_finish_typing")
	await process_frame
	await _capture("05-memory-recall")

	story.call("start_at", 0, 16)
	await create_timer(1.65).timeout
	await _capture("06-train-stop")

	story.call("start_at", 0, 17)
	await create_timer(1.35).timeout
	scene.call("_finish_typing")
	await process_frame
	await _capture("07-final-answer")
	scene.call("_advance_story")
	await create_timer(2.55).timeout
	await _capture("08-reality-fade-in")
	await create_timer(1.55).timeout
	await _capture("09-birthday-morning")

	print("G0 visual captures written to %s." % CAPTURE_DIR)
	scene.free()
	quit(0)


func _capture(label: String) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [CAPTURE_DIR, label]
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save G0 visual capture %s." % path)
		quit(1)
