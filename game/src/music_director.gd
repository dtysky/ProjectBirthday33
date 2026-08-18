class_name MusicDirector
extends Node

const CUE_DATA_PATH := "res://content/music_cues.json"
const SILENCE_DB := -80.0
const AUDIO_BUSES := ["Voice", "Narration", "Ambience", "SFX", "Music"]

var cues: Array = []
var cue_by_id: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var channel_states: Array[Dictionary] = []

var music_bed_db := -3.0
var default_fade_in_seconds := 1.5
var default_fade_out_seconds := 2.2
var default_crossfade_seconds := 2.0
var active_cue_id := ""
var active_player_index := -1


func setup() -> bool:
	if not _load_cue_data():
		return false
	_ensure_audio_buses()
	for index in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "MusicPlayer%s" % ["A", "B"][index]
		player.bus = "Music"
		player.volume_db = SILENCE_DB
		add_child(player)
		players.append(player)
		channel_states.append({
			"gain": 0.0,
			"start_gain": 0.0,
			"target_gain": 0.0,
			"elapsed": 0.0,
			"duration": 0.0,
		})
	set_process(false)
	return true


func sync_to_line(line_id: String) -> void:
	var next_cue := cue_for_line(line_id)
	var next_cue_id := str(next_cue.get("id", ""))
	if next_cue_id == active_cue_id:
		return
	if next_cue_id.is_empty():
		_stop_for_active_cue()
		return
	_play_cue(next_cue)


func play_cue_id(cue_id: String) -> void:
	var cue := cue_by_id.get(cue_id, {}) as Dictionary
	if cue.is_empty():
		push_error("Unknown music cue: %s" % cue_id)
		return
	if active_cue_id == cue_id:
		return
	_play_cue(cue)


func cue_for_line(line_id: String) -> Dictionary:
	if line_id.is_empty():
		return {}
	for cue_variant in cues:
		var cue := cue_variant as Dictionary
		if str(cue.get("trigger_mode", "line")) == "custom":
			continue
		if _cue_covers_line(cue, line_id):
			return cue
	return {}


func _cue_covers_line(cue: Dictionary, line_id: String) -> bool:
	var ranges := cue.get("ranges", []) as Array
	if ranges.is_empty():
		ranges = [{
			"start_line": cue.get("start_line", ""),
			"end_line": cue.get("end_line", ""),
		}]
	for range_variant in ranges:
		var line_range := range_variant as Dictionary
		var start_line := str(line_range.get("start_line", ""))
		var end_line := str(line_range.get("end_line", ""))
		if line_id >= start_line and line_id <= end_line:
			return true
	return false


func fade_out(seconds: float = -1.0, expected_cue_id: String = "") -> void:
	if not expected_cue_id.is_empty() and active_cue_id != expected_cue_id:
		return
	var duration := seconds
	if duration < 0.0:
		var cue := cue_by_id.get(active_cue_id, {}) as Dictionary
		duration = float(cue.get("fade_out_seconds", default_fade_out_seconds))
	_fade_all_to_silence(duration)


func hard_stop() -> void:
	for index in range(players.size()):
		players[index].stop()
		players[index].stream = null
		_set_channel_gain(index, 0.0)
		var state := channel_states[index]
		state["start_gain"] = 0.0
		state["target_gain"] = 0.0
		state["elapsed"] = 0.0
		state["duration"] = 0.0
	active_cue_id = ""
	active_player_index = -1
	set_process(false)


func is_cue_active(cue_id: String) -> bool:
	return active_cue_id == cue_id


func _process(delta: float) -> void:
	var still_fading := false
	for index in range(channel_states.size()):
		var state := channel_states[index]
		var duration := float(state.get("duration", 0.0))
		if duration <= 0.0:
			continue
		var elapsed := minf(float(state.get("elapsed", 0.0)) + delta, duration)
		var progress := elapsed / duration
		var start_gain := float(state.get("start_gain", 0.0))
		var target_gain := float(state.get("target_gain", 0.0))
		var gain: float
		if target_gain >= start_gain:
			gain = lerpf(start_gain, target_gain, sin(progress * PI * 0.5))
		else:
			gain = target_gain + (start_gain - target_gain) * cos(progress * PI * 0.5)
		state["elapsed"] = elapsed
		_set_channel_gain(index, gain)
		if elapsed >= duration:
			state["duration"] = 0.0
			_set_channel_gain(index, target_gain)
			if target_gain <= 0.0001:
				players[index].stop()
				players[index].stream = null
		else:
			still_fading = true
	set_process(still_fading)


func _play_cue(cue: Dictionary) -> void:
	var stream_path := str(cue.get("stream", ""))
	var stream := ResourceLoader.load(stream_path) as AudioStream
	if stream == null:
		push_error("Cannot load music cue %s: %s" % [cue.get("id", ""), stream_path])
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = bool(cue.get("loop", true))

	var hard_transition := str(cue.get("start_mode", "crossfade")) == "hard"
	if hard_transition:
		hard_stop()
	var had_active_cue := not active_cue_id.is_empty()
	var next_index := _available_player_index()
	var transition_seconds := 0.0
	if not hard_transition:
		transition_seconds = float(
			cue.get(
				"crossfade_seconds" if had_active_cue else "fade_in_seconds",
				default_crossfade_seconds if had_active_cue else default_fade_in_seconds,
			)
		)
	for index in range(players.size()):
		if index != next_index and players[index].playing:
			_begin_fade(index, 0.0, transition_seconds)

	players[next_index].stop()
	players[next_index].stream = stream
	_set_channel_gain(next_index, 0.0)
	players[next_index].play()
	_begin_fade(next_index, 1.0, transition_seconds)
	active_cue_id = str(cue.get("id", ""))
	active_player_index = next_index


func _available_player_index() -> int:
	if active_player_index >= 0:
		return 1 - active_player_index
	for index in range(players.size()):
		if not players[index].playing:
			return index
	return 0 if _channel_gain(0) <= _channel_gain(1) else 1


func _stop_for_active_cue() -> void:
	if active_cue_id.is_empty():
		return
	var cue := cue_by_id.get(active_cue_id, {}) as Dictionary
	if str(cue.get("stop_mode", "fade")) == "hard":
		hard_stop()
		return
	fade_out(float(cue.get("fade_out_seconds", default_fade_out_seconds)))


func _fade_all_to_silence(seconds: float) -> void:
	for index in range(players.size()):
		if players[index].playing:
			_begin_fade(index, 0.0, maxf(seconds, 0.0))
	active_cue_id = ""
	active_player_index = -1


func _begin_fade(index: int, target_gain: float, seconds: float) -> void:
	var state := channel_states[index]
	state["start_gain"] = _channel_gain(index)
	state["target_gain"] = clampf(target_gain, 0.0, 1.0)
	state["elapsed"] = 0.0
	state["duration"] = maxf(seconds, 0.0)
	if seconds <= 0.0:
		_set_channel_gain(index, target_gain)
		if target_gain <= 0.0001:
			players[index].stop()
			players[index].stream = null
		return
	set_process(true)


func _channel_gain(index: int) -> float:
	return float(channel_states[index].get("gain", 0.0))


func _set_channel_gain(index: int, gain: float) -> void:
	gain = clampf(gain, 0.0, 1.0)
	channel_states[index]["gain"] = gain
	players[index].volume_db = (
		SILENCE_DB if gain <= 0.0001 else music_bed_db + linear_to_db(gain)
	)


func _load_cue_data() -> bool:
	var file := FileAccess.open(CUE_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open music cue data: %s" % CUE_DATA_PATH)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Music cue data is not a JSON object.")
		return false
	var data := parsed as Dictionary
	cues = data.get("cues", []) as Array
	if cues.is_empty():
		push_error("Music cue data has no cues.")
		return false
	music_bed_db = float(data.get("music_bed_db", music_bed_db))
	default_fade_in_seconds = float(
		data.get("default_fade_in_seconds", default_fade_in_seconds)
	)
	default_fade_out_seconds = float(
		data.get("default_fade_out_seconds", default_fade_out_seconds)
	)
	default_crossfade_seconds = float(
		data.get("default_crossfade_seconds", default_crossfade_seconds)
	)
	cue_by_id.clear()
	for cue_variant in cues:
		var cue := cue_variant as Dictionary
		cue_by_id[str(cue.get("id", ""))] = cue
	return true


func _ensure_audio_buses() -> void:
	for bus_name in AUDIO_BUSES:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var bus_index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, "Master")
