extends SceneTree

const VoiceSequencePlayerClass := preload("res://src/voice_sequence_player.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var timeline := VoiceSequencePlayerClass.new()
	root.add_child(timeline)
	if not timeline.setup():
		push_error("Voice sequence player setup failed.")
		quit(1)
		return
	if (
		not timeline.has_sequence_for_unit("G4-01")
		or not timeline.has_sequence_for_line("G4-01-09")
		or not timeline.is_soundtrack_line("G4-01-01")
	):
		push_error("G4-01 timed soundtrack mapping is incomplete.")
		quit(1)
		return

	var emitted: Array[String] = []
	var handoffs: Array[String] = []
	timeline.cue_started.connect(func(line_id: String) -> void: emitted.append(line_id))
	timeline.handoff_reached.connect(func(unit_id: String) -> void: handoffs.append(unit_id))
	if not timeline.start_for_line("G4-01", "G4-01-01"):
		push_error("G4-01 timed soundtrack could not start.")
		quit(1)
		return
	timeline.seek(12.50)
	await process_frame
	if emitted != ["G4-01-01", "G4-01-02", "G4-01-03"]:
		push_error("Timed soundtrack did not emit ordered subtitle cues: %s" % emitted)
		quit(1)
		return
	timeline.seek(56.52)
	await process_frame
	if handoffs != ["G4-01"] or not timeline.is_active():
		push_error("Timed soundtrack did not expose its controlled handoff point.")
		quit(1)
		return
	timeline.set_paused(true)
	if not timeline.player.stream_paused:
		push_error("Timed soundtrack did not pause with blocking UI.")
		quit(1)
		return
	timeline.set_paused(false)
	timeline.fade_out(0.04)
	await create_timer(0.08).timeout
	if timeline.is_active() or timeline.player.stream != null:
		push_error("Timed soundtrack did not fade and release its stream at the age jump.")
		quit(1)
		return
	timeline.queue_free()
	await process_frame
	print("Voice sequence test passed: reusable timeline, ordered cues, pause and controlled fade-out.")
	quit(0)
