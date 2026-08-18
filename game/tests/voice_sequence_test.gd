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
	var narration_bus_index := AudioServer.get_bus_index("Narration")
	if (
		narration_bus_index < 0
		or AudioServer.get_bus_effect_count(narration_bus_index) != 5
		or not is_equal_approx(
			AudioServer.get_bus_volume_db(narration_bus_index),
			0.0,
		)
		or not AudioServer.get_bus_effect(narration_bus_index, 0) is AudioEffectHighPassFilter
		or not AudioServer.get_bus_effect(narration_bus_index, 1) is AudioEffectEQ10
		or not AudioServer.get_bus_effect(narration_bus_index, 2) is AudioEffectCompressor
		or not AudioServer.get_bus_effect(narration_bus_index, 3) is AudioEffectAmplify
		or not AudioServer.get_bus_effect(narration_bus_index, 4) is AudioEffectLimiter
	):
		push_error("Realtime narration enhancement bus is incomplete.")
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
	var segment_emitted: Array[String] = []
	var handoffs: Array[String] = []
	var finishes: Array[String] = []
	timeline.cue_started.connect(func(line_id: String) -> void: emitted.append(line_id))
	timeline.segment_cue_started.connect(
		func(line_id: String, segment_index: int) -> void:
			segment_emitted.append("%s/%d" % [line_id, segment_index])
	)
	timeline.handoff_reached.connect(func(unit_id: String) -> void: handoffs.append(unit_id))
	timeline.sequence_finished.connect(
		func(unit_id: String, handed_off: bool, advance_on_finish: bool) -> void:
			finishes.append("%s/%s/%s" % [unit_id, handed_off, advance_on_finish])
	)
	if not timeline.start_for_line("G4-01", "G4-01-01"):
		push_error("G4-01 timed soundtrack could not start.")
		quit(1)
		return
	if (
		str(timeline.player.bus) != "Voice"
		or not is_equal_approx(timeline.player.volume_db, -4.0)
	):
		push_error("G4-01 original soundtrack routing or reviewed gain is incorrect.")
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

	if (
		not timeline.has_sequence_for_line("G1-01-02")
		or not timeline.has_sequence_for_segment("G1-01-02", 1)
		or not timeline.has_sequence_for_line("G4-02-18")
		or timeline.is_soundtrack_line("G4-02-18")
		or timeline.line_advances_automatically("G4-02-18")
	):
		push_error("Manual narration mappings are incomplete or incorrectly automated.")
		quit(1)
		return
	emitted.clear()
	segment_emitted.clear()
	if not timeline.start_for_line("G1-01", "G1-01-02"):
		push_error("Manual narration page could not start.")
		quit(1)
		return
	await process_frame
	if (
		not emitted.is_empty()
		or not segment_emitted.is_empty()
		or timeline.advances_automatically()
		or str(timeline.player.bus) != "Narration"
		or not is_equal_approx(timeline.player.volume_db, -2.0)
	):
		push_error(
			"Manual narration unexpectedly emitted cues, auto-advanced, or used the wrong processing route."
		)
		quit(1)
		return
	timeline.call("_on_player_finished")
	await process_frame
	if finishes != ["G1-01/false/false"] or timeline.is_active():
		push_error("A completed manual narration page attempted to advance the story.")
		quit(1)
		return
	if not timeline.start_for_segment("G1-01", "G1-01-02", 1):
		push_error("Reviewed second-page narration could not be triggered by page advance.")
		quit(1)
		return
	timeline.stop()
	emitted.clear()
	if (
		not timeline.has_sequence_for_line("G5-05-03")
		or not timeline.line_advances_automatically("G5-05-03")
		or not timeline.start_for_line("G5-05", "G5-05-03")
	):
		push_error("G5 ending identity sequence could not start as a controlled timeline.")
		quit(1)
		return
	timeline.seek(5.45)
	await process_frame
	if emitted != ["G5-05-03"]:
		push_error("G5 ending did not delay the first identity cue until after the walk.")
		quit(1)
		return
	timeline.seek(7.40)
	await process_frame
	if emitted != ["G5-05-03", "G5-05-04"]:
		push_error("G5 ending identity lines did not remain in one ordered voice sequence.")
		quit(1)
		return
	timeline.seek(10.25)
	await process_frame
	if handoffs != ["G4-01", "G5-05"]:
		push_error("G5 ending did not hand off from the identity line to its final hold.")
		quit(1)
		return
	timeline.stop()
	timeline.queue_free()
	await process_frame
	print(
		"Voice sequence test passed: soundtrack handoff, manual narration and the G5 ending timeline."
	)
	quit(0)
