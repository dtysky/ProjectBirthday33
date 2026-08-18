class_name VoiceSequencePlayer
extends Node

signal cue_started(line_id: String)
signal segment_cue_started(line_id: String, segment_index: int)
signal handoff_reached(unit_id: String)
signal sequence_finished(unit_id: String, handed_off: bool, advance_on_finish: bool)

const CONFIG_PATH := "res://content/voice_sequences.json"
const NARRATION_BUS := "Narration"
const NARRATION_MAKEUP_GAIN_DB := 1.8

var player: AudioStreamPlayer
var sequences_by_unit: Dictionary = {}
var cues_by_line: Dictionary = {}
var cues_by_segment: Dictionary = {}
var active_sequence: Dictionary = {}
var active_unit_id := ""
var next_cue_index := 0
var _active := false
var _handoff_emitted := false
var fade_tween: Tween


func setup() -> bool:
	_configure_narration_bus()
	player = AudioStreamPlayer.new()
	player.name = "VoiceTrack"
	add_child(player)
	player.finished.connect(_on_player_finished)
	if not _load_config():
		return false
	return true


func has_sequence_for_line(line_id: String) -> bool:
	return cues_by_line.has(line_id)


func has_sequence_for_segment(line_id: String, segment_index: int) -> bool:
	return cues_by_segment.has(_segment_key(line_id, segment_index))


func has_sequence_for_unit(unit_id: String) -> bool:
	return sequences_by_unit.has(unit_id)


func is_soundtrack_line(line_id: String) -> bool:
	if not cues_by_line.has(line_id):
		return false
	var mapped := cues_by_line[line_id] as Dictionary
	var sequence := mapped.get("sequence", {}) as Dictionary
	return bool(sequence.get("soundtrack", false))


func line_advances_automatically(line_id: String) -> bool:
	if not cues_by_line.has(line_id):
		return false
	var mapped := cues_by_line[line_id] as Dictionary
	var sequence := mapped.get("sequence", {}) as Dictionary
	return bool(sequence.get("advance_on_finish", true))


func advances_automatically() -> bool:
	return _active and bool(active_sequence.get("advance_on_finish", true))


func start_for_line(unit_id: String, line_id: String, resume_position := -1.0) -> bool:
	if not cues_by_line.has(line_id):
		return false
	return _start_mapped(unit_id, cues_by_line[line_id] as Dictionary, resume_position)


func start_for_segment(unit_id: String, line_id: String, segment_index: int) -> bool:
	var key := _segment_key(line_id, segment_index)
	if not cues_by_segment.has(key):
		return false
	return _start_mapped(unit_id, cues_by_segment[key] as Dictionary)


func _start_mapped(unit_id: String, mapped: Dictionary, resume_position := -1.0) -> bool:
	var sequence := mapped.get("sequence", {}) as Dictionary
	if str(sequence.get("unit_id", "")) != unit_id:
		return false
	var stream_path := str(sequence.get("stream", ""))
	var stream := ResourceLoader.load(stream_path) as AudioStream
	if stream == null:
		push_error("Voice sequence stream could not be loaded: %s" % stream_path)
		return false

	stop()
	active_sequence = sequence.duplicate(true)
	active_unit_id = unit_id
	player.stream = stream
	player.bus = _playback_bus(sequence)
	player.volume_db = float(sequence.get("volume_db", 0.0))
	var cue_index := int(mapped.get("index", 0))
	var cue := (sequence.get("cues", []) as Array)[cue_index] as Dictionary
	var sequence_start_at := float(sequence.get("start_at", 0.0))
	var start_position := (
		resume_position
		if resume_position >= 0.0
		else (sequence_start_at if cue_index == 0 else float(cue.get("at", 0.0)))
	)
	next_cue_index = (
		cue_index
		if bool(sequence.get("emit_cues", true))
		else (sequence.get("cues", []) as Array).size()
	)
	_active = true
	_handoff_emitted = false
	player.play(maxf(0.0, start_position))
	_emit_due_cues(start_position + 0.02)
	_emit_due_handoff(start_position + 0.02)
	return true


func resume_carry(unit_id: String, position: float) -> bool:
	if not sequences_by_unit.has(unit_id):
		return false
	var sequence := sequences_by_unit[unit_id] as Dictionary
	var handoff_at := float(sequence.get("handoff_at", -1.0))
	if handoff_at < 0.0 or position < handoff_at:
		return false
	var stream_path := str(sequence.get("stream", ""))
	var stream := ResourceLoader.load(stream_path) as AudioStream
	if stream == null:
		push_error("Voice sequence stream could not be loaded: %s" % stream_path)
		return false

	stop()
	active_sequence = sequence.duplicate(true)
	active_unit_id = unit_id
	player.stream = stream
	player.bus = _playback_bus(sequence)
	player.volume_db = float(sequence.get("volume_db", 0.0))
	next_cue_index = (sequence.get("cues", []) as Array).size()
	_active = true
	_handoff_emitted = true
	player.play(maxf(0.0, position))
	return true


func seek(position: float) -> void:
	if not _active:
		return
	if position < player.get_playback_position():
		next_cue_index = 0
	player.seek(maxf(0.0, position))
	_emit_due_cues(position + 0.03)
	_emit_due_handoff(position + 0.03)


func stop() -> void:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = null
	_active = false
	active_sequence.clear()
	active_unit_id = ""
	next_cue_index = 0
	_handoff_emitted = false
	if player != null:
		player.stop()
		player.stream = null
		player.volume_db = 0.0


func fade_out(duration: float) -> void:
	if not _active or player == null:
		stop()
		return
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(
		player,
		"volume_db",
		-60.0,
		maxf(0.01, duration),
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.finished.connect(_finish_fade_out)


func _finish_fade_out() -> void:
	fade_tween = null
	stop()


func set_paused(paused: bool) -> void:
	if player != null:
		player.stream_paused = paused


func is_active() -> bool:
	return _active


func is_carrying_soundtrack() -> bool:
	return (
		_active
		and _handoff_emitted
		and bool(active_sequence.get("soundtrack", false))
	)


func get_position() -> float:
	if not _active or player == null:
		return 0.0
	return player.get_playback_position()


func get_state() -> Dictionary:
	if not _active:
		return {}
	return {
		"unit_id": active_unit_id,
		"position": get_position(),
		"handed_off": _handoff_emitted,
	}


func _process(_delta: float) -> void:
	if not _active or player == null or not player.playing or player.stream_paused:
		return
	var position := player.get_playback_position() + 0.025
	_emit_due_cues(position)
	_emit_due_handoff(position)


func _emit_due_cues(position: float) -> void:
	var cues := active_sequence.get("cues", []) as Array
	while next_cue_index < cues.size():
		var cue := cues[next_cue_index] as Dictionary
		if float(cue.get("at", 0.0)) > position:
			break
		next_cue_index += 1
		var line_id := str(cue.get("line_id", ""))
		var segment_index := int(cue.get("segment_index", 0))
		if segment_index > 0:
			segment_cue_started.emit(line_id, segment_index)
		else:
			cue_started.emit(line_id)


func _emit_due_handoff(position: float) -> void:
	if _handoff_emitted:
		return
	var handoff_at := float(active_sequence.get("handoff_at", -1.0))
	if handoff_at < 0.0 or position < handoff_at:
		return
	_handoff_emitted = true
	handoff_reached.emit(active_unit_id)


func _on_player_finished() -> void:
	if not _active:
		return
	var finished_unit_id := active_unit_id
	var handed_off := _handoff_emitted
	var advance_on_finish := bool(active_sequence.get("advance_on_finish", true))
	_active = false
	active_sequence.clear()
	active_unit_id = ""
	next_cue_index = 0
	_handoff_emitted = false
	player.stream = null
	sequence_finished.emit(finished_unit_id, handed_off, advance_on_finish)


func _playback_bus(sequence: Dictionary) -> String:
	# G4-01 keeps its original mixed soundtrack route; only sequence gain is adjusted.
	# Every current non-soundtrack sequence is the protagonist's narration.
	if bool(sequence.get("soundtrack", false)):
		return str(sequence.get("bus", "Voice"))
	return NARRATION_BUS


func _configure_narration_bus() -> void:
	var voice_bus_index := AudioServer.get_bus_index("Voice")
	if voice_bus_index < 0:
		AudioServer.add_bus()
		voice_bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(voice_bus_index, "Voice")
	AudioServer.set_bus_send(voice_bus_index, "Master")

	var bus_index := AudioServer.get_bus_index(NARRATION_BUS)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, NARRATION_BUS)
	AudioServer.set_bus_send(bus_index, "Master")
	AudioServer.set_bus_volume_db(bus_index, 0.0)
	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_bypass_effects(bus_index, false)

	# Rebuild the dedicated chain so repeated setup calls remain deterministic.
	while AudioServer.get_bus_effect_count(bus_index) > 0:
		AudioServer.remove_bus_effect(bus_index, 0)

	var high_pass := AudioEffectHighPassFilter.new()
	high_pass.cutoff_hz = 65.0
	high_pass.resonance = 0.5
	high_pass.db = 1 # 12 dB/octave
	AudioServer.add_bus_effect(bus_index, high_pass)

	var equalizer := AudioEffectEQ10.new()
	equalizer.set_band_gain_db(2, 0.8) # 125 Hz: retain body
	equalizer.set_band_gain_db(3, 1.0) # 250 Hz: add chest weight
	equalizer.set_band_gain_db(4, -1.0) # 500 Hz: reduce boxiness
	equalizer.set_band_gain_db(6, 1.2) # 2 kHz: improve presence
	equalizer.set_band_gain_db(7, 0.3) # 4 kHz: preserve articulation
	equalizer.set_band_gain_db(8, -0.6) # 8 kHz: mild static de-essing
	AudioServer.add_bus_effect(bus_index, equalizer)

	var compressor := AudioEffectCompressor.new()
	compressor.threshold = -18.5
	compressor.ratio = 2.2
	compressor.gain = 0.0
	compressor.attack_us = 2000.0
	compressor.release_ms = 140.0
	compressor.mix = 0.8
	AudioServer.add_bus_effect(bus_index, compressor)

	# Keep make-up gain inside the effect chain so the final limiter always sees it.
	var makeup_gain := AudioEffectAmplify.new()
	makeup_gain.volume_db = NARRATION_MAKEUP_GAIN_DB
	AudioServer.add_bus_effect(bus_index, makeup_gain)

	var limiter := AudioEffectLimiter.new()
	limiter.threshold_db = -2.0
	limiter.ceiling_db = -1.0
	limiter.soft_clip_db = 1.5
	limiter.soft_clip_ratio = 6.0
	AudioServer.add_bus_effect(bus_index, limiter)


func _load_config() -> bool:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("Voice sequence config is missing: %s" % CONFIG_PATH)
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Voice sequence config is not a JSON object.")
		return false
	var root := parsed as Dictionary
	if int(root.get("version", 0)) != 1:
		push_error("Unsupported voice sequence config version.")
		return false
	for sequence_variant in root.get("sequences", []) as Array:
		var sequence := sequence_variant as Dictionary
		var unit_id := str(sequence.get("unit_id", ""))
		var cues := sequence.get("cues", []) as Array
		if unit_id.is_empty() or cues.is_empty():
			push_error("Voice sequence is missing a unit or cues.")
			return false
		var duration := float(sequence.get("duration", 0.0))
		var handoff_at := float(sequence.get("handoff_at", -1.0))
		if handoff_at >= 0.0 and (handoff_at >= duration or handoff_at <= 0.0):
			push_error("Voice sequence has an invalid handoff time: %s" % unit_id)
			return false
		sequences_by_unit[unit_id] = sequence
		for cue_index in range(cues.size()):
			var cue := cues[cue_index] as Dictionary
			var line_id := str(cue.get("line_id", ""))
			var segment_index := int(cue.get("segment_index", 0))
			if line_id.is_empty() or segment_index < 0:
				push_error("Voice cue line or segment is invalid: %s" % line_id)
				return false
			var segment_key := _segment_key(line_id, segment_index)
			if cues_by_segment.has(segment_key):
				push_error("Voice cue page is duplicated: %s" % segment_key)
				return false
			var mapped := {
				"sequence": sequence,
				"index": cue_index,
			}
			cues_by_segment[segment_key] = mapped
			if segment_index > 0:
				continue
			if cues_by_line.has(line_id):
				push_error("Voice cue line is duplicated: %s" % line_id)
				return false
			cues_by_line[line_id] = mapped
	return not sequences_by_unit.is_empty()


func _segment_key(line_id: String, segment_index: int) -> String:
	return "%s/%d" % [line_id, segment_index]
