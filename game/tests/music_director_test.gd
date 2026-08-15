extends SceneTree

const MusicDirectorClass := preload("res://src/music_director.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var director := MusicDirectorClass.new()
	director.name = "MusicDirectorTest"
	root.add_child(director)
	if not director.setup():
		push_error("Music director setup failed.")
		quit(1)
		return

	for bus_name in ["Voice", "Ambience", "SFX", "Music"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			push_error("Runtime audio bus was not created: %s." % bus_name)
			quit(1)
			return
	if str(director.cue_for_line("G1-01-01").get("id", "")) != "MUS-01":
		push_error("MUS-01 start boundary did not resolve.")
		quit(1)
		return
	if str(director.cue_for_line("G1-01-02").get("id", "")) != "MUS-03B":
		push_error("MUS-03B did not begin after the G0 dream line.")
		quit(1)
		return
	if str(director.cue_for_line("G1-04-06").get("id", "")) != "MUS-02":
		push_error("MUS-02 did not remain active through G1-04.")
		quit(1)
		return
	if str(director.cue_for_line("G1-05-01").get("id", "")) != "MUS-03B":
		push_error("MUS-03B did not resume for G1-05 and G1-06.")
		quit(1)
		return
	if str(director.cue_for_line("G4-05-02").get("id", "")) != "MUS-08B":
		push_error("MUS-08B did not cover the G4 closing section.")
		quit(1)
		return
	if str(director.cue_for_line("G5-04-03").get("id", "")) != "MUS-09C":
		push_error("MUS-09B to MUS-09C boundary did not resolve.")
		quit(1)
		return

	director.sync_to_line("G1-01-01")
	await create_timer(0.05).timeout
	var dream_stream := (
		director.players[director.active_player_index].stream as AudioStreamOggVorbis
	)
	if (
		not director.is_cue_active("MUS-01")
		or not _any_player_is_playing(director)
		or dream_stream == null
		or not dream_stream.loop
	):
		push_error("MUS-01 did not start on its first line.")
		quit(1)
		return
	director.sync_to_line("G1-01-02")
	await create_timer(0.05).timeout
	if not director.is_cue_active("MUS-03B") or _playing_player_count(director) != 2:
		push_error("MUS-01 did not crossfade into MUS-03B after the dream line.")
		quit(1)
		return

	if str(director.cue_for_line("G2-06-15").get("id", "")) != "MUS-04":
		push_error("MUS-04 must cover all of G2.")
		quit(1)
		return
	if str(director.cue_for_line("G3-03-04").get("id", "")) != "MUS-06B":
		push_error("MUS-06B must continue beneath the lead-in to the evidence event.")
		quit(1)
		return
	director.play_cue_id("MUS-05A")
	await create_timer(0.05).timeout
	director.sync_to_line("G3-03-05")
	await create_timer(0.05).timeout
	var loop_stream := (
		director.players[director.active_player_index].stream as AudioStreamOggVorbis
	)
	if (
		not director.is_cue_active("MUS-05B")
		or _playing_player_count(director) != 2
		or loop_stream == null
		or not loop_stream.loop
	):
		push_error("The evidence hit did not crossfade MUS-05A into MUS-05B.")
		quit(1)
		return
	director.fade_out(0.05, "MUS-05B")
	await create_timer(0.10).timeout
	if not director.active_cue_id.is_empty() or _any_player_is_playing(director):
		push_error("Music fade-out did not release both players.")
		quit(1)
		return

	print(
		"Music director test passed: discontiguous cue ranges, crossfades, "
		+ "dual players and fade-out."
	)
	director.hard_stop()
	director.cues.clear()
	director.cue_by_id.clear()
	director.free()
	quit(0)


func _any_player_is_playing(director: Node) -> bool:
	return _playing_player_count(director) > 0


func _playing_player_count(director: Node) -> int:
	var count := 0
	for player_variant in director.get("players") as Array:
		var player := player_variant as AudioStreamPlayer
		if player.playing:
			count += 1
	return count
