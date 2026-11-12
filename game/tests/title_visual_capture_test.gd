extends SceneTree

const CAPTURE_PATH := "user://title-visual-qa.png"
const LATER_CAPTURE_PATH := "user://title-animation-qa-04.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://src/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await create_timer(0.35).timeout

	var title_overlay := scene.get_node("TitleOverlay") as Control
	var title_content := scene.get_node("TitleOverlay/TitleContent") as VBoxContainer
	var title_backdrop := scene.get_node("TitleOverlay/TitleBackdrop") as TextureRect
	var title_video := scene.get_node("TitleOverlay/TitleBackdropVideo") as VideoStreamPlayer
	var spare_overlay := scene.get_node(
		"TitleOverlay/TitleVehicleSpareOverlay"
	) as TextureRect
	var title_name := scene.get_node("TitleOverlay/TitleContent/TitleName") as Label
	var title_wind := scene.get_node("TitleSeaWind") as AudioStreamPlayer
	if (
		not title_overlay.visible
		or title_content.size.x < 700.0
		or title_backdrop.texture == null
		or title_video.stream == null
		or not title_video.is_playing()
		or spare_overlay.texture == null
		or title_name.text != "三十三岁的勇气，\n是坦然地失去"
		or title_wind.stream == null
		or not title_wind.playing
	):
		push_error("Title screen layout did not initialize correctly.")
		scene.free()
		quit(1)
		return

	await process_frame
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path(CAPTURE_PATH)
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save title capture: %s." % path)
		scene.free()
		quit(1)
		return
	print("Title visual capture written to %s." % path)

	await create_timer(3.65).timeout
	await process_frame
	var later_image := root.get_texture().get_image()
	var later_path := ProjectSettings.globalize_path(LATER_CAPTURE_PATH)
	var later_error := later_image.save_png(later_path)
	if later_error != OK:
		push_error("Could not save animated title capture: %s." % later_path)
		scene.free()
		quit(1)
		return
	if image.get_data() == later_image.get_data():
		push_error("Title animation produced two identical rendered frames.")
		scene.free()
		quit(1)
		return
	print("Animated title capture written to %s." % later_path)

	scene.call("_start_new_game")
	await create_timer(0.20).timeout
	if title_overlay.visible or title_video.is_playing() or not title_wind.playing:
		push_error("Title wind did not continue through the start-screen fade.")
		scene.free()
		quit(1)
		return
	await create_timer(1.30).timeout
	if title_wind.playing:
		push_error("Title wind did not stop after its start-screen fade.")
		scene.free()
		quit(1)
		return
	scene.call("_return_to_title")
	await create_timer(0.10).timeout
	if not title_overlay.visible or not title_video.is_playing() or not title_wind.playing:
		push_error("Returning to title did not restart the title ambience.")
		scene.free()
		quit(1)
		return
	scene.free()
	quit(0)
