extends SceneTree

const SoundDirectorClass := preload("res://src/sound_director.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var director := SoundDirectorClass.new()
	director.name = "SoundDirectorTest"
	root.add_child(director)
	if not director.setup():
		_fail("Sound director could not load all nine split assets.")
		return

	if director.ambience_for_line("G1-01-18") != "city_drive":
		_fail("The commute ambience does not begin on G1-01-18.")
		return
	if not director.ambience_for_line("G1-01-21").is_empty():
		_fail("The commute ambience must leave before the black-screen line.")
		return
	if not director.ambience_for_line("G1-02-01").is_empty():
		_fail("The office ambience must not cover the outdoor campus walk.")
		return
	if director.ambience_for_line("G1-03-01") != "office":
		_fail("The office ambience does not cover the workstation scene.")
		return
	if director.ambience_for_line("G1-04-01") != "creative_wind":
		_fail("The rooftop wind was not reused for the mountain creative performance.")
		return
	if not director.ambience_for_line("G5-04-02").is_empty():
		_fail("The ending seaside ambience begins too early on the daytime beach.")
		return
	if (
		director.ambience_for_line("G5-04-03") != "seaside"
		or director.ambience_for_line("G5-05-04") != "seaside"
	):
		_fail("The seaside ambience does not reach the final identity hold.")
		return
	for event_line in [
		"G1-01-D01",
		"G1-01-D03",
		"G1-01-D17",
		"G1-01-08",
		"G1-01-15",
	]:
		if director.event_for_line(event_line).is_empty():
			_fail("Missing sound event mapping: %s." % event_line)
			return
	if not director.event_for_line("G1-01-D16").is_empty():
		_fail("The train whistle still starts too early on the approach line.")
		return
	var church_bell_seconds := float(
		director.play_event_for_line("G1-01-D03", true)
	)
	if church_bell_seconds < 5.5 or church_bell_seconds > 5.9:
		_fail("The church-bell event is no longer the reviewed two-toll duration.")
		return
	director.sync_to_line("G1-01-08")
	await create_timer(0.02).timeout
	if not director.is_event_active("G1-01-08"):
		_fail("The washing sound did not start with its scene.")
		return
	director.sync_to_line("G1-01-09")
	await create_timer(0.02).timeout
	if not director.is_event_active("G1-01-08"):
		_fail("The washing sound did not remain inside its intended scene.")
		return
	director.sync_to_line("G1-01-11")
	await create_timer(0.14).timeout
	if director.is_event_active("G1-01-08"):
		_fail("The washing sound leaked into the next scene.")
		return

	director.sync_to_line("G1-01-18")
	await create_timer(0.08).timeout
	var active_stream := (
		director.ambience_players[director.active_ambience_player_index].stream
		as AudioStreamOggVorbis
	)
	if (
		not director.is_ambience_active("city_drive")
		or active_stream == null
		or not active_stream.loop
	):
		_fail("The commute ambience did not start as a loop.")
		return

	director.sync_to_line("G1-01-21")
	await create_timer(0.32).timeout
	if _any_ambience_is_playing(director):
		_fail("The commute ambience did not clear during the black-screen cut.")
		return

	director.sync_to_line("G5-05-04")
	await create_timer(0.08).timeout
	if not director.is_ambience_active("seaside"):
		_fail("The final seaside ambience did not start.")
		return

	print(
		"Sound director test passed: nine assets load, event cues map, "
		+ "ambience loops and the commute clears before black."
	)
	director.hard_stop()
	director.free()
	quit(0)


func _any_ambience_is_playing(director: Node) -> bool:
	for player_variant in director.get("ambience_players") as Array:
		if (player_variant as AudioStreamPlayer).playing:
			return true
	return false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
