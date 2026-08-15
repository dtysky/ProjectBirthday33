class_name VoiceSequencePlayer
extends Node

signal cue_started(line_id: String)
signal handoff_reached(unit_id: String)
signal sequence_finished(unit_id: String, handed_off: bool)

const CONFIG_PATH := "res://content/voice_sequences.json"

var player: AudioStreamPlayer
var sequences_by_unit: Dictionary = {}
var cues_by_line: Dictionary = {}
var active_sequence: Dictionary = {}
var active_unit_id := ""
var next_cue_index := 0
var _active := false
var _handoff_emitted := false
var fade_tween: Tween


func setup() -> bool:
	player = AudioStreamPlayer.new()
	player.name = "VoiceTrack"
	add_child(player)
	player.finished.connect(_on_player_finished)
	if not _load_config():
		return false
	return true


func has_sequence_for_line(line_id: String) -> bool:
	return cues_by_line.has(line_id)


func has_sequence_for_unit(unit_id: String) -> bool:
	return sequences_by_unit.has(unit_id)


func is_soundtrack_line(line_id: String) -> bool:
	if not cues_by_line.has(line_id):
		return false
	var mapped := cues_by_line[line_id] as Dictionary
	var sequence := mapped.get("sequence", {}) as Dictionary
	return bool(sequence.get("soundtrack", false))


func start_for_line(unit_id: String, line_id: String, resume_position := -1.0) -> bool:
	if not sequences_by_unit.has(unit_id) or not cues_by_line.has(line_id):
		return false
	var mapped := cues_by_line[line_id] as Dictionary
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
	player.bus = str(sequence.get("bus", "Voice"))
	player.volume_db = 0.0
	var cue_index := int(mapped.get("index", 0))
	var cue := (sequence.get("cues", []) as Array)[cue_index] as Dictionary
	var start_position := (
		resume_position
		if resume_position >= 0.0
		else (0.0 if cue_index == 0 else float(cue.get("at", 0.0)))
	)
	next_cue_index = cue_index
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
	player.bus = str(sequence.get("bus", "Voice"))
	player.volume_db = 0.0
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
		cue_started.emit(str(cue.get("line_id", "")))


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
	_active = false
	active_sequence.clear()
	active_unit_id = ""
	next_cue_index = 0
	_handoff_emitted = false
	player.stream = null
	sequence_finished.emit(finished_unit_id, handed_off)


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
			if line_id.is_empty() or cues_by_line.has(line_id):
				push_error("Voice cue line is empty or duplicated: %s" % line_id)
				return false
			cues_by_line[line_id] = {
				"sequence": sequence,
				"index": cue_index,
			}
	return not sequences_by_unit.is_empty()
