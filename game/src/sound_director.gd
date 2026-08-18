class_name SoundDirector
extends Node

const SILENCE_DB := -80.0
const DEFAULT_FADE_SECONDS := 0.65
const AMBIENCE_BUS := "Ambience"
const SFX_BUS := "SFX"

const AMBIENCE_CUES := {
	"city_drive": {
		"stream": "res://assets/audio/ambience/amb-g1-city-drive.ogg",
		"volume_db": -3.0,
	},
	"office": {
		"stream": "res://assets/audio/ambience/amb-g1-office.ogg",
		"volume_db": -2.0,
	},
	"creative_wind": {
		"stream": "res://assets/audio/ambience/amb-g0-rooftop-wind-v2.ogg",
		"volume_db": -6.0,
	},
	"seaside": {
		"stream": "res://assets/audio/ambience/amb-g5-seaside.ogg",
		"volume_db": 0.0,
	},
}

const EVENT_CUES := {
	"G1-01-D01": {
		"stream": "res://assets/audio/sfx/sfx-g0-opening-wind-howl.ogg",
		"volume_db": -2.0,
		"active_lines": ["G1-01-D01", "G1-01-D02"],
	},
	"G1-01-D03": {
		"stream": "res://assets/audio/sfx/sfx-g0-church-bell.ogg",
		"volume_db": -8.0,
		"automatic": false,
		"active_lines": ["G1-01-D03"],
	},
	"G1-01-D17": {
		"stream": "res://assets/audio/sfx/sfx-g0-train-whistle.ogg",
		"volume_db": -12.0,
		"automatic": false,
		"active_lines": ["G1-01-D17"],
	},
	"G1-01-08": {
		"stream": "res://assets/audio/sfx/sfx-g1-morning-wash.ogg",
		"volume_db": 0.0,
		"active_lines": ["G1-01-08", "G1-01-09", "G1-01-10"],
	},
	"G1-01-15": {
		"stream": "res://assets/audio/sfx/sfx-g1-car-door.ogg",
		"volume_db": -5.0,
		"active_lines": ["G1-01-15"],
	},
}

var ambience_players: Array[AudioStreamPlayer] = []
var ambience_states: Array[Dictionary] = []
var event_players: Array[AudioStreamPlayer] = []
var event_cue_ids_by_player: Array[String] = []
var event_fade_tweens: Array = []
var active_ambience_id := ""
var active_ambience_player_index := -1
var next_event_player_index := 0
var last_event_line_id := ""
var suppressed_event_line_id := ""


func setup() -> bool:
	_ensure_audio_bus(AMBIENCE_BUS)
	_ensure_audio_bus(SFX_BUS)
	for index in range(2):
		var ambience_player := AudioStreamPlayer.new()
		ambience_player.name = "AmbiencePlayer%s" % ["A", "B"][index]
		ambience_player.bus = AMBIENCE_BUS
		ambience_player.volume_db = SILENCE_DB
		add_child(ambience_player)
		ambience_players.append(ambience_player)
		ambience_states.append({
			"gain": 0.0,
			"start_gain": 0.0,
			"target_gain": 0.0,
			"elapsed": 0.0,
			"duration": 0.0,
		})
	for index in range(3):
		var event_player := AudioStreamPlayer.new()
		event_player.name = "EventPlayer%d" % (index + 1)
		event_player.bus = SFX_BUS
		add_child(event_player)
		event_players.append(event_player)
		event_cue_ids_by_player.append("")
		event_fade_tweens.append(null)
	set_process(false)
	return _all_assets_loadable()


func sync_to_line(line_id: String, play_event: bool = true) -> void:
	_stop_events_outside_line(line_id)
	suppressed_event_line_id = "" if play_event else line_id
	var next_ambience_id := ambience_for_line(line_id)
	if next_ambience_id != active_ambience_id:
		var fade_seconds := 0.24 if line_id == "G1-01-21" else DEFAULT_FADE_SECONDS
		if next_ambience_id.is_empty():
			fade_out(fade_seconds)
		else:
			_play_ambience(next_ambience_id, fade_seconds)
	if play_event and line_id != last_event_line_id:
		play_event_for_line(line_id)
	last_event_line_id = line_id


func ambience_for_line(line_id: String) -> String:
	if line_id >= "G1-01-18" and line_id <= "G1-01-20":
		return "city_drive"
	if line_id.begins_with("G1-03-"):
		return "office"
	if line_id.begins_with("G1-04-"):
		return "creative_wind"
	if (
		line_id >= "G5-04-03"
		and (
			line_id.begins_with("G5-04-")
			or line_id.begins_with("G5-05-")
		)
	):
		return "seaside"
	return ""


func event_for_line(line_id: String) -> Dictionary:
	return EVENT_CUES.get(line_id, {}) as Dictionary


func play_event_for_line(line_id: String, force: bool = false) -> float:
	var cue := event_for_line(line_id)
	if (
		cue.is_empty()
		or line_id == suppressed_event_line_id
		or (not force and not bool(cue.get("automatic", true)))
	):
		return 0.0
	return _play_event(line_id, cue)


func fade_out(seconds: float = DEFAULT_FADE_SECONDS) -> void:
	for index in range(ambience_players.size()):
		if ambience_players[index].playing:
			_begin_ambience_fade(index, 0.0, seconds)
	active_ambience_id = ""
	active_ambience_player_index = -1


func hard_stop() -> void:
	for index in range(ambience_players.size()):
		ambience_players[index].stop()
		ambience_players[index].stream = null
		_set_ambience_gain(index, 0.0)
		var state := ambience_states[index]
		state["start_gain"] = 0.0
		state["target_gain"] = 0.0
		state["elapsed"] = 0.0
		state["duration"] = 0.0
	for player in event_players:
		player.stop()
		player.stream = null
	for tween_variant in event_fade_tweens:
		var tween := tween_variant as Tween
		if tween != null and tween.is_valid():
			tween.kill()
	for index in range(event_cue_ids_by_player.size()):
		event_cue_ids_by_player[index] = ""
		event_fade_tweens[index] = null
	active_ambience_id = ""
	active_ambience_player_index = -1
	next_event_player_index = 0
	last_event_line_id = ""
	suppressed_event_line_id = ""
	set_process(false)


func set_paused(paused: bool) -> void:
	for player in ambience_players:
		player.stream_paused = paused
	for player in event_players:
		player.stream_paused = paused


func is_ambience_active(ambience_id: String) -> bool:
	return active_ambience_id == ambience_id


func is_event_active(event_line_id: String) -> bool:
	for index in range(event_players.size()):
		if event_cue_ids_by_player[index] == event_line_id and event_players[index].playing:
			return true
	return false


func _process(delta: float) -> void:
	var still_fading := false
	for index in range(ambience_states.size()):
		var state := ambience_states[index]
		var duration := float(state.get("duration", 0.0))
		if duration <= 0.0:
			continue
		var elapsed := minf(float(state.get("elapsed", 0.0)) + delta, duration)
		var progress := elapsed / duration
		var start_gain := float(state.get("start_gain", 0.0))
		var target_gain := float(state.get("target_gain", 0.0))
		var gain := lerpf(start_gain, target_gain, sin(progress * PI * 0.5))
		state["elapsed"] = elapsed
		_set_ambience_gain(index, gain)
		if elapsed >= duration:
			state["duration"] = 0.0
			_set_ambience_gain(index, target_gain)
			if target_gain <= 0.0001:
				ambience_players[index].stop()
				ambience_players[index].stream = null
		else:
			still_fading = true
	set_process(still_fading)


func _play_ambience(ambience_id: String, fade_seconds: float) -> void:
	var cue := AMBIENCE_CUES.get(ambience_id, {}) as Dictionary
	if cue.is_empty():
		push_error("Unknown ambience cue: %s" % ambience_id)
		return
	var stream_path := str(cue.get("stream", ""))
	var stream := ResourceLoader.load(stream_path) as AudioStream
	if stream == null:
		push_error("Cannot load ambience cue %s: %s" % [ambience_id, stream_path])
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true

	var next_index := _available_ambience_player_index()
	for index in range(ambience_players.size()):
		if index != next_index and ambience_players[index].playing:
			_begin_ambience_fade(index, 0.0, fade_seconds)
	ambience_players[next_index].stop()
	ambience_players[next_index].stream = stream
	_set_ambience_gain(next_index, 0.0)
	ambience_players[next_index].play()
	_begin_ambience_fade(
		next_index,
		db_to_linear(float(cue.get("volume_db", 0.0))),
		fade_seconds,
	)
	active_ambience_id = ambience_id
	active_ambience_player_index = next_index


func _play_event(line_id: String, cue: Dictionary) -> float:
	var stream_path := str(cue.get("stream", ""))
	var stream := ResourceLoader.load(stream_path) as AudioStream
	if stream == null:
		push_error("Cannot load sound event for %s: %s" % [line_id, stream_path])
		return 0.0
	var player_index := next_event_player_index
	var player := event_players[player_index]
	next_event_player_index = (player_index + 1) % event_players.size()
	var fade_tween := event_fade_tweens[player_index] as Tween
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	event_fade_tweens[player_index] = null
	player.stop()
	player.stream = stream
	player.volume_db = float(cue.get("volume_db", 0.0))
	player.play()
	event_cue_ids_by_player[player_index] = line_id
	return maxf(stream.get_length(), 0.0)


func _stop_events_outside_line(line_id: String) -> void:
	for index in range(event_players.size()):
		var cue_line_id := event_cue_ids_by_player[index]
		if cue_line_id.is_empty():
			continue
		if not event_players[index].playing:
			event_players[index].stream = null
			event_cue_ids_by_player[index] = ""
			continue
		var cue := event_for_line(cue_line_id)
		var active_lines := cue.get("active_lines", [cue_line_id]) as Array
		if not active_lines.has(line_id):
			_fade_out_event_player(index, 0.10)


func _fade_out_event_player(index: int, seconds: float) -> void:
	var player := event_players[index]
	var active_tween := event_fade_tweens[index] as Tween
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	if not player.playing or seconds <= 0.0:
		player.stop()
		player.stream = null
		event_cue_ids_by_player[index] = ""
		event_fade_tweens[index] = null
		return
	var tween := create_tween()
	event_fade_tweens[index] = tween
	tween.tween_property(player, "volume_db", SILENCE_DB, seconds)
	tween.finished.connect(_finish_event_fade.bind(index))


func _finish_event_fade(index: int) -> void:
	event_fade_tweens[index] = null
	event_players[index].stop()
	event_players[index].stream = null
	event_cue_ids_by_player[index] = ""


func _available_ambience_player_index() -> int:
	for index in range(ambience_players.size()):
		if index != active_ambience_player_index and not ambience_players[index].playing:
			return index
	for index in range(ambience_players.size()):
		if index != active_ambience_player_index:
			return index
	return 0


func _begin_ambience_fade(index: int, target_gain: float, seconds: float) -> void:
	var state := ambience_states[index]
	state["start_gain"] = float(state.get("gain", 0.0))
	state["target_gain"] = maxf(target_gain, 0.0)
	state["elapsed"] = 0.0
	state["duration"] = maxf(seconds, 0.0)
	if seconds <= 0.0:
		_set_ambience_gain(index, target_gain)
		if target_gain <= 0.0001:
			ambience_players[index].stop()
			ambience_players[index].stream = null
		return
	set_process(true)


func _set_ambience_gain(index: int, gain: float) -> void:
	var safe_gain := maxf(gain, 0.0)
	ambience_states[index]["gain"] = safe_gain
	ambience_players[index].volume_db = (
		linear_to_db(safe_gain) if safe_gain > 0.0001 else SILENCE_DB
	)


func _all_assets_loadable() -> bool:
	for cue_variant in AMBIENCE_CUES.values():
		var cue := cue_variant as Dictionary
		if ResourceLoader.load(str(cue.get("stream", ""))) == null:
			return false
	for cue_variant in EVENT_CUES.values():
		var cue := cue_variant as Dictionary
		if ResourceLoader.load(str(cue.get("stream", ""))) == null:
			return false
	return true


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
